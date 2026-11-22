
do_restore() {
    local dest_dir="${DEST:-}"
    local archive_arg="${RESTORE_ARCHIVE:-}"
    local archive_name
    local archive_path
    local restore_dir
    local entry
    local dest_abs
    local archive_parent

    if [[ -z "$dest_dir" ]]; then
        echo "GAGAL: Folder DEST belum diatur."
        return 1
    fi

    if [[ -z "$archive_arg" ]]; then
        echo "GAGAL: Nama arsip belum diberikan."
        return 1
    fi

    if [[ ! -d "$dest_dir" ]]; then
        echo "GAGAL: Folder DEST tidak ditemukan."
        return 1
    fi

    dest_abs="$(cd -- "$dest_dir" && pwd -P)" || return 1

    if [[ "$archive_arg" == */* ]]; then
        archive_name="${archive_arg##*/}"

        archive_parent="$(cd -- "$(dirname -- "$archive_arg")" 2>/dev/null && pwd -P)" || {
            echo "GAGAL: Lokasi arsip tidak valid."
            return 1
        }

        if [[ "$archive_parent" != "$dest_abs" ]]; then
            echo "GAGAL: Arsip harus berada di folder DEST."
            return 1
        fi

        archive_path="$archive_parent/$archive_name"
    else
        archive_name="$archive_arg"
        archive_path="$dest_abs/$archive_name"
    fi

    if [[ ! "$archive_name" =~ ^backup_[0-9]{8}-[0-9]{6}\.tar\.gz$ ]]; then
        echo "GAGAL: Format nama arsip tidak valid."
        return 1
    fi

    restore_dir="$dest_abs/restore"

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
