#!/bin/bash

# Node Version Manager (nodenv)
# Node.jsバージョン管理ツール（nvmの代替）のサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
NODENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$NODENV_SCRIPT_DIR/../common.sh"

# nodenvパッケージ一覧取得
get_nodenv_packages() {
    if command_exists nodenv || [[ -d "$HOME/.nodenv/versions" ]]; then
        local packages
        if command_exists nodenv; then
            packages=$(nodenv versions --bare 2>/dev/null | sort)
        else
            packages=$(ls "$HOME/.nodenv/versions" 2>/dev/null | sort)
        fi
        local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
        
        if is_count_only; then
            count_packages "nodenv" "$count"
            return
        fi
        
        echo "$packages" | while read -r package; do
            if [[ -n "$package" ]]; then
                if is_version_mode; then
                    # Node.jsバージョン管理の場合
                    output_csv "nodenv" "Node.js" "$package"
                else
                    output_csv "nodenv" "$package" ""
                fi
            fi
        done
    else
        warn_msg "nodenvが見つかりません"
        if is_count_only; then
            count_packages "nodenv" "0"
        fi
    fi
}

# パッケージ情報を取得
get_nodenv_info() {
    local package="$1"
    if ! command_exists nodenv && [[ ! -d "$HOME/.nodenv/versions" ]]; then
        error_msg "nodenvが見つかりません"
        return 1
    fi
    
    local version_path=""
    if [[ -d "$HOME/.nodenv/versions/$package" ]]; then
        version_path="$HOME/.nodenv/versions/$package"
    else
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    echo "Node.js バージョン: $package"
    echo "インストール場所: $version_path"
    echo "実行可能ファイル: $version_path/bin/node"
    if [[ -f "$version_path/bin/node" ]]; then
        echo "バージョン情報: $("$version_path/bin/node" --version 2>/dev/null || echo "取得できませんでした")"
    fi
    
    # npmの情報も表示
    if [[ -f "$version_path/bin/npm" ]]; then
        local npm_count=$("$version_path/bin/npm" list -g --depth=0 --parseable 2>/dev/null | wc -l | tr -d ' ')
        echo "グローバルnpmパッケージ数: $npm_count"
    fi
}

# パッケージを削除
delete_nodenv_package() {
    local package="$1"
    if ! command_exists nodenv && [[ ! -d "$HOME/.nodenv/versions" ]]; then
        error_msg "nodenvが見つかりません"
        return 1
    fi
    
    if [[ ! -d "$HOME/.nodenv/versions/$package" ]]; then
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: nodenv uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if command_exists nodenv; then
            # nodenvコマンドが利用可能な場合
            if nodenv uninstall -f "$package" 2>/dev/null; then
                success_msg "パッケージ '$package' を削除しました"
            else
                error_msg "パッケージ '$package' の削除に失敗しました"
                return 1
            fi
        else
            # 直接ディレクトリを削除
            if rm -rf "$HOME/.nodenv/versions/$package"; then
                success_msg "パッケージ '$package' を削除しました"
            else
                error_msg "パッケージ '$package' の削除に失敗しました"
                return 1
            fi
        fi
    else
        info_msg "キャンセルされました"
    fi
}

# パッケージをアップデート
update_nodenv_package() {
    local package="$1"
    if ! command_exists nodenv && [[ ! -d "$HOME/.nodenv/versions" ]]; then
        error_msg "nodenvが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: nodenvで管理されているNode.jsバージョンの更新はサポートされていません"
        else
            info_msg "DRY RUN: nodenvで管理されているNode.jsバージョンの更新はサポートされていません"
        fi
        return 0
    fi
    
    # nodenvではバージョンの更新ではなく、新しいバージョンのインストールが必要
    error_msg "nodenvで管理されているNode.jsバージョンの更新はサポートされていません"
    error_msg "新しいバージョンをインストールするには: nodenv install <version>"
    return 1
}