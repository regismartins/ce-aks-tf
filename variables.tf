variable "owner-name" {
  type     = string
  nullable = false
}

variable "prefix" {
  type    = string
  default = "ce-ob-aks-tf"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "vm-size" {
  type    = string
  default = "Standard_D11_v2"
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}