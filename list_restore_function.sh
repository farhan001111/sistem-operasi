#!/bin/bash
do_list() {
    local dest_dir="${DEST:-}"
    local file
    local name
    local human
    local bytes
    local found=0
    local nullglob_was_enabled=0

    if [[ -z "$dest_dir" || ! -d "$dest_dir" ]]; then
        echo "GAGAL: Folder DEST tidak ditemukan: $dest_dir" >&2
        return 1
    fi

    if shopt -q nullglob; then
        nullglob_was_enabled=1
    fi
    shopt -s nullglob

    echo "Daftar arsip di $dest_dir"
    printf '%-34s %s\n' "NAMA" "UKURAN"

    for file in "$dest_dir"/backup_*.tar.gz; do
        [[ -f "$file" ]] || continue
        found=1
        name="${file##*/}"
        human="$(du -h -- "$file" | cut -f1)"
        bytes="$(wc -c < "$file" | tr -d ' ')"
        printf '%-34s %s (%s bytes)\n' "$name" "$human" "$bytes"
    done

    if (( nullglob_was_enabled == 0 )); then
        shopt -u nullglob
    fi

    if (( found == 0 )); then
        echo "(belum ada arsip)"
    fi

    return 0
}

do_restore() {
    local dest_dir="${DEST:-}"
    local archive_arg="${RESTORE_ARCHIVE:-}"
    local archive_name
    local archive_path
    local restore_dir
    local entry
    local dest_abs

    if [[ -z "$dest_dir" ]]; then
        echo "GAGAL: Folder DEST belum diatur." >&2
        return 1
    fi

    if [[ -z "$archive_arg" ]]; then
        echo "GAGAL: Nama arsip belum diberikan." >&2
        return 1
    fi

    if [[ ! -d "$dest_dir" ]]; then
        echo "GAGAL: Folder DEST tidak ditemukan: $dest_dir" >&2
        return 1
    fi

    dest_abs="$(cd -- "$dest_dir" && pwd -P)" || return 1

    if [[ "$archive_arg" == */* ]]; then
        archive_path="$archive_arg"
    else
        archive_path="$dest_abs/$archive_arg"
    fi
    archive_name="${archive_path##*/}"

    if [[ ! -f "$archive_path" ]]; then
        echo "GAGAL: Arsip tidak ditemukan: $archive_arg" >&2
        return 1
    fi

    if ! tar -tzf "$archive_path" >/dev/null 2>&1; then
        echo "GAGAL: Arsip tidak valid atau rusak." >&2
        return 1
    fi

    while IFS= read -r entry; do
        case "$entry" in
            /*|../*|*/../*|..)
                echo "GAGAL: Arsip mengandung path yang tidak aman." >&2
                return 1
                ;;
        esac
    done < <(tar -tzf "$archive_path")

    restore_dir="$dest_abs/restore"

    if ! mkdir -p -- "$restore_dir"; then
        echo "GAGAL: Tidak dapat membuat folder restore." >&2
        return 1
    fi

    echo "================================"
    echo "         PROSES RESTORE"
    echo "================================"
    echo "Arsip  : $archive_name"
    echo "Tujuan : $restore_dir"
    echo

    if tar -xzf "$archive_path" -C "$restore_dir"; then
        echo "Restore berhasil!"
        echo "File dikembalikan ke: $restore_dir"
        return 0
    else
        echo "GAGAL: Proses restore tidak berhasil." >&2
        return 1
    fi
}
