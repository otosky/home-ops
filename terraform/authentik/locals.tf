locals {
  authentik_fields = data.onepassword_item.this["authentik"].section_map["terraform"].field_map
  forgejo_fields   = data.onepassword_item.this["forgejo"].section_map["terraform"].field_map
}
