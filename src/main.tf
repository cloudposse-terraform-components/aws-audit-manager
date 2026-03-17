locals {
  enabled                                = module.this.enabled
  account_map                            = module.account_map.outputs.full_account_map
  org_delegated_administrator_account_id = local.account_map[var.delegated_administrator_account_name]

  current_account_id = one(data.aws_caller_identity.this[*].account_id)
}

data "aws_caller_identity" "this" {
  count = local.enabled ? 1 : 0
}

# Enable Audit Manager in the Organization management (root) account
resource "aws_auditmanager_account_registration" "default" {
  count = local.enabled ? 1 : 0

  deregister_on_destroy = var.deregister_on_destroy
}

# Delegate Audit Manager to the administrator account (usually the security account)
resource "aws_auditmanager_organization_admin_account_registration" "default" {
  count = local.enabled ? 1 : 0

  admin_account_id = local.org_delegated_administrator_account_id

  depends_on = [aws_auditmanager_account_registration.default]
}
