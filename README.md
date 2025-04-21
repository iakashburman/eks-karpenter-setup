# EKS Karpenter Setup using Terraform

This project helps you quickly spin up an Amazon EKS cluster with Karpenter using Terraform and Helm. Karpenter is used to automatically provision compute resources based on your application's needs.

---

## 🚀 Steps to Use

### 1. Clone the Repository

```bash

git clone https://github.com/iakashburman/eks-karpenter-setup.git
cd eks-karpenter-setup

Make sure your AWS credentials are configured. You can set them up using:

aws configure

Initialize and Apply Terraform
Run the following Terraform commands to create the EKS cluster along with required IAM roles and policies:

terraform init
terraform validate
terraform plan
terraform apply

This will take a few minutes to complete. Once the EKS cluster is ready, configure your local kubeconfig:

aws eks update-kubeconfig --region us-east-1 --name karpenter-demo

Verify that your cluster nodes are up:

kubectl get nodes -o wide

Deploy Karpenter Using Helm commands are already there in the karpenter.sh file. Once deployed, apply the provisioner configuration:

kubectl apply -f provisioner.yaml

Check that the Karpenter pods are running:

kubectl get po -A -o wide | grep kar

Test with a Sample Deployment.
Create one namespace lets say test then apply the yaml file.

kubectl apply -f inflate.yaml

You can increase/decrease replicas to see Karpenter in action.

Cleanup Resources
After testing, do not forget to destroy the resources:

terraform destroy

Then, manually check the EC2 Spot Instances in the AWS Console. Karpenter might have created instances that Terraform cannot manage delete them manually if any are still running.

Notes:

This setup includes Terraform-managed IAM roles and policies.
Karpenter dynamically provisions Spot instances based on your deployment needs.
Make sure to monitor costs and clean up unused resources.

Thank You
Feel free to explore, test, and tweak the configuration. Happy building!