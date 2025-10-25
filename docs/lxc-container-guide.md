# Proxmox LXCコンテナ作成ガイド

## 概要

このガイドでは、TerraformとMakefileを使用してProxmox上でLXCコンテナを簡単に作成する方法を説明します。

## LXCコンテナとVMの違い

### LXCコンテナの特徴

**メリット:**
- 軽量で高速な起動（数秒）
- リソース効率が良い（メモリ、ディスク使用量が少ない）
- ホストカーネルを共有するため、オーバーヘッドが少ない
- VMよりも多くのコンテナを同じハードウェアで実行可能

**デメリット:**
- カーネルをホストと共有するため、異なるカーネルが必要な場合は使えない
- Windowsやカスタムカーネルが必要な用途には不向き
- セキュリティ面でVMより分離度が低い

### 使い分け

| 用途 | 推奨 |
|------|------|
| Webサーバー、データベース | LXCコンテナ |
| 開発環境、テスト環境 | LXCコンテナ |
| Docker/Kubernetesホスト | LXCコンテナ |
| Windows環境 | VM |
| カスタムカーネル | VM |
| 高度なセキュリティ要件 | VM |

## 前提条件

1. Proxmoxサーバーへのアクセス
2. APIトークンの取得済み
3. `.env`ファイルの設定済み
4. LXCテンプレートのダウンロード済み

### LXCテンプレートのダウンロード

Proxmox WebUIから：
1. Datacenter → ノード(pve) → local (pve) → CT Templates
2. 「Templates」ボタンをクリック
3. 必要なテンプレートを選択してダウンロード

推奨テンプレート：
- Ubuntu 22.04 Standard
- Ubuntu 20.04 Standard
- Debian 12 Standard
- Alpine 3.18 (軽量)

## コンテナ作成方法

### 基本的な使い方

```bash
# コンテナ作成ウィザードを起動
make create-container
```

### 対話形式での設定

1. **コンテナID** (100-999)
   - 例: 200

2. **コンテナ名**
   - 例: web-server-01
   - デフォルト: lxc-{ID}

3. **OSテンプレート**
   ```
   1. Ubuntu 22.04 LTS
   2. Ubuntu 20.04 LTS
   3. Debian 12
   4. Alpine 3.18
   ```

4. **CPUコア数** (1-32)
   - デフォルト: 1
   - 推奨: 1-2コア（軽量な用途）

5. **メモリ容量**
   - デフォルト: 512MB
   - 例: 512MB, 1GB, 2GB
   - 推奨:
     - 軽量サービス: 512MB
     - Webサーバー: 1GB
     - データベース: 2GB以上

6. **スワップ容量**
   - デフォルト: 512MB
   - 推奨: メモリと同じ容量

7. **ディスクサイズ** (GB)
   - デフォルト: 8GB
   - 推奨:
     - 基本用途: 8GB
     - 開発環境: 20GB
     - データストレージ: 50GB以上

8. **ストレージ**
   ```
   1. local-lvm
   2. usb-ssd-baffulo
   3. data-hdd
   4. data-ssd
   ```

9. **rootパスワード**
   - 確認のため2回入力

10. **非特権コンテナ**
    - Y/n (デフォルト: Yes)
    - 推奨: Yes（セキュリティ向上）

### 設定例

#### 例1: Webサーバー用コンテナ

```
コンテナID: 201
コンテナ名: web-nginx
テンプレート: Ubuntu 22.04 LTS
CPUコア数: 2
メモリ: 1GB
スワップ: 1GB
ディスクサイズ: 20GB
ストレージ: local-lvm
非特権: Yes
```

#### 例2: データベース用コンテナ

```
コンテナID: 202
コンテナ名: db-postgres
テンプレート: Ubuntu 22.04 LTS
CPUコア数: 2
メモリ: 2GB
スワップ: 2GB
ディスクサイズ: 50GB
ストレージ: data-ssd
非特権: Yes
```

#### 例3: 軽量サービス用コンテナ

```
コンテナID: 203
コンテナ名: monitoring
テンプレート: Alpine 3.18
CPUコア数: 1
メモリ: 512MB
スワップ: 512MB
ディスクサイズ: 8GB
ストレージ: local-lvm
非特権: Yes
```

