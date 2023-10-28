variable "namespace" {
  description = "Namespace where resources will be created"
  type        = string
}

variable "root_cert_name" {
  description = "The name of the root certificate secret"
  type        = string
  default     = "root-cert"
}

variable "dns_names" {
  description = "The DNS names we should generate certificates for"
  type        = list(string)
}

variable "certs_path" {
  description = "The path where the root cert is at"
  type        = string
}
