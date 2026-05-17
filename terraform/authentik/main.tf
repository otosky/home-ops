terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2026.0"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.3"
    }
  }
}

provider "onepassword" {
  connect_url   = var.OP_CONNECT_HOST
  connect_token = var.OP_CONNECT_TOKEN
}

data "onepassword_vault" "this" {
  name = var.OP_VAULT_NAME
}

data "onepassword_item" "this" {
  for_each = toset(["authentik", "forgejo"])

  vault = data.onepassword_vault.this.uuid
  title = each.key
}

provider "authentik" {
  url   = var.AUTHENTIK_URL
  token = local.authentik_fields["OPENTOFU_TOKEN"].value
}