## 作成されるファイル構造

```
containers/
└── {container-name}/
    ├── main.tf              # Terraformメイン設定
    ├── variables.tf         # 変数定義
    ├── terraform.tfvars     # Proxmox接続情報（.gitignoreで除外）
    ├── .terraform/          # Terraformプラグイン
    ├── terraform.tfstate    # Terraform状態ファイル（.gitignoreで除外）
    └── .terraform.lock.hcl  # 依存関係ロック
```

## コンテナ管理コマンド

### リスト表示

```bash
# 管理中のコンテナ一覧
make list-containers
```

### SSH接続

```bash
# IPアドレスは make list-containers で確認
ssh root@{ip-address}
```

### コンテナの削除

```bash
# 対話形式で削除
make destroy

# 手動で削除
cd containers/{container-name}
terraform destroy
```

## トラブルシューティング

### テンプレートが見つからない

**エラー:**
```
Error: template file not found
```

**解決策:**
1. Proxmox WebUIでテンプレートをダウンロード
2. テンプレートのパスを確認:
   ```bash
   pvesh get /nodes/pve/storage/local/content --content vztmpl
   ```
3. `create-container.sh`のテンプレートパスを更新

### IPアドレスが取得できない

**原因:**
- DHCPサーバーが応答していない
- ネットワーク設定が間違っている

**解決策:**
```bash
# コンテナ内で確認
pct enter {container-id}
ip addr show
dhclient eth0  # DHCPでIPを取得
```

### 非特権コンテナでDockerが動かない

**解決策:**

1. `nesting`機能を有効化（デフォルトで有効）
2. 必要に応じて追加設定:
   ```bash
   # Proxmoxホストで実行
   pct set {container-id} -features keyctl=1,nesting=1
   ```

### メモリ不足

**症状:**
- プロセスが強制終了される
- OOM (Out of Memory) エラー

**解決策:**
```bash
# コンテナのメモリを増やす
cd containers/{container-name}
# variables.tfのmemory値を変更
terraform apply
```

または、Proxmox WebUIから:
1. コンテナを停止
2. Resources → Memory → Edit
3. メモリ量を増やす
4. コンテナを起動

## ベストプラクティス

### 1. 非特権コンテナを使用する

```hcl
unprivileged = true
```

セキュリティが向上し、ホストへの影響を最小限に抑えられます。

### 2. リソースは必要最小限から

最初は少なめに設定し、必要に応じて増やす方が効率的です：
- メモリ: 512MB → 必要に応じて増加
- CPU: 1コア → 負荷に応じて増加
- ディスク: 8GB → データ量に応じて増加

### 3. タグを活用する

```hcl
tags = ["production", "web", "nginx"]
```

管理しやすくなります。

### 4. バックアップを設定する

Proxmox WebUIまたはcronで定期バックアップを設定：
```bash
# Proxmoxホストで実行
vzdump {container-id} --mode snapshot --storage local
```

### 5. 監視を設定する

リソース使用状況を定期的に確認：
```bash
# コンテナ内で
htop
df -h
free -m
```

## Terraformモジュールの詳細

### modules/proxmox_lxc

LXCコンテナ作成用のモジュールです。

**主な機能:**
- DHCP/静的IPアドレス設定
- SSH公開鍵認証
- 非特権/特権コンテナの選択
- nesting機能（Docker等のサポート）
- 自動的なIPアドレス取得

**出力:**
- `container_id`: コンテナID
- `container_name`: コンテナ名
- `ip_address`: IPアドレス

## 参考情報

### Proxmox VE Documentation
- [Linux Container](https://pve.proxmox.com/wiki/Linux_Container)
- [Unprivileged LXC containers](https://pve.proxmox.com/wiki/Unprivileged_LXC_containers)

### Terraform Provider
- [bpg/proxmox - Container Resource](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_container)

## まとめ

LXCコンテナは以下のような用途に最適です：
- 軽量なサービス実行
- マイクロサービスアーキテクチャ
- 開発・テスト環境
- リソース効率の重視

VMと組み合わせて使用することで、Proxmox環境を最大限に活用できます。
