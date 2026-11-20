#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/backup.conf"

# ==========================================
# Nilai konfigurasi awal
# ==========================================

SOURCE="$HOME/data-penting"
DEST="$HOME/backup"
RETENTION=3
EXCLUDE="*.tmp draft"
CRON="0 2 * * *"

# ==========================================
# Variabel override
# ==========================================

SRC_OVERRIDE=""
DEST_OVERRIDE=""
ACTION=""
RESTORE_ARCHIVE=""

# ==========================================
# Fungsi bantuan
# ==========================================

show_help() {
    echo "Sistem Backup Lokal"
    echo
    echo "Penggunaan: ./backup.sh [opsi]"
    echo
    echo "Opsi:"
    echo "  -h          Tampilkan bantuan"
    echo "  -c FILE     Gunakan file konfigurasi"
    echo "  -s SRC      Override folder sumber"
    echo "  -d DEST     Override folder tujuan"
    echo "  -l          Tampilkan daftar arsip"
    echo "  -r ARSIP    Restore arsip"
    echo "  -i          Pasang crontab"
    echo "  -U          Hapus crontab"
}

# ==========================================
# Membaca konfigurasi
# ==========================================

load_config() {
    if [[ ! -f "$CONFIG" ]]; then
        echo "GAGAL: File konfigurasi tidak ditemukan."
        echo "Lokasi: $CONFIG"
        exit 1
    fi

    source "$CONFIG"

    if ! [[ "$RETENTION" =~ ^[0-9]+$ ]] || (( RETENTION < 1 )); then
        echo "GAGAL: RETENTION harus berupa bilangan bulat minimal 1."
        exit 1
    fi
}

# ==========================================
# Placeholder fitur anggota lain
# ==========================================

do_backup() {
    echo "Fitur backup akan diintegrasikan."
}

do_list() {
    echo "Fitur list akan diintegrasikan."
}

do_restore() {
    echo "Fitur restore akan diintegrasikan."
}

# ==========================================
# ANGGOTA 5 - MENU INTERAKTIF
# ==========================================

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
        echo "4. Keluar"
        echo "================================"

        read -rp "Pilih menu [1-4]: " pilihan || break

        case "$pilihan" in
            1)
                echo
                do_backup
                ;;
            2)
                echo
                do_list
                ;;
            3)
                echo
                read -rp "Masukkan nama arsip: " RESTORE_ARCHIVE

                if [[ -n "$RESTORE_ARCHIVE" ]]; then
                    do_restore
                else
                    echo "Nama arsip tidak boleh kosong."
                fi
                ;;
            4)
                echo "Program selesai."
                break
                ;;
            *)
                echo "Pilihan tidak valid."
                ;;
        esac
    done
}

# ==========================================
# ANGGOTA 5 - MEMASANG CRON
# ==========================================

install_cron() {
    local SCRIPT_PATH CONFIG_PATH CRON_LINE CURRENT_CRON

    SCRIPT_PATH="$(realpath "$0")" || return 1
    CONFIG_PATH="$(realpath "$CONFIG")" || return 1

    CRON_LINE="$CRON $SCRIPT_PATH -c $CONFIG_PATH"

    CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

    if printf '%s\n' "$CURRENT_CRON" | grep -Fxq -- "$CRON_LINE"; then
        echo "Jadwal backup sudah terpasang."
        return 0
    fi

    if [[ -n "$CURRENT_CRON" ]]; then
        printf '%s\n%s\n' "$CURRENT_CRON" "$CRON_LINE" | crontab -
    else
        printf '%s\n' "$CRON_LINE" | crontab -
    fi

    if [[ $? -eq 0 ]]; then
        echo "Jadwal backup berhasil dipasang."
        echo "Jadwal: $CRON"
    else
        echo "GAGAL: Tidak dapat memasang jadwal Cron."
        return 1
    fi
}

# ==========================================
# ANGGOTA 5 - MENGHAPUS CRON
# ==========================================

remove_cron() {
    local SCRIPT_PATH CONFIG_PATH CRON_LINE CURRENT_CRON

    SCRIPT_PATH="$(realpath "$0")" || return 1
    CONFIG_PATH="$(realpath "$CONFIG")" || return 1

    CRON_LINE="$CRON $SCRIPT_PATH -c $CONFIG_PATH"

    CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

    if ! printf '%s\n' "$CURRENT_CRON" | grep -Fxq -- "$CRON_LINE"; then
        echo "Jadwal backup tidak ditemukan."
        return 0
    fi

    printf '%s\n' "$CURRENT_CRON" |
        grep -Fvx -- "$CRON_LINE" | crontab -

    if [[ $? -eq 0 ]]; then
        echo "Jadwal backup berhasil dihapus."
    else
        echo "GAGAL: Tidak dapat menghapus jadwal Cron."
        return 1
    fi
}

# ==========================================
# Tanpa argumen: menu interaktif
# ==========================================

if [[ $# -eq 0 ]]; then
    load_config
    interactive_menu
    exit 0
fi

# ==========================================
# Membaca argumen CLI
# ==========================================

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
            ACTION="install_cron"
            ;;
        U)
            ACTION="remove_cron"
            ;;
        :)
            echo "GAGAL: Opsi -$OPTARG membutuhkan argumen."
            exit 1
            ;;
        \?)
            echo "GAGAL: Opsi tidak dikenal: -$OPTARG"
            show_help
            exit 1
            ;;
    esac
done

# ==========================================
# Membaca konfigurasi
# ==========================================

load_config

# ==========================================
# Override konfigurasi
# ==========================================

if [[ -n "$SRC_OVERRIDE" ]]; then
    SOURCE="$SRC_OVERRIDE"
fi

if [[ -n "$DEST_OVERRIDE" ]]; then
    DEST="$DEST_OVERRIDE"
fi

# ==========================================
# Menjalankan aksi
# ==========================================

case "$ACTION" in
    list)
        do_list
        ;;
    restore)
        do_restore
        ;;
    install_cron)
        install_cron
        ;;
    remove_cron)
        remove_cron
        ;;
    *)
        do_backup
        ;;
esac
