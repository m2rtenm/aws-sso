# Terraform AWS IAM Identity Center Management Module

## Overview

This Terraform module provides a structured and reusable way to manage users, groups, permission sets, and account assignments within AWS IAM Identity Center (formerly AWS SSO). It allows for a clear separation of concerns by defining the core resource management logic within the module and keeping your organization-specific data (users, group structures, account mappings, permission rules) in your root Terraform configuration.

This module is designed to be used with an existing IAM Identity Center instance and a configured delegated administrator account for IAM Identity Center within your AWS Organization.

## Features

* **User Management:** Create and manage users directly within the IAM Identity Center's internal identity store.
* **Group Management:** Define groups and manage their memberships.
* **Permission Set Management:**
    * Create permission sets with specified session durations.
    * Attach AWS managed IAM policies to permission sets.
    * Define and attach custom inline IAM policies to permission sets.
    * Tag permission sets.
* **Account Assignments:** Assign groups to permission sets on specified AWS accounts within your organization.
* **Data-Driven Configuration:** Leverages local variables in your root module for defining users, groups, target accounts, and complex assignment rules.
* **Reusable and Modular:** Designed to be invoked as a child module, promoting clean infrastructure-as-code practices.

## Prerequisites

1.  **AWS Organization:** An existing AWS Organization.
2.  **IAM Identity Center Enabled:** IAM Identity Center must be enabled, preferably with a delegated administrator account configured.
3.  **Delegated Administrator Credentials:** Terraform must be run with credentials that have permissions to manage IAM Identity Center. This typically means running Terraform from, or assuming a role in, the IAM Identity Center delegated administrator account. Necessary permissions include `ssoadmin:*` and `identitystore:*`.
4.  **Terraform:** Terraform v1.0.0 or later.
5.  **AWS Provider:** AWS Provider v5.0 or later configured in your root module.

## Module Structure

The project is structured as follows:
```
├── main.tf             # Root module: Calls the child module
├── locals.tf           # Root module: Contains your organization-specific data
├── provider.tf         # Root module: AWS provider configuration
├── terraform.tf        # Root module: Terraform and backend configuration
├── variables.tf        # Root module: Input variable definitions
└── modules/
    └── identity_center/
        ├── main.tf         # Child module: Core resource definitions
        ├── locals.tf       # Child module: Contains specific definitions
        ├── variables.tf    # Child module: Input variable definitions
        ├── output.tf       # Child module: Output variable definitions
└── README.md           # Child module: This file
```

## Usage

1.  **Configure AWS Provider:** In your root `provider.tf`, configure the AWS provider, ensuring it authenticates with appropriate permissions for IAM Identity Center (ideally via the delegated administrator account).

    ```terraform
    # ./terraform.tf
      backend "s3" {
        bucket = "<bucket-name>"
        key = "/path/to/the/key"
        region = "<region>"
        profile = "<profile-name>"
    }

    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = ">= 5.0"
      }
    }

    required_version = ">= 1.5.0"

    # ./provider.tf
    provider "aws" {
      region = "us-east-1" # Your AWS SSO/Identity Center Region
    }
    ```

2.  **Define Configuration Data:** In your root `locals.tf`, define your users, groups, target AWS accounts, permission set configurations, and assignment rules.

    ```terraform
    # ./locals.tf
    locals {
      identity_center_region = "us-east-1" # Must match provider region for Identity Center

      target_accounts = {
        "development" = "111111111111"
        "production"  = "222222222222"
        # ... more accounts
      }

      users = [
        { user_name = "alice.doe", given_name = "Alice", family_name = "Doe", email = "alice.doe@example.com" },
        # ... more users
      ]

      groups = {
        "SoftwareEngineers" = {
          description = "Application development team"
          members     = ["alice.doe"]
        },
        # ... more groups
      }

      permission_sets_config = {
        "AdministratorAccess" = {
          description        = "Grants AWS AdministratorAccess"
          aws_managed_policy = "AdministratorAccess"
          session_duration   = "PT12H"
        },
        "ViewOnlyAccess" = {
          description        = "Grants AWS ViewOnlyAccess"
          aws_managed_policy = "ViewOnlyAccess"
        }
        # ... more permission sets
      }

      assignments = [
        { group_name = "SoftwareEngineers", permission_set_name = "AdministratorAccess", account_keys = ["development"] },
        { group_name = "SoftwareEngineers", permission_set_name = "ViewOnlyAccess", account_keys = ["production"] },
        # ... more assignments
      ]

    }
    ```

