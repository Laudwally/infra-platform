variable "name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the control plane."
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC to deploy the cluster into."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets (private recommended) for the control plane ENIs and node group."
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "endpoint_public_access" {
  description = "Whether the API server endpoint is reachable from outside the VPC. Disable for stricter environments and access via a bastion/VPN instead."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
