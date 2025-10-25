#!/bin/bash

# VMのIPアドレスを取得するスクリプト

VM_DIR=$1

if [ -z "$VM_DIR" ]; then
    echo "Usage: $0 <vm-directory>"
    exit 1
fi

if [ ! -d "$VM_DIR" ]; then
    echo "Error: Directory $VM_DIR not found"
    exit 1
fi

# Terraformの出力からIPアドレスを取得
cd "$VM_DIR"

# まずTerraform outputから取得を試みる
IP_ADDRESS=$(terraform output -json 2>/dev/null | jq -r '.vm_info.value.ip_address // empty' 2>/dev/null)

# IPアドレスが取得できなかった場合、stateファイルから直接取得
if [ -z "$IP_ADDRESS" ] || [ "$IP_ADDRESS" = "null" ]; then
    # VM IDを取得
    VM_ID=$(grep -o 'vm_id *= *[0-9]*' main.tf 2>/dev/null | grep -o '[0-9]*' | head -1)

    if [ -n "$VM_ID" ]; then
        # Proxmox APIから直接IPアドレスを取得する方法もあるが、
        # ここでは簡易的にユーザーに入力を求める
        echo "IPアドレスを自動取得できませんでした。"
        echo "VM ID: $VM_ID"
        echo "Proxmox UIまたはVMにログインしてIPアドレスを確認してください。"
        read -p "VMのIPアドレスを入力してください: " IP_ADDRESS
    fi
fi

echo "$IP_ADDRESS"
