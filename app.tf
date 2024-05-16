resource "kubernetes_service_account" "example" {
  metadata {
    name      = "example-service-account"
    namespace = "default"
  }
}

resource "kubernetes_secret" "kubeconfig" {
  metadata {
    name      = "kubeconfig-secret"
    namespace = "default"
  }

  data = {
    "config" = base64encode(file("~/.kube/config"))
  }
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
        service_account_name = kubernetes_service_account.example.metadata.0.name

        container {
          image = "sharmanayan/hello-world:0.1.RELEASE"
          name  = "hello-app-container"

          port {
            container_port = 8080
            name           = "http"
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }

          volume {
            name = "kubeconfig-volume"

            secret {
              secret_name = kubernetes_secret.kubeconfig.metadata.0.name
            }
          }

          volume_mount {
            name      = "kubeconfig-volume"
            mount_path = "/kube/config"
            read_only = true
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
