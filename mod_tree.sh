#!/usr/bin/env bash
set -euo pipefail

declare -A module_map
declare -A visited

MODULE_DIR=""
OUTPUT_FILE=""

# -------------------------
# 统一模块命名（关键修复）
# -------------------------
normalize() {
    echo "$1" | tr '_' '-'
}

log() {
    if [[ -n "${OUTPUT_FILE}" ]]; then
        echo "$*" >> "$OUTPUT_FILE"
    else
        echo "$*"
    fi
}

usage() {
cat <<EOF
Usage:
  $0 [-d module_dir] [-o output] <module|module.ko>
EOF
exit 1
}

# -------------------------
# 建索引（关键：统一 name）
# -------------------------
build_index() {
    local dir="$1"

    while IFS= read -r -d '' ko; do
        local name
        name=$(modinfo -F name "$ko" 2>/dev/null || true)

        [[ -z "$name" ]] && continue

        name=$(normalize "$name")
        module_map["$name"]="$ko"
    done < <(find "$dir" -type f -name "*.ko" -print0)
}

# -------------------------
# 解析模块 -> ko
# -------------------------
resolve() {
    local m="$1"

    # file path
    if [[ -f "$m" ]]; then
        echo "$m"
        return
    fi

    m=$(normalize "$m")

    if [[ -n "${module_map[$m]:-}" ]]; then
        echo "${module_map[$m]}"
        return
    fi

    echo "$m"
}

# -------------------------
# 获取模块名（统一 display）
# -------------------------
module_name() {
    local m="$1"

    if [[ -f "$m" ]]; then
        modinfo -F name "$m" 2>/dev/null | tr '_' '-' || basename "$m"
    else
        echo "$m"
    fi
}

# -------------------------
# 获取 depends（统一 normalize）
# -------------------------
get_deps() {
    local m="$1"

    if [[ -f "$m" ]]; then
        modinfo -F depends "$m" 2>/dev/null || true
    else
        if [[ -n "${module_map[$m]:-}" ]]; then
            modinfo -F depends "${module_map[$m]}" 2>/dev/null || true
        else
            modinfo -F depends "$m" 2>/dev/null || true
        fi
    fi
}

# -------------------------
# 核心 tree
# -------------------------
show_tree() {
    local input="$1"
    local prefix="$2"
    local last="$3"
    local path="$4"

    local mod
    mod=$(resolve "$input")

    local name
    name=$(module_name "$mod")

    local branch child_prefix

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
        log "${prefix}${branch}${name}"
    fi

    local key="${path}::${name}"

    # 防循环（路径级）
    if [[ -n "${visited[$key]:-}" ]]; then
        log "${child_prefix}(*)"
        return
    fi
    visited["$key"]=1

    local deps
    deps=$(get_deps "$mod")

    [[ -z "$deps" ]] && return

    IFS=',' read -ra arr <<< "$deps"

    # -------------------------
    # 同级严格去重（关键）
    # -------------------------
    declare -A seen
    local children=()

    for d in "${arr[@]}"; do
        d=$(echo "$d" | xargs)
        [[ -z "$d" ]] && continue

        d=$(normalize "$d")

        if [[ -z "${seen[$d]:-}" ]]; then
            children+=("$d")
            seen["$d"]=1
        fi
    done

    local i
    for ((i=0; i<${#children[@]}; i++)); do
        show_tree "${children[$i]}" "$child_prefix" \
            $([[ $i -eq $((${#children[@]}-1)) ]] && echo 1 || echo 0) \
            "${path}::${name}"
    done
}

# -------------------------
# args
# -------------------------
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

[[ -n "$OUTPUT_FILE" ]] && : > "$OUTPUT_FILE"

[[ -n "$MODULE_DIR" ]] && build_index "$MODULE_DIR"

show_tree "$TARGET" "" 1 ""
