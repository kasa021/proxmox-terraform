#!/bin/bash

set -e

# 色の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# .envファイルの確認と読み込み
if [ ! -f ".env" ]; then
    echo -e "${RED}エラー: .envファイルが見つかりません${NC}"
    echo -e "${YELLOW}.env.exampleをコピーして.envを作成してください:${NC}"
    echo -e "  ${BLUE}cp .env.example .env${NC}"
    echo -e "  ${BLUE}vi .env  # 実際の値を設定${NC}"
    exit 1
fi

# .envファイルを読み込む
echo -e "${BLUE}.envファイルを読み込んでいます...${NC}"
set -a
source .env
set +a

# 必須の環境変数をチェック
if [ -z "$PROXMOX_VE_ENDPOINT" ] || [ -z "$PROXMOX_VE_API_TOKEN" ]; then
    echo -e "${RED}エラー: .envファイルにPROXMOX_VE_ENDPOINTとPROXMOX_VE_API_TOKENが設定されていません${NC}"
    exit 1
fi

echo -e "${GREEN}Proxmox接続情報を読み込みました${NC}"
echo ""

# ストレージの選択肢
STORAGE_OPTIONS=("local-lvm" "usb-ssd-baffulo" "data-hdd" "data-ssd")

# テンプレート（localストレージに存在）
TEMPLATE="local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
TEMPLATE_NAME="Ubuntu 24.04 LTS"

# メモリ単位をMBに変換する関数
convert_memory_to_mb() {
    local input=$1
    local value
    local unit

    # 数字と単位を分離
    if [[ $input =~ ^([0-9]+)([GgMm][Bb]?)$ ]]; then
        value="${BASH_REMATCH[1]}"
        unit="${BASH_REMATCH[2]}"

        # 単位を大文字に変換
        unit=$(echo "$unit" | tr '[:lower:]' '[:upper:]')

        case $unit in
            G|GB)
                echo $((value * 1024))
                ;;
            M|MB)
                echo "$value"
                ;;
            *)
                echo "0"
                return 1
                ;;
        esac
    elif [[ $input =~ ^[0-9]+$ ]]; then
        # 単位なしの場合はMBとして扱う
        echo "$input"
    else
        echo "0"
        return 1
    fi
}

# 入力値のバリデーション
validate_number() {
    local value=$1
    local min=$2
    local max=$3

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    if [ -n "$min" ] && [ "$value" -lt "$min" ]; then
        return 1
    fi

    if [ -n "$max" ] && [ "$value" -gt "$max" ]; then
        return 1
    fi

    return 0
}

echo -e "${BLUE}LXCコンテナ設定を入力してください${NC}"
echo ""

# コンテナID
while true; do
    read -p "コンテナID (100-999): " CONTAINER_ID
    if validate_number "$CONTAINER_ID" 100 999; then
        break
    else
        echo -e "${RED}エラー: 100-999の範囲で数字を入力してください${NC}"
    fi
done

# コンテナ名
read -p "コンテナ名 (例: web-server-01): " CONTAINER_NAME
if [ -z "$CONTAINER_NAME" ]; then
    CONTAINER_NAME="lxc-${CONTAINER_ID}"
    echo -e "${YELLOW}デフォルト値を使用: ${CONTAINER_NAME}${NC}"
fi

# テンプレート表示
echo ""
echo -e "使用するOSテンプレート: ${GREEN}${TEMPLATE_NAME}${NC}"

# CPUコア数
while true; do
    read -p "CPUコア数 (1-32, デフォルト: 1): " CORES
    if [ -z "$CORES" ]; then
        CORES=1
        echo -e "${YELLOW}デフォルト値を使用: ${CORES}${NC}"
        break
    elif validate_number "$CORES" 1 32; then
        break
    else
        echo -e "${RED}エラー: 1-32の範囲で数字を入力してください${NC}"
    fi
done

# メモリ
while true; do
    read -p "メモリ容量 (例: 512MB, 1GB, デフォルト: 512MB): " MEMORY_INPUT
    if [ -z "$MEMORY_INPUT" ]; then
        MEMORY=512
        echo -e "${YELLOW}デフォルト値を使用: 512MB${NC}"
        break
    else
        MEMORY=$(convert_memory_to_mb "$MEMORY_INPUT")
        if [ $? -eq 0 ] && [ "$MEMORY" -gt 0 ]; then
            echo -e "${GREEN}メモリ: ${MEMORY}MB${NC}"
            break
        else
            echo -e "${RED}エラー: 正しい形式で入力してください (例: 512MB, 1GB)${NC}"
        fi
    fi
