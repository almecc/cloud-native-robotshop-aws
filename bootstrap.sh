#!/bin/bash
# Run this once, right after "terraform apply" on a fresh cluster.
# These three things are not managed by Terraform and do not survive a rebuild.
set -e

echo "1. Switching cluster to API_AND_CONFIG_MAP auth mode..."
aws eks update-cluster-config \
  --name robotshop-cluster \
  --region us-east-1 \
  --access-config authenticationMode=API_AND_CONFIG_MAP

echo "   waiting for it to finish..."
while [ "$(aws eks describe-cluster --name robotshop-cluster --region us-east-1 --query cluster.status --output text)" != "ACTIVE" ]; do
  sleep 5
done

echo "2. Connecting kubectl..."
aws eks update-kubeconfig --region us-east-1 --name robotshop-cluster

echo "3. Installing metrics-server..."
kubectl apply -f 02-robotshop-on-eks/metrics-server.yaml

echo "4. Creating robot-shop namespace..."
kubectl create namespace robot-shop --dry-run=client -o yaml | kubectl apply -f -

echo "Done. Cluster is ready for: terraform apply (access entries) and the pipeline deploy job."
