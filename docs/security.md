# Security

## Identity

- GitHub Actions uses Workload Identity Federation. No service-account keys are required.
- GKE workloads use Workload Identity Federation for GKE through the `retail-workloads` Kubernetes service account.
- Service accounts are split by runtime: data workloads, Composer, GKE nodes, dbt, and GitHub deploy.

## Network

- GKE nodes are private.
- Subnets have Private Google Access enabled.
- Cloud NAT provides controlled egress.
- Kubernetes NetworkPolicy defaults to namespace-local ingress, DNS egress, metadata-server egress for GKE Workload Identity Federation, and Google API egress only through Private Google Access.

## Data Protection

- Cloud Storage uses uniform bucket-level access and public access prevention.
- Buckets and BigQuery datasets use customer-managed KMS encryption.
- Secret Manager stores external platform credentials.
- Audit logs are enabled for BigQuery, Pub/Sub, and Cloud Storage data access.

## Production Hardening Checklist

- Replace broad deploy roles with custom IAM roles after first successful deployment.
- Enable Binary Authorization for GKE image admission.
- Add VPC Service Controls around BigQuery, Storage, and Pub/Sub.
- Use self-hosted runners for private-only GKE control-plane access.
- Add organization policies for service-account key disablement and uniform bucket access.
