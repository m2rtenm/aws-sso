locals {

  identity_center_region = "eu-north-1"

  # Define target accounts with ID-s
  target_accounts = {
    "dev"    = "390403872472"
    "prod"   = "565393049153"
    "shared" = "221082181947"
    "sec"    = "311141538914"
    # Add here other accounts as well if needed
  }

  # Define your users
  users = [
    { user_name = "liam.westbrook", given_name = "Liam", family_name = "Westbrook", email = "liam.westbrook@example.com" },
    { user_name = "ava.hartley", given_name = "Ava", family_name = "Hartley", email = "ava.hartley@example.com" },
    { user_name = "noah.caldwell", given_name = "Noah", family_name = "Caldwell", email = "noah.caldwell@example.com" },
    { user_name = "maya.dresden", given_name = "Maya", family_name = "Dresden", email = "maya.dresden@example.com" },
    { user_name = "ethan.sommer", given_name = "Ethan", family_name = "Sommer", email = "ethan.sommer@example.com" },
    { user_name = "zoe.langford", given_name = "Zoe", family_name = "Langford", email = "zoe.langford@example.com" },
    { user_name = "lucas.merrick", given_name = "Lucas", family_name = "Merrick", email = "lucas.merrick@example.com" },
  ]

  # Define your groups
  groups = {
    "SoftwareEngineers" = {
      description = "Software development team"
      members = ["liam.westbrook", "ava.hartley"]
    },
    "InfoSec" = {
      description = "Information Security team"
      members = ["noah.caldwell", "maya.dresden"]
    },
    "InfraEngineers" = {
      description = "DevOps Engineers team"
      members = ["ethan.sommer", "zoe.langford"]
    },
    "ReadOnlyUsers" = {
      description = "Users with global read-only permissions"
      members = ["maya.dresden", "liam.westbrook"]
    }
  }

  # Define permission sets to create via module
  # Key = Permission set name used in assignments below
  permission_sets_config = {
    # Using AWS Managed policies
    "AdministratorAccess" = {
      description = "Grants AWS AdministratorAccess"
      aws_managed_policy = "AdministratorAccess" # Exact name of AWS Managed policy
      session_duration = "PT2H" # Optional: Override default session duration
    }
    "PowerUserAccess" = {
      description = "Grants AWS PowerUserAccess"
      aws_managed_policy = "PowerUserAccess"
    }
    "ViewOnlyAccess" = {
      description = "Grants AWS ViewOnlyAccess"
      aws_managed_policy = "ViewOnlyAccess"
      session_duration = "PT12H"
    }
    # Example: Custom Inline policy Permission set (Optional)
    #"CustomS3Writer" = {
    #  description = "Allows writing to a specific S3 bucket"
    #  inline_policy = jsonencode({ ... your policy json ...})
    #  session_duration = "PT2H"
    #}
  }

  # Define assignment rules (Group -> Permission set -> Accounts)
  assignments = [
    # --- SoftwareEngineers assignments ---
    { group_name = "SoftwareEngineers", permission_set_name = "AdministratorAccess", account_keys = ["dev"] },
    { group_name = "SoftwareEngineers", permission_set_name = "PowerUserAccess", account_keys = ["prod", "shared"] },

    # --- InfoSec assignments ---
    { group_name = "InfoSec", permission_set_name = "AdministratorAccess", account_keys = ["sec"] },
    { group_name = "InfoSec", permission_set_name = "ViewOnlyAccess", account_keys = ["dev", "prod", "shared"] },

    # --- InfraEngineers assignments ---
    # Apply to all accounts defined in target_accounts using keys()
    { group_name = "InfraEngineers", permission_set_name = "AdministratorAccess", account_keys = keys(local.target_accounts) },

    # --- ReadOnlyUsers assignments ---
    # Apply to all accounts defined in target_accounts using keys()
    { group_name = "ReadOnlyUsers", permission_set_name = "ViewOnlyAccess", account_keys = keys(local.target_accounts) }
  ]
}