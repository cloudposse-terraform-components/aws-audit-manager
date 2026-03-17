variable "account_verification_enabled" {
  type        = bool
  description = <<-DOC
  Enable account verification. When true (default), the component verifies that Terraform is executing
  in the correct AWS account by comparing the current account ID against the expected account from the
  account_map based on the component's tenant-stage context.
  DOC
  default     = true
}

variable "account_map_enabled" {
  type        = bool
  description = <<-DOC
  Enable the account map component. When true, the component fetches account mappings from the
  `account-map` component via remote state. When false (default), the component uses the static `account_map` variable instead.
  DOC
  default     = false
}

variable "account_map" {
  type = object({
    full_account_map              = map(string)
    audit_account_account_name    = optional(string, "")
    root_account_account_name     = optional(string, "")
    identity_account_account_name = optional(string, "")
    aws_partition                 = optional(string, "aws")
    iam_role_arn_templates        = optional(map(string), {})
  })
  description = <<-DOC
  Static account map configuration. Only used when `account_map_enabled` is `false`.
  Map keys use `tenant-stage` format (e.g., `core-security`, `core-audit`, `plat-prod`).
  DOC
  default = {
    full_account_map              = {}
    audit_account_account_name    = ""
    root_account_account_name     = ""
    identity_account_account_name = ""
    aws_partition                 = "aws"
    iam_role_arn_templates        = {}
  }
}

variable "account_map_component_name" {
  type        = string
  description = "The name of the account-map component"
  default     = "account-map"
}

variable "account_map_tenant" {
  type        = string
  default     = "core"
  description = "The tenant where the `account_map` component required by remote-state is deployed"
}

variable "global_environment" {
  type        = string
  default     = "gbl"
  description = "Global environment name"
}

variable "privileged" {
  type        = bool
  default     = false
  description = "true if the default provider already has access to the backend"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "root_account_stage" {
  type        = string
  default     = "root"
  description = <<-DOC
  The stage name for the Organization root (management) account. This is used to lookup account IDs from account names
  using the `account-map` component.
  DOC
}

variable "delegated_administrator_account_name" {
  type        = string
  default     = "core-security"
  description = "The name of the account that is the AWS Organization Delegated Administrator account"
}

variable "deregister_on_destroy" {
  type        = bool
  default     = true
  description = "Flag to deregister AuditManager in the account upon destruction. If set to `false`, AuditManager will remain active in the account, even if this resource is removed"
}
