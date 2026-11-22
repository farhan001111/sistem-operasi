#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

load_config() {
    if [[ -f "$CONFIG" ]]; then
        source "$CONFIG"
    else
        echo "GAGAL: File konfigurasi tidak ditemukan."
        exit 1
    fi

    if [[ -n "$SRC_OVERRIDE" ]]; then
        SOURCE="$SRC_OVERRIDE"
    fi

    if [[ -n "$DEST_OVERRIDE" ]]; then
        DEST="$DEST_OVERRIDE"
    fi
}

show_help() {
    echo "Penggunaan: ./backup.sh [opsi]"
    echo
    echo "-h        Menampilkan bantuan"
    echo "-c FILE   Menggunakan file konfigurasi"
    echo "-s SRC    Mengubah folder sumber"
    echo "-d DEST   Mengubah folder tujuan"
    echo "-l        Menampilkan daftar backup"
    echo "-r ARSIP  Melakukan restore"
    echo "-i        Memasang cron"
    echo "-U        Menghapus cron"
    echo
}

do_backup() {
    create_backup

    if [[ $? -eq 0 ]]; then
        apply_retention
    fi
}

install_cron() {
    local script_path="$SCRIPT_DIR/backup.sh"
    local cron_line="$CRON /bin/bash \"$script_path\" -c \"$CONFIG\""
    local current_cron

    current_cron=$(crontab -l 2>/dev/null)

    if echo "$current_cron" | grep -Fq "$script_path"; then
        echo "Cron sudah terpasang."
        return 0
    fi

    (echo "$current_cron"; echo "$cron_line") | crontab -

    if [[ $? -eq 0 ]]; then
        echo "Cron berhasil dipasang."
    else
        echo "GAGAL: Cron tidak berhasil dipasang."
        return 1
    fi
}

remove_cron() {
    local script_path="$SCRIPT_DIR/backup.sh"
    local current_cron

    current_cron=$(crontab -l 2>/dev/null)

    if ! echo "$current_cron" | grep -Fq "$script_path"; then
        echo "Cron tidak ditemukan."
        return 0
    fi

    echo "$current_cron" | grep -Fv "$script_path" | crontab -

    if [[ $? -eq 0 ]]; then
        echo "Cron berhasil dihapus."
    else
        echo "GAGAL: Cron tidak berhasil dihapus."
        return 1
    fi
}

interactive_menu() {
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

        read -rp "Pilih menu [1-6]: " pilihan

        case "$pilihan" in
            1)
                do_backup
                ;;
            2)
                do_list
                ;;
            3)
                read -rp "Masukkan nama arsip: " RESTORE_ARCHIVE
                do_restore
                ;;
            4)
                install_cron
                ;;
            5)
                remove_cron
                ;;
            6)
                echo "Program selesai."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid."
                ;;
        esac
    done
}

while getopts ":hc:s:d:lr:iU" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        c)
            CONFIG="$OPTARG"
            ;;
        s)
            SRC_OVERRIDE="$OPTARG"
            ;;
        d)
            DEST_OVERRIDE="$OPTARG"
            ;;
        l)
            ACTION="list"
            ;;
        r)
            ACTION="restore"
            RESTORE_ARCHIVE="$OPTARG"
            ;;
        i)
            ACTION="install"
            ;;
        U)
            ACTION="remove"
            ;;
        :)
            echo "GAGAL: Opsi -$OPTARG membutuhkan argumen."
            exit 1
            ;;
        \?)
            echo "GAGAL: Opsi tidak dikenal."
            show_help
            exit 1
            ;;
    esac
done

load_config

source "$SCRIPT_DIR/retensi_log.sh"
source "$SCRIPT_DIR/backup_function.sh"
source "$SCRIPT_DIR/list_restore_function.sh"

if [[ -z "$ACTION" ]]; then
    if [[ $# -eq 0 ]]; then
        interactive_menu
    else
        do_backup
    fi
else
    case "$ACTION" in
        list)
            do_list
            ;;
        restore)
            do_restore
            ;;
        install)
            install_cron
            ;;
        remove)
            remove_cron
            ;;
    esac
fi
