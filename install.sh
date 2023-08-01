#!/bin/bash

# Command 1
aws iam create-policy --policy-name VeleroAccessPolicy --policy-document file://velero_policy.json

# Command 2
eksctl utils associate-iam-oidc-provider --region=eu-west-3 --cluster=myapp-eks-cluster --approve

# Command 3
eksctl create iamserviceaccount --cluster="myapp-eks-cluster" --name=velero-server --namespace=velero --role-name=eks-velero-backup --role-only --attach-policy-arn=arn:aws:iam::949351973512:policy/VeleroAccessPolicy --approve

# Command 4
helm install velero vmware-tanzu/velero --create-namespace --namespace velero -f values.yaml

# Command 5
kubectl get pods -n velero

# Command 6
velero get backup location

# Command 7
velero backup-location create default --provider aws --bucket ghassenfinal --config region=eu-west-3
