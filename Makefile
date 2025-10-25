.PHONY: help create-vm list-vms destroy clean

# デフォルトターゲット
help:
	@echo "Proxmox Terraform VM Manager"
	@echo ""
	@echo "使用可能なコマンド:"
	@echo "  make create-vm  - 対話形式でVMを作成"
	@echo "  make list-vms   - 管理中のVMリストを表示"
	@echo "  make destroy    - VMを削除（対話形式）"
	@echo "  make clean      - 指定したVMの一時ファイルをクリーンアップ"
	@echo ""

# 対話形式でVMを作成
create-vm:
	@echo "================================================"
	@echo "    Proxmox VM 作成ウィザード"
	@echo "================================================"
	@echo ""
	@./scripts/create-vm.sh

# 管理中のVMをリスト表示
list-vms:
	@./scripts/list-vms.sh

# VMを削除（対話形式）
destroy:
	@./scripts/destroy-vm.sh

# クリーンアップ
clean:
	@./scripts/clean-vm.sh
