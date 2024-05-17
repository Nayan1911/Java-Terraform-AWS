provider "aws" {
  region = "us-east-1"  # Update with your desired AWS region
}

# Provision a VPC for the EKS cluster
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]  # Update with your desired availability zones
}

# Provision subnets for the EKS cluster across multiple availability zones
resource "aws_subnet" "eks_subnets" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = var.availability_zones[count.index]
}


# Create an IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name               = "example-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Provision an EKS cluster
resource "aws_eks_cluster" "example" {
  name            = "example-eks-cluster"
  role_arn        = aws_iam_role.eks_cluster_role.arn
  vpc_config {
    subnet_ids = aws_subnet.eks_subnets[*].id
  }
}


#Deploy the application to the Kubernetes cluster
resource "kubernetes_deployment" "example_app" {
  metadata {
    name      = "example-app"
    labels = {
      app = "example-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "example-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "example-app"
        }
      }

      spec {
        container {
          name  = "example-app"
          image = "sharmanayan/hello-world:0.1.RELEASE"  # Update with your Docker image

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Expose the application using a Kubernetes service
resource "kubernetes_service" "example_service" {
  metadata {
    name      = "example-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.example_app.spec[0].template[0].metadata[0].labels["app"]
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

