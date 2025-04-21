module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "karpenter-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/karpenter-demo" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = "karpenter-demo"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "karpenter-demo"
  cluster_version = "1.32"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.medium"]
      min_size      = 2
      max_size      = 3
      desired_size  = 2
    }
  }

  node_security_group_additional_rules = {
    ingress_karpenter_webhook = {
      description = "Cluster API to Karpenter webhook"
      protocol    = "tcp"
      from_port   = 8443
      to_port     = 8443
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    "karpenter.sh/discovery" = "karpenter-demo"
  }
}

resource "aws_iam_role" "karpenter_controller" {
  name = "karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "karpenter_controller" {
  name        = "KarpenterControllerPolicy"
  description = "Permissions for Karpenter controller"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "iam:PassRole",
          "ssm:GetParameter",
          "pricing:GetProducts"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:TerminateInstances"
        ],
        Resource = "arn:aws:ec2:*:*:instance/*",
        Condition = {
          "StringEquals": {
            "ec2:ResourceTag/karpenter.sh/provisioner-name": "*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

resource "aws_iam_role_policy_attachment" "karpenter_ssm" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile"
  role = module.eks.eks_managed_node_groups["initial"].iam_role_name
}


# Add this output if missing
output "aws_iam_instance_profile_karpenter_name" {
  value = aws_iam_instance_profile.karpenter.name
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "karpenter_iam_role_arn" {
  value = aws_iam_role.karpenter_controller.arn
}

