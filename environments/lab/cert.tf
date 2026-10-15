# TLS certificates via Google Cloud Certificate Manager.
#
# A Google-managed certificate is issued through DNS authorization and published
# in a certificate map, which is attached to the global HTTPS target proxy in
# `load-balancer.tf`. This is the "cert" path: no certificate material is stored
# in the repository.

resource "google_certificate_manager_dns_authorization" "hello_world" {
  project  = var.project_id
  name     = "${var.project_name}-hello-world-dnsauth"
  location = "global"
  domain   = var.domain_name

  depends_on = [google_project_service.required]
}

resource "google_certificate_manager_certificate" "hello_world" {
  project  = var.project_id
  name     = "${var.project_name}-hello-world-cert"
  location = "global"

  managed {
    domains            = [var.domain_name]
    dns_authorizations = [google_certificate_manager_dns_authorization.hello_world.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_certificate_manager_certificate_map" "hello_world" {
  project     = var.project_id
  name        = "${var.project_name}-hello-world-certmap"
  description = "Certificate map for the hello-world global external load balancer"
}

resource "google_certificate_manager_certificate_map_entry" "hello_world" {
  project      = var.project_id
  name         = "${var.project_name}-hello-world-certmap-entry"
  map          = google_certificate_manager_certificate_map.hello_world.name
  certificates = [google_certificate_manager_certificate.hello_world.id]
  hostname     = var.domain_name
}

# Optional: create the DNS records in a Cloud DNS managed zone owned by you.
# When var.manage_dns_records is false, create them manually using the
# `dns_authorization_record` output and the `hello_world_public_ip` output.
resource "google_dns_record_set" "a" {
  count        = var.manage_dns_records ? 1 : 0
  project      = var.project_id
  managed_zone = var.dns_managed_zone_name
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.hello_world.address]
}

resource "google_dns_record_set" "dns_authorization" {
  count        = var.manage_dns_records ? 1 : 0
  project      = var.project_id
  managed_zone = var.dns_managed_zone_name
  name         = google_certificate_manager_dns_authorization.hello_world.dns_resource_record[0].name
  type         = google_certificate_manager_dns_authorization.hello_world.dns_resource_record[0].type
  ttl          = 300
  rrdatas      = [google_certificate_manager_dns_authorization.hello_world.dns_resource_record[0].data]
}
