variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "assume_role_arn" {
  type        = string
  default     = "arn:aws:iam::311141538914:role/sec-OrganizationAccountAccessRole"
  description = "Role to be assumed in delegated admin account"
}