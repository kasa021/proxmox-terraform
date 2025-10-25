#!/bin/bash

set -e

# 色の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 引数チェック
if [ $# -lt 3 ]; then
    echo -e "${RED}Usage: $0 <vm-directory> <vm-name> <username>${NC}"
    exit 1
fi

VM_DIR=$1
VM_NAME=$2
USERNAME=$3

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Ansible プロビジョニング${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Ansibleがインストールされているか確認
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}エラー: Ansibleがインストールされていません${NC}"
    echo -e "${YELLOW}Ansibleをインストールしてください:${NC}"
    echo -e "  ${BLUE}pip3 install ansible${NC}"
    echo -e "または"
    echo -e "  ${BLUE}brew install ansible${NC} (macOS)"
    exit 1
fi

# VMのIPアドレスを取得
echo -e "${BLUE}VMのIPアドレスを取得しています...${NC}"
echo ""
echo -e "${YELLOW}VMが完全に起動するまで少し待ってください（30秒程度）${NC}"
echo -e "${YELLOW}DHCP環境の場合、VMにログインしてIPアドレスを確認してください${NC}"
echo ""
read -p "VMのIPアドレスを入力してください: " VM_IP

if [ -z "$VM_IP" ]; then
    echo -e "${RED}エラー: IPアドレスが入力されませんでした${NC}"
    exit 1
fi

# SSH接続確認
echo ""
echo -e "${BLUE}SSH接続をテストしています...${NC}"
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${USERNAME}@${VM_IP} "echo 'SSH接続成功'" &> /dev/null; then
    echo -e "${GREEN}SSH接続に成功しました${NC}"
else
    echo -e "${RED}SSH接続に失敗しました${NC}"
    echo -e "${YELLOW}以下を確認してください:${NC}"
    echo -e "  1. VMが完全に起動しているか"
    echo -e "  2. IPアドレスが正しいか"
    echo -e "  3. SSH鍵が正しく設定されているか"
    echo ""
    read -p "続行しますか? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}キャンセルされました${NC}"
        exit 0
    fi
fi

# Ansibleインベントリを生成
INVENTORY_FILE="ansible/inventory/${VM_NAME}"
echo -e "${BLUE}Ansibleインベントリを生成しています: ${INVENTORY_FILE}${NC}"

mkdir -p ansible/inventory

cat > "$INVENTORY_FILE" <<EOF
# ${VM_NAME} のインベントリ
[${VM_NAME}]
${VM_IP} ansible_user=${USERNAME} ansible_python_interpreter=/usr/bin/python3

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo -e "${GREEN}インベントリを生成しました${NC}"

# プロビジョニング設定を選択
echo ""
echo -e "${BLUE}プロビジョニング設定:${NC}"
echo ""
echo "1. 基本設定のみ（パッケージインストール、タイムゾーン設定）"
echo "2. 基本設定 + Docker インストール"
echo "3. カスタム設定（vars.ymlを手動編集）"
echo ""
read -p "選択 (1-3, デフォルト: 1): " PROVISION_TYPE

PROVISION_TYPE=${PROVISION_TYPE:-1}

# vars.ymlを生成
VARS_FILE="ansible/playbooks/vars_${VM_NAME}.yml"

case $PROVISION_TYPE in
    1)
        cat > "$VARS_FILE" <<EOF
---
upgrade_packages: false
set_hostname: true
timezone: "Asia/Tokyo"
disable_password_auth: false
disable_root_login: false
install_docker: false
EOF
        ;;
    2)
        cat > "$VARS_FILE" <<EOF
---
upgrade_packages: false
set_hostname: true
timezone: "Asia/Tokyo"
disable_password_auth: false
disable_root_login: false
install_docker: true
EOF
        ;;
    3)
        cp ansible/playbooks/vars.yml.example "$VARS_FILE"
        echo -e "${YELLOW}vars.ymlを編集してください: ${VARS_FILE}${NC}"
        read -p "編集が完了したらEnterを押してください..."
        ;;
esac

# Ansible Playbookを実行
echo ""
echo -e "${BLUE}Ansible Playbookを実行しています...${NC}"
echo -e "${YELLOW}管理者権限が必要なため、VMのパスワード入力を求められる場合があります${NC}"
echo ""

cd ansible

if ansible-playbook \
    -i "inventory/${VM_NAME}" \
    -e "@playbooks/vars_${VM_NAME}.yml" \
    playbooks/provision.yml; then

    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}プロビジョニングが完了しました！${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "VM情報:"
    echo -e "  名前: ${GREEN}${VM_NAME}${NC}"
    echo -e "  IP: ${GREEN}${VM_IP}${NC}"
    echo -e "  ユーザー: ${GREEN}${USERNAME}${NC}"
    echo ""
    echo -e "SSH接続:"
    echo -e "  ${BLUE}ssh ${USERNAME}@${VM_IP}${NC}"
else
    echo ""
    echo -e "${RED}プロビジョニングに失敗しました${NC}"
    echo -e "${YELLOW}エラーを確認してください${NC}"
    exit 1
fi
