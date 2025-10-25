.PHONY: help create-vm init plan apply destroy clean

# デフォルトターゲット
help:
	@echo "Proxmox Terraform VM Manager"
	@echo ""
	@echo "使用可能なコマンド:"
	@echo "  make create-vm  - 対話形式でVMを作成"
	@echo "  make init       - Terraformを初期化"
	@echo "  make plan       - Terraform実行計画を確認"
	@echo "  make apply      - Terraformを実行してVMを作成"
	@echo "  make destroy    - 作成したVMを削除"
	@echo "  make clean      - 生成されたファイルをクリーンアップ"
	@echo ""

# 対話形式でVMを作成
create-vm:
	@echo "================================================"
	@echo "    Proxmox VM 作成ウィザード"
	@echo "================================================"
	@echo ""
	@./scripts/create-vm.sh

# Terraformの初期化
init:
	@cd envs/example && terraform init

# Terraform実行計画
plan:
	@cd envs/example && terraform plan

# Terraformを実行
apply:
	@cd envs/example && terraform apply

# VMを削除
destroy:
	@cd envs/example && terraform destroy

# クリーンアップ
clean:
	@echo "Terraformの一時ファイルをクリーンアップしています..."
	@rm -rf envs/example/.terraform
	@rm -f envs/example/.terraform.lock.hcl
	@rm -f envs/example/terraform.tfstate*
	@echo "クリーンアップ完了"
