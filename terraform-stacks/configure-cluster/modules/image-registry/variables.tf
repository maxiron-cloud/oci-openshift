variable "storage_size" {
  type        = string
  description = "Size of the PVC for image registry storage"
}

variable "storage_class" {
  type        = string
  description = "StorageClass to use for the image registry PVC"
}

