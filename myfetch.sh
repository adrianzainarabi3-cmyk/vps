#!/bin/bash

USERNAME_=$(whoami)
HOSTNAME_=$(hostname)

# OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS="$PRETTY_NAME $(uname -m)"
elif command -v getprop >/dev/null 2>&1; then
  OS="Android $(getprop ro.build.version.release) $(uname -m)"
else
  OS="$(uname -o) $(uname -m)"
fi

# Host
HOST=""
if [ -r /sys/devices/virtual/dmi/id/product_name ]; then
  HOST=$(cat /sys/devices/virtual/dmi/id/product_name)
elif command -v getprop >/dev/null 2>&1; then
  HOST="$(getprop ro.product.manufacturer) $(getprop ro.product.model)"
fi
[ -z "$HOST" ] && HOST="Unknown"

KERNEL=$(uname -r)

# Uptime
UP=$(uptime -p 2>/dev/null)
UPTIME=${UP#up }
if [ -z "$UPTIME" ]; then
  UPTIME=$(awk '{printf "%d hours, %d mins", $1/3600, ($1%3600)/60}' /proc/uptime 2>/dev/null)
fi
[ -z "$UPTIME" ] && UPTIME="Unknown"

# Packages
if command -v dpkg-query >/dev/null 2>&1; then
  N=$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l)
  PACKAGES="$N (dpkg)"
elif command -v rpm >/dev/null 2>&1; then
  N=$(rpm -qa 2>/dev/null | wc -l)
  PACKAGES="$N (rpm)"
elif command -v pacman >/dev/null 2>&1; then
  N=$(pacman -Qq 2>/dev/null | wc -l)
  PACKAGES="$N (pacman)"
else
  PACKAGES="Unknown"
fi

# Shell / Terminal
SHELL_="${SHELL##*/} ${BASH_VERSION%%(*}"
TERM_=$(tty 2>/dev/null)
case "$TERM_" in
  /dev/*) ;;
  *) TERM_="$TERM" ;;
esac

# CPU
CPU_NAME=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ *//; s/ *@.*//')
[ -z "$CPU_NAME" ] && CPU_NAME=$(getprop ro.soc.model 2>/dev/null)
[ -z "$CPU_NAME" ] && CPU_NAME=$(getprop ro.board.platform 2>/dev/null)
[ -z "$CPU_NAME" ] && CPU_NAME=$(uname -m)
CPU_CORES=$(nproc 2>/dev/null)
CPU="$CPU_NAME ($CPU_CORES)"
MHZ=$(grep -m1 'cpu MHz' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | tr -d ' ')
if [ -n "$MHZ" ]; then
  GHZ=$(awk -v m="$MHZ" 'BEGIN {printf "%.3fGHz", int(m)/1000}')
  CPU="$CPU @ $GHZ"
fi

# GPU
GPU=""
if command -v lspci >/dev/null 2>&1; then
  GPU=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -1 | sed 's/^[^ ]* [^:]*: //')
fi
[ -z "$GPU" ] && GPU="Unknown"

# Memory
MEM=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%dMiB / %dMiB", (t-a)/1024, t/1024}' /proc/meminfo)

# Colors (same as neofetch Linux logo: grey body, white belly, yellow beak/feet)
ESC=$'\e'
R=$'\e[0m'
Y=$'\e[1;33m'
W=$'\e[1;37m'
G=$'\e[1;32m'
D=$'\e[1;30m'
RD=$'\e[1;31m'

linux_logo=(
"${D}        #####"
"${D}       #######"
"${D}       ##${W}O${D}#${W}O${D}##"
"${D}       #${Y}#####${D}#"
"${D}     ##${W}##${Y}###${W}##${D}##"
"${D}    #${W}##########${D}##"
"${D}   #${W}############${D}##"
"${D}   #${W}############${D}###"
"${Y}  ##${D}#${W}###########${D}##${Y}#"
"${Y}######${D}#${W}#######${D}#${Y}######"
"${Y}#######${D}#${W}#####${D}#${Y}#######"
"  ${Y}#####${D}#######${Y}#####"
)

termux_logo=(
"${G}╭───────────────────╮"
"${G}│ ${RD}●${G} ${Y}●${G} ${G}●             ${G}│"
"${G}├───────────────────┤"
"${G}│                   │"
"${G}│   ${W}\\${G}               │"
"${G}│    ${W}\\${G}              │"
"${G}│     ${W}\\${G}             │"
"${G}│    ${W}/${G}      ____    │"
"${G}│   ${W}/${G}               │"
"${G}│                   │"
"${G}│      ${W}TERMUX${G}       │"
"${G}╰───────────────────╯"
)

# Logo: Termux gets the Termux logo, everything else gets the Linux logo
# Force one with: bash myfetch.sh linux   or   bash myfetch.sh termux
MODE=${1:-auto}
if [ "$MODE" = "auto" ]; then
  if [ -n "$TERMUX_VERSION" ] || [[ "$PREFIX" == *com.termux* ]]; then
    MODE=termux
  else
    MODE=linux
  fi
fi

FIXED_W=""
if [ "$MODE" = "termux" ]; then
  logo=("${termux_logo[@]}")
  FIXED_W=21
else
  logo=("${linux_logo[@]}")
fi

info=(
"${G}${USERNAME_}${R}@${G}${HOSTNAME_}${R}"
"${W}------------------------${R}"
"${Y}OS${R}: ${OS}"
"${Y}Host${R}: ${HOST}"
"${Y}Kernel${R}: ${KERNEL}"
"${Y}Uptime${R}: ${UPTIME}"
"${Y}Packages${R}: ${PACKAGES}"
"${Y}Shell${R}: ${SHELL_}"
"${Y}Terminal${R}: ${TERM_}"
"${Y}CPU${R}: ${CPU}"
"${Y}GPU${R}: ${GPU}"
"${Y}Memory${R}: ${MEM}"
)

WIDTH=24
echo
for i in "${!logo[@]}"; do
  if [ -n "$FIXED_W" ]; then
    pad=$((WIDTH - FIXED_W))
  else
    plain=$(printf '%s' "${logo[$i]}" | sed "s/$ESC\[[0-9;]*m//g")
    pad=$((WIDTH - ${#plain}))
  fi
  [ "$pad" -lt 0 ] && pad=0
  printf "%s%*s%s  %s\n" "${logo[$i]}" "$pad" "" "$R" "${info[$i]}"
done

echo
printf "%*s" $((WIDTH + 2)) ""
for i in 0 1 2 3 4 5 6 7; do printf "\e[4${i}m   "; done
printf "%s\n" "$R"
printf "%*s" $((WIDTH + 2)) ""
for i in 0 1 2 3 4 5 6 7; do printf "\e[10${i}m   "; done
printf "%s\n\n" "$R"
