# Proxmox Terraform プロジェクト

TerraformでProxmox上のVMを管理するプロジェクトです。

## 前提条件

- Terraform >= 1.0.0
- Proxmox VE 8.x
- Proxmox APIトークン
- SSH公開鍵（VMにログインするため）

## プロジェクト構成

```
proxmox-terraform/
├── .env                      # 環境変数ファイル（機密情報を含む、Git管理外）
├── .env.example              # 環境変数のテンプレート
├── modules/
│   └── proxmox_vm/           # VM作成モジュール
│       ├── provider.tf       # Proxmox Provider設定
│       ├── variables.tf      # 変数定義
│       ├── main.tf           # VM リソース定義
│       └── outputs.tf        # 出力定義
├── envs/
│   └── example/              # 環境ごとの設定
│       ├── main.tf           # VM定義
│       ├── variables.tf      # 変数定義
│       └── terraform.tfvars.example  # 変数値のテンプレート
└── template/                 # テンプレートファイル
    ├── main.tf.example
    ├── variables.tf.example
    └── terraform.tfvars.example
```

## クイックスタート（対話形式）

最も簡単な方法は、Makefileを使った対話形式のVM作成です。

```bash
# VM作成ウィザードを起動
make create-vm
```

このコマンドで以下の項目を対話的に入力できます：
- VM ID (100-999)
- VM名
- CPUコア数 (1-32)
- メモリ容量 (例: 2GB, 1024MB)
- ディスクサイズ (GB)
- ストレージ（選択肢から選択）
- ユーザー名
- パスワード

設定内容を確認後、自動的に`vms/{VM名}/`ディレクトリが作成され、Terraformファイルが生成され、VMが作成されます。

### VM管理の仕組み

各VMは独立したディレクトリで管理されます：
```
vms/
├── web-server-01/      # VM名ごとのディレクトリ
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── terraform.tfstate
├── db-server-01/
│   └── ...
└── test-vm/
    └── ...
```

これにより：
- **複数VMの並行管理**: 新しいVMを作成しても既存のVMに影響なし
- **個別の状態管理**: 各VMが独立したステートファイルを持つ
- **簡単な削除**: VMごとに選択して削除可能

### その他のMakeコマンド

```bash
make help       # ヘルプを表示
make list-vms   # 管理中のVMリストを表示
make destroy    # VMを削除（選択式）
make clean      # 一時ファイルをクリーンアップ（選択式）
```

## 手動セットアップ手順

対話形式を使わず、手動で設定する場合は以下の手順に従ってください。

### 1. 環境変数ファイルの作成（初回のみ）

プロジェクトルートで `.env` ファイルを作成します。

```bash
# テンプレートをコピー
cp .env.example .env

# .env を編集して実際の値を設定
```

`.env` ファイルの内容：

```bash
PROXMOX_VE_ENDPOINT=https://192.168.1.2:8006/
PROXMOX_VE_API_TOKEN=terraform-prov@pve!terraform-token=your-actual-secret
PROXMOX_VE_INSECURE=true
```

**重要**: `.env` ファイルは `.gitignore` に含まれており、Gitにコミットされません。

### 2. SSH公開鍵の確認

VMにログインするためのSSH公開鍵を準備します。

```bash
# 公開鍵が存在するか確認
ls ~/.ssh/id_rsa.pub

# 存在しない場合は作成
ssh-keygen -t rsa -b 4096
```

### 3. 新しい環境の作成

新しいVMを作成するには、`envs/`配下に新しいディレクトリを作成します。

```bash
# 新しい環境ディレクトリを作成
mkdir -p envs/my-vm

# テンプレートファイルをコピー
cp template/main.tf.example envs/my-vm/main.tf
cp template/variables.tf.example envs/my-vm/variables.tf
cp template/terraform.tfvars.example envs/my-vm/terraform.tfvars
```

### 4. 設定ファイルの編集

#### 4-1. terraform.tfvars を編集

`envs/my-vm/terraform.tfvars` を編集して、Proxmox接続情報を設定します。

```hcl
proxmox_endpoint   = "https://192.168.1.2:8006/"
proxmox_api_token  = "terraform-prov@pve!terraform-token=c8f5e5ff-8a4d-40f8-a46a-17d1f7de3ab8"
proxmox_insecure   = true
```

**注意**: `terraform.tfvars` は `.gitignore` に含まれており、Gitにコミットされません。

#### 4-2. main.tf を編集

`envs/my-vm/main.tf` を編集して、VM設定をカスタマイズします。

