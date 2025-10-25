module "ubuntu_vm" {
  source = "../../modules/proxmox_vm"

  # Proxmox接続設定
  proxmox_endpoint   = var.proxmox_endpoint
  proxmox_api_token  = var.proxmox_api_token
  proxmox_insecure   = var.proxmox_insecure

  # VM基本設定
  vm_name     = "ubuntu-server-01"
  vm_id       = 300
  target_node = "pve"
  template_id = 9000

  # リソース設定
  cores     = 2
  memory    = 2048
  disk_size = 20
  storage   = "local-lvm"

  # ネットワーク設定
  use_dhcp = true  # DHCPを使用
  bridge   = "vmbr1"

  # SSH設定
  username       = "ubuntu"
  user_password  = "ubuntu"  # パスワード（本番環境では変数化推奨）
  ssh_public_key = file("~/.ssh/common.pub")

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
