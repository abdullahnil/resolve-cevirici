#!/bin/bash
# resolve-cevirici'yi kaldırır (ffmpeg'e dokunmaz).
set -eu
rm -f "$HOME/.local/bin/resolve-cevir" "$HOME/.local/bin/resolve-cevir-kayipsiz"
rm -f "$HOME/.local/share/nautilus/scripts/Resolve için çevir (normal)" \
      "$HOME/.local/share/nautilus/scripts/Resolve için çevir (kayıpsız)"
rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/resolve-cevirici"
echo "Resolve Çevirici kaldırıldı. Çevrilmiş videolarına dokunulmadı."
