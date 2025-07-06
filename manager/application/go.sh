#!/bin/bash

# go パッケージマネージャ
# Go modules (installed packages) のサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
GO_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$GO_SCRIPT_DIR/../common.sh"

# goパッケージ一覧取得
get_go_packages() {
    if ! command_exists go; then
        warn_msg "goが見つかりません"
        if is_count_only; then
            echo "go,0"
        fi
        return
    fi
    
    local packages=""
    local count=0
    
    # GOPATHが設定されている場合、そこからパッケージを探す
    if [[ -n "${GOPATH:-}" ]] && [[ -d "$GOPATH/pkg/mod" ]]; then
        if is_version_mode; then
            # バージョン情報付き（パッケージ@バージョン形式）
            packages=$(find "$GOPATH/pkg/mod" -maxdepth 1 -type d 2>/dev/null | \
                      grep -v "cache" | \
                      sed "s|$GOPATH/pkg/mod/||" | \
                      grep "@" | \
                      sort | \
                      uniq)
        else
            # パッケージ名のみ
            packages=$(find "$GOPATH/pkg/mod" -maxdepth 2 -type d 2>/dev/null | \
                      grep -v "cache" | \
                      sed "s|$GOPATH/pkg/mod/||" | \
                      grep "/" | \
                      sort | \
                      uniq)
        fi
        count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    elif [[ -d "$HOME/go/pkg/mod" ]]; then
        if is_version_mode; then
            # バージョン情報付き（パッケージ@バージョン形式）
            packages=$(find "$HOME/go/pkg/mod" -maxdepth 1 -type d 2>/dev/null | \
                      grep -v "cache" | \
                      sed "s|$HOME/go/pkg/mod/||" | \
                      grep "@" | \
                      sort | \
                      uniq)
        else
            # パッケージ名のみ
            packages=$(find "$HOME/go/pkg/mod" -maxdepth 2 -type d 2>/dev/null | \
                      grep -v "cache" | \
                      sed "s|$HOME/go/pkg/mod/||" | \
                      grep "/" | \
                      sort | \
                      uniq)
        fi
        count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    fi
    
    if is_count_only; then
        echo "go,$count"
        return
    fi
    
    if [[ -n "$packages" ]]; then
        echo "$packages" | while read -r line; do
            if [[ -n "$line" ]]; then
                if is_version_mode; then
                    # package@version形式を分離
                    local package=$(echo "$line" | cut -d'@' -f1)
                    local version=$(echo "$line" | cut -d'@' -f2-)
                    
                    if is_new_version_mode; then
                        # Goモジュールの最新バージョン情報は取得困難なため、現在のバージョンを使用
                        echo "go,$package,$version,$version"
                    else
                        output_csv "go" "$package" "$version"
                    fi
                else
                    output_csv "go" "$line" ""
                fi
            fi
        done
    fi
}

# パッケージ情報を取得
get_go_info() {
    local package="$1"
    if ! command_exists go; then
        error_msg "goが見つかりません"
        return 1
    fi
    
    echo "Goモジュール: $package"
    if [[ -n "${GOPATH:-}" ]] && [[ -d "$GOPATH/pkg/mod" ]]; then
        find "$GOPATH/pkg/mod" -name "*$package*" -type d 2>/dev/null | head -10
    elif [[ -d "$HOME/go/pkg/mod" ]]; then
        find "$HOME/go/pkg/mod" -name "*$package*" -type d 2>/dev/null | head -10
    fi
    echo ""
    echo "詳細情報を取得するには 'go list -m $package' を実行してください"
}

# パッケージを削除
delete_go_package() {
    local package="$1"
    if ! command_exists go; then
        error_msg "goが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: go clean -modcache (注意: Goモジュールの個別削除は困難です)"
        return 0
    fi
    
    warn_msg "Goモジュールの個別削除は標準的な方法がありません"
    warn_msg "'go clean -modcache' で全モジュールキャッシュをクリアできます"
    return 1
}

# パッケージをアップデート
update_go_package() {
    local package="$1"
    if ! command_exists go; then
        error_msg "goが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: go get -u all (注意: プロジェクトコンテキストが必要です)"
        else
            info_msg "DRY RUN: go get -u $package"
        fi
        return 0
    fi
    
    warn_msg "Goモジュールの更新にはプロジェクトコンテキストが必要です"
    warn_msg "Goプロジェクトディレクトリで 'go get -u' を実行してください"
    return 1
}