locals {
  enabled     = module.this.enabled
  account_map = module.account_map.outputs.full_account_map

  current_account_id = one(data.aws_caller_identity.this[*].account_id)
}

data "aws_caller_identity" "this" {
  count = local.enabled ? 1 : 0
}
