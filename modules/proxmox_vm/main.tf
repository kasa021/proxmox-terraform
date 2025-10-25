resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.vm_name
  vm_id       = var.vm_id
  node_name   = var.target_node
  description = "Managed by Terraform"

  tags = var.tags

  clone {
    vm_id = var.template_id
    full  = true
  }

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = "raw"
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.use_dhcp ? "dhcp" : var.ip_address
        gateway = var.use_dhcp ? null : var.gateway
      }
    }

    user_account {
      username = var.username
      password = var.user_password != "" ? var.user_password : null
      keys     = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    }
  }

  started = true

  # QEMU Guest Agentを無効化してIPアドレス取得を待たない
  agent {
    enabled = false
  }

  lifecycle {
    ignore_changes = [
      network_device,
      initialization,
    ]
  }
}
