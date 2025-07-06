#!/bin/bash

# Perl パッケージマネージャ
# Perl modules (ExtUtils::Installed) のサポート

# 共通ユーティリティを読み込み
# このファイルが直接実行された場合とsourceされた場合の両方に対応
PERL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PERL_SCRIPT_DIR/../common.sh"

# Perlパッケージ一覧取得
get_perl_packages() {
    if ! command_exists perl; then
        warn_msg "Perlが見つかりません"
        if is_count_only; then
            echo "perl,0"
        fi
        return
    fi
    
    local packages
    if is_version_mode; then
        # バージョン情報付きで取得
        packages=$(perl -MExtUtils::Installed -e '
            my $inst = ExtUtils::Installed->new();
            my @modules = $inst->modules();
            foreach my $module (@modules) {
                next if $module eq "Perl";
                eval {
                    my $version = $inst->version($module) || "unknown";
                    print "$module,$version\n";
                };
            }
        ' 2>/dev/null | sort)
    else
        # パッケージ名のみ取得
        packages=$(perl -MExtUtils::Installed -e 'my $inst = ExtUtils::Installed->new(); print join("\n", $inst->modules());' 2>/dev/null | \
                  grep -v "^Perl$" | \
                  sort)
    fi
    
    local count=$(echo "$packages" | grep -v "^$" | wc -l | tr -d ' ')
    if is_count_only; then
        echo "perl,$count"
        return
    fi
    
    echo "$packages" | while read -r line; do
        if [[ -n "$line" ]]; then
            if is_version_mode; then
                # module,version形式を分離
                local package=$(echo "$line" | cut -d',' -f1)
                local version=$(echo "$line" | cut -d',' -f2)
                
                if is_new_version_mode; then
                    # Perlモジュールの最新バージョン情報は取得困難なため、現在のバージョンを使用
                    echo "perl,$package,$version,$version"
                else
                    output_csv "perl" "$package" "$version"
                fi
            else
                output_csv "perl" "$line" ""
            fi
        fi
    done
}

# パッケージ情報を取得
get_perl_info() {
    local package="$1"
    if ! command_exists perl; then
        error_msg "Perlが見つかりません"
        return 1
    fi
    
    perl -M"$package" -e "print \"モジュール: $package\n\"" 2>/dev/null && \
    perl -M"$package" -e "print \"バージョン: \$$package::VERSION\n\"" 2>/dev/null || {
        error_msg "モジュール '$package' が見つからないか、情報を取得できません"
        return 1
    }
}

# パッケージを削除
delete_perl_package() {
    local package="$1"
    if ! command_exists perl; then
        error_msg "Perlが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        info_msg "DRY RUN: cpan -u $package (注意: Perlモジュールの削除は複雑です)"
        return 0
    fi
    
    warn_msg "Perlモジュールの削除は標準的な方法がありません"
    warn_msg "手動で削除するか、専用のツールを使用してください"
    return 1
}

# パッケージをアップデート
update_perl_package() {
    local package="$1"
    if ! command_exists perl; then
        error_msg "Perlが見つかりません"
        return 1
    fi
    
    if is_dry_run; then
        if [[ -z "$package" ]]; then
            info_msg "DRY RUN: cpan -u (全モジュールの更新)"
        else
            info_msg "DRY RUN: cpan -u $package"
        fi
        return 0
    fi
    
    warn_msg "Perlモジュールの更新にはCPANクライアントが必要です"
    warn_msg "'cpan -u' または 'cpanm --reinstall' を使用してください"
    return 1
}