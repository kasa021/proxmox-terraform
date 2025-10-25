#!/bin/bash

# 色の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

VMS_DIR="vms"

# vmsディレクトリが存在するか確認
if [ ! -d "$VMS_DIR" ]; then
    echo -e "${YELLOW}管理中のVMが見つかりません${NC}"
    echo -e "VMを作成するには: ${BLUE}make create-vm${NC}"
    exit 0
fi

# VMリストを取得
VM_LIST=($(ls -1 "$VMS_DIR" 2>/dev/null))

if [ ${#VM_LIST[@]} -eq 0 ]; then
    echo -e "${YELLOW}管理中のVMが見つかりません${NC}"
    echo -e "VMを作成するには: ${BLUE}make create-vm${NC}"
    exit 0
fi

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    管理中のVMリスト${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# ヘッダー
printf "%-3s %-25s %-8s %-10s %-15s\n" "No" "VM名" "VM ID" "ステータス" "ディレクトリ"
echo "--------------------------------------------------------------------"

# VMリストを表示
for i in "${!VM_LIST[@]}"; do
    VM_NAME="${VM_LIST[$i]}"
    VM_DIR="${VMS_DIR}/${VM_NAME}"

    # VM情報を取得
    if [ -f "${VM_DIR}/terraform.tfstate" ]; then
        # VM IDを取得
        VM_ID=$(cd "$VM_DIR" && terraform show -json 2>/dev/null | grep -o '"value":[0-9]*' | head -1 | sed 's/"value"://' || echo "N/A")

        if [ -z "$VM_ID" ] || [ "$VM_ID" = "N/A" ]; then
            # 別の方法でVM IDを取得
            VM_ID=$(cd "$VM_DIR" && grep -o 'vm_id *= *[0-9]*' main.tf 2>/dev/null | grep -o '[0-9]*' || echo "N/A")
        fi

        STATUS="${GREEN}作成済み${NC}"
    else
        VM_ID="N/A"
        STATUS="${YELLOW}未作成${NC}"
    fi

    # パスの短縮表示
    SHORT_DIR=$(echo "$VM_DIR" | sed 's|^vms/||')

    printf "%-3s %-25s %-8s %-23s %-15s\n" "$((i+1))" "$VM_NAME" "$VM_ID" "$(echo -e $STATUS)" "$SHORT_DIR"
done

echo ""
echo -e "${CYAN}合計: ${#VM_LIST[@]} VM${NC}"
echo ""
echo -e "操作コマンド:"
echo -e "  ${BLUE}make create-vm${NC}  - 新しいVMを作成"
echo -e "  ${BLUE}make destroy${NC}    - VMを削除"
echo ""
