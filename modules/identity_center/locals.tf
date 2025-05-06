locals {
  # Fetch instance details once
  identity_store_id = one(data.aws_ssoadmin_instances.this.identity_store_ids)
  instance_arn      = one(data.aws_ssoadmin_instances.this.arns)

  # Flatten users for easy lookup by user_name
  users_map = { for user in var.users : user.user_name => user }

  # Flatten group memberships: Create a list of { group_name, user_name }
  group_memberships_flat = flatten([
    for group_name, group_details in var.groups : [
      for member_user_name in group_details.members : {
        group_name = group_name
        user_name  = member_user_name
      } if contains(keys(local.users_map), member_user_name) # Ensure user exists
    ] if group_details.members != null                       # Handle potentially empty user lists
  ])

  # Flatten account assignments: Create a list of { unique_key, group_name, permission_set_name, account_id }
  account_assignments_flat = flatten([
    for assignment_rule in var.assignments : [
      for account_key in assignment_rule.account_keys : {
        assignment_resource_key = "${assignment_rule.group_name}-${assignment_rule.permission_set_name}-${account_key}"
        group_name              = assignment_rule.group_name
        permission_set_name     = assignment_rule.permission_set_name
        account_id              = var.target_accounts[account_key]
      } if contains(keys(var.target_accounts), account_key) && contains(keys(var.groups), assignment_rule.group_name) && contains(keys(var.permission_sets_config), assignment_rule.permission_set_name) # Safety checks
    ]
  ])

  # Prepare permission sets that use AWS managed policies
  permission_sets_aws_managed = {
    for name, config in var.permission_sets_config : name => config
    if config.aws_managed_policy != null && config.inline_policy == null
  }

  # Prepare permission sets that use inline policies
  permission_sets_aws_inline = {
    for name, config in var.permission_sets_config : name => config
    if config.inline_policy != null && config.aws_managed_policy == null
  }

  # Combine all created permission set ARNs for easier lookup in assignments
  all_permission_set_arns = merge(
    { for name, ps in aws_ssoadmin_permission_set.aws_managed : name => ps.arn },
    { for name, ps in aws_ssoadmin_permission_set.inline : name => ps.arn }
    # Add other types here if implementing customer managed policies etc.
  )
}