#!/bin/bash
# resolve-cevirici kurulumu.
# Çevirmede ekran kartı mı işlemci mi kullanılacağını sorar, ffmpeg'i kontrol eder,
# komutları ~/.local/bin'e ve sağ tık menüsünü (Dosyalar / Nautilus) kurar.
# Ayarı değiştirmek için bu betiği tekrar çalıştırman yeterli.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

BIN="$HOME/.local/bin"
AYAR_KLASORU="${XDG_CONFIG_HOME:-$HOME/.config}/resolve-cevirici"
NAUTILUS="$HOME/.local/share/nautilus/scripts"

if [ -t 1 ]; then Y=$'\e[1;32m'; S=$'\e[1;33m'; K=$'\e[1;31m'; M=$'\e[1;34m'; N=$'\e[0m'; else Y=; S=; K=; M=; N=; fi
adim()  { echo; echo "${M}==>${N} $*"; }
bilgi() { echo "    $*"; }
uyari() { echo "    ${S}$*${N}"; }
hata()  { echo "${K}HATA:${N} $*" >&2; exit 1; }
sor()   { local c; read -r -p "    $1 [E/h] " c </dev/tty || c=; [[ ! "$c" =~ ^[hHnN] ]]; }

[ "$EUID" -eq 0 ] && hata "sudo ile değil, normal kullanıcı olarak çalıştır."
echo "${Y}Resolve Çevirici — kurulum${N}"

# ---------- 1. ffmpeg ----------
adim "1/4 ffmpeg kontrol ediliyor"
KODLAYICILAR=""
kodlayicilari_oku() { KODLAYICILAR="$(ffmpeg -hide_banner -encoders 2>/dev/null || true)"; }
kodlayici_var() { grep -q " $1 " <<<"$KODLAYICILAR"; }
command -v ffmpeg >/dev/null && kodlayicilari_oku
if ! command -v ffmpeg >/dev/null || ! kodlayici_var libsvtav1 || ! kodlayici_var dnxhd; then
    uyari "Tam sürüm ffmpeg gerekli (Fedora'nın varsayılan ffmpeg-free paketi yetmiyor)."
    if command -v dnf >/dev/null && sor "RPM Fusion'dan tam ffmpeg kurulsun mu?"; then
        rpm -q rpmfusion-free-release >/dev/null 2>&1 || sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        if rpm -q ffmpeg-free >/dev/null 2>&1; then
            sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
        else
            sudo dnf install -y ffmpeg
        fi
    else
        hata "ffmpeg olmadan devam edilemiyor."
    fi
fi
bilgi "ffmpeg hazır: $(ffmpeg -version | head -1 | cut -d' ' -f1-3)"

# ---------- 2. donanım ----------
adim "2/4 Donanım seçimi"
test_et() { # 1 karelik deneme kodlaması
    ffmpeg -hide_banner -loglevel error -f lavfi -i color=c=black:s=640x360:d=0.1 \
        -frames:v 1 "$@" -f null - >/dev/null 2>&1
}
NVIDIA_VAR=false; NVENC_AV1=false; CUDA_COZME=false
if nvidia-smi >/dev/null 2>&1; then
    NVIDIA_VAR=true
    GPU_ADI="$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
    test_et -c:v av1_nvenc && NVENC_AV1=true
    ffmpeg -hide_banner -loglevel error -init_hw_device cuda -f lavfi -i nullsrc -frames:v 1 -f null - \
        >/dev/null 2>&1 && CUDA_COZME=true
fi

echo
echo "    Videolar neyle çevrilsin?"
echo
if $NVIDIA_VAR; then
    if $NVENC_AV1; then
        echo "      ${Y}1) Ekran kartı${N} — $GPU_ADI  ${Y}(önerilen, ~5-6 kat hızlı)${N}"
    else
        echo "      ${Y}1) Ekran kartı${N} — $GPU_ADI  (video çözme kartta, AV1 kodlama işlemcide;"
        echo "         bu kart AV1 kodlamayı desteklemiyor, RTX 40 ve sonrası gerekir)"
    fi
    echo "      2) İşlemci — $(nproc) çekirdek, daha yavaş ama her dosyada çalışır"
    VARSAYILAN=1
else
    echo "      1) Ekran kartı — ${S}NVIDIA kart / sürücü bulunamadı, kullanılamaz${N}"
    echo "      ${Y}2) İşlemci${N} — $(nproc) çekirdek  ${Y}(önerilen)${N}"
    VARSAYILAN=2
fi
echo
read -r -p "    Seçimin [$VARSAYILAN]: " secim </dev/tty || secim=
secim="${secim:-$VARSAYILAN}"

case "$secim" in
    1)  $NVIDIA_VAR || hata "NVIDIA ekran kartı/sürücüsü yok; işlemciyi (2) seç."
        $CUDA_COZME || uyari "CUDA ile video çözme denenemedi; çözme gerekirse işlemciye düşer."
        DONANIM=gpu
        $NVENC_AV1 && AV1_KODLAYICI=av1_nvenc || AV1_KODLAYICI=libsvtav1 ;;
    2)  DONANIM=cpu; AV1_KODLAYICI=libsvtav1 ;;
    *)  hata "Geçersiz seçim: $secim" ;;
esac

mkdir -p "$AYAR_KLASORU"
cat > "$AYAR_KLASORU/ayar" <<AYAR
# resolve-cevirici ayarı — kur.sh tarafından oluşturuldu
DONANIM=$DONANIM
AV1_KODLAYICI=$AV1_KODLAYICI
AYAR
bilgi "Kaydedildi: DONANIM=$DONANIM, AV1_KODLAYICI=$AV1_KODLAYICI"

# ---------- 3. komutlar ----------
adim "3/4 Komutlar kuruluyor ($BIN)"
mkdir -p "$BIN"
install -m 755 bin/resolve-cevir "$BIN/resolve-cevir"
ln -sf resolve-cevir "$BIN/resolve-cevir-kayipsiz"
bilgi "resolve-cevir, resolve-cevir-kayipsiz"
case ":$PATH:" in *":$BIN:"*) ;; *) uyari "$BIN PATH'te değil; terminalden kullanmak için oturumu yeniden aç." ;; esac

# ---------- 4. sağ tık menüsü ----------
adim "4/4 Dosyalar (Nautilus) sağ tık menüsü kuruluyor"
mkdir -p "$NAUTILUS"
for tur in normal kayipsiz; do
    [ "$tur" = normal ] && ad="Resolve için çevir (normal)" kmt="resolve-cevir" \
                        || ad="Resolve için çevir (kayıpsız)" kmt="resolve-cevir-kayipsiz"
    sed "s|@KOMUT@|$BIN/$kmt|" nautilus/sablon.sh > "$NAUTILUS/$ad"
    chmod +x "$NAUTILUS/$ad"
    bilgi "$ad"
done

echo
echo "${Y}Kurulum tamamlandı!${N}"
cat <<SON

  Kullanım:
    • Dosyalar'da videolara sağ tıkla → Betikler → "Resolve için çevir (normal)"
    • Terminalden:  resolve-cevir video.mp4
                    resolve-cevir -k video.mp4     (kayıpsız)
                    resolve-cevir --cpu video.mp4  (bu seferlik işlemciyle)

  Çıktılar videonun yanındaki "Resolve" klasörüne yazılır.
  Ekran kartı / işlemci seçimini değiştirmek için ./kur.sh'i tekrar çalıştır.
SON
