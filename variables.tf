variable "server_ip" {
  type        = string
  description = "Public IP address of your VPS"
}

variable "ssh_user" {
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  type        = string
  description = "Path to your SSH private key"
}
