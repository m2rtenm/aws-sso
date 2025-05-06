module "identity_center" {
  source = "./modules/identity_center"
  
  # Pass data from root locals to the module variables
  identity_center_region = local.identity_center_region
  target_accounts = local.target_accounts
  users = local.users
  groups = local.groups
  assignments = local.assignments
  permission_sets_config = local.permission_sets_config
}