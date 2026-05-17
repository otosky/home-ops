variable "OP_CONNECT_HOST" {
  type        = string
  description = "1Password Connect API URL."
}

variable "OP_CONNECT_TOKEN" {
  type        = string
  description = "1Password Connect API token."
  sensitive   = true
}

variable "OP_VAULT_NAME" {
  type        = string
  description = "1Password vault containing Terraform-managed application secrets."
  default     = "Homelab-Kubernetes"
}

variable "CLUSTER_DOMAIN" {
  type        = string
  description = "Primary cluster DNS domain."
  default     = "toskbot.xyz"
}

variable "AUTHENTIK_URL" {
  type        = string
  description = "Base URL for Authentik."
}
