# SeekrFlow Scripts

1. Authenticate to the Seekr ECR Repository using an assumable role:

```bash
bash ./scripts/auth.sh \
 --customer-arn arn:aws:iam::{customer-account-id}:role/{role-name} \
 --seekr-role-arn arn:aws:iam::515966517287:role/seekrflow-helm-chart-ecr-access
```

2. Update the values.yaml file and add your License key. See `Required Values` in `Configuration` section below.

3. Install the chart:

```bash
# Install the chart
bash ./scripts/helm.sh install --release-name seekrflow --namespace seekrflow --version 1.6.0 --values values.yaml

# Upgrade the chart
bash ./scripts/helm.sh upgrade --release-name seekrflow --namespace seekrflow --version 1.6.0 --values values.yaml
```

Customers can use their own auth and pull methods. Above are simple wrappers to AWS account role assumption and ecr oci helm chart pulls.

```bash
# Assume the roles to get access to the cross account images
aws sts assume-role --role-arn "arn:aws:iam::{customer-account-id}:role/{role-name}" --role-session-name Customer-ECR-Session --output json

aws sts assume-role --role-arn "arn:aws:iam::515966517287:role/seekrflow-helm-chart-ecr-access" --role-session-name SeekrFlow-ECR-Session --output json

# Login to ecr
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 515966517287.dkr.ecr.us-east-1.amazonaws.com

# Pull seekrflow helm chart
helm pull oci://515966517287.dkr.ecr.us-east-1.amazonaws.com/seekr/flow-helm-chart --version 1.6.0

# Install the seekrflow helm chart
helm install seekrflow . -n seekrflow --values values.yaml --create-namespace

# Upgrade the seekrflow helm chart
helm upgrade --install seekrflow . --values values.yaml
```
