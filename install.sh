#!/usr/bin/env bash
# instala o tema em /usr/share/sddm/themes/hypr-pallas.
#
# copia so o que e versionado. o theme.conf e o wallpaper ficam de fora
# de proposito: o theme.conf do repo vem com background vazio, e passa-lo
# por cima de uma instalacao existente apagaria o wallpaper local (que o
# .gitignore mantem fora do repo).
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${DESTDIR:-}/usr/share/sddm/themes/hypr-pallas"

files=(Main.qml arch-mask.png arch-outline.png metadata.desktop)

for f in "${files[@]}"; do
    [[ -f "$src/$f" ]] || { echo "erro: faltando $f em $src" >&2; exit 1; }
done

# so escala privilegio quando o destino realmente exige. com DESTDIR
# apontando para uma pasta do usuario, roda sem sudo nenhum
sudo=()
probe="$dest"
while [[ ! -e "$probe" ]]; do probe="$(dirname "$probe")"; done
if [[ ! -w "$probe" ]]; then
    if [[ $EUID -eq 0 ]]; then
        echo "erro: $probe nao e gravavel nem como root" >&2; exit 1
    fi
    command -v sudo >/dev/null || { echo "erro: rode como root ou instale o sudo" >&2; exit 1; }
    sudo=(sudo)
fi

"${sudo[@]}" install -d -m 755 "$dest"
"${sudo[@]}" install -m 644 "${files[@]/#/$src/}" "$dest/"
echo "instalado: ${files[*]}"

if [[ -f "$dest/theme.conf" ]]; then
    echo "mantido: theme.conf existente (wallpaper e ajustes locais preservados)"
else
    "${sudo[@]}" install -m 644 "$src/theme.conf" "$dest/"
    echo "instalado: theme.conf padrao (sem wallpaper, usa o gradiente Catppuccin)"
fi

# aviso quando o theme.conf aponta para um wallpaper que nao esta la:
# o greeter nao reclama, so cai no gradiente, e isso confunde
bg="$(sed -n 's/^background=//p' "$dest/theme.conf" | tail -1)"
if [[ -n "$bg" && ! -f "$dest/$bg" ]]; then
    echo "aviso: theme.conf aponta para '$bg', que nao existe em $dest" >&2
fi

echo
echo "para conferir sem reiniciar:"
echo "  sddm-greeter-qt6 --test-mode --theme $dest"