```hcl
module "ubuntu_vm" {
  source = "../../modules/proxmox_vm"

  # Proxmox接続設定（必須）
  proxmox_endpoint   = var.proxmox_endpoint
  proxmox_api_token  = var.proxmox_api_token
  proxmox_insecure   = var.proxmox_insecure

  # VM基本設定
  vm_name       = "my-ubuntu-vm"      # VM名
  vm_id         = 100                  # VM ID（任意、省略可）
  target_node   = "pve"                # Proxmoxノード名
  template_name = "ubuntu-2204-template"  # テンプレート名

  # リソース設定（カスタマイズ可能）
  cores     = 2      # CPUコア数
  memory    = 2048   # メモリ (MB)
  disk_size = 20     # ディスク (GB)
  storage   = "local-lvm"  # ストレージ名

  # ネットワーク設定（必須）
  ip_address = "192.168.1.100/24"  # IPアドレス（CIDR形式）
  gateway    = "192.168.1.1"        # ゲートウェイ
  bridge     = "vmbr0"              # ネットワークブリッジ

  # SSH設定
  username       = "ubuntu"
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  # タグ（オプション）
  tags = ["terraform", "ubuntu", "production"]
}
```

### 5. Terraformの実行

```bash
# 環境ディレクトリに移動
cd envs/my-vm

# 初期化
terraform init

# 実行計画の確認
terraform plan

# VMを作成
terraform apply

# VMを削除
terraform destroy
```

## 環境変数を使った実行（推奨）

より安全に運用するため、環境変数を使用することもできます。

```bash
# プロジェクトルートの .env を読み込む
export $(cat ../../.env | xargs)

# または、直接環境変数を設定
export TF_VAR_proxmox_endpoint="https://192.168.1.2:8006/"
export TF_VAR_proxmox_api_token="terraform-prov@pve!terraform-token=xxxxx"
export TF_VAR_proxmox_insecure=true

# Terraform実行
terraform plan
terraform apply
```

この場合、`terraform.tfvars` ファイルは不要になります。

## 設定パラメータ

### 必須パラメータ

| パラメータ | 説明 | 例 |
|-----------|------|-----|
| `proxmox_endpoint` | ProxmoxのエンドポイントURL | `"https://192.168.1.2:8006/"` |
| `proxmox_api_token` | Proxmox APIトークン | `"user@pve!token=secret"` |
| `vm_name` | VM名 | `"ubuntu-server-01"` |
| `ip_address` | IPアドレス (CIDR形式) | `"192.168.1.100/24"` |

### オプションパラメータ

| パラメータ | デフォルト値 | 説明 |
|-----------|------------|------|
| `proxmox_insecure` | `true` | 自己署名証明書を許可 |
| `vm_id` | `null` (自動割当) | VM ID |
| `target_node` | `"pve"` | Proxmoxノード名 |
| `template_name` | `"ubuntu-2204-template"` | VMテンプレート名 |
| `cores` | `2` | CPUコア数 |
| `memory` | `2048` | メモリ (MB) |
| `disk_size` | `20` | ディスクサイズ (GB) |
| `storage` | `"local-lvm"` | ストレージ名 |
| `gateway` | `"192.168.1.1"` | ゲートウェイ |
| `bridge` | `"vmbr0"` | ネットワークブリッジ |
| `username` | `"ubuntu"` | VMのユーザー名 |
| `ssh_public_key` | `""` | SSH公開鍵 |
| `tags` | `[]` | タグのリスト |

## 複数VMの作成

同じ環境ファイル内で複数のVMを定義できます。

```hcl
module "web_server" {
  source = "../../modules/proxmox_vm"

  proxmox_endpoint  = var.proxmox_endpoint
  proxmox_api_token = var.proxmox_api_token

  vm_name    = "web-server-01"
  vm_id      = 100
  ip_address = "192.168.1.100/24"
  cores      = 4
  memory     = 4096
  # ...
}

module "db_server" {
  source = "../../modules/proxmox_vm"

  proxmox_endpoint  = var.proxmox_endpoint
  proxmox_api_token = var.proxmox_api_token

  vm_name    = "db-server-01"
  vm_id      = 101
  ip_address = "192.168.1.101/24"
  cores      = 8
  memory     = 8192
  disk_size  = 100
  # ...
}
```

## トラブルシューティング

### テンプレートが見つからない

- Proxmox WebUIでテンプレートが存在するか確認
- `template_name` パラメータがテンプレート名と一致しているか確認

### IPアドレスの重複

- 既に使用されているIPアドレスを指定していないか確認
- CIDR形式（例: `192.168.1.100/24`）で記述されているか確認

### SSH接続できない

- `ssh_public_key` が正しく設定されているか確認
- VMのCloud-initが正常に動作しているか確認

### API認証エラー

- `.env` または `terraform.tfvars` のAPIトークンが正しいか確認
- Proxmox側でトークンが有効か、権限が正しく設定されているか確認

## 参考

- [Proxmox Provider Documentation](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)
