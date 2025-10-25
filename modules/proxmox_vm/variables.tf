# Proxmox接続設定
variable "proxmox_endpoint" {
  description = "ProxmoxのエンドポイントURL"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox APIトークン"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "自己署名証明書を許可するか"
  type        = bool
  default     = true
}

# VM設定
variable "vm_name" {
  description = "VM名"
  type        = string
}

variable "vm_id" {
  description = "VM ID (100-999の範囲を推奨)"
  type        = number
  default     = null
}

variable "target_node" {
  description = "Proxmoxノード名"
  type        = string
  default     = "pve"
}

variable "template_name" {
  description = "使用するVMテンプレート名"
  type        = string
  default     = "ubuntu-2204-template"
}

variable "cores" {
  description = "CPUコア数"
  type        = number
  default     = 2
}

variable "memory" {
  description = "メモリ容量 (MB)"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "ディスクサイズ (GB)"
  type        = number
  default     = 20
}

variable "storage" {
  description = "ストレージ名"
  type        = string
  default     = "local-lvm"
}

variable "ip_address" {
  description = "IPアドレス (CIDR形式: 例 192.168.1.100/24)"
  type        = string
}

variable "gateway" {
  description = "ゲートウェイアドレス"
  type        = string
  default     = "192.168.1.1"
}

variable "bridge" {
  description = "ネットワークブリッジ"
  type        = string
  default     = "vmbr0"
}

variable "ssh_public_key" {
  description = "SSH公開鍵"
  type        = string
  default     = ""
}

variable "username" {
  description = "VMのユーザー名"
  type        = string
  default     = "ubuntu"
}

variable "tags" {
  description = "VMに付けるタグのリスト"
  type        = list(string)
  default     = []
}
