# unipkg - Unified Package Manager Tool

複数のパッケージマネージャーを統一インターフェースで操作できるコマンドラインツールです。

## 概要

`unipkg`は、異なるパッケージマネージャーのパッケージ操作（一覧表示、情報取得、削除、アップデート）を統一されたインターフェースで実行できるツールです。macOSやUnix系システムで利用可能な**19種類**のパッケージマネージャーに対応し、**バージョン情報表示機能**も含む包括的なパッケージ管理ツールです。


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
- unipkgのコメント形式 /* */ はbashで使用できない形式です # に修正してください
- 一覧表示の時にバージョン番号も表示したい
- npmでanthropic-ai/claude-code@1.0.35とバージョン表示されているのは、パッケージ名 anthropic-ai/claude-code, バージョン 1.0.35 が正しいです
- システムパッケージマネージャーや、バージョン管理マネージャについても、バージョン表示の対応を進めてください
- -nv を指定した場合に、インストールされているバージョン番号の表示に加えて、そのパッケージの最新バージョンを表示。かつ更新バージョンがある場合はカラーリングで示してください
- brewについては、更新があるバージョンの取得コマンド brew outdated が別に用意されているので、こちらを使って高速化してください
- dnfについて実装しましょう dnf list updatesで更新のあるパッケージが取得できます
- dnfパッケージのバージョン形式の取得で、ハイフンより後の情報をカットしないでください
- nvオプションの追加をメモリに記憶し、READMEも更新してください


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

# バージョン情報も表示
./unipkg -v

# 特定のパッケージマネージャーでバージョン情報を表示
./unipkg brew -v

# 現在のバージョンと最新バージョンを比較表示（更新必要なパッケージは赤色表示）
./unipkg -nv

# 特定のパッケージマネージャーで最新バージョンと比較
./unipkg brew -nv

# JSON形式で出力
./unipkg -f json

# バージョン情報付きでJSON形式で出力
./unipkg -v -f json

# 最新バージョン比較をJSON形式で出力
./unipkg -nv -f json

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

# バージョン情報付きでCSV形式で出力
./unipkg -v -f csv -o packages_with_versions.csv

# 最新バージョン比較をCSV形式で出力
./unipkg -nv -f csv -o packages_with_latest.csv

# 色の出力を無効にする
./unipkg --no-color
```

### オプション一覧

- `-h, --help`: ヘルプメッセージを表示
- `-f, --format FORMAT`: 出力フォーマット (table|json|csv) [デフォルト: table]
- `-o, --output FILE`: 結果をファイルに出力
- `-c, --count`: パッケージ数のみを表示
- `-v, --with-version`: バージョン情報も表示
- `-nv, --new-version`: 現在のバージョンと最新バージョンを比較表示
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

### バージョン情報付きテーブル形式
```
Manager      Package                        Version
------------ ------------------------------ -------
brew         bat                            0.25.0_1
brew         git                            2.50.0
npm          @anthropic-ai/claude-code      1.0.35
pip3         requests                       2.31.0
gem          bundler                        2.4.10
nvm          Node.js                        18.17.0
rbenv        Ruby                           3.0.0
```

### 最新バージョン比較表示（-nvオプション）
```
Manager      Package                        Current         Latest          Status
------------ ------------------------------ --------------- --------------- ------
brew         bat                            0.25.0_1        0.25.0_1        OK
brew         git                            2.50.0          2.51.0          UPDATE
npm          @anthropic-ai/claude-code      1.0.35          1.0.40          UPDATE
pip3         requests                       2.31.0          2.31.0          OK
dnf          vim                            9.0.2120-1.el9  9.0.2153-1.el9  UPDATE
```

**ステータス表示**:
- `OK` (緑色): 最新バージョン
- `UPDATE` (赤色): 更新が必要
- `NEWER` (黄色): インストール版が新しい

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

### バージョン情報付きJSON形式
```json
{
  "timestamp": "2025-06-30T21:59:31+09:00",
  "packages": [
    {"manager": "brew", "package": "bat", "version": "0.25.0_1"},
    {"manager": "npm", "package": "@anthropic-ai/claude-code", "version": "1.0.35"},
    {"manager": "pip3", "package": "requests", "version": "2.31.0"},
    {"manager": "gem", "package": "bundler", "version": "1.17.2"},
    {"manager": "nvm", "package": "Node.js", "version": "18.17.0"}
  ]
}
```

### 最新バージョン比較JSON形式（-nvオプション）
```json
{
  "timestamp": "2025-07-05T21:45:12+09:00",
  "packages": [
    {"manager": "brew", "package": "bat", "current": "0.25.0_1", "latest": "0.25.0_1", "status": "OK"},
    {"manager": "brew", "package": "git", "current": "2.50.0", "latest": "2.51.0", "status": "UPDATE"},
    {"manager": "npm", "package": "@anthropic-ai/claude-code", "current": "1.0.35", "latest": "1.0.40", "status": "UPDATE"},
    {"manager": "dnf", "package": "vim", "current": "9.0.2120-1.el9", "latest": "9.0.2153-1.el9", "status": "UPDATE"}
  ]
}
```

### CSV形式
```
Manager,Package
brew,bat
npm,@vue/cli
pip3,requests
```

### バージョン情報付きCSV形式
```
Manager,Package,Version
brew,bat,0.25.0_1
npm,@anthropic-ai/claude-code,1.0.35
pip3,requests,2.31.0
gem,bundler,1.17.2
nvm,Node.js,18.17.0
rbenv,Ruby,3.0.0
```

### 最新バージョン比較CSV形式（-nvオプション）
```
Manager,Package,Current,Latest,Status
brew,bat,0.25.0_1,0.25.0_1,OK
brew,git,2.50.0,2.51.0,UPDATE
npm,@anthropic-ai/claude-code,1.0.35,1.0.40,UPDATE
dnf,vim,9.0.2120-1.el9,9.0.2153-1.el9,UPDATE
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

### 最新バージョン比較機能（-nvオプション）について
- **実装済みパッケージマネージャー**: `brew`（高速化済み）、`npm`、`dnf`
- **部分実装**: `pip3`, `gem`, `cargo`（最新バージョン取得関数のみ定義済み）
- **未実装**: その他のパッケージマネージャー
- **パフォーマンス**: 
  - `brew`: `brew outdated`で一括取得（高速）
  - `dnf`: `dnf list updates`で一括取得（高速）
  - `npm`: 個別パッケージごとに`npm view`で取得（やや時間がかかる）

### その他の注意事項
- CPANは設定が複雑なため、Perlモジュール一覧として代替実装しています
- Goモジュールは`$GOPATH/pkg/mod`または`$HOME/go/pkg/mod`から検索します
- 一部のパッケージマネージャーが利用できない場合は警告メッセージが表示されます
- エラーメッセージは標準エラー出力、データは標準出力に出力されます

## 技術仕様

- **言語**: Bash
- **動作環境**: macOS、Linux、その他Unix系システム
- **依存関係**: 各パッケージマネージャーが個別にインストールされている必要があります
- **エラーハンドリング**: `set -euo pipefail`による厳密なエラー処理
