output "container_id" {
  description = "作成されたコンテナのID"
  value       = proxmox_virtual_environment_container.container.vm_id
}

output "container_name" {
  description = "作成されたコンテナの名前"
  value       = proxmox_virtual_environment_container.container.initialization[0].hostname
}

output "ip_address" {
  description = "コンテナのIPアドレス（DHCPの場合は手動確認が必要）"
  value       = var.use_dhcp ? null : var.ip_address
}