3.  **Call the Module:** In your root `main.tf`, instantiate the module and pass the data defined in `locals.tf`.

    ```terraform
    # ./main.tf
    module "identity_center" {
      source = "./modules/identity_center"

      identity_center_region = local.identity_center_region
      target_accounts        = local.target_accounts
      users                  = local.users
      groups                 = local.groups
      assignments            = local.assignments
      permission_sets_config = local.permission_sets_config
    }
    ```

## Inputs

| Name                     | Description                                                                                                 | Type                                                                                               | Default | Required |
| ------------------------ | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- | ------- | :------: |
| `identity_center_region` | The AWS region where the IAM Identity Center instance is located.                                           | `string`                                                                                           | n/a     |   yes    |
| `target_accounts`        | Map of friendly names to AWS Account IDs for assignments.                                                   | `map(string)`                                                                                      | n/a     |   yes    |
| `users`                  | List of users to manage in the Identity Store. Each object requires `user_name`, `given_name`, `family_name`, `email`. | `list(object({...}))`                                                                              | `[]`    |    no    |
| `groups`                 | Map of groups to create. Key is group name. Value is object with `description` and `members` (list of user_names). | `map(object({description=string, members=list(string)}))`                                          | `{}`    |    no    |
| `assignments`            | List of assignment rules. Each object requires `group_name`, `permission_set_name`, `account_keys` (list of keys from `target_accounts`). | `list(object({...}))`                                                                              | `[]`    |    no    |
| `permission_sets_config` | Configuration for permission sets. Key is Permission Set name. Value object defines `description`, `session_duration`, `aws_managed_policy`, `aws_managed_job_function_policy` or `inline_policy`. | `map(object({description=string, session_duration=string, aws_managed_policy=string, aws_managed_job_function_policy=string, inline_policy=string}))` | `{}`    |    no    |

## Outputs

| Name                           | Description                                                                       |
| ------------------------------ | --------------------------------------------------------------------------------- |
| `identity_store_id`            | The ID of the Identity Store associated with the IAM Identity Center instance.    |
| `identity_center_instance_arn` | The ARN of the IAM Identity Center instance.                                      |
| `user_details`                 | Details of the created users (map of user_name to user attributes including ID).  |
| `group_details`                | Details of the created groups (map of group_name to group attributes including ID). |
| `permission_set_arns`          | Map of permission set names to their ARNs.                                        |
| `account_assignments`          | Details of the created account assignments.                                       |

## Terraform Commands

1.  **Initialize:** `terraform init`
2.  **Plan:** `terraform plan` (Review the proposed changes carefully)
3.  **Apply:** `terraform apply`

## Important Considerations

* **Delegated Administrator:** Always run this Terraform configuration with credentials associated with the IAM Identity Center delegated administrator account for your AWS Organization.
* **User Management:** If you are syncing users from an external Identity Provider (IdP) like Azure AD or Okta into IAM Identity Center, do *not* manage those users with this module. This module is intended for managing users directly in the IAM Identity Center internal identity store. Attempting to manage externally synced users with Terraform can lead to conflicts.
* **Idempotency:** Terraform will manage the state of your Identity Center resources. Manual changes made in the AWS console outside of Terraform can lead to drift and unexpected behavior on subsequent Terraform runs.
* **Session Duration:** Configure `session_duration` for permission sets according to your security policies. The format is ISO 8601 duration (e.g., "PT1H" for 1 hour, "PT8H" for 8 hours).
* **Policy Naming:** When using `aws_managed_policy` or `aws_managed_job_function_policy` in `permission_sets_config`, ensure the policy name is the exact AWS managed policy name (e.g., "AdministratorAccess", "PowerUserAccess", "ViewOnlyAccess", "SecurityAudit").

---
