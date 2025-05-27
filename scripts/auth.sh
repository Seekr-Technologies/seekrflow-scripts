#!/bin/bash

set -e

print_usage() {
  cat <<EOF
Usage: $0 [OPTIONS] [COMMAND]

Options:
  --customer-arn ARN        ARN of the first role to assume
  --seekr-role-arn ARN      ARN of the second role
  --ecr-registry URL        ECR registry URL
  --validate                Validate roles after assuming them

Example:
  $0 --customer-arn arn:aws:iam::123:role/customer-role --seekr-role-arn arn:aws:iam::515966517287:role/seekrflow-helm-chart-ecr-access --validate
EOF
}

VALIDATE=false
while [ $# -gt 0 ]; do
  case "$1" in
  --customer-arn)
    CUSTOMER_ROLE_ARN="$2"
    shift
    ;;
  --seekr-role-arn)
    SEEKR_ROLE_ARN="$2"
    shift
    ;;
  --ecr-registry)
    ECR_REGISTRY="$2"
    shift
    ;;
  --validate)
    VALIDATE=true
    ;;
  -h | --help)
    print_usage
    exit 0
    ;;
  *)
    echo "Unknown parameter: $1"
    print_usage
    exit 1
    ;;
  esac
  shift
done

CUSTOMER_ROLE_ARN="${CUSTOMER_ROLE_ARN}"
SEEKR_ROLE_ARN="${SEEKR_ROLE_ARN:-"arn:aws:iam::515966517287:role/seekrflow-helm-chart-ecr-access"}"
ECR_REGISTRY="${ECR_REGISTRY:-"515966517287.dkr.ecr.us-east-1.amazonaws.com"}"
REGION=$(echo ${ECR_REGISTRY} | awk -F'.' '{print $4}')

# Assume the customer role from their own account
customer_account=$(aws sts assume-role --role-arn "$CUSTOMER_ROLE_ARN" --role-session-name Customer-ECR-Session --output json)

export AWS_ACCESS_KEY_ID=$(echo "$customer_account" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$customer_account" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$customer_account" | jq -r '.Credentials.SessionToken')

if [ "$VALIDATE" = true ]; then
  aws sts get-caller-identity
fi

# Assume the Seekr role using credentials from the customer account
seekr_account=$(aws sts assume-role --role-arn "$SEEKR_ROLE_ARN" --role-session-name SeekrFlow-ECR-Session --output json)

AWS_ACCESS_KEY_ID=$(echo "$seekr_account" | jq -r '.Credentials.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo "$seekr_account" | jq -r '.Credentials.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo "$seekr_account" | jq -r '.Credentials.SessionToken')

echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID " >.seekr-ecr-access-env
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >>.seekr-ecr-access-env
echo "export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" >>.seekr-ecr-access-env

if [ "$VALIDATE" = true ]; then
  aws sts get-caller-identity
fi

# Seekr ECR login and Helm OCI ECR pull
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$ECR_REGISTRY"
