# Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying the Recipe Planner application to a Kubernetes cluster.

## Prerequisites

1. **Kubernetes Cluster**: Access to a Kubernetes cluster (local with Minikube/Kind, or cloud provider like GKE, EKS, AKS)
2. **kubectl**: Kubernetes command-line tool installed and configured
3. **Docker**: Docker installed for building images
4. **NGINX Ingress Controller**: Required for external access

## File Overview

- `postgresql.yml` - PostgreSQL StatefulSet with persistent storage
- `configmap.yml` - Non-sensitive application configuration
- `secrets.yml.example` - Template for sensitive data (database credentials, Rails keys)
- `deployment.yml` - Rails application deployment with 2 replicas
- `service.yml` - ClusterIP service for internal communication
- `ingress.yml` - Ingress rules for external HTTPS access

## Quick Start Deployment

### 1. Build and Push Docker Image

```bash
# Build the Docker image
docker build -t recipe-planner:latest .

# Tag for your registry (if using remote cluster)
docker tag recipe-planner:latest your-registry.com/recipe-planner:latest

# Push to registry
docker push your-registry.com/recipe-planner:latest

# Update deployment.yml to use your registry image
```

### 2. Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### 3. Create Secrets

```bash
# Copy the secrets example file
cp secrets.yml.example secrets.yml

# Generate base64 encoded values
# Linux/Mac:
echo -n "your-value" | base64

# Windows PowerShell:
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("your-value"))

# Edit secrets.yml with your actual values:
# - database-name: Base64 of "recipe_planner_production"
# - database-user: Base64 of your PostgreSQL username
# - database-password: Base64 of your secure password
# - rails-master-key: Base64 of your config/master.key content
# - secret-key-base: Base64 of output from: rails secret
```

### 4. Update Configuration

Edit `configmap.yml` and `ingress.yml` to match your environment:

```bash
# In configmap.yml:
# - Update RAILS_HOSTNAME to your domain

# In ingress.yml:
# - Replace recipe-planner.example.com with your actual domain (appears twice)
```

### 5. Deploy to Kubernetes

```bash
# Apply all manifests in order
kubectl apply -f configmap.yml
kubectl apply -f secrets.yml
kubectl apply -f postgresql.yml
kubectl apply -f deployment.yml
kubectl apply -f service.yml
kubectl apply -f ingress.yml
```

Or deploy everything at once:

```bash
kubectl apply -f k8s/
```

### 6. Verify Deployment

```bash
# Check all resources
kubectl get all

# Check pods status
kubectl get pods

# View logs
kubectl logs -l app=recipe-planner --tail=100 -f

# Check services
kubectl get services

# Check ingress
kubectl get ingress
```

### 7. Access the Application

```bash
# Get the ingress external IP
kubectl get ingress recipe-planner-ingress

# If using local cluster (Minikube), use port forwarding
kubectl port-forward service/recipe-planner 3000:80

# Access at: http://localhost:3000
```

## SSL/TLS Setup

### Option 1: cert-manager with Let's Encrypt (Recommended)

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Uncomment the cert-manager annotation in ingress.yml
# cert-manager.io/cluster-issuer: "letsencrypt-prod"

# Reapply ingress
kubectl apply -f ingress.yml
```

### Option 2: Manual Certificate

```bash
# Create TLS secret with your certificate
kubectl create secret tls recipe-planner-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key
```

## Scaling

```bash
# Scale application pods
kubectl scale deployment recipe-planner --replicas=3

# Enable horizontal pod autoscaling (HPA)
kubectl autoscale deployment recipe-planner \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

## Maintenance Commands

```bash
# View logs
kubectl logs -l app=recipe-planner --tail=100 -f

# Access Rails console
kubectl exec -it deployment/recipe-planner -- rails console

# Run database migrations manually
kubectl exec -it deployment/recipe-planner -- rails db:migrate

# Shell into a pod
kubectl exec -it deployment/recipe-planner -- bash

# Restart deployment (rolling restart)
kubectl rollout restart deployment/recipe-planner

# Check rollout status
kubectl rollout status deployment/recipe-planner

# View deployment history
kubectl rollout history deployment/recipe-planner

# Rollback to previous version
kubectl rollout undo deployment/recipe-planner
```

## Database Backup

```bash
# Backup PostgreSQL database
kubectl exec -it statefulset/postgres -- pg_dump -U postgres recipe_planner_production > backup.sql

# Restore database
kubectl exec -i statefulset/postgres -- psql -U postgres recipe_planner_production < backup.sql
```

## Troubleshooting

### Pods not starting

```bash
# Describe pod for events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check init container logs
kubectl logs <pod-name> -c db-migrate
```

### Database connection issues

```bash
# Check PostgreSQL pod
kubectl get pod -l app=postgres

# Check PostgreSQL logs
kubectl logs -l app=postgres

# Test connection from app pod
kubectl exec -it deployment/recipe-planner -- psql $DATABASE_URL -c "SELECT 1"
```

### Ingress not working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress details
kubectl describe ingress recipe-planner-ingress

# Check ingress logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

## Cleanup

```bash
# Delete all resources
kubectl delete -f k8s/

# Or delete individually
kubectl delete ingress recipe-planner-ingress
kubectl delete service recipe-planner
kubectl delete deployment recipe-planner
kubectl delete configmap recipe-planner-config
kubectl delete secret recipe-planner-secrets
kubectl delete statefulset postgres
kubectl delete service postgres
kubectl delete pvc postgres-pvc recipe-planner-storage-pvc
```

## Production Considerations

1. **Resource Limits**: Adjust CPU/memory limits based on your workload
2. **Database Backups**: Set up automated backups for PostgreSQL
3. **Monitoring**: Install Prometheus and Grafana for monitoring
4. **Logging**: Consider using ELK stack or similar for centralized logging
5. **Secrets Management**: Use external secrets managers (AWS Secrets Manager, HashiCorp Vault)
6. **Image Registry**: Use a private registry for production images
7. **Network Policies**: Implement network policies for security
8. **Pod Security**: Use Pod Security Standards/Policies
9. **High Availability**: Run multiple replicas across different nodes/zones
10. **Disaster Recovery**: Document and test your disaster recovery plan

## Support

For more information, see the main [CLAUDE.md](../CLAUDE.md) file in the project root.
