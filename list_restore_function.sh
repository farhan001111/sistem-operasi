#!/bin/bash

do_list() {
    local dest_dir="${DEST:-}"
    local archive
    local filename
    local size
    local found=0

    if [[ -z "$dest_dir" ]]; then
        echo "GAGAL: Folder DEST belum diatur."
        return 1
    fi

    if [[ ! -d "$dest_dir" ]]; then
        echo "Folder backup belum tersedia: $dest_dir"
        echo "Belum ada arsip backup."
        return 0
    fi

    echo "================================"
    echo "       DAFTAR ARSIP BACKUP"
    echo "================================"

    for archive in "$dest_dir"/backup_*.tar.gz; do
        [[ -f "$archive" ]] || continue

        filename="${archive##*/}"
        size=$(du -h "$archive" | cut -f1)

        printf "%-35s %10s\n" "$filename" "$size"
        found=1
    done

    if [[ "$found" -eq 0 ]]; then
        echo "Belum ada arsip backup."
    fi

    echo "================================"

    return 0
}

do_restore() {
    local dest_dir="${DEST:-}"
    local archive_name="${RESTORE_ARCHIVE:-}"
    local archive_path
    local restore_dir
    local entry

    if [[ -z "$dest_dir" ]]; then
        echo "GAGAL: Folder DEST belum diatur."
        return 1
    fi

    if [[ -z "$archive_name" ]]; then
        echo "GAGAL: Nama arsip belum diberikan."
        return 1
    fi

    if [[ "$archive_name" == */* || "$archive_name" == "." || "$archive_name" == ".." ]]; then
        echo "GAGAL: Masukkan nama arsip saja."
        return 1
    fi

    if [[ ! "$archive_name" =~ ^backup_[0-9]{8}-[0-9]{6}\.tar\.gz$ ]]; then
        echo "GAGAL: Format nama arsip tidak valid."
        return 1
    fi

    archive_path="$dest_dir/$archive_name"
    restore_dir="$dest_dir/restore"

    if [[ ! -f "$archive_path" ]]; then
        echo "GAGAL: Arsip tidak ditemukan: $archive_name"
        return 1
    fi

    if ! tar -tzf "$archive_path" >/dev/null 2>&1; then
        echo "GAGAL: Arsip tidak valid atau rusak."
        return 1
    fi

    while IFS= read -r entry; do
        case "$entry" in
            /*|../*|*/../*|..)
                echo "GAGAL: Arsip mengandung path yang tidak aman."
                return 1
                ;;
        esac
    done < <(tar -tzf "$archive_path")

    if ! mkdir -p "$restore_dir"; then
        echo "GAGAL: Tidak dapat membuat folder restore."
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
        echo "GAGAL: Proses restore tidak berhasil."
        return 1
    fi
}
