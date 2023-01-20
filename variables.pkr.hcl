# Proxmox Variables
variable "proxmox_api_url" {
  type    = string
  default = "https://*.*.*.*:*/api2/json/"
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "proxmox_vm_id" {
  type    = string
  default = "100"
}

# Ssh Variables
variable "ssh_username" {
  type    = string
  default = "packer"
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

# Other Variables
variable "cloud_init_apt_packages" {
  type    = list(string)
  default = ["sudo"]
}