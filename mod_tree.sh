#!/usr/bin/env bash
set -euo pipefail

declare -A module_map
declare -A expanded

MODULE_DIR=""
OUTPUT_FILE=""

usage() {
cat <<EOF
Usage:
  $0 [-d module_dir] [-o output_file] <module|module.ko>
EOF
exit 1
}

log() {
    if [[ -n "${OUTPUT_FILE}" ]]; then
        echo "$*" >> "$OUTPUT_FILE"
    else
        echo "$*"
    fi
}

build_index() {
    local dir="$1"

    while IFS= read -r -d '' ko; do
        local name
        name=$(modinfo -F name "$ko" 2>/dev/null || true)
        [[ -z "$name" ]] && continue
        module_map["$name"]="$ko"
    done < <(find "$dir" -type f -name "*.ko" -print0)
}

resolve() {
    local m="$1"
    if [[ -f "$m" ]]; then
        echo "$m"
        return
    fi
    if [[ -n "${module_map[$m]:-}" ]]; then
        echo "${module_map[$m]}"
        return
    fi
    echo "$m"
}

name_of() {
    local m="$1"
    if [[ -f "$m" ]]; then
        modinfo -F name "$m" 2>/dev/null || basename "$m"
    else
        echo "$m"
    fi
}

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

# =========================
# 核心：层级严格树展开
# =========================
show_tree() {
    local mod="$1"
    local prefix="$2"
    local last="$3"

    local path="$4"

    local real
    real=$(resolve "$mod")

    local name
    name=$(name_of "$real")

    local branch child_prefix

    if [[ "$last" == "1" ]]; then
        branch="└── "
        child_prefix="${prefix}    "
    else
        branch="├── "
        child_prefix="${prefix}│   "
    fi

    # 输出当前节点
    if [[ -z "$prefix" ]]; then
        log "$name"
    else
        log "${prefix}${branch}${name}"
    fi

    # ⭐关键：全局只展开一次
    local key="${path}::${name}"

    if [[ -n "${expanded[$key]:-}" ]]; then
        log "${child_prefix}(*)"
        return
    fi
    expanded["$key"]=1

    local deps
    deps=$(get_deps "$real")
    [[ -z "$deps" ]] && return

    IFS=',' read -ra arr <<< "$deps"

    # ⭐同级严格去重（只影响当前层）
    declare -A seen
    local children=()

    for d in "${arr[@]}"; do
        d=$(echo "$d" | xargs)
        [[ -z "$d" ]] && continue

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

# =========================
# args
# =========================
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
