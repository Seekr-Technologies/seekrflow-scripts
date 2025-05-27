#!/bin/bash

set -e

source .seekr-ecr-access-env

removeAWSCreds() {
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_ACCESS_KEY_ID
  unset AWS_SESSION_TOKEN

}

HELM_CHART_NAME="${HELM_CHART_NAME:-"seekr/flow-helm-chart"}"
HELM_CHART_VERSION="${HELM_CHART_VERSION:-"1.0.0"}"
HELM_VALUES_FILE="${HELM_VALUES_FILE:-"values.yaml"}"
RELEASE_NAME="${RELEASE_NAME:-"seekrflow"}"
NAMESPACE="${NAMESPACE:-"seekrflow"}"
ECR_REGISTRY="${ECR_REGISTRY:-"515966517287.dkr.ecr.us-east-1.amazonaws.com"}"
USE_TAR=false

print_usage() {
  cat <<EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
  pull                     Pull Helm chart from ECR/OCI registry
  install                  Install Helm chart (from ECR/OCI or local tar)
  upgrade                  Upgrade Helm release (from ECR/OCI or local tar)
  uninstall                Uninstall Helm release
  clean_helm               Remove downloaded Helm chart archive

Options:
  --release-name NAME      Helm release name (default: seekrflow)
  --namespace NAMESPACE    Kubernetes namespace (default: seekrflow)
  --helm-chart NAME        Helm chart name (default: seekr/flow-helm-chart)
  --version VERSION        Helm chart version (default: 1.0.0)
  --values VERSION         Helm values file (default: values.yaml)
  --ecr-registry URL       ECR registry URL (default: 515966517287.dkr.ecr.us-east-1.amazonaws.com)
  --use-tar                Use local Helm chart tar file instead of pulling from OCI (default: false)
  -h, --help               Show this help message

Examples:
  # Pull chart from OCI
  $0 pull --version 1.0.0

  # Install from OCI
  $0 install --release-name seekrflow --namespace seekrflow --version 1.0.0

  # Install from local tar
  $0 install --release-name seekrflow --use-tar

  # Upgrade from OCI
  $0 upgrade --release-name seekrflow --version 1.0.0

  # Uninstall release
  $0 uninstall --release-name seekrflow

  # Clean local Helm chart archive
  $0 clean_helm
EOF
}

COMMAND="$1"
shift

while [ $# -gt 0 ]; do
  case "$1" in
  --release-name)
    RELEASE_NAME="$2"
    shift
    ;;
  --namespace)
    NAMESPACE="$2"
    shift
    ;;
  --helm-chart)
    HELM_CHART_NAME="$2"
    shift
    ;;
  --version)
    HELM_CHART_VERSION="$2"
    shift
    ;;
  --values)
    HELM_VALUES_FILE="$2"
    shift
    ;;
  --ecr-registry)
    ECR_REGISTRY="$2"
    shift
    ;;
  --use-tar)
    USE_TAR=true
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

CHART_REF="$HELM_CHART_NAME-$HELM_CHART_VERSION.tgz"
OCI_REF="oci://$ECR_REGISTRY/$HELM_CHART_NAME"

case "$COMMAND" in
pull)
  helm pull "$OCI_REF" --version "$HELM_CHART_VERSION"
  ;;
install)
  removeAWSCreds

  if [ "$USE_TAR" = true ]; then
    helm install "$RELEASE_NAME" "$CHART_REF" -n "$NAMESPACE" --values "$HELM_VALUES_FILE" --create-namespace
  else
    helm install "$RELEASE_NAME" "$OCI_REF" --version "$HELM_CHART_VERSION" -n "$NAMESPACE" --values "$HELM_VALUES_FILE" --create-namespace
  fi
  ;;
upgrade)
  removeAWSCreds

  if [ "$USE_TAR" = true ]; then
    helm upgrade "$RELEASE_NAME" "$CHART_REF" -n "$NAMESPACE" --values "$HELM_VALUES_FILE"
  else
    helm upgrade "$RELEASE_NAME" "$OCI_REF" --version "$HELM_CHART_VERSION" -n "$NAMESPACE" --values "$HELM_VALUES_FILE"
  fi
  ;;
uninstall)
  removeAWSCreds

  helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
  ;;
clean_helm)
  rm -f "$CHART_REF"
  echo "Helm chart archive removed."
  ;;
*)
  echo "Unknown command: $COMMAND"
  print_usage
  exit 1
  ;;
esac
