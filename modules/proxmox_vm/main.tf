resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.vm_name
  vm_id       = var.vm_id
  node_name   = var.target_node
  description = "Managed by Terraform"

  tags = var.tags

  clone {
    vm_id = var.template_name
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
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      username = var.username
      keys     = var.ssh_public_key != "" ? [var.ssh_public_key] : []
    }
  }

  started = true

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}
