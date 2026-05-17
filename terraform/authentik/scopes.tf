data "authentik_flow" "authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "invalidation" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

data "authentik_property_mapping_provider_scope" "default" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

resource "authentik_property_mapping_provider_scope" "groups" {
  name       = "Forgejo groups"
  scope_name = "groups"
  expression = <<-EOF
    return {
      "groups": [group.name for group in request.user.ak_groups.all()],
    }
  EOF
}
