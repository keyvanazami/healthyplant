variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "app_name" {
  description = "Application name used for resource naming"
  type        = string
  default     = "healthyplant"
}

variable "anthropic_api_key" {
  description = "Anthropic API key for Claude integration"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Deployment environment (e.g. prod, staging, dev)"
  type        = string
  default     = "prod"
}
