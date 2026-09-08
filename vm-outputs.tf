output "vm_ip_publica" {
  description = "IP publica de la maquina virtual"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_comando_ssh" {
  description = "Comando para conectarse a la VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}
