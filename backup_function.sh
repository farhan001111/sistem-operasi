#!/bin/bash

backup_log_status() {
    local dest_dir="$1"
    local archive_name="$2"
    local status="$3"

    if declare -F log_line >/dev/null 2>&1; then
        log_line "$archive_name" "$status"
    else
        printf '%s | %s | %s\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$archive_name" \
            "$status" >> "$dest_dir/backup.log"
    fi
}

create_backup() {
    local source_dir="${SOURCE:-}"
    local dest_dir="${DEST:-}"
    local source_path
    local dest_path
    local timestamp
    local filename
    local backup_file
    local pattern
    local -a tar_args
    local -a exclude_patterns

    if [[ -z "$source_dir" || ! -d "$source_dir" ]]; then
        echo "Error: Folder sumber tidak ditemukan: $source_dir" >&2
        return 1
    fi

    if [[ -z "$dest_dir" ]]; then
        echo "Error: Folder tujuan belum diatur." >&2
        return 1
    fi

    if ! mkdir -p -- "$dest_dir"; then
        echo "Error: Gagal membuat folder tujuan: $dest_dir" >&2
        return 1
    fi

    if ! source_path=$(cd -- "$source_dir" && pwd -P) ||
       ! dest_path=$(cd -- "$dest_dir" && pwd -P); then
        echo "Error: Gagal membaca lokasi folder." >&2
        return 1
    fi

    timestamp=$(date '+%Y%m%d-%H%M%S')
    filename="backup_${timestamp}.tar.gz"
    backup_file="$dest_path/$filename"

    if [[ -e "$backup_file" ]]; then
        echo "Error: Arsip dengan nama ini sudah ada: $backup_file" >&2
        return 1
    fi

    tar_args=(-czf "$backup_file")

    if [[ -n "${EXCLUDE:-}" ]]; then
        read -r -a exclude_patterns <<< "$EXCLUDE"

        for pattern in "${exclude_patterns[@]}"; do
            tar_args+=("--exclude=$pattern")
        done
    fi

    echo "Memulai proses backup..."

    if tar "${tar_args[@]}" \
        -C "$(dirname -- "$source_path")" \
        -- "$(basename -- "$source_path")" &&
       tar -tzf "$backup_file" >/dev/null; then
        echo "Backup berhasil!"
        echo "File: $backup_file"

        if ! backup_log_status "$dest_path" "$filename" "SUKSES"; then
            echo "Peringatan: backup berhasil, tetapi status gagal dicatat ke log." >&2
        fi

        return 0
    else
        echo "Backup gagal atau arsip tidak valid." >&2
        rm -f -- "$backup_file"

        if ! backup_log_status "$dest_path" "$filename" "GAGAL"; then
            echo "Peringatan: status gagal tidak dapat dicatat ke log." >&2
        fi

        return 1
    fi
}
