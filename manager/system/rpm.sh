#!/bin/bash

# RPM パッケージマネージャ
# Red Hat系ディストリビューション用の低レベルパッケージマネージャサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
RPM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RPM_SCRIPT_DIR/../common.sh"

# RPMパッケージ一覧取得
get_rpm_packages() {
    if ! command_exists rpm; then
        warn_msg "RPMが見つかりません"
        if is_count_only; then
            count_packages "rpm" "0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$(rpm -qa --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' 2>/dev/null | \
                  sort | \
                  uniq)
    else
        # パッケージ名のみ取得
        packages=$(rpm -qa --queryformat '%{NAME}\n' 2>/dev/null | \
                  sort | \
                  uniq)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        count_packages "rpm" "$count"
        return
    fi
    
    echo "$packages" | while read -r line; do
        if [[ -n "$line" ]]; then
            if is_version_mode; then
                # package version-release形式を分離
                local package=$(echo "$line" | awk '{print $1}')
                local version=$(echo "$line" | awk '{print $2}')
                output_csv "rpm" "$package" "$version"
            else
                output_csv "rpm" "$line" ""
            fi
        fi
    done
}

# パッケージ情報を取得
get_rpm_info() {
    local package="$1"
    if ! command_exists rpm; then
        error_msg "RPMが見つかりません"
        return 1
    fi
    
    rpm -qi "$package" 2>/dev/null || {
        error_msg "パッケージ '$package' の情報を取得できませんでした"
        return 1
    }
}

# パッケージを削除
delete_rpm_package() {
    local package="$1"
    if ! command_exists rpm; then
        error_msg "RPMが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: sudo rpm -e $package"
        return 0
    fi
    
    if confirm_action "削除" "$package"; then
        if sudo rpm -e "$package" 2>/dev/null; then
            success_msg "パッケージ '$package' を削除しました"
        else
            error_msg "パッケージ '$package' の削除に失敗しました"
            return 1
        fi
    else
        info_msg "キャンセルされました"
    fi
}

# パッケージをアップデート
update_rpm_package() {
    local package="$1"
    if ! command_exists rpm; then
        error_msg "RPMが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: RPMは直接アップデートできません。YUM/DNFを使用してください"
        else
            info_msg "DRY RUN: RPMは直接アップデートできません。YUM/DNFを使用してください"
        fi
        return 0
    fi
    
    # RPMは低レベルのツールなので、直接アップデートはできない
    error_msg "RPMは直接アップデートできません。YUM/DNFを使用してください"
    return 1
}