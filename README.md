# Resolve Çevirici

Videoları **ücretsiz DaVinci Resolve'un Linux'ta açabildiği** biçime çeviren küçük bir araç.
Dosyalar'da videoya sağ tıklayıp tek tıkla çevirebilirsin. NVIDIA ekran kartı varsa onu kullanır.

## Neden gerekli?

Ücretsiz DaVinci Resolve, Linux'ta lisans nedeniyle **H.264 / H.265 (HEVC) video** ve
**AAC ses** çözemez. Telefon, OBS, kamera ve internetten indirilen videoların neredeyse hepsi bu
biçimlerdedir. Resolve'a eklediğinde görüntü ya da ses gelmez, bazen dosya hiç görünmez.

Bu araç videoları Resolve'un sorunsuz açtığı biçimlere çevirir:

| Mod | Video | Ses | Dosya | Boyut (1080p60) | Ne zaman? |
|---|---|---|---|---|---|
| **Normal** | AV1 | PCM | `.mp4` | ~dakikada 100-300 MB | Günlük kullanım |
| **Kayıpsız** | DNxHR HQ | PCM | `.mov` | ~dakikada 3,5 GB | Renk düzenleme, en yüksek kalite |

## Kurulum

```bash
git clone https://github.com/KULLANICI_ADIN/resolve-cevirici.git
cd resolve-cevirici
./kur.sh
```

Kurulum betiği şunları yapar:

1. **ffmpeg'i kontrol eder.** Fedora'nın varsayılan `ffmpeg-free` paketi gerekli kodlayıcıları içermez; gerekirse RPM Fusion'dan tam sürümü kurmayı önerir.
2. **Ekran kartı mı, işlemci mi kullanılsın diye sorar.** Kartı otomatik algılar, AV1 kodlamayı destekleyip desteklemediğini dener ve uygun seçeneği önerir:
   ```
   Videolar neyle çevrilsin?

     1) Ekran kartı — NVIDIA GeForce RTX 4060 Laptop GPU  (önerilen, ~5-6 kat hızlı)
     2) İşlemci — 28 çekirdek, daha yavaş ama her dosyada çalışır

   Seçimin [1]:
   ```
3. `resolve-cevir` ve `resolve-cevir-kayipsiz` komutlarını `~/.local/bin` klasörüne kurar.
4. Dosyalar (Nautilus) **sağ tık menüsüne** iki seçenek ekler.

Seçimini değiştirmek istersen `./kur.sh`'i tekrar çalıştırman yeterli.

## Kullanım

**Sağ tık:** Videoları seç, sağ tıkla, **Betikler** menüsünden şunlardan birini seç:
- **Resolve için çevir (normal)**
- **Resolve için çevir (kayıpsız)**

Bir terminal penceresi açılır ve ilerlemeyi gösterir.

**Terminal:**

```bash
resolve-cevir video.mp4                # normal
resolve-cevir *.mp4                    # birden fazla dosya
resolve-cevir -k video.mp4             # kayıpsız (veya: resolve-cevir-kayipsiz video.mp4)
resolve-cevir --cpu video.mp4          # bu seferlik yalnızca işlemci
resolve-cevir --gpu video.mp4          # bu seferlik ekran kartı
```

Çıktılar videonun bulunduğu klasörde açılan **`Resolve/`** alt klasörüne yazılır; orijinal dosyalara dokunulmaz.

## Ekran kartı ne kadar hızlandırır?

RTX 4060 Laptop üzerinde 1080p60 HEVC telefon videosuyla ölçülen değerler:

| Mod | İşlemci | Ekran kartı |
|---|---|---|
| Normal (AV1) | 76 kare/sn | **464 kare/sn** (~6x) |
| Kayıpsız (DNxHR) | 64 kare/sn | **293 kare/sn** (~4,5x) |

Ekran kartı modunda video hem **kartta çözülür** (CUDA/NVDEC) hem de **kartta kodlanır** (NVENC AV1). Görüntü
kartın belleğinden hiç çıkmadığı için en hızlı yol budur. Kayıpsız modda DNxHR kodlaması her zaman işlemcide yapılır,
çünkü bunun ekran kartı karşılığı yoktur; çözme ise yine kartta olur.

**Otomatik geri dönüş:** Kartın desteklemediği bir dosya gelirse (ör. 4:4:4 renkli, çok eski ya da tuhaf biçimler) betik
bunu kendisi fark eder ve o dosyayı işlemciyle çevirir.

**Eski NVIDIA kartlar (RTX 30 ve öncesi):** Bu kartlar AV1 kodlayamaz. Kurulum bunu algılar; video çözme kartta,
AV1 kodlama işlemcide (SVT-AV1) yapılır.

## Ayar dosyası

`~/.config/resolve-cevirici/ayar`

```bash
DONANIM=gpu              # gpu | cpu
AV1_KODLAYICI=av1_nvenc  # av1_nvenc | libsvtav1
```

## Kaldırma

```bash
./kaldir.sh
```

## Gereksinimler

- Linux (Fedora'da denendi), `ffmpeg` (libsvtav1 ve dnxhd destekli)
- İsteğe bağlı: NVIDIA ekran kartı ve sürücüsü (AV1 kodlama için RTX 40 serisi veya sonrası)
- İsteğe bağlı: Nautilus (GNOME Dosyalar) sağ tık menüsü için

## Lisans

MIT
