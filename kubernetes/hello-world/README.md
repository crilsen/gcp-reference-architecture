# Hello World with a Terraform-managed global Application Load Balancer

The application is published by a **global external Application Load Balancer**
owned by Terraform (in `environments/lab`), with Cloud Armor and a
Google-managed TLS certificate from Certificate Manager:

```text
Internet -> global static IP -> HTTPS forwarding rule -> target HTTPS proxy
         -> URL map -> backend service (Cloud Armor)
         -> GKE standalone NEG -> ClusterIP Service -> Pod
```

The `Service` stays `ClusterIP` and exposes a standalone NEG through the
`cloud.google.com/neg` annotation. Terraform references that NEG by name and
creates every other load-balancer component.

> The GKE Ingress API does not support Certificate Manager certificate maps, so
> the load balancer is managed in Terraform instead of a Kubernetes Ingress.

## Deploy order

The standalone NEG exists only after the Service is applied to the cluster, and
Terraform's backend service references the NEG. The lab therefore applies in two
phases.

### 1. Create the cluster first

Keep the load balancer disabled for the first apply:

```bash
cd environments/lab
terraform init
terraform apply -var enable_application_load_balancer=false
```

### 2. Deploy the application (this creates the NEG)

```bash
gcloud container clusters get-credentials kubernetes-lab \
  --zone us-east1-b --project YOUR_PROJECT_ID

kubectl apply -f kubernetes/hello-world/hello-world.yaml
kubectl rollout status deployment/hello-world -n lab-workloads
```

Confirm the NEG was created (the name must be `kubernetes-lab-hello-world`):

```bash
kubectl get service hello-world -n lab-workloads \
  -o jsonpath='{.metadata.annotations.cloud\.google\.com/neg-status}'
gcloud compute network-endpoint-groups list --filter='name~hello-world'
```

### 3. Create the load balancer

```bash
cd environments/lab
terraform apply -var enable_application_load_balancer=true
terraform output hello_world_public_ip
terraform output dns_authorization_record
```

### 4. Configure DNS

Point your domain at the static IP and satisfy the Certificate Manager DNS
authorization. With `manage_dns_records = false`, create these records manually
in your DNS provider:

```text
A     gcp-test.example.com        -> <terraform output hello_world_public_ip>
CNAME <dns_authorization_record.name> -> <dns_authorization_record.data>
```

Replace `gcp-test.example.com` in `terraform.tfvars` (`domain_name`) with a domain
you control. If the zone is in Cloud DNS, set `manage_dns_records = true` and
`dns_managed_zone_name` so Terraform creates both records.

The certificate stays `PROVISIONING` until the DNS authorization record resolves;
provisioning can take up to a few hours.

## Validate

```bash
curl "https://gcp-test.example.com"
curl "https://gcp-test.example.com/healthz"
# HTTP redirects to HTTPS (301).
curl -I "http://gcp-test.example.com"
```

## Remove

Delete the Kubernetes resources first, then destroy Terraform:

```bash
kubectl delete -f kubernetes/hello-world/hello-world.yaml
terraform -chdir=environments/lab destroy
```

The load balancer, Cloud Armor policy, certificate, and static IP, plus logging
and network egress, generate charges against the trial credit.
