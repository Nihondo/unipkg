#!/bin/bash

# Go Version Manager (gvm)
# Goバージョン管理ツールのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
GVM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$GVM_SCRIPT_DIR/../common.sh"

# gvmパッケージ一覧取得
get_gvm_packages() {
    if [[ -d "$HOME/.gvm/gos" ]]; then
        local packages
        packages=$(ls "$HOME/.gvm/gos" 2>/dev/null | sort)
        local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
        
        if is_count_only; then
            count_packages "gvm" "$count"
            return
        fi
        
        echo "$packages" | while read -r package; do
            if [[ -n "$package" ]]; then
                if is_version_mode; then
                    # Goバージョン管理の場合
                    output_csv "gvm" "Go" "$package"
                else
                    output_csv "gvm" "$package" ""
                fi
            fi
        done
    else
        warn_msg "gvmが見つかりません"
        if is_count_only; then
            count_packages "gvm" "0"
        fi
    fi
}

# パッケージ情報を取得
get_gvm_info() {
    local package="$1"
    if [[ ! -d "$HOME/.gvm/gos" ]]; then
        error_msg "gvmが見つかりません"
        return 1
    fi
    
    local version_path="$HOME/.gvm/gos/$package"
    if [[ ! -d "$version_path" ]]; then
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    echo "Go バージョン: $package"
    echo "インストール場所: $version_path"
    echo "実行可能ファイル: $version_path/bin/go"
    if [[ -f "$version_path/bin/go" ]]; then
        echo "バージョン情報: $("$version_path/bin/go" version 2>/dev/null || echo "取得できませんでした")"
    fi
    
    # 現在使用中のバージョンを確認
    if command_exists gvm; then
        # gvmの現在のバージョンを確認
        local current_version=$(gvm list 2>/dev/null | grep "=>" | awk '{print $2}' | sed 's/=>//')
        if [[ "$current_version" == "$package" ]]; then
            echo "状態: 現在使用中"
        else
            echo "状態: インストール済み"
        fi
    fi
    
    # GOROOT, GOPATHの情報
    if [[ -d "$version_path" ]]; then
        echo "GOROOT: $version_path"
        if [[ -d "$HOME/.gvm/pkgsets/$package" ]]; then
            echo "GOPATH: $HOME/.gvm/pkgsets/$package/global"
        fi
    fi
}

# パッケージを削除
delete_gvm_package() {
    local package="$1"
    if [[ ! -d "$HOME/.gvm/gos" ]]; then
        error_msg "gvmが見つかりません"
        return 1
    fi
    
    if [[ ! -d "$HOME/.gvm/gos/$package" ]]; then
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: gvm uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if command_exists gvm; then
            # gvmコマンドが利用可能な場合
            # gvm uninstallコマンドは対話的なので、直接ディレクトリを削除
            if rm -rf "$HOME/.gvm/gos/$package" && rm -rf "$HOME/.gvm/pkgsets/$package" 2>/dev/null; then
                success_msg "パッケージ '$package' を削除しました"
            else
                error_msg "パッケージ '$package' の削除に失敗しました"
                return 1
            fi
        else
            # 直接ディレクトリを削除
            if rm -rf "$HOME/.gvm/gos/$package" && rm -rf "$HOME/.gvm/pkgsets/$package" 2>/dev/null; then
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
update_gvm_package() {
    local package="$1"
    if [[ ! -d "$HOME/.gvm/gos" ]]; then
        error_msg "gvmが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: gvmで管理されているGoバージョンの更新はサポートされていません"
        else
            info_msg "DRY RUN: gvmで管理されているGoバージョンの更新はサポートされていません"
        fi
        return 0
    fi
    
    # gvmではバージョンの更新ではなく、新しいバージョンのインストールが必要
    error_msg "gvmで管理されているGoバージョンの更新はサポートされていません"
    error_msg "新しいバージョンをインストールするには: gvm install <version>"
    return 1
}