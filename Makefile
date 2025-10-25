.PHONY: help create-vm create-container list-vms list-containers destroy clean

# デフォルトターゲット
help:
	@echo "Proxmox Terraform Manager"
	@echo ""
	@echo "VM管理コマンド:"
	@echo "  make create-vm     - 対話形式でVMを作成"
	@echo "  make list-vms      - 管理中のVMリストを表示"
	@echo ""
	@echo "コンテナ管理コマンド:"
	@echo "  make create-container  - 対話形式でLXCコンテナを作成"
	@echo "  make list-containers   - 管理中のコンテナリストを表示"
	@echo ""
	@echo "共通コマンド:"
	@echo "  make destroy       - VM/コンテナを削除（対話形式）"
	@echo "  make clean         - 指定したVM/コンテナの一時ファイルをクリーンアップ"
	@echo ""

# 対話形式でVMを作成
create-vm:
	@echo "================================================"
	@echo "    Proxmox VM 作成ウィザード"
	@echo "================================================"
	@echo ""
	@./scripts/create-vm.sh

# 対話形式でLXCコンテナを作成
create-container:
	@echo "================================================"
	@echo "    Proxmox LXC コンテナ作成ウィザード"
	@echo "================================================"
	@echo ""
	@./scripts/create-container.sh

# 管理中のVMをリスト表示
list-vms:
	@./scripts/list-vms.sh

# 管理中のコンテナをリスト表示
list-containers:
	@echo "管理中のLXCコンテナ:"
	@echo ""
	@if [ -d "containers" ] && [ -n "$$(ls -A containers 2>/dev/null)" ]; then \
		for dir in containers/*; do \
			if [ -d "$$dir" ] && [ -f "$$dir/main.tf" ]; then \
				name=$$(basename $$dir); \
				cd $$dir && \
				id=$$(terraform output -json 2>/dev/null | grep container_id | grep -oE '[0-9]+' | head -1); \
				ip=$$(terraform output -json 2>/dev/null | grep ip_address | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"' | tr -d '"'); \
				cd - > /dev/null; \
				echo "  - $$name (ID: $$id, IP: $$ip)"; \
			fi \
		done \
	else \
		echo "  管理中のコンテナはありません"; \
	fi
	@echo ""

# VMを削除（対話形式）
destroy:
	@./scripts/destroy-vm.sh

# クリーンアップ
clean:
	@./scripts/clean-vm.sh
