provider "kubernetes" {
  config_path = "~/.kube/config"  # Specify the path to your kubeconfig file for AWS EKS
}

resource "kubernetes_deployment_v1" "default" {
  metadata {
    name = "example-hello-app-deployment"
  }

  spec {
    selector {
      match_labels = {
        app = "hello-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-app"
        }
      }

      spec {
        container {
          image = "sharmanayan/hello-world:0.1.RELEASE"  # Replace with your AWS ECR URL and image name
          name  = "hello-app-container"

          port {
            container_port = 8080
            name           = "hello-app-svc"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080  # Use the container port directly

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }

        security_context {
          run_as_non_root = true

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "default" {
  metadata {
    name = "example-hello-app-loadbalancer"
  }

  spec {
    selector = {
      app = kubernetes_deployment_v1.default.spec[0].selector[0].match_labels.app
    }

    port {
      port        = 80
      target_port = 8080  # Use the container port directly
    }

    type = "LoadBalancer"
  }
}