done

# スワップ
while true; do
    read -p "スワップ容量 (例: 512MB, 1GB, デフォルト: 512MB): " SWAP_INPUT
    if [ -z "$SWAP_INPUT" ]; then
        SWAP=512
        echo -e "${YELLOW}デフォルト値を使用: 512MB${NC}"
        break
    else
        SWAP=$(convert_memory_to_mb "$SWAP_INPUT")
        if [ $? -eq 0 ] && [ "$SWAP" -gt 0 ]; then
            echo -e "${GREEN}スワップ: ${SWAP}MB${NC}"
            break
        else
            echo -e "${RED}エラー: 正しい形式で入力してください (例: 512MB, 1GB)${NC}"
        fi
    fi
done

# ディスクサイズ
while true; do
    read -p "ディスクサイズ (GB, デフォルト: 8): " DISK_SIZE
    if [ -z "$DISK_SIZE" ]; then
        DISK_SIZE=8
        echo -e "${YELLOW}デフォルト値を使用: ${DISK_SIZE}GB${NC}"
        break
    elif validate_number "$DISK_SIZE" 1 1000; then
        break
    else
        echo -e "${RED}エラー: 1-1000の範囲で数字を入力してください${NC}"
    fi
done

# ストレージ選択
echo ""
echo "ストレージを選択してください:"
for i in "${!STORAGE_OPTIONS[@]}"; do
    echo "  $((i+1)). ${STORAGE_OPTIONS[$i]}"
done

while true; do
    read -p "選択 (1-${#STORAGE_OPTIONS[@]}, デフォルト: 1): " STORAGE_CHOICE
    if [ -z "$STORAGE_CHOICE" ]; then
        STORAGE_CHOICE=1
        echo -e "${YELLOW}デフォルト値を使用: ${STORAGE_OPTIONS[0]}${NC}"
        break
    elif validate_number "$STORAGE_CHOICE" 1 "${#STORAGE_OPTIONS[@]}"; then
        break
    else
        echo -e "${RED}エラー: 1-${#STORAGE_OPTIONS[@]}の範囲で選択してください${NC}"
    fi
done

STORAGE="${STORAGE_OPTIONS[$((STORAGE_CHOICE-1))]}"
echo -e "${GREEN}選択されたストレージ: ${STORAGE}${NC}"

# rootパスワード
while true; do
    read -sp "rootパスワード: " ROOT_PASSWORD
    echo ""
    if [ -z "$ROOT_PASSWORD" ]; then
        echo -e "${RED}エラー: パスワードは必須です${NC}"
    else
        read -sp "パスワード確認: " ROOT_PASSWORD_CONFIRM
        echo ""
        if [ "$ROOT_PASSWORD" = "$ROOT_PASSWORD_CONFIRM" ]; then
            break
        else
            echo -e "${RED}エラー: パスワードが一致しません${NC}"
        fi
    fi
done

# 非特権コンテナ
read -p "非特権コンテナとして作成しますか? (Y/n): " UNPRIVILEGED_INPUT
if [[ "$UNPRIVILEGED_INPUT" =~ ^[Nn]$ ]]; then
    UNPRIVILEGED="false"
else
    UNPRIVILEGED="true"
    echo -e "${YELLOW}デフォルト値を使用: 非特権コンテナ${NC}"
fi

