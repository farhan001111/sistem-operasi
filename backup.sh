#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
CONFIG="$SCRIPT_DIR/backup.conf"

SOURCE="$HOME/data-penting"
DEST="$HOME/backup"
RETENTION=3
EXCLUDE="*.tmp draft"
CRON="0 2 * * *"

SRC_OVERRIDE=""
DEST_OVERRIDE=""
ACTION=""
RESTORE_ARCHIVE=""

for helper in retensi_log.sh backup_function.sh list_restore_function.sh; do
    if [[ ! -f "$SCRIPT_DIR/$helper" ]]; then
        echo "GAGAL: File pendukung tidak ditemukan: $SCRIPT_DIR/$helper" >&2
        exit 1
    fi
    source "$SCRIPT_DIR/$helper"
done

show_help() {
    echo "Sistem Backup Lokal"
    echo
    echo "Penggunaan: ./backup.sh [opsi]"
    echo
    echo "Opsi:"
    echo "  -h          Menampilkan bantuan"
    echo "  -c FILE     Menggunakan file konfigurasi FILE (default: backup.conf)"
    echo "  -s SRC      Override nilai SOURCE"
    echo "  -d DEST     Override nilai DEST"
    echo "  -l          Menampilkan daftar arsip di DEST"
    echo "  -r ARSIP    Restore ARSIP ke folder restore/ di dalam DEST"
    echo "  -i          Memasang baris crontab dari konfigurasi"
    echo "  -U          Menghapus baris crontab yang dipasang"
    echo
    echo "Tanpa opsi apa pun: membuka menu interaktif."
    echo "Hanya opsi -c/-s/-d: menjalankan backup satu kali."
}

load_config() {
    if [[ ! -f "$CONFIG" ]]; then
        echo "GAGAL: File konfigurasi tidak ditemukan: $CONFIG" >&2
        exit 1
    fi

    source "$CONFIG"

    [[ -n "$SRC_OVERRIDE" ]] && SOURCE="$SRC_OVERRIDE"
    [[ -n "$DEST_OVERRIDE" ]] && DEST="$DEST_OVERRIDE"

    if [[ ! "$RETENTION" =~ ^[1-9][0-9]*$ ]]; then
        echo "GAGAL: RETENTION harus bilangan bulat minimal 1 (nilai: '$RETENTION')." >&2
        exit 1
    fi
}

abs_path() {
    local dir
    dir="$(cd -- "$(dirname -- "$1")" 2>/dev/null && pwd -P)" || return 1
    printf '%s/%s\n' "$dir" "$(basename -- "$1")"
}

do_backup() {
    create_backup || return 1
    apply_retention
}

install_cron() {
    local script_path="$SCRIPT_DIR/$SCRIPT_NAME"
    local config_path
    local cron_line
    local marker
    local current
    local -a fields

    read -r -a fields <<< "$CRON"
    if (( ${#fields[@]} != 5 )); then
        echo "GAGAL: CRON harus berisi 5 field (nilai: '$CRON')." >&2
        return 1
    fi

    config_path="$(abs_path "$CONFIG")" || {
        echo "GAGAL: Path konfigurasi tidak valid." >&2
        return 1
    }

    cron_line="$CRON $script_path -c $config_path"
    marker=" $script_path -c "

    current="$(crontab -l 2>/dev/null)"

    if { printf '%s\n' "$current" | grep -Fv -- "$marker" | grep -v '^$'
         echo "$cron_line"; } | crontab -; then
        echo "Cron berhasil dipasang."
        echo "Baris: $cron_line"
    else
        echo "GAGAL: Cron tidak berhasil dipasang." >&2
        return 1
    fi
}

remove_cron() {
    local script_path="$SCRIPT_DIR/$SCRIPT_NAME"
    local marker=" $script_path -c "
    local current

    current="$(crontab -l 2>/dev/null)"

    if ! printf '%s\n' "$current" | grep -Fq -- "$marker"; then
        echo "Cron tidak ditemukan."
        return 0
    fi

    if printf '%s\n' "$current" | grep -Fv -- "$marker" | crontab -; then
        echo "Cron berhasil dihapus."
    else
        echo "GAGAL: Cron tidak berhasil dihapus." >&2
        return 1
    fi
}

interactive_menu() {
    local pilihan

    while true; do
        echo
        echo "================================"
        echo "       SISTEM BACKUP LOKAL"
        echo "================================"
        echo "1. Backup sekarang"
        echo "2. Lihat daftar backup"
        echo "3. Restore backup"
        echo "4. Pasang cron"
        echo "5. Hapus cron"
        echo "6. Keluar"
        echo "================================"

        read -rp "Pilih menu [1-6]: " pilihan || { echo; exit 0; }

        case "$pilihan" in
            1) do_backup ;;
            2) do_list ;;
            3)
                do_list
                read -rp "Masukkan nama arsip: " RESTORE_ARCHIVE || { echo; exit 0; }
                do_restore
                ;;
            4) install_cron ;;
            5) remove_cron ;;
            6)
                echo "Program selesai."
                exit 0
                ;;
            *) echo "Pilihan tidak valid." ;;
        esac
    done
}

NUM_ARGS=$#

while getopts ":hc:s:d:lr:iU" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        c) CONFIG="$OPTARG" ;;
        s) SRC_OVERRIDE="$OPTARG" ;;
        d) DEST_OVERRIDE="$OPTARG" ;;
        l) ACTION="list" ;;
        r)
            ACTION="restore"
            RESTORE_ARCHIVE="$OPTARG"
            ;;
        i) ACTION="install" ;;
        U) ACTION="remove" ;;
        :)
            echo "GAGAL: Opsi -$OPTARG membutuhkan argumen." >&2
            exit 1
            ;;
        \?)
            echo "GAGAL: Opsi tidak dikenal: -$OPTARG" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

load_config

if (( NUM_ARGS == 0 )); then
    interactive_menu
    exit 0
fi

case "$ACTION" in
    list)    do_list ;;
    restore) do_restore ;;
    install) install_cron ;;
    remove)  remove_cron ;;
    *)       do_backup ;;
esac
exit $?
