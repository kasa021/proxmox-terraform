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
  value       = try(proxmox_virtual_environment_vm.vm.ipv4_addresses[1][0], null)
}
