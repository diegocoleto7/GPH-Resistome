#!/bin/bash
# Uso: bash 04_merge_viromeqc.sh <reports_dir> <out_tsv>
# Une los report_*.txt de ViromeQC en una tabla. Sample = nombre de la muestra (sin _hostclean_R1).
# La columna Reads (pares de lecturas sin host) es el denominador para el CPM.

set -euo pipefail

REPORTS_DIR="${1:?Uso: bash 04_merge_viromeqc.sh <reports_dir> <out_tsv>}"
OUT="${2:?Uso: bash 04_merge_viromeqc.sh <reports_dir> <out_tsv>}"

shopt -s nullglob
REPORTS=( "${REPORTS_DIR}"/report_*.txt )
if [[ ${#REPORTS[@]} -eq 0 ]]; then
    echo "ERROR: no hay reports en ${REPORTS_DIR}" >&2
    exit 1
fi

{
    head -n 1 "${REPORTS[0]}"
    for r in "${REPORTS[@]}"; do
        tail -n +2 "${r}"
    done | sed 's/_hostclean_R1\t/\t/' | sort -t_ -k2,2n
} > "${OUT}"

echo "Tabla: ${OUT} | $(( $(wc -l < "${OUT}") - 1 )) muestras"