# 設定内容の確認
echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}設定内容の確認${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "コンテナID:    ${GREEN}${CONTAINER_ID}${NC}"
echo -e "コンテナ名:    ${GREEN}${CONTAINER_NAME}${NC}"
echo -e "テンプレート:  ${GREEN}${TEMPLATE_NAME}${NC}"
echo -e "CPUコア数:     ${GREEN}${CORES}${NC}"
echo -e "メモリ:        ${GREEN}${MEMORY}MB${NC}"
echo -e "スワップ:      ${GREEN}${SWAP}MB${NC}"
echo -e "ディスクサイズ: ${GREEN}${DISK_SIZE}GB${NC}"
echo -e "ストレージ:    ${GREEN}${STORAGE}${NC}"
echo -e "非特権:        ${GREEN}${UNPRIVILEGED}${NC}"
echo -e "パスワード:    ${GREEN}********${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

read -p "この設定でコンテナを作成しますか? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}キャンセルされました${NC}"
    exit 0
fi

# コンテナ用のディレクトリを作成
CONTAINER_DIR="containers/${CONTAINER_NAME}"
echo ""
echo -e "${BLUE}コンテナディレクトリを作成しています: ${CONTAINER_DIR}${NC}"

mkdir -p "${CONTAINER_DIR}"

# variables.tfを生成
cat > "${CONTAINER_DIR}/variables.tf" <<EOF
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
EOF

# terraform.tfvarsを.envから生成
echo -e "${BLUE}terraform.tfvarsを生成しています...${NC}"
cat > "${CONTAINER_DIR}/terraform.tfvars" <<EOF
# Proxmox接続設定（.envから自動生成）
proxmox_endpoint   = "${PROXMOX_VE_ENDPOINT}"
proxmox_api_token  = "${PROXMOX_VE_API_TOKEN}"
proxmox_insecure   = ${PROXMOX_VE_INSECURE:-true}
EOF
echo -e "${GREEN}terraform.tfvarsを生成しました${NC}"

# main.tfを生成
echo -e "${BLUE}Terraformファイルを生成しています...${NC}"

cat > "${CONTAINER_DIR}/main.tf" <<EOF
module "lxc_container" {
  source = "../../modules/proxmox_lxc"

  # Proxmox接続設定
  proxmox_endpoint   = var.proxmox_endpoint
  proxmox_api_token  = var.proxmox_api_token
  proxmox_insecure   = var.proxmox_insecure

  # コンテナ基本設定
  container_name = "${CONTAINER_NAME}"
  container_id   = ${CONTAINER_ID}
  target_node    = "pve"
  template       = "${TEMPLATE}"

  # リソース設定
  cores     = ${CORES}
  memory    = ${MEMORY}
  swap      = ${SWAP}
  disk_size = ${DISK_SIZE}
  storage   = "${STORAGE}"

  # ネットワーク設定
  use_dhcp = true
  bridge   = "vmbr1"

  # 認証設定
  password       = "${ROOT_PASSWORD}"
  ssh_public_key = file("~/.ssh/common.pub")

  # コンテナタイプ
  unprivileged = ${UNPRIVILEGED}

  # タグ
  tags = ["terraform", "lxc", "auto-created"]
}

output "container_info" {
  value = {
    container_id   = module.lxc_container.container_id
    container_name = module.lxc_container.container_name
    ip_address     = module.lxc_container.ip_address
  }
}
EOF

echo -e "${GREEN}Terraformファイルを生成しました${NC}"
echo ""
echo -e "${BLUE}Terraformを初期化しています...${NC}"

cd "${CONTAINER_DIR}"
terraform init

echo ""
echo -e "${BLUE}Terraform実行計画を確認しています...${NC}"
terraform plan

echo ""
read -p "コンテナを作成しますか? (y/N): " APPLY_CONFIRM
if [[ "$APPLY_CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}コンテナを作成しています...${NC}"
    terraform apply -auto-approve
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}コンテナの作成が完了しました！${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}コンテナ名: ${CONTAINER_NAME}${NC}"
    echo -e "${GREEN}コンテナID: ${CONTAINER_ID}${NC}"
    echo -e "${GREEN}ディレクトリ: ${CONTAINER_DIR}${NC}"
    echo ""

    # IPアドレスを取得（DHCP使用時は表示されない）
    CONTAINER_IP=$(terraform output container_info 2>/dev/null | grep 'ip_address' | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"' | tr -d '"' || echo "")

    if [ -n "$CONTAINER_IP" ]; then
        echo -e "${GREEN}IPアドレス: ${CONTAINER_IP}${NC}"
        echo ""
        echo -e "SSH接続:"
        echo -e "  ${BLUE}ssh root@${CONTAINER_IP}${NC}"
    else
        echo -e "${YELLOW}IPアドレスはDHCPで自動割り当てされます${NC}"
        echo -e "${YELLOW}IPアドレスを確認するには:${NC}"
        echo -e "  ${BLUE}pct exec ${CONTAINER_ID} ip addr show${NC}"
        echo -e "または Proxmox WebUIでコンテナを確認してください"
    fi

    echo ""
    echo -e "コンテナ管理コマンド:"
    echo -e "  ${BLUE}make list-containers${NC}   - 管理中のコンテナリストを表示"
    echo -e "  ${BLUE}make destroy-container${NC} - コンテナを削除"
else
    echo -e "${YELLOW}コンテナ作成をスキップしました${NC}"
    echo -e "後で作成する場合は以下のコマンドを実行してください:"
    echo -e "  ${BLUE}cd ${CONTAINER_DIR} && terraform apply${NC}"
fi
