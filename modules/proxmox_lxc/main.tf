resource "proxmox_virtual_environment_container" "container" {
  node_name    = var.target_node
  vm_id        = var.container_id
  description  = "Managed by Terraform"
  unprivileged = var.unprivileged

  tags = var.tags

  # 起動設定
  started = true

  # オペレーティングシステム
  operating_system {
    template_file_id = var.template
    type             = "ubuntu"
  }

  # CPU設定
  cpu {
    cores = var.cores
  }

  # メモリ設定
  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  # ディスク設定
  disk {
    datastore_id = var.storage
    size         = var.disk_size
  }

  # ネットワーク設定
  network_interface {
    name   = "eth0"
    bridge = var.bridge
  }

  # 初期化設定
  initialization {
    hostname = var.container_name

    ip_config {
      ipv4 {
        address = var.use_dhcp ? "dhcp" : var.ip_address
        gateway = var.use_dhcp ? null : var.gateway
      }
    }

    user_account {
      password = var.password
      keys     = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    }
  }

  # 機能設定（特権的な機能）
  features {
    nesting = true  # Docker等のコンテナを実行可能にする
  }

  lifecycle {
    ignore_changes = [
      network_interface,
      initialization,
    ]
  }
}
