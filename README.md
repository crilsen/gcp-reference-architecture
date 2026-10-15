# Google Cloud: GKE Standard on Compute Engine

This implementation is the Google Cloud equivalent of EKS with EC2 worker nodes:
Google manages the Kubernetes control plane, while a GKE Standard node pool runs
on configurable Compute Engine VMs. It is not Autopilot and it does not install
Kubernetes directly with `kubeadm`.

## Lab architecture

```text
Internet
   |
   +-- restricted public GKE API endpoint (/32 allowlist)
   |
Google Cloud VPC (custom mode, regional routing)
   |
   +-- subnet 10.62.0.0/20
       +-- secondary range: Pods 10.63.0.0/16
       +-- secondary range: Services 10.64.0.0/20
       +-- private GKE Standard node pool (Compute Engine)
              |
              +-- Cloud Router -> Cloud NAT -> outbound Internet

Google-managed GKE control plane
Artifact Registry
Cloud Logging + Monitoring + Managed Service for Prometheus
Workload Identity Federation for GKE

Internet -> global static IP -> global external Application Load Balancer
         (Cloud Armor + Certificate Manager) -> GKE standalone NEG -> Pod
```

Terraform creates:

- required project APIs;
- a custom-mode VPC, subnet, VPC Flow Logs, Pod and Service alias-IP ranges;
- regional Cloud Router and Public Cloud NAT for nodes without public IPs;
- ingress, IAP SSH, explicit egress, and deny-by-default firewall rules;
- a zonal private-node GKE Standard cluster using the Regular release channel;
- a separately managed, autoscaling Compute Engine node pool;
- Dataplane V2, Cloud DNS, CSI drivers, managed Prometheus, Logging, and Monitoring;
- a least-privilege node service account and Workload Identity;
- a regional Docker Artifact Registry repository;
- a global external Application Load Balancer (backend service, URL map, HTTPS
  and HTTP->HTTPS forwarding rules) in front of a GKE standalone NEG;
- a Cloud Armor security policy (per-IP rate limiting and preconfigured WAF);
- a Google-managed TLS certificate issued by Certificate Manager and wired to
  the load balancer through a certificate map.

GCP VPCs already install the local subnet route and default Internet route. GKE
VPC-native uses alias IP routes for Pods and Services. Custom static routes are
therefore neither necessary nor desirable here; Cloud Router and Cloud NAT own
private-node egress.

## Before applying

Use an existing project with billing linked. The caller needs permission to enable
APIs, create IAM bindings, networks, GKE clusters, service accounts, and Artifact
Registry repositories.

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

Edit `environments/lab/terraform.tfvars`:

1. Replace `replace-with-gcp-project-id`.
2. Replace the documentation address `203.0.113.10/32` with your current public
   IPv4 address followed by `/32`.
3. Keep one zonal node initially. Set `node_spot = true` only for interruptible
   workloads.

## Deploy

Create the remote-state bucket once before initializing the Lab environment:

```bash
terraform -chdir=gcp/bootstrap/state init
terraform -chdir=gcp/bootstrap/state apply \
  -var='project_id=YOUR_PROJECT_ID' \
  -var='bucket_name=YOUR_GLOBALLY_UNIQUE_TFSTATE_BUCKET'
```

If the Lab already has local state, migrate it safely to GCS:

```bash
terraform -chdir=gcp/environments/lab init -migrate-state \
  -backend-config='bucket=YOUR_GLOBALLY_UNIQUE_TFSTATE_BUCKET' \
  -backend-config='prefix=environments/lab'
```

For a new environment, replace `-migrate-state` with `-reconfigure`. See
`gcp/bootstrap/state/README.md` for verification and recovery guidance.

```bash
cd gcp/environments/lab
terraform fmt -check -recursive
terraform validate
# Phase 1: cluster and network only (the load balancer needs the app's NEG).
terraform apply -var enable_application_load_balancer=false
```

Then deploy the application and apply again with the load balancer enabled (see
the next section and `kubernetes/hello-world/README.md`).

Connect after apply:

```bash
gcloud container clusters get-credentials kubernetes-lab \
  --zone us-east1-b \
  --project YOUR_PROJECT_ID
kubectl get nodes -o wide
kubectl get pods --all-namespaces
```

If your public IP changes, update `master_authorized_networks` and apply again
before using `kubectl`.

## Load balancer, Cloud Armor, and TLS

The global external Application Load Balancer, its Cloud Armor policy, and the
Certificate Manager certificate are managed by `environments/lab` (files
`load-balancer.tf` and `cert.tf`), not by a Kubernetes Ingress. The Service
exposes a standalone NEG that Terraform references by name.

Because the NEG exists only after the Service is applied, the lab applies in two
phases: create the cluster with `enable_application_load_balancer = false`,
deploy the application, then apply with the load balancer enabled. See
`kubernetes/hello-world/README.md` for the exact sequence, the DNS records, and
the Cloud Armor and certificate settings (`terraform.tfvars`).

## Trial cost controls

The defaults deliberately use a zonal cluster and one `e2-standard-2` node. The
GKE monthly free-tier credit covers the management fee of one zonal Standard
cluster, but not Compute Engine, disks, NAT, logs, network egress, or load
balancers. Autoscaling can grow to two nodes, so watch Billing closely.

For an idle lab, destroy it instead of merely scaling workloads to zero:

```bash
terraform destroy
```

`deletion_protection` defaults to `false` only so this disposable lab can be
destroyed. Enable it for any persistent environment. A single-zone cluster is a
cost choice and is not highly available; production should use a regional cluster
and nodes spread across at least three zones.

## Organization boundary

`environments/organization` remains separate. It can create protected workload
projects and organization policies when you have a Google Cloud Organization.
The 90-day trial can deploy `environments/lab` directly into an existing billed
project without applying the organization root.
