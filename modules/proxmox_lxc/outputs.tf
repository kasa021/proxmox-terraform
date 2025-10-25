output "container_id" {
  description = "作成されたコンテナのID"
  value       = proxmox_virtual_environment_container.container.vm_id
}

output "container_name" {
  description = "作成されたコンテナの名前"
  value       = proxmox_virtual_environment_container.container.initialization[0].hostname
}

output "ip_address" {
  description = "コンテナのIPアドレス"
  value       = try(proxmox_virtual_environment_container.container.ipv4_addresses[1][0], null)
}
