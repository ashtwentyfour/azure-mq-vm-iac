output "mq_vm_ip" {
  value = azurerm_linux_virtual_machine.mq_vm.public_ip_address
}

output "mq_vm_id" {
  value = azurerm_linux_virtual_machine.mq_vm.id
}