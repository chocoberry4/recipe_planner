#!/bin/bash
# Kubernetes Deployment Helper Script for Recipe Planner

set -e

NAMESPACE=${NAMESPACE:-default}
IMAGE_TAG=${IMAGE_TAG:-latest}
REGISTRY=${REGISTRY:-recipe-planner}

echo "========================================="
echo "Recipe Planner Kubernetes Deployment"
echo "========================================="
echo ""

# Function to check if secrets.yml exists
check_secrets() {
  if [ ! -f "secrets.yml" ]; then
    echo "❌ Error: secrets.yml not found!"
    echo ""
    echo "Please create secrets.yml from the template:"
    echo "  cp secrets.yml.example secrets.yml"
    echo ""
    echo "Then edit secrets.yml with your actual base64-encoded values."
    exit 1
  fi
  echo "✅ secrets.yml found"
}

# Function to check kubectl
check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl not found!"
    echo "Please install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
  fi
  echo "✅ kubectl found"
}

# Function to check cluster connection
check_cluster() {
  if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Error: Cannot connect to Kubernetes cluster!"
    echo "Please configure kubectl to connect to your cluster."
    exit 1
  fi
  echo "✅ Connected to Kubernetes cluster"
}

# Function to deploy
deploy() {
  echo ""
  echo "Deploying to namespace: $NAMESPACE"
  echo "Using image tag: $IMAGE_TAG"
  echo ""

  # Create namespace if it doesn't exist
  kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

  # Apply manifests
  echo "📦 Applying ConfigMap..."
  kubectl apply -f configmap.yml -n $NAMESPACE

  echo "🔐 Applying Secrets..."
  kubectl apply -f secrets.yml -n $NAMESPACE

  echo "🗄️  Deploying PostgreSQL..."
  kubectl apply -f postgresql.yml -n $NAMESPACE

  echo "⏳ Waiting for PostgreSQL to be ready..."
  kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=120s || true

  echo "🚀 Deploying Application..."
  kubectl apply -f deployment.yml -n $NAMESPACE

  echo "🌐 Creating Service..."
  kubectl apply -f service.yml -n $NAMESPACE

  echo "🔌 Creating Ingress..."
  kubectl apply -f ingress.yml -n $NAMESPACE

  echo ""
  echo "✅ Deployment complete!"
  echo ""
}

# Function to show status
status() {
  echo ""
  echo "========================================="
  echo "Deployment Status"
  echo "========================================="
  echo ""

  echo "📦 Pods:"
  kubectl get pods -n $NAMESPACE
  echo ""

  echo "🌐 Services:"
  kubectl get services -n $NAMESPACE
  echo ""

  echo "🔌 Ingress:"
  kubectl get ingress -n $NAMESPACE
  echo ""
}

# Function to show logs
logs() {
  echo "📋 Application Logs (last 50 lines):"
  kubectl logs -l app=recipe-planner -n $NAMESPACE --tail=50
}

# Function to delete deployment
delete() {
  echo "⚠️  WARNING: This will delete all Recipe Planner resources!"
  read -p "Are you sure? (yes/no): " -r
  echo ""
  if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "🗑️  Deleting resources..."
    kubectl delete -f . -n $NAMESPACE || true
    echo "✅ Cleanup complete!"
  else
    echo "❌ Deletion cancelled"
  fi
}

# Main script
case "${1:-deploy}" in
  deploy)
    check_kubectl
    check_cluster
    check_secrets
    deploy
    status
    ;;
  status)
    check_kubectl
    check_cluster
    status
    ;;
  logs)
    check_kubectl
    check_cluster
    logs
    ;;
  delete)
    check_kubectl
    check_cluster
    delete
    ;;
  *)
    echo "Usage: $0 {deploy|status|logs|delete}"
    echo ""
    echo "Commands:"
    echo "  deploy  - Deploy Recipe Planner to Kubernetes (default)"
    echo "  status  - Show deployment status"
    echo "  logs    - Show application logs"
    echo "  delete  - Delete all Recipe Planner resources"
    echo ""
    echo "Environment variables:"
    echo "  NAMESPACE   - Kubernetes namespace (default: default)"
    echo "  IMAGE_TAG   - Docker image tag (default: latest)"
    echo "  REGISTRY    - Docker registry (default: recipe-planner)"
    exit 1
    ;;
esac
