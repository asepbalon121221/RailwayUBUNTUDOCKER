#!/bin/bash
# XD VPS — SSH login banner
# Dev: KurrXd

[ -t 1 ] || return 0 2>/dev/null || exit 0

C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
C_CYAN=$'\e[38;5;51m'; C_BLUE=$'\e[38;5;33m'
C_GREEN=$'\e[38;5;46m'; C_YELLOW=$'\e[38;5;220m'; C_GREY=$'\e[38;5;245m'
C_WHITE=$'\e[38;5;231m'

_os="$( . /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-Linux}" )"
_kernel="$(uname -r 2>/dev/null)"
_host="$(hostname 2>/dev/null)"
_user="$(whoami 2>/dev/null)"
_uptime="$(uptime -p 2>/dev/null | sed 's/^up //')"; : "${_uptime:=just now}"
_cpu="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ *//; s/  */ /g')"
_cores="$(nproc 2>/dev/null)"; : "${_cpu:=CPU}"
_mem="$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " / " $2}')"
_disk="$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"; : "${_ip:=n/a}"

printf '\n'
printf '%s\n' "${C_CYAN}${C_BOLD}  ██╗  ██╗██████╗      ██╗   ██╗██████╗ ███████╗${C_RESET}"
printf '%s\n' "${C_CYAN}${C_BOLD}  ╚██╗██╔╝██╔══██╗     ██║   ██║██╔══██╗██╔════╝${C_RESET}"
printf '%s\n' "${C_BLUE}${C_BOLD}   ╚███╔╝ ██║  ██║     ██║   ██║██████╔╝███████╗${C_RESET}"
printf '%s\n' "${C_BLUE}${C_BOLD}   ██╔██╗ ██║  ██║     ╚██╗ ██╔╝██╔═══╝ ╚════██║${C_RESET}"
printf '%s\n' "${C_WHITE}${C_BOLD}  ██╔╝ ██╗██████╔╝      ╚████╔╝ ██║     ███████║${C_RESET}"
printf '%s\n' "${C_WHITE}${C_BOLD}  ╚═╝  ╚═╝╚═════╝        ╚═══╝  ╚═╝     ╚══════╝${C_RESET}"
printf '\n'
printf '%s\n' "${C_WHITE}${C_BOLD}          Cloud VPS · Railway Ubuntu${C_RESET}"
printf '%s\n' "${C_YELLOW}${C_BOLD}               Dev · KurrXd${C_RESET}"
printf '\n'

line="${C_GREY}  ────────────────────────────────────────────────${C_RESET}"
printf '%s\n' "$line"

row() { printf "  ${C_CYAN}%s${C_RESET} ${C_DIM}%s${C_RESET} %b\n" "$1" "$2" "$3"; }
row " User    " "│" "${C_WHITE}${_user}${C_RESET}${C_GREY} @ ${C_WHITE}${_host}${C_RESET}"
row " OS      " "│" "${C_WHITE}${_os}${C_RESET}"
row " Kernel  " "│" "${C_WHITE}${_kernel}${C_RESET}"
row " Uptime  " "│" "${C_WHITE}${_uptime}${C_RESET}"
row " CPU     " "│" "${C_WHITE}${_cpu} ${C_GREY}(${_cores} cores)${C_RESET}"
row " Memory  " "│" "${C_WHITE}${_mem}${C_RESET}"
row " Disk    " "│" "${C_WHITE}${_disk}${C_RESET}"
row " IP      " "│" "${C_WHITE}${_ip}${C_RESET}"
row " 9router " "│" "${C_GREEN}● :20128${C_RESET}"

if [ -f /var/lib/xd/src-repo ]; then
  _repo="$(cat /var/lib/xd/src-repo 2>/dev/null)"
  _src="${C_GREEN}● synced → ${C_RESET}${C_WHITE}${_repo}${C_RESET}"
else
  _src="${C_GREY}● off — set GITHUB_TOKEN to backup${C_RESET}"
fi
row " backup  " "│" "${_src}"

printf '%s\n' "$line"
printf "  ${C_GREEN}➜${C_RESET} ${C_DIM}9router UI${C_RESET} ${C_YELLOW}${C_BOLD}:20128${C_RESET} ${C_DIM}(password = root password)${C_RESET}\n"
printf "  ${C_GREEN}➜${C_RESET} ${C_DIM}Run${C_RESET} ${C_YELLOW}${C_BOLD}usage${C_RESET} ${C_DIM}to check Railway trial credit${C_RESET}\n"
printf "  ${C_GREEN}➜${C_RESET} ${C_DIM}Run${C_RESET} ${C_YELLOW}${C_BOLD}src-sync --status${C_RESET} ${C_DIM}to see backup repo${C_RESET}\n"
printf '\n'
