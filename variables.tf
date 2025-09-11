variable "name_function" {
  type        = string
  description = "Name Function"
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
  default     = "lab-rg"
}

variable "storage_account_name" {
  description = "Name of the Storage Account (lowercase, 3-24 chars, unique globally)"
  type        = string
}

variable "service_plan_name" {
  description = "Name of the Service Plan"
  type        = string
  default     = "lab-serviceplan"
}

variable "location" {
  type        = string
  default     = "brazilsouth"
  description = "Location"
}