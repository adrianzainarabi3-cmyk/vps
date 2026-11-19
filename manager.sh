#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTANCE_DIR="$BASE_DIR/instances"

mkdir -p "$INSTANCE_DIR"

show_header() {
    clear 2>/dev/null || true
    echo "================================"
    echo "       ARABI VPS MANAGER"
    echo "       Quota Safe Edition"
    echo "================================"
    echo
}

check_host() {
    echo "===== HOST INFORMATION ====="
    uname -a
    echo
    echo "===== CPU ====="
    nproc 2>/dev/null || echo "CPU info unavailable"
    echo
    echo "===== MEMORY ====="
    free -h 2>/dev/null || echo "Memory info unavailable"
    echo
    echo "===== DISK ====="
    df -h "$BASE_DIR"
    echo
    echo "===== QEMU ====="
    command -v qemu-system-x86_64 || echo "QEMU not installed"
    command -v qemu-img || echo "qemu-img not installed"
}

list_instances() {
    echo "===== VM INSTANCES ====="
    if [ ! -d "$INSTANCE_DIR" ] || [ -z "$(find "$INSTANCE_DIR" -mindepth 1 -maxdepth 1 -type d -print -quit)" ]; then
        echo "No instance directories found."
        return
    fi

    for dir in "$INSTANCE_DIR"/*/; do
        [ -d "$dir" ] || continue
        echo
        echo "Name: $(basename "$dir")"
        du -sh "$dir" 2>/dev/null || true
        find "$dir" -maxdepth 1 -type f -printf '  %f (%s bytes)\n' 2>/dev/null || true
    done
}

show_menu() {
    show_header
    echo "1. Host information"
    echo "2. List VM instances"
    echo "3. Check quota safety"
    echo "4. Exit"
    echo
    read -r -p "Select: " choice

    case "$choice" in
        1) check_host ;;
        2) list_instances ;;
        3)
            echo "===== QUOTA SAFETY ====="
            echo "Paid usage: DISABLED"
            echo "Automatic VM creation: DISABLED"
            echo "Automatic disk deletion: DISABLED"
            echo "No billing or quota changes will be made."
            ;;
        4) exit 0 ;;
        *) echo "Invalid option." ;;
    esac

    echo
    read -r -p "Press Enter to continue..."
}

while true; do
    show_menu
done
