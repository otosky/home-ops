locals {
  forgejo_url = "https://forgejo.${var.CLUSTER_DOMAIN}"
}

resource "authentik_group" "forgejo_users" {
  name = "forgejo-users"
}

resource "authentik_group" "forgejo_admins" {
  name = "forgejo-admins"
}

resource "authentik_provider_oauth2" "forgejo" {
  name                       = "Forgejo"
  client_id                  = local.forgejo_fields["AUTHENTIK_CLIENT_ID"].value
  client_secret              = local.forgejo_fields["AUTHENTIK_CLIENT_SECRET"].value
  client_type                = "confidential"
  authorization_flow         = data.authentik_flow.authorization.id
  invalidation_flow          = data.authentik_flow.invalidation.id
  signing_key                = data.authentik_certificate_key_pair.generated.id
  include_claims_in_id_token = true
  access_token_validity      = "hours=4"

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "${local.forgejo_url}/user/oauth2/authentik/callback"
    },
  ]

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    [authentik_property_mapping_provider_scope.groups.id],
  )
}

resource "authentik_application" "forgejo" {
  name               = "Forgejo"
  slug               = "forgejo"
  protocol_provider  = authentik_provider_oauth2.forgejo.id
  meta_launch_url    = local.forgejo_url
  policy_engine_mode = "all"
}

resource "authentik_policy_binding" "forgejo_users_access" {
  target = authentik_application.forgejo.uuid
  group  = authentik_group.forgejo_users.id
  order  = 0
}

resource "authentik_policy_binding" "forgejo_admins_access" {
  target = authentik_application.forgejo.uuid
  group  = authentik_group.forgejo_admins.id
  order  = 1
}
