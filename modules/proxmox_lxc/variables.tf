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

variable "container_name" {
  description = "コンテナ名"
  type        = string
}

variable "container_id" {
  description = "コンテナID (100-999)"
  type        = number
}

variable "target_node" {
  description = "Proxmoxノード名"
  type        = string
  default     = "pve"
}

variable "template" {
  description = "コンテナテンプレート名"
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

variable "cores" {
  description = "CPUコア数"
  type        = number
  default     = 1
}

variable "memory" {
  description = "メモリ容量（MB）"
  type        = number
  default     = 512
}

variable "swap" {
  description = "スワップ容量（MB）"
  type        = number
  default     = 512
}

variable "disk_size" {
  description = "ディスクサイズ（GB）"
  type        = number
  default     = 8
}

variable "storage" {
  description = "ストレージ名"
  type        = string
  default     = "local-lvm"
}

variable "use_dhcp" {
  description = "DHCPを使用するか"
  type        = bool
  default     = true
}

variable "ip_address" {
  description = "IPアドレス（CIDR形式、例: 192.168.1.100/24）"
  type        = string
  default     = ""
}

variable "gateway" {
  description = "デフォルトゲートウェイ"
  type        = string
  default     = ""
}

variable "bridge" {
  description = "ネットワークブリッジ"
  type        = string
  default     = "vmbr0"
}

variable "username" {
  description = "ユーザー名"
  type        = string
  default     = "root"
}

variable "password" {
  description = "rootパスワード"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH公開鍵"
  type        = string
  default     = ""
}

variable "unprivileged" {
  description = "非特権コンテナとして作成するか"
  type        = bool
  default     = true
}

variable "tags" {
  description = "タグのリスト"
  type        = list(string)
  default     = []
}
