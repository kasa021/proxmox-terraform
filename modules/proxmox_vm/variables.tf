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

variable "template_id" {
  description = "使用するVMテンプレートのID"
  type        = number
  default     = 9000
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

variable "use_dhcp" {
  description = "DHCPを使用するか（trueの場合はDHCP、falseの場合は静的IP）"
  type        = bool
  default     = true
}

variable "ip_address" {
  description = "IPアドレス (CIDR形式: 例 192.168.1.100/24) ※use_dhcp=falseの場合のみ使用"
  type        = string
  default     = null
}

variable "gateway" {
  description = "ゲートウェイアドレス ※use_dhcp=falseの場合のみ使用"
  type        = string
  default     = null
}

variable "bridge" {
  description = "ネットワークブリッジ"
  type        = string
  default     = "vmbr1"
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

variable "user_password" {
  description = "VMのユーザーパスワード（設定しない場合は空文字）"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "VMに付けるタグのリスト"
  type        = list(string)
  default     = []
}
