# Variables adicionales para la maquina virtual.
# Terraform carga todos los archivos .tf del directorio, asi que estas
# conviven sin problema con las de variables.tf

variable "name_vm" {
  type        = string
  description = "Nombre base de la maquina virtual y sus recursos de red"
}

variable "vm_size" {
  type        = string
  default     = "Standard_B1s"
  description = "Tamano de la VM. B1s consume muy poco credito"
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Usuario administrador de la VM"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Ruta a la llave publica SSH"
}

variable "allowed_ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR autorizado para conectarse por SSH"
}
