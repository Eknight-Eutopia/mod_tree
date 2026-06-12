#!/usr/bin/env bash

set -euo pipefail

declare -A visited
declare -A module_map

MODULE_DIR=""
OUTPUT_FILE=""

usage() {
cat <<EOF
Usage:
    $0 [-d module_dir] [-o output_file] <module|module.ko>

Examples:
    $0 ext4

    $0 ./msm_kgsl.ko

    $0 -d ./rootfs/lib/modules msm_kgsl

    $0 -d ./rootfs/lib/modules -o result.txt msm_kgsl
EOF
exit 1
}

#
# 输出封装（关键新增）
#
log() {
    if [[ -n "${OUTPUT_FILE}" ]]; then
        echo "$*" >> "$OUTPUT_FILE"
    else
        echo "$*"
    fi
}

#
# 扫描模块目录
#
build_index() {
    local dir="$1"

    while IFS= read -r -d '' ko; do
        local name
        name=$(modinfo -F name "$ko" 2>/dev/null || true)

        [[ -z "$name" ]] && continue

        module_map["$name"]="$ko"
    done < <(find "$dir" -type f -name "*.ko" -print0)
}

resolve_module() {
    local mod="$1"

    if [[ -f "$mod" ]]; then
        echo "$mod"
        return
    fi

    if [[ -n "${module_map[$mod]:-}" ]]; then
        echo "${module_map[$mod]}"
        return
    fi

    echo "$mod"
}

module_name() {
    local mod="$1"

    if [[ -f "$mod" ]]; then
        modinfo -F name "$mod" 2>/dev/null || basename "$mod"
    else
        echo "$mod"
    fi
}

get_deps() {
    local mod="$1"

    if [[ -f "$mod" ]]; then
        modinfo -F depends "$mod" 2>/dev/null || true
        return
    fi

    if [[ -n "${module_map[$mod]:-}" ]]; then
        modinfo -F depends "${module_map[$mod]}" 2>/dev/null || true
        return
    fi

    modinfo -F depends "$mod" 2>/dev/null || true
}

#
# 核心递归
#
show_tree() {
    local input="$1"
    local prefix="$2"
    local last="$3"

    local mod
    mod=$(resolve_module "$input")

    local name
    name=$(module_name "$mod")

    local branch
    local child_prefix

    if [[ "$last" == "1" ]]; then
        branch="└── "
        child_prefix="${prefix}    "
    else
        branch="├── "
        child_prefix="${prefix}│   "
    fi

    if [[ -z "$prefix" ]]; then
        log "$name"
    else
        if [[ -n "${visited[$name]:-}" ]]; then
            log "${prefix}${branch}${name} (*)"
            return
        fi
        log "${prefix}${branch}${name}"
    fi

    visited["$name"]=1

    local deps
    deps=$(get_deps "$mod")

    [[ -z "$deps" ]] && return

    IFS=',' read -ra dep_array <<< "$deps"

    declare -A seen
    local filtered=()

    for dep in "${dep_array[@]}"; do
        dep=$(echo "$dep" | xargs)
        [[ -z "$dep" ]] && continue

        if [[ -z "${seen[$dep]:-}" ]]; then
            filtered+=("$dep")
            seen["$dep"]=1
        fi
    done

    local count=${#filtered[@]}
    for ((i=0; i<count; i++)); do
        if [[ $i -eq $((count - 1)) ]]; then
            show_tree "${filtered[$i]}" "$child_prefix" 1
        else
            show_tree "${filtered[$i]}" "$child_prefix" 0
        fi
    done
}

#
# 参数解析
#
while getopts "d:o:h" opt; do
    case "$opt" in
        d) MODULE_DIR="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

shift $((OPTIND - 1))

[[ $# -ne 1 ]] && usage

TARGET="$1"

#
# 初始化输出文件
#
if [[ -n "$OUTPUT_FILE" ]]; then
    : > "$OUTPUT_FILE"
fi

#
# 建索引
#
if [[ -n "$MODULE_DIR" ]]; then
    [[ -d "$MODULE_DIR" ]] || {
        echo "ERROR: module directory not found: $MODULE_DIR" >&2
        exit 1
    }
    build_index "$MODULE_DIR"
fi

#
# 输出
#
show_tree "$TARGET" "" 1
