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

data "onepassword_item" "authentik" {
  vault = data.onepassword_vault.this.uuid
  title = "authentik"
}

data "onepassword_item" "forgejo" {
  vault = data.onepassword_vault.this.uuid
  title = "forgejo"
}

locals {
  authentik_fields = merge(
    {
      username = data.onepassword_item.authentik.username
      password = data.onepassword_item.authentik.password
    },
    try(merge([
      for section in data.onepassword_item.authentik.section : merge([
        for field in section.field : {
          (field.label) = field.value
        }
      ]...)
    ]...), {})
  )

  forgejo_fields = merge(
    {
      username = data.onepassword_item.forgejo.username
      password = data.onepassword_item.forgejo.password
    },
    try(merge([
      for section in data.onepassword_item.forgejo.section : merge([
        for field in section.field : {
          (field.label) = field.value
        }
      ]...)
    ]...), {})
  )
}

provider "authentik" {
  url   = var.AUTHENTIK_URL
  token = local.authentik_fields["OPENTOFU_TOKEN"]
}
