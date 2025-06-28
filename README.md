# unipkg - Unified Package Manager Tool

複数のパッケージマネージャーを統一インターフェースで操作できるコマンドラインツールです。

## 概要

`unipkg`は、異なるパッケージマネージャーのパッケージ操作（一覧表示、情報取得、削除、アップデート）を統一されたインターフェースで実行できるツールです。macOSやUnix系システムで利用可能な主要なパッケージマネージャーに対応しています。


## 注意 Claude Codeのみで開発する実験の成果物です
### 以下のプロンプトのみで開発しています
- brew, npm, cpan, cpanmなどのパッケージを一覧にするスクリプトを作成したい
- /init READMEも作成してください
- dnf, yum, aptなども対応したい
- nvm等のバージョン管理マネージャも加えたいです
- パッケージ名を引数で与えた場合に、パッケージの情報を出力したい
- パッケージのアンインストールもしたい
- パッケージのアップデートも行いたいです
- -u, --uninstall は、-d , --delete に変更します
- アップデートには、--update だけでなく -u も指定可能とします
- アップデート、削除に対応したので、list_packages.sh というタイトルを変えたいです。どんな案がありますか
- unipkgはどうでしょう
- gitにリモートリポジトリを作成してプッシュしてください
- コーディング規約に従ってコメントをつけてください

## 対応パッケージマネージャー

### アプリケーションパッケージマネージャー
- **brew**: Homebrew (macOS)
- **npm**: Node Package Manager
- **perl**: Perl modules (ExtUtils::Installed使用)
- **pip3**: Python Package Index
- **gem**: Ruby Gems
- **cargo**: Rust Cargo packages
- **go**: Go modules

### システムパッケージマネージャー
- **dnf**: DNF Package Manager (Fedora/RHEL 8+)
- **yum**: YUM Package Manager (RHEL/CentOS)
- **apt**: APT Package Manager (Debian/Ubuntu)
- **dpkg**: DPKG Package Manager (Debian/Ubuntu)
- **rpm**: RPM Package Manager (Red Hat系)

### バージョン管理マネージャー
- **nvm**: Node Version Manager
- **rbenv**: Ruby Version Manager
- **pyenv**: Python Version Manager
- **nodenv**: Node Version Manager (alternative)
- **tfenv**: Terraform Version Manager
- **jenv**: Java Version Manager
- **asdf**: Universal Version Manager
- **gvm**: Go Version Manager
- **rustup**: Rust toolchain installer

## インストール・セットアップ

```bash
# スクリプトを実行可能にする
chmod +x unipkg
```

## 使用方法

### 基本的な使用例

```bash
# 全パッケージマネージャーの一覧を表示
./unipkg

# パッケージ数のみを表示
./unipkg -c

# 特定のパッケージマネージャーのみ表示
./unipkg brew npm pip3

# システムパッケージマネージャーのみ表示
./unipkg dnf apt dpkg

# バージョン管理マネージャーのみ表示
./unipkg nvm pyenv rbenv

# JSON形式で出力
./unipkg -f json

# パッケージの詳細情報を表示
./unipkg -i git

# 特定のパッケージマネージャーでパッケージ情報を表示
./unipkg -i express npm

# パッケージを削除（確認あり）
./unipkg -d oldpackage

# 特定のパッケージマネージャーで削除
./unipkg -d somelib npm

# ドライランで削除内容を確認
./unipkg -d package --dry-run

# 確認なしで削除（注意！）
./unipkg -d package --force

# 全パッケージをアップデート
./unipkg -u

# 特定のパッケージをアップデート
./unipkg -u somepackage

# 特定のパッケージマネージャーでアップデート
./unipkg -u git brew

# ドライランでアップデート内容を確認
./unipkg -u --dry-run

# 確認なしでアップデート
./unipkg -u --force

# CSV形式でファイルに出力
./unipkg -f csv -o packages.csv

# 色の出力を無効にする
./unipkg --no-color
```

### オプション一覧

- `-h, --help`: ヘルプメッセージを表示
- `-f, --format FORMAT`: 出力フォーマット (table|json|csv) [デフォルト: table]
- `-o, --output FILE`: 結果をファイルに出力
- `-c, --count`: パッケージ数のみを表示
- `-i, --info PACKAGE`: 指定したパッケージの詳細情報を表示
- `-d, --delete PACKAGE`: 指定したパッケージを削除
- `-u, --update [PACKAGE]`: 全パッケージまたは指定パッケージをアップデート
- `--dry-run`: 実行内容を表示（実際には実行しない）
- `--force`: 確認なしで実行
- `--no-color`: 色の出力を無効にする

## 出力例

### テーブル形式（デフォルト）
```
Manager    Package
---------- -------
brew       bat
brew       git
npm        @vue/cli
pip3       requests
gem        bundler
```

### カウントモード
```
Manager    Count
---------- -----
apt        1234
brew       108
dnf        0
npm        5
pip3       12
gem        48
```

### JSON形式
```json
{
  "timestamp": "2025-06-28T21:52:41+09:00",
  "packages": [
    {"manager": "brew", "package": "bat"},
    {"manager": "npm", "package": "@vue/cli"}
  ]
}
```

### パッケージ情報表示
```
$ ./unipkg -i git brew

=== brew ===
==> git: stable 2.50.0 (bottled), HEAD
Distributed revision control system
https://git-scm.com
Not installed
From: https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/g/git.rb
License: GPL-2.0-only
==> Dependencies
Required: gettext, pcre2
```

### アンインストール例
```
$ ./unipkg -d somepackage brew

=== brew ===
警告: brew から somepackage を削除しようとしています。
この操作は取り消せません。続行しますか？ (y/N)
y
情報: brew で somepackage を削除しています...
成功: brew: somepackage の削除が完了しました
```

### アップデート例
```
$ ./unipkg -u git brew

=== brew ===
brew で git をアップデートしようとしています。続行しますか？ (y/N)
y
情報: brew で git をアップデートしています...
成功: brew: git のアップデートが完了しました
```

## 注意事項

### 安全性について
- **削除・アップデート機能は慎重に使用してください**
- `--dry-run`オプションで事前に実行内容を確認することを推奨します
- システムパッケージ（dnf、yum、apt等）の操作には`sudo`権限が必要です
- アップデート処理は時間がかかる場合があります

- CPANは設定が複雑なため、Perlモジュール一覧として代替実装しています
- Goモジュールは`$GOPATH/pkg/mod`または`$HOME/go/pkg/mod`から検索します
- 一部のパッケージマネージャーが利用できない場合は警告メッセージが表示されます
- エラーメッセージは標準エラー出力、データは標準出力に出力されます

## 技術仕様

- **言語**: Bash
- **動作環境**: macOS、Linux、その他Unix系システム
- **依存関係**: 各パッケージマネージャーが個別にインストールされている必要があります
- **エラーハンドリング**: `set -euo pipefail`による厳密なエラー処理