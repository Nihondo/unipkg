#!/bin/bash

# Node Version Manager (nvm)
# Node.jsバージョン管理ツールのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
NVM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$NVM_SCRIPT_DIR/../common.sh"

# nvmパッケージ一覧取得
get_nvm_packages() {
    if [[ -d "$HOME/.nvm/versions/node" ]]; then
        local packages
        packages=$(ls "$HOME/.nvm/versions/node" 2>/dev/null | sort)
        local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
        
        if is_count_only; then
            count_packages "nvm" "$count"
            return
        fi
        
        echo "$packages" | while read -r package; do
            if [[ -n "$package" ]]; then
                if is_version_mode; then
                    # Node.jsバージョン管理の場合、パッケージ名としてNode.jsを、バージョンとして各バージョンを表示
                    output_csv "nvm" "Node.js" "$package"
                else
                    output_csv "nvm" "$package" ""
                fi
            fi
        done
    else
        warn_msg "nvmが見つかりません"
        if is_count_only; then
            count_packages "nvm" "0"
        fi
    fi
}

# パッケージ情報を取得
get_nvm_info() {
    local package="$1"
    if [[ ! -d "$HOME/.nvm/versions/node" ]]; then
        error_msg "nvmが見つかりません"
        return 1
    fi
    
    if [[ -d "$HOME/.nvm/versions/node/$package" ]]; then
        echo "Node.js バージョン: $package"
        echo "インストール場所: $HOME/.nvm/versions/node/$package"
        echo "実行可能ファイル: $HOME/.nvm/versions/node/$package/bin/node"
        if [[ -f "$HOME/.nvm/versions/node/$package/bin/node" ]]; then
            echo "バージョン情報: $("$HOME/.nvm/versions/node/$package/bin/node" --version 2>/dev/null || echo "取得できませんでした")"
        fi
    else
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
}

# パッケージを削除
delete_nvm_package() {
    local package="$1"
    if [[ ! -d "$HOME/.nvm/versions/node" ]]; then
        error_msg "nvmが見つかりません"
        return 1
    fi
    
    if [[ ! -d "$HOME/.nvm/versions/node/$package" ]]; then
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: nvm uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if command_exists nvm; then
            # nvmコマンドが利用可能な場合
            if nvm uninstall "$package" 2>/dev/null; then
                success_msg "パッケージ '$package' を削除しました"
            else
                error_msg "パッケージ '$package' の削除に失敗しました"
                return 1
            fi
        else
            # 直接ディレクトリを削除
            if rm -rf "$HOME/.nvm/versions/node/$package"; then
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
update_nvm_package() {
    local package="$1"
    if [[ ! -d "$HOME/.nvm/versions/node" ]]; then
        error_msg "nvmが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: nvmで管理されているNode.jsバージョンの更新はサポートされていません"
        else
            info_msg "DRY RUN: nvmで管理されているNode.jsバージョンの更新はサポートされていません"
        fi
        return 0
    fi
    
    # nvmではバージョンの更新ではなく、新しいバージョンのインストールが必要
    error_msg "nvmで管理されているNode.jsバージョンの更新はサポートされていません"
    error_msg "新しいバージョンをインストールするには: nvm install <version>"
    return 1
}