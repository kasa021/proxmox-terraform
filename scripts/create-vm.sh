#!/bin/bash

set -e

# 色の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ストレージの選択肢
STORAGE_OPTIONS=("local-lvm" "usb-ssd-baffulo" "data-hdd" "data-ssd")

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

echo -e "${BLUE}VM設定を入力してください${NC}"
echo ""

# VM ID
while true; do
    read -p "VM ID (100-999): " VM_ID
    if validate_number "$VM_ID" 100 999; then
        break
    else
        echo -e "${RED}エラー: 100-999の範囲で数字を入力してください${NC}"
    fi
done

# VM名
read -p "VM名 (例: ubuntu-server-01): " VM_NAME
if [ -z "$VM_NAME" ]; then
    VM_NAME="ubuntu-server-${VM_ID}"
    echo -e "${YELLOW}デフォルト値を使用: ${VM_NAME}${NC}"
fi

# CPUコア数
while true; do
    read -p "CPUコア数 (1-32, デフォルト: 2): " CORES
    if [ -z "$CORES" ]; then
        CORES=2
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
    read -p "メモリ容量 (例: 2GB, 1024MB, デフォルト: 2GB): " MEMORY_INPUT
    if [ -z "$MEMORY_INPUT" ]; then
        MEMORY=2048
        echo -e "${YELLOW}デフォルト値を使用: 2GB (2048MB)${NC}"
        break
    else
        MEMORY=$(convert_memory_to_mb "$MEMORY_INPUT")
        if [ $? -eq 0 ] && [ "$MEMORY" -gt 0 ]; then
            echo -e "${GREEN}メモリ: ${MEMORY}MB${NC}"
            break
        else
            echo -e "${RED}エラー: 正しい形式で入力してください (例: 2GB, 1024MB)${NC}"
        fi
    fi
done

# ディスクサイズ
while true; do
    read -p "ディスクサイズ (GB, デフォルト: 20): " DISK_SIZE
    if [ -z "$DISK_SIZE" ]; then
        DISK_SIZE=20
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

# ユーザー名
read -p "ユーザー名 (デフォルト: ubuntu): " USERNAME
if [ -z "$USERNAME" ]; then
    USERNAME="ubuntu"
    echo -e "${YELLOW}デフォルト値を使用: ${USERNAME}${NC}"
fi

# パスワード
while true; do
    read -sp "ユーザーパスワード: " USER_PASSWORD
    echo ""
    if [ -z "$USER_PASSWORD" ]; then
        echo -e "${RED}エラー: パスワードは必須です${NC}"
    else
        read -sp "パスワード確認: " USER_PASSWORD_CONFIRM
        echo ""
        if [ "$USER_PASSWORD" = "$USER_PASSWORD_CONFIRM" ]; then
            break
        else
            echo -e "${RED}エラー: パスワードが一致しません${NC}"
        fi
    fi
done

# 設定内容の確認
echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}設定内容の確認${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "VM ID:         ${GREEN}${VM_ID}${NC}"
echo -e "VM名:          ${GREEN}${VM_NAME}${NC}"
echo -e "CPUコア数:     ${GREEN}${CORES}${NC}"
echo -e "メモリ:        ${GREEN}${MEMORY}MB${NC}"
echo -e "ディスクサイズ: ${GREEN}${DISK_SIZE}GB${NC}"
echo -e "ストレージ:    ${GREEN}${STORAGE}${NC}"
echo -e "ユーザー名:    ${GREEN}${USERNAME}${NC}"
echo -e "パスワード:    ${GREEN}********${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

read -p "この設定でVMを作成しますか? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}キャンセルされました${NC}"
    exit 0
fi

# main.tfを生成
echo ""
echo -e "${BLUE}Terraformファイルを生成しています...${NC}"

cat > envs/example/main.tf <<EOF
module "ubuntu_vm" {
  source = "../../modules/proxmox_vm"

  # Proxmox接続設定
  proxmox_endpoint   = var.proxmox_endpoint
  proxmox_api_token  = var.proxmox_api_token
  proxmox_insecure   = var.proxmox_insecure

  # VM基本設定
  vm_name     = "${VM_NAME}"
  vm_id       = ${VM_ID}
  target_node = "pve"
  template_id = 9000

  # リソース設定
  cores     = ${CORES}
  memory    = ${MEMORY}
  disk_size = ${DISK_SIZE}
  storage   = "${STORAGE}"

  # ネットワーク設定
  use_dhcp = true
  bridge   = "vmbr1"

  # SSH設定
  username       = "${USERNAME}"
  user_password  = "${USER_PASSWORD}"
  ssh_public_key = file("~/.ssh/common.pub")

  # タグ
  tags = ["terraform", "auto-created"]
}

output "vm_info" {
  value = {
    vm_id      = module.ubuntu_vm.vm_id
    vm_name    = module.ubuntu_vm.vm_name
    ip_address = module.ubuntu_vm.ip_address
  }
}
EOF

echo -e "${GREEN}main.tfを生成しました${NC}"
echo ""
echo -e "${BLUE}Terraformを初期化しています...${NC}"

cd envs/example
terraform init

echo ""
echo -e "${BLUE}Terraform実行計画を確認しています...${NC}"
terraform plan

echo ""
read -p "VMを作成しますか? (y/N): " APPLY_CONFIRM
if [[ "$APPLY_CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}VMを作成しています...${NC}"
    terraform apply -auto-approve
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}VMの作成が完了しました！${NC}"
    echo -e "${GREEN}================================================${NC}"
else
    echo -e "${YELLOW}VM作成をスキップしました${NC}"
    echo -e "後で作成する場合は以下のコマンドを実行してください:"
    echo -e "  ${BLUE}cd envs/example && terraform apply${NC}"
fi
