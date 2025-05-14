variable "region" {
    type = string
    default = "canadaeast"
}

variable "vm_name" {
    type = string
    default = "mq-vm-01"
}

variable "resource_group" {
    type = string
    default = "mq-rg-1"
}

variable "disk_name" {
    type = string
}

variable "network_interface" {
    type = string
    default = "mq-vm-01-nic-01"
}

variable "network_security_group" {
    type = string
    default = "mq-vm-01-nsg-01"
}

variable "public_ip" {
    type = string
}

variable "virtual_network" {
    type = string
    default = "mq-vnet-01"
}

variable "subscription_id" {
    type = string
}

variable "vm_admin_password" {
    type = string
    sensitive = true
}