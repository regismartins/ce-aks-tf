variable "owner-name" {
  type     = string
  nullable = false
}

variable "prefix" {
  type    = string
  default = "ce-aks-tf"
}

variable "location" {
  type    = string
  default = "Canada Central"
}

variable "vm-size" {
  type    = string
  default = "Standard_B4ms"
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "kubernetes_version" {
  default = "1.22.11"
}
