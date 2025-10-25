output "vm_id" {
  description = "作成されたVMのID"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  description = "作成されたVMの名前"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "ip_address" {
  description = "VMのIPアドレス"
  value       = var.ip_address
}
