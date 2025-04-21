helm install karpenter karpenter/karpenter \
  --namespace karpenter \
  --create-namespace \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$(terraform output -raw karpenter_iam_role_arn) \
  --set clusterName=$(terraform output -raw cluster_name) \
  --set clusterEndpoint=$(terraform output -raw cluster_endpoint) \
  --set aws.defaultInstanceProfile=KarpenterNodeInstanceProfile