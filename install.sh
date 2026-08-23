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

files=(
    Main.qml
    metadata.desktop
    arch-mask.png   arch-outline.png
    circle-mask.png circle-outline.png
    square-mask.png square-outline.png
)

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
echo "instalado: ${#files[@]} arquivos em $dest"

if [[ -f "$dest/theme.conf" ]]; then
    echo "mantido: theme.conf existente (wallpaper e ajustes locais preservados)"
else
    "${sudo[@]}" install -m 644 "$src/theme.conf" "$dest/"
    echo "instalado: theme.conf padrao (sem wallpaper, usa o gradiente Catppuccin)"
fi

# o theme.conf existente pode ser mais velho que o do repo. como este script
# nunca o sobrescreve, avisa quais chaves faltam: o tema cai no padrao delas,
# e quem quiser mexer precisa acrescenta-las a mao
missing=()
while IFS= read -r key; do
    grep -q "^${key}=" "$dest/theme.conf" || missing+=("$key")
done < <(sed -n 's/^\([A-Za-z][A-Za-z0-9]*\)=.*/\1/p' "$src/theme.conf")
if (( ${#missing[@]} )); then
    echo
    echo "aviso: o theme.conf instalado nao tem estas chaves: ${missing[*]}"
    echo "       o tema usa o padrao de cada uma; para ajusta-las, copie as"
    echo "       linhas correspondentes de $src/theme.conf"
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
