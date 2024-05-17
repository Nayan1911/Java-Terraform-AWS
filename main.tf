# Configure AWS region (replace with your desired region)
variable "aws_region" {
  type = string
  default = "us-east-1"
}

# Define EKS cluster and ECR repository names
variable "eks_cluster_name" {
  type = string
  default = "java-app-cluster"
}

variable "ecr_repository_name" {
  type = string
  default = "java-app-ecr-repo"
}

# ... other variables for image tag, service type, etc. (add as needed)

# Create VPC with public and private subnets
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  subnet {
    cidr_block = "10.0.1.0/24"
    availability_zone = var.aws_region + "a"
  }

  subnet {
    cidr_block = "10.0.2.0/24"
    availability_zone = var.aws_region + "b"
  }
}

# Create security group for the EKS cluster
resource "aws_security_group" "cluster_sg" {
  name = "eks-cluster-sg"
  description = "Security group for EKS cluster"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all ingress for initial setup (adjust later)
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IAM roles for the EKS cluster and service account
resource "aws_iam_role" "cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  # ... attach necessary policies
}

resource "aws_iam_role" "service_account_role" {
  name = "java-app-service-account-role"
  # ... attach policies for service account access
}

# Create an Amazon ECR repository to store your Docker image
resource "aws_ecr_repository" "app_repository" {
  name = var.ecr_repository_name
}

# Configure Kubernetes provider with EKS cluster details
provider "kubernetes" {
  host        = aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.cluster_certificate)
  token       = aws_eks_cluster_auth.cluster_auth.token
}

# Provision the EKS cluster using the configured VPC and security group
resource "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  vpc_config {
    security_group_ids = [aws_security_group.cluster_sg.id]
    subnet_ids = [
      aws_subnet.public.id,
      aws_subnet.private.id,
    ]
  }
  # ... other cluster configuration options (e.g., node group configuration)
}

# Define Kubernetes deployment for your Java application
resource "kubernetes_deployment" "java_app_deployment" {
  metadata {
    name = "java-app"
  }

  spec {
    replicas = 2  # Adjust replica count as needed

    selector {
      match_labels = {
        app = "java-app"
      }
    }
  }

    template {
      metadata {
        labels = {
          app = "java-app"
        }
      }

      spec {
        container {
          name = "java-app"
          image = "sharmanayan/hello-world:0.1.RELEASE"  # Update with
        }
      }
    }
}

