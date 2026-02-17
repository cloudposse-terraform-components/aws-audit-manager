output "account_registration_id" {
  value       = one(aws_auditmanager_account_registration.default[*].id)
  description = "Unique identifier for the account registration"
}

output "account_registration_status" {
  value       = one(aws_auditmanager_account_registration.default[*].status)
  description = "Status of the account registration request"
}

output "organization_administrator_account_id" {
  value       = one(aws_auditmanager_organization_admin_account_registration.default[*].admin_account_id)
  description = "Organization administrator account ID"
}
