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
    exit 1
fi

# VMリストを取得
VM_LIST=($(ls -1 "$VMS_DIR" 2>/dev/null))

if [ ${#VM_LIST[@]} -eq 0 ]; then
    echo -e "${YELLOW}管理中のVMが見つかりません${NC}"
    exit 0
fi

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    VM クリーンアップ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "クリーンアップするVMを選択してください:"
echo ""

# VMリストを表示
for i in "${!VM_LIST[@]}"; do
    VM_NAME="${VM_LIST[$i]}"
    echo "  $((i+1)). ${VM_NAME}"
done

echo ""
echo "  0. キャンセル"
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
echo -e "${BLUE}クリーンアップ対象: ${SELECTED_VM}${NC}"
echo ""
echo "以下のファイルが削除されます:"
echo "  - .terraform/ (プロバイダーファイル)"
echo "  - .terraform.lock.hcl (ロックファイル)"
echo "  - terraform.tfstate* (ステートファイル)"
echo ""
echo -e "${YELLOW}注意: VMリソースは削除されません（ディレクトリのクリーンアップのみ）${NC}"
echo ""

read -p "クリーンアップを実行しますか? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}キャンセルされました${NC}"
    exit 0
fi

# クリーンアップ実行
cd "$VM_DIR"

CLEANED=0

if [ -d ".terraform" ]; then
    rm -rf .terraform
    echo -e "${GREEN}✓ .terraform/ を削除しました${NC}"
    CLEANED=1
fi

if [ -f ".terraform.lock.hcl" ]; then
    rm -f .terraform.lock.hcl
    echo -e "${GREEN}✓ .terraform.lock.hcl を削除しました${NC}"
    CLEANED=1
fi

if ls terraform.tfstate* 1> /dev/null 2>&1; then
    rm -f terraform.tfstate*
    echo -e "${GREEN}✓ terraform.tfstate* を削除しました${NC}"
    CLEANED=1
fi

if [ $CLEANED -eq 0 ]; then
    echo -e "${YELLOW}クリーンアップするファイルが見つかりませんでした${NC}"
else
    echo ""
    echo -e "${GREEN}クリーンアップが完了しました${NC}"
fi
