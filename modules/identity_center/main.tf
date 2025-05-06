data "aws_ssoadmin_instances" "this" {}

# IAM Identity Center users
resource "aws_identitystore_user" "this" {
  for_each = local.users_map

  identity_store_id = local.identity_store_id
  user_name         = each.value.user_name
  display_name      = "${each.value.given_name} ${each.value.family_name}"

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value   = each.value.email
    primary = true
  }
}

# IAM Identity Center groups
resource "aws_identitystore_group" "this" {
  for_each = var.groups

  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = each.value.description
}

# Create group memberships
resource "aws_identitystore_group_membership" "this" {
  # Use a unique key combining group and user name for the for_each map
  for_each = { for membership in local.group_memberships_flat : "${membership.group_name}-${membership.user_name}" => membership }

  identity_store_id = local.identity_store_id
  group_id          = aws_identitystore_group.this[each.value.group_name].group_id
  member_id         = aws_identitystore_user.this[each.value.user_name].user_id

  depends_on = [
    aws_identitystore_group.this,
    aws_identitystore_user.this,
  ]
}

# --- Permission sets --- 

# Create permission sets using AWS managed policies
resource "aws_ssoadmin_permission_set" "aws_managed" {
  for_each = local.permission_sets_aws_managed

  name             = each.key
  description      = each.value.description
  instance_arn     = local.instance_arn
  session_duration = each.value.session_duration
}

resource "aws_ssoadmin_managed_policy_attachment" "aws_managed" {
  for_each = aws_ssoadmin_permission_set.aws_managed

  instance_arn       = local.instance_arn
  permission_set_arn = each.value.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/${local.permission_sets_aws_managed[each.key].aws_managed_policy}" # Use the policy name from config
}

# Create permission sets using inline policies
resource "aws_ssoadmin_permission_set" "inline" {
  for_each = local.permission_sets_aws_inline

  name             = each.key
  description      = each.value.description
  instance_arn     = local.instance_arn
  session_duration = each.value.session_duration
}

resource "aws_ssoadmin_permission_set_inline_policy" "inline" {
  for_each = aws_ssoadmin_permission_set.inline

  instance_arn       = local.instance_arn
  permission_set_arn = each.value.arn
  inline_policy      = local.permission_sets_aws_inline[each.key].inline_policy # Use the inline policy JSON from config
}

# --- Account assignments ---
# Assign groups to permission sets on specific AWS accounts
resource "aws_ssoadmin_account_assignment" "this" {
  for_each = { for assignment in local.account_assignments_flat : assignment.assignment_resource_key => assignment }

  instance_arn   = local.instance_arn
  target_type    = "AWS_ACCOUNT"
  target_id      = each.value.account_id
  principal_type = "GROUP"
  principal_id   = aws_identitystore_group.this[each.value.group_name].group_id

  # Look up the permission set ARN from the combined map
  permission_set_arn = lookup(local.all_permission_set_arns, each.value.permission_set_name, null)

  depends_on = [
    aws_identitystore_group.this,
    aws_ssoadmin_managed_policy_attachment.aws_managed,
    aws_ssoadmin_permission_set_inline_policy.inline,
    # Add other permission set attachment types if implemented
  ]
}