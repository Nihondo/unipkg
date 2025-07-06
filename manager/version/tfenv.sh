#!/bin/bash

# Terraform Version Manager (tfenv)
# Terraformバージョン管理ツールのサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
TFENV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TFENV_SCRIPT_DIR/../common.sh"

# tfenvパッケージ一覧取得
get_tfenv_packages() {
    if command_exists tfenv || [[ -d "$HOME/.tfenv/versions" ]]; then
        local packages
        if command_exists tfenv; then
            packages=$(tfenv list 2>/dev/null | grep -v "^*" | sed 's/^\s*//' | sort)
        else
            packages=$(ls "$HOME/.tfenv/versions" 2>/dev/null | sort)
        fi
        local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
        
        if is_count_only; then
            count_packages "tfenv" "$count"
            return
        fi
        
        echo "$packages" | while read -r package; do
            if [[ -n "$package" ]]; then
                if is_version_mode; then
                    # Terraformバージョン管理の場合
                    output_csv "tfenv" "Terraform" "$package"
                else
                    output_csv "tfenv" "$package" ""
                fi
            fi
        done
    else
        warn_msg "tfenvが見つかりません"
        if is_count_only; then
            count_packages "tfenv" "0"
        fi
    fi
}

# パッケージ情報を取得
get_tfenv_info() {
    local package="$1"
    if ! command_exists tfenv && [[ ! -d "$HOME/.tfenv/versions" ]]; then
        error_msg "tfenvが見つかりません"
        return 1
    fi
    
    local version_path=""
    if [[ -d "$HOME/.tfenv/versions/$package" ]]; then
        version_path="$HOME/.tfenv/versions/$package"
    else
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    echo "Terraform バージョン: $package"
    echo "インストール場所: $version_path"
    echo "実行可能ファイル: $version_path/terraform"
    if [[ -f "$version_path/terraform" ]]; then
        echo "バージョン情報: $("$version_path/terraform" version 2>/dev/null | head -1 || echo "取得できませんでした")"
    fi
    
    # 現在使用中のバージョンを確認
    if command_exists tfenv; then
        local current_version=$(tfenv version-name 2>/dev/null)
        if [[ "$current_version" == "$package" ]]; then
            echo "状態: 現在使用中"
        else
            echo "状態: インストール済み"
        fi
    fi
}

# パッケージを削除
delete_tfenv_package() {
    local package="$1"
    if ! command_exists tfenv && [[ ! -d "$HOME/.tfenv/versions" ]]; then
        error_msg "tfenvが見つかりません"
        return 1
    fi
    
    if [[ ! -d "$HOME/.tfenv/versions/$package" ]]; then
        error_msg "パッケージ '$package' が見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: tfenv uninstall $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if command_exists tfenv; then
            # tfenvコマンドが利用可能な場合
            if tfenv uninstall "$package" 2>/dev/null; then
                success_msg "パッケージ '$package' を削除しました"
            else
                error_msg "パッケージ '$package' の削除に失敗しました"
                return 1
            fi
        else
            # 直接ディレクトリを削除
            if rm -rf "$HOME/.tfenv/versions/$package"; then
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
update_tfenv_package() {
    local package="$1"
    if ! command_exists tfenv && [[ ! -d "$HOME/.tfenv/versions" ]]; then
        error_msg "tfenvが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: tfenvで管理されているTerraformバージョンの更新はサポートされていません"
        else
            info_msg "DRY RUN: tfenvで管理されているTerraformバージョンの更新はサポートされていません"
        fi
        return 0
    fi
    
    # tfenvではバージョンの更新ではなく、新しいバージョンのインストールが必要
    error_msg "tfenvで管理されているTerraformバージョンの更新はサポートされていません"
    error_msg "新しいバージョンをインストールするには: tfenv install <version>"
    return 1
}