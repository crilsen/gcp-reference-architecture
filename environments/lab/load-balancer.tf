# Global external Application Load Balancer (L7) owned by Terraform and
# fronting a GKE standalone Network Endpoint Group (NEG).
#
# Traffic path:
#   Internet -> global static IP -> (HTTPS forwarding rule) -> target HTTPS proxy
#            -> URL map -> backend service (Cloud Armor) -> GKE NEG -> Pod
#
# The NEG is created by the GKE NEG controller from the `cloud.google.com/neg`
# annotation on the hello-world Service. Its name is fixed by var.neg_name so
# Terraform can reference it without a round trip to the cluster.

resource "google_compute_global_address" "hello_world" {
  project      = var.project_id
  name         = "hello-world-ip"
  description  = "Static external IP used by the hello-world global load balancer."
  address_type = "EXTERNAL"
  ip_version   = "IPV4"

  depends_on = [google_project_service.required]
}

locals {
  # Self-link of the standalone NEG managed by the GKE NEG controller.
  neg_self_link = "projects/${var.project_id}/zones/${var.gcp_zone}/networkEndpointGroups/${var.neg_name}"
}

resource "google_compute_health_check" "hello_world" {
  count   = var.enable_application_load_balancer ? 1 : 0
  project = var.project_id
  name    = "${var.project_name}-hello-world-health"

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 8080
    request_path = "/healthz"
  }
}

# Cloud Armor ---------------------------------------------------------------

resource "google_compute_security_policy" "hello_world" {
  count       = var.enable_cloud_armor ? 1 : 0
  project     = var.project_id
  name        = "${var.project_name}-hello-world-armor"
  description = "Cloud Armor policy for the hello-world GKE application"
  type        = "CLOUD_ARMOR"

  # Default rule: allow.
  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }

  # Per-client-IP rate limiting with a temporary ban.
  rule {
    action      = "rate_based_ban"
    priority    = 1000
    description = "Per-IP rate limit"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = 600

      rate_limit_threshold {
        count        = var.armor_rate_limit_count
        interval_sec = 60
      }
    }
  }

  # Preconfigured WAF: SQL injection.
  rule {
    action      = "deny(403)"
    priority    = 2000
    description = "SQL injection"

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
  }

  # Preconfigured WAF: cross-site scripting.
  rule {
    action      = "deny(403)"
    priority    = 2001
    description = "Cross-site scripting"

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
  }
}

# Backend, routing, and frontends -------------------------------------------

resource "google_compute_backend_service" "hello_world" {
  count                 = var.enable_application_load_balancer ? 1 : 0
  project               = var.project_id
  name                  = "${var.project_name}-hello-world-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  timeout_sec           = 30

  health_checks   = [google_compute_health_check.hello_world[0].id]
  security_policy = var.enable_cloud_armor ? google_compute_security_policy.hello_world[0].id : null

  backend {
    group                 = local.neg_self_link
    balancing_mode        = "RATE"
    max_rate_per_endpoint = var.backend_max_rate_per_endpoint
    capacity_scaler       = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_url_map" "hello_world" {
  count           = var.enable_application_load_balancer ? 1 : 0
  project         = var.project_id
  name            = "${var.project_name}-hello-world-urlmap"
  description     = "Routes requests for the hello-world application"
  default_service = google_compute_backend_service.hello_world[0].id

  host_rule {
    hosts        = [var.domain_name]
    path_matcher = "hello-world"
  }

  path_matcher {
    name            = "hello-world"
    default_service = google_compute_backend_service.hello_world[0].id
  }
}

resource "google_compute_ssl_policy" "hello_world" {
  count           = var.enable_application_load_balancer ? 1 : 0
  project         = var.project_id
  name            = "${var.project_name}-hello-world-ssl"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

resource "google_compute_target_https_proxy" "hello_world" {
  count           = var.enable_application_load_balancer ? 1 : 0
  project         = var.project_id
  name            = "${var.project_name}-hello-world-https"
  url_map         = google_compute_url_map.hello_world[0].id
  ssl_policy      = google_compute_ssl_policy.hello_world[0].id
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.hello_world.id}"
}

# HTTP -> HTTPS redirect.
resource "google_compute_url_map" "redirect" {
  count   = var.enable_application_load_balancer ? 1 : 0
  project = var.project_id
  name    = "${var.project_name}-hello-world-redirect"

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_target_http_proxy" "hello_world" {
  count   = var.enable_application_load_balancer ? 1 : 0
  project = var.project_id
  name    = "${var.project_name}-hello-world-http"
  url_map = google_compute_url_map.redirect[0].id
}

resource "google_compute_global_forwarding_rule" "https" {
  count                 = var.enable_application_load_balancer ? 1 : 0
  project               = var.project_id
  name                  = "${var.project_name}-hello-world-https"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.hello_world[0].id
  ip_address            = google_compute_global_address.hello_world.address
}

resource "google_compute_global_forwarding_rule" "http" {
  count                 = var.enable_application_load_balancer ? 1 : 0
  project               = var.project_id
  name                  = "${var.project_name}-hello-world-http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.hello_world[0].id
  ip_address            = google_compute_global_address.hello_world.address
}

# Allow load-balancer health checks and proxies to reach the application port.
resource "google_compute_firewall" "lb_health_check" {
  count   = var.enable_application_load_balancer ? 1 : 0
  project = var.project_id
  name    = "${var.project_name}-allow-lb-health-check"
  network = module.network.network_name

  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["${var.project_name}-gke-node"]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}
