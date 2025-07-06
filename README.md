# unipkg - Unified Package Manager Tool

複数のパッケージマネージャーを統一インターフェースで操作できるコマンドラインツールです。

## 概要

`unipkg`は、異なるパッケージマネージャーのパッケージ操作（一覧表示、情報取得、削除、アップデート）を統一されたインターフェースで実行できるツールです。macOSやUnix系システムで利用可能な**19種類**のパッケージマネージャーに対応し、**バージョン情報表示機能**と**最新バージョン比較・ステータス表示機能**を含む包括的なパッケージ管理ツールです。

### 新機能: モジュラーアーキテクチャ
v2.0では完全なモジュラーアーキテクチャを採用し、各パッケージマネージャーの機能が独立したモジュールに分離されています。これにより保守性と拡張性が大幅に向上しました。


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
- パッケージマネージャごとにシェルを分割して、managerディレクトリ配下のサブモジュールとして管理するように変更します
- brew.sh 29行目、32行目の brew コマンドが、パスが通ってないのではないでしょうか
- get_brew_outdated_info関数は正しく、カラムを取得できていないです。brew outdated --formula は "cloudflared (2025.6.1) < 2025.7.0" の形式での出力です
- オリジナルにあった、現バージョンと最新バージョンが異なる場合の Status 表記がなくなりました。format_table 関数の場合だけ、表示をリッチにするのと合わせて Latest, Outdated のステータス列を追加します
- brew以外のマネージャーでも最新バージョンを返すものにはstatusを追加してください
- gemの最新バージョン取得が、「"gem" "psych" "3.1.0" "5.2.6 ruby java" "Outdated"」のように不要な文字列が残っています


## 対応パッケージマネージャー

### アプリケーションパッケージマネージャー（8個）
- **brew**: Homebrew (macOS) - 最新バージョン比較対応
- **npm**: Node Package Manager - 最新バージョン比較対応
- **perl**: Perl modules (ExtUtils::Installed使用)
- **cpan**: CPAN (Perl)
- **pip3**: Python Package Index - 最新バージョン比較対応
- **gem**: Ruby Gems - 最新バージョン比較対応
- **cargo**: Rust Cargo packages
- **go**: Go modules

### システムパッケージマネージャー（5個）
- **dnf**: DNF Package Manager (Fedora/RHEL 8+) - 最新バージョン比較対応
- **yum**: YUM Package Manager (RHEL/CentOS)
- **apt**: APT Package Manager (Debian/Ubuntu)
- **dpkg**: DPKG Package Manager (Debian/Ubuntu)
- **rpm**: RPM Package Manager (Red Hat系)

### バージョン管理マネージャー（9個）
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
brew         bat                            0.25.0_1        0.25.0_1        Latest
brew         git                            2.50.0          2.51.0          Outdated
npm          @anthropic-ai/claude-code      1.0.35          1.0.40          Outdated
pip3         requests                       2.31.0          2.31.0          Latest
dnf          vim                            9.0.2120-1.el9  9.0.2153-1.el9  Outdated
```

**ステータス表示**:
- `Latest` (緑色): 最新バージョン
- `Outdated` (赤色): 更新が必要

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
[
  {"Manager": "brew", "Package": "bat", "Current Version": "0.25.0_1", "Latest Version": "0.25.0_1", "Status": "Latest"},
  {"Manager": "brew", "Package": "git", "Current Version": "2.50.0", "Latest Version": "2.51.0", "Status": "Outdated"},
  {"Manager": "npm", "Package": "@anthropic-ai/claude-code", "Current Version": "1.0.35", "Latest Version": "1.0.40", "Status": "Outdated"},
  {"Manager": "dnf", "Package": "vim", "Current Version": "9.0.2120-1.el9", "Latest Version": "9.0.2153-1.el9", "Status": "Outdated"}
]
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
Manager,Package,Current Version,Latest Version,Status
brew,bat,0.25.0_1,0.25.0_1,Latest
brew,git,2.50.0,2.51.0,Outdated
npm,@anthropic-ai/claude-code,1.0.35,1.0.40,Outdated
dnf,vim,9.0.2120-1.el9,9.0.2153-1.el9,Outdated
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
- **完全実装**: `brew`、`npm`、`gem`、`pip3`、`dnf`
- **ステータス表示**: `Latest`（最新）と`Outdated`（更新必要）をカラー表示
- **未実装**: その他のパッケージマネージャー（将来追加予定）
- **パフォーマンス**: 
  - `brew`: `brew outdated --verbose`で一括取得（高速）
  - `dnf`: `dnf list updates`で一括取得（高速）
  - `npm`: 個別パッケージごとに`npm view`で取得（やや時間がかかる）
  - `gem`: 個別パッケージごとに`gem list --remote`で取得（やや時間がかかる）
  - `pip3`: ローカル情報のみ（限定的機能）

### その他の注意事項
- CPANは設定が複雑なため、Perlモジュール一覧として代替実装しています
- Goモジュールは`$GOPATH/pkg/mod`または`$HOME/go/pkg/mod`から検索します
- 一部のパッケージマネージャーが利用できない場合は警告メッセージが表示されます
- エラーメッセージは標準エラー出力、データは標準出力に出力されます

## 技術仕様

- **言語**: Bash
- **動作環境**: macOS、Linux、その他Unix系システム
- **アーキテクチャ**: モジュラー設計（22個の独立モジュール）
- **互換性**: bash 3.2.57以上（macOSのデフォルトbashに対応）
- **依存関係**: 各パッケージマネージャーが個別にインストールされている必要があります
- **エラーハンドリング**: `set -euo pipefail`による厳密なエラー処理

### ファイル構成
```
unipkg/
├── unipkg                    # メインスクリプト
└── manager/
    ├── common.sh            # 共通ユーティリティ関数
    ├── application/         # アプリケーションパッケージマネージャー（8個）
    ├── system/             # システムパッケージマネージャー（5個）
    └── version/            # バージョン管理マネージャー（9個）
```
