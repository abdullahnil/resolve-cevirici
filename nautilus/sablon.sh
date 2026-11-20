#!/bin/bash
# Nautilus betiği: seçili videoları bir terminal penceresinde çevirir.
IFS=$'\n'
dosyalar=($NAUTILUS_SCRIPT_SELECTED_FILE_PATHS)
[ ${#dosyalar[@]} -eq 0 ] && exit 0

calistir='"$0" "$@"; echo; read -r -p "Kapatmak için Enter tuşuna bas..."'
for t in ptyxis kgx gnome-terminal konsole xfce4-terminal xterm; do
    command -v "$t" >/dev/null || continue
    case "$t" in
        ptyxis)          exec ptyxis --new-window -- bash -c "$calistir" "@KOMUT@" "${dosyalar[@]}" ;;
        kgx)             exec kgx -- bash -c "$calistir" "@KOMUT@" "${dosyalar[@]}" ;;
        gnome-terminal)  exec gnome-terminal --wait -- bash -c "$calistir" "@KOMUT@" "${dosyalar[@]}" ;;
        *)               exec "$t" -e bash -c "$calistir" "@KOMUT@" "${dosyalar[@]}" ;;
    esac
done
notify-send "Resolve Çevirici" "Terminal bulunamadı" 2>/dev/null
