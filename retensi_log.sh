#!/usr/bin/env bash
log_line() {
    local archive_name="${1:-}"
    local status="${2:-}"
    local log_file

    if [[ -z "${DEST:-}" ]]; then
        echo "ERROR: DEST belum ditentukan." >&2
        return 1
    fi

    if [[ -z "$archive_name" || -z "$status" ]]; then
        echo "ERROR: Nama arsip dan status log wajib diisi." >&2
        return 1
    fi

    case "$status" in
        SUKSES|GAGAL|HAPUS)
            ;;
        *)
            echo "ERROR: Status log tidak valid: $status" >&2
            return 1
            ;;
    esac

    if ! mkdir -p -- "$DEST"; then
        echo "ERROR: Tidak dapat membuat direktori DEST: $DEST" >&2
        return 1
    fi

    log_file="$DEST/backup.log"

    if ! printf '%s | %s | %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$archive_name" \
        "$status" >> "$log_file"; then
        echo "ERROR: Tidak dapat menulis ke $log_file." >&2
        return 1
    fi

    return 0
}

apply_retention() {
    local retention="${RETENTION:-}"
    local archive
    local archive_name
    local total
    local excess
    local i
    local nullglob_was_enabled=0
    local LC_ALL=C
    local -a archives=()

    if [[ -z "${DEST:-}" ]]; then
        echo "ERROR: DEST belum ditentukan." >&2
        return 1
    fi

    if [[ ! "$retention" =~ ^[1-9][0-9]*$ ]]; then
        echo "ERROR: RETENTION harus bilangan bulat minimal 1." >&2
        return 1
    fi

    if ! mkdir -p -- "$DEST"; then
        echo "ERROR: Tidak dapat membuat direktori DEST: $DEST" >&2
        return 1
    fi

    if shopt -q nullglob; then
        nullglob_was_enabled=1
    fi

    shopt -s nullglob

    for archive in "$DEST"/backup_*.tar.gz; do
        if [[ -f "$archive" ]]; then
            archives+=("$archive")
        fi
    done

    if (( nullglob_was_enabled == 0 )); then
        shopt -u nullglob
    fi

    total=${#archives[@]}
    echo "Jumlah arsip saat ini: $total"
    echo "Batas retensi: $retention"

    if (( total <= retention )); then
        echo "Retensi: tidak ada arsip yang perlu dihapus."
        return 0
    fi

    excess=$((total - retention))

    for ((i = 0; i < excess; i++)); do
        archive="${archives[$i]}"
        archive_name="${archive##*/}"

        if rm -f -- "$archive"; then
            echo "Retensi: berhasil menghapus $archive_name"

            if ! log_line "$archive_name" "HAPUS"; then
                echo "ERROR: Arsip sudah dihapus, tetapi gagal dicatat ke log." >&2
                return 1
            fi
        else
            echo "ERROR: Gagal menghapus arsip: $archive_name" >&2
            return 1
        fi
    done

    echo "Retensi berhasil diterapkan. Sisa arsip: $retention"
    return 0
}
