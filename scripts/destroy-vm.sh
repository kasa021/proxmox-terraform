#!/bin/bash

set -e

# 色の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

VMS_DIR="vms"

# vmsディレクトリが存在するか確認
if [ ! -d "$VMS_DIR" ]; then
    echo -e "${RED}エラー: vmsディレクトリが見つかりません${NC}"
    echo -e "${YELLOW}まずはVMを作成してください: make create-vm${NC}"
    exit 1
fi

# VMリストを取得
VM_LIST=($(ls -1 "$VMS_DIR" 2>/dev/null))

if [ ${#VM_LIST[@]} -eq 0 ]; then
    echo -e "${YELLOW}管理中のVMが見つかりません${NC}"
    echo -e "VMを作成するには: ${BLUE}make create-vm${NC}"
    exit 0
fi

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    VM削除ウィザード${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "削除するVMを選択してください:"
echo ""

# VMリストを表示
for i in "${!VM_LIST[@]}"; do
    VM_NAME="${VM_LIST[$i]}"
    VM_DIR="${VMS_DIR}/${VM_NAME}"

    # VM情報を取得
    if [ -f "${VM_DIR}/terraform.tfstate" ]; then
        VM_ID=$(cd "$VM_DIR" && terraform show -json 2>/dev/null | grep -o '"vm_id":[0-9]*' | head -1 | cut -d: -f2 || echo "N/A")
        STATUS="${GREEN}[作成済み]${NC}"
    else
        VM_ID="N/A"
        STATUS="${YELLOW}[未作成]${NC}"
    fi

    echo -e "  $((i+1)). ${VM_NAME} (ID: ${VM_ID}) ${STATUS}"
done

echo ""
echo -e "  0. キャンセル"
echo ""

# VM選択
while true; do
    read -p "選択 (0-${#VM_LIST[@]}): " CHOICE

    if [ "$CHOICE" = "0" ]; then
        echo -e "${YELLOW}キャンセルされました${NC}"
        exit 0
    fi

    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#VM_LIST[@]}" ]; then
        break
    else
        echo -e "${RED}エラー: 0-${#VM_LIST[@]}の範囲で選択してください${NC}"
    fi
done

SELECTED_VM="${VM_LIST[$((CHOICE-1))]}"
VM_DIR="${VMS_DIR}/${SELECTED_VM}"

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}削除対象VM${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "VM名: ${RED}${SELECTED_VM}${NC}"
echo -e "ディレクトリ: ${RED}${VM_DIR}${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${RED}警告: このVMとそのディレクトリが完全に削除されます！${NC}"
echo ""

read -p "本当に削除しますか? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}キャンセルされました${NC}"
    exit 0
fi

# Terraformでリソースを削除
echo ""
echo -e "${BLUE}Terraformでリソースを削除しています...${NC}"

cd "$VM_DIR"

if [ -f "terraform.tfstate" ]; then
    terraform destroy -auto-approve
    echo -e "${GREEN}Terraformリソースの削除が完了しました${NC}"
else
    echo -e "${YELLOW}terraform.tfstateが見つかりません。リソースは作成されていない可能性があります${NC}"
fi

# ディレクトリを削除
cd ../..
echo ""
read -p "VMディレクトリも削除しますか? (y/N): " DELETE_DIR

if [[ "$DELETE_DIR" =~ ^[Yy]$ ]]; then
    rm -rf "$VM_DIR"
    echo -e "${GREEN}ディレクトリを削除しました: ${VM_DIR}${NC}"
else
    echo -e "${YELLOW}ディレクトリは保持されました: ${VM_DIR}${NC}"
    echo -e "手動で削除する場合: ${BLUE}rm -rf ${VM_DIR}${NC}"
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}削除が完了しました${NC}"
echo -e "${GREEN}================================================${NC}"
