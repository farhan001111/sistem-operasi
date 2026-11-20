
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/backup.conf"

# Variabel default
SOURCE="$HOME/data-penting"
DEST="$HOME/backup"
RETENTION=3
EXCLUDE="*.tmp draft"
CRON="0 2 * * *"

# ------------------------------------------
# Fungsi bantuan
# ------------------------------------------
show_help() {
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

# ------------------------------------------
# Fungsi pembacaan konfigurasi
# ------------------------------------------
load_config() {
    if [[ ! -f "$CONFIG" ]]; then
        echo "GAGAL: File konfigurasi tidak ditemukan: $CONFIG"
        exit 1
    fi

    source "$CONFIG"
}

# ------------------------------------------
# Placeholder fitur anggota lain
# ------------------------------------------
do_backup() {
    echo "Fitur backup akan diintegrasikan."
}

do_list() {
    echo "Fitur list akan diintegrasikan."
}

do_restore() {
    echo "Fitur restore akan diintegrasikan."
}

install_cron() {
    echo "Fitur pemasangan cron akan diintegrasikan."
}

remove_cron() {
    echo "Fitur penghapusan cron akan diintegrasikan."
}

interactive_menu() {
    echo "Menu interaktif akan dibuat oleh Anggota 5."
}

# ------------------------------------------
# Program utama
# ------------------------------------------

# Tanpa argumen: menu interaktif
if [[ $# -eq 0 ]]; then
    load_config
    interactive_menu
    exit 0
fi

ACTION=""

# Membaca opsi CLI
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
            SOURCE="$OPTARG"
            ;;
        d)
            DEST="$OPTARG"
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

# Membaca konfigurasi terlebih dahulu
load_config

# Override konfigurasi CLI
# Nilai yang diberikan melalui -s dan -d
# harus mengalahkan nilai dari konfigurasi.

# (Bagian override akan disempurnakan pada integrasi)

# Menentukan aksi
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
