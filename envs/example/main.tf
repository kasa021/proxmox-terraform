module "ubuntu_vm" {
  source = "../../modules/proxmox_vm"

  # Proxmox接続設定
  proxmox_endpoint   = var.proxmox_endpoint
  proxmox_api_token  = var.proxmox_api_token
  proxmox_insecure   = var.proxmox_insecure

  # VM基本設定
  vm_name       = "ubuntu-server-01"
  vm_id         = 300
  target_node   = "pve"
  template_name = "ubuntu-2204-template"

  # リソース設定
  cores     = 2
  memory    = 2048
  disk_size = 20
  storage   = "local-lvm"

  # ネットワーク設定
  ip_address = "192.168.1.100/24"
  gateway    = "192.168.1.1"
  bridge     = "vmbr0"

  # SSH設定
  username       = "ubuntu"
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  # タグ
  tags = ["terraform", "ubuntu"]
}

output "vm_info" {
  value = {
    vm_id      = module.ubuntu_vm.vm_id
    vm_name    = module.ubuntu_vm.vm_name
    ip_address = module.ubuntu_vm.ip_address
  }
}
