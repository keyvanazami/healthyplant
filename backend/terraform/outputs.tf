output "cloud_run_url" {
  description = "URL of the deployed Cloud Run API service"
  value       = module.cloud_run.service_url
}

output "storage_bucket_name" {
  description = "Name of the GCS bucket for plant photos"
  value       = module.cloud_storage.bucket_name
}

output "function_urls" {
  description = "URLs of the deployed Cloud Functions"
  value       = module.cloud_functions.function_urls
}
