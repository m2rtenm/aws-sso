output "identity_store_id" {
  value       = local.identity_store_id
  description = "The ID of the Identity Store associated with the IAM Identity Center instance"
}

output "identity_center_instance_arn" {
  value       = local.instance_arn
  description = "The ARN of the IAM Identity Center instance"
}

output "user_details" {
  value = { for name, user in aws_identitystore_user.this : name => {
    user_id      = user.user_id
    user_name    = user.user_name
    display_name = user.display_name
    # Add other relevant attributes if needed
  } }
  description = "Details of the created users"
  sensitive   = true
}

output "group_details" {
  value = { for name, group in aws_identitystore_group.this : name => {
    group_id     = group.group_id
    display_name = group.display_name
    description  = group.description
  } }
  description = "Details of the created groups"
}

output "permission_set_arns" {
  value       = local.all_permission_set_arns
  description = "Map of permission set names to their ARNs"
}

output "account_assignments" {
  value = { for key, assignment in aws_ssoadmin_account_assignment.this : key => {
    account_id         = assignment.target_id
    group_id           = assignment.principal_id
    permission_set_arn = assignment.permission_set_arn
  } }
  description = "Details of the created account assignments"
}
