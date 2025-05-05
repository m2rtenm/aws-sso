variable "region" {
  type = string
  description = "Teh AWS region where the IAM Identity Center instance is located"
}

variable "target_accounts" {
  type = map(string)
  description = "Map of AWS account ID-s with names for assignments"
}

variable "users" {
  type = list(object({
    user_name = string
    given_name = string
    family_name = string
    email = string
  }))
  description = "List of users to manage in the Identity Store"
  default = []
}

variable "groups" {
  type = map(object({
    description = string
    members = list(string) # List of user_names
  }))
  description = "Map of groups to create"
  default = {}
}

variable "assignments" {
  type = list(object({
    group_name = string
    permission_set_name = string
    account_keys  = list(string) # List of keys from var.target_accounts
  }))
  description = "List of assignment rules linking groups to permission sets across specified account keys"
  default = []
}

variable "permission_sets_config" {
  type = map(object({
    description = optional(string, "Managed by Terraform")
    session_duration = optional(string, "PT4H") # Default 4 hours
    aws_managed_policy = optional(string) # Name of AWS Managed policy, for example AdministratorAccess
    inline_policy = optional(string) # JSON string of inline policy
    # customer_managed_policies = optional(list(string)) # ARNs of customer managed policies
  }))
  description = "Configuration for the permission sets to create. Key is the permission set name used in assignments"
  default = {}
}