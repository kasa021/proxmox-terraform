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
