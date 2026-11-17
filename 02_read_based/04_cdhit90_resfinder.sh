#!/bin/bash
# Uso: bash 05_cdhit90_resfinder.sh <resfinder_all.fsa> <out_dir>
# Clusterización de la base de datos de ResFinder al 90% de identidad (CD-HIT-EST, resto de parámetros por defecto).
# Solo se conserva el .clstr: <out_dir>/resfinder_cdhit90.clstr

set -euo pipefail

DB="${1:?Uso: bash 05_cdhit90_resfinder.sh <resfinder_all.fsa> <out_dir>}"
OUT_DIR="${2:?Uso: bash 05_cdhit90_resfinder.sh <resfinder_all.fsa> <out_dir>}"
mkdir -p "${OUT_DIR}"
TMP_DIR=$(mktemp -d "${OUT_DIR}/tmp.XXXX")

set +u; eval "$(conda shell.bash hook)"; conda activate cdhit; set -u

cd-hit-est \
    -i "${DB}" \
    -o "${TMP_DIR}/resfinder_cdhit90.fsa" \
    -c 0.9 \
    -T 8 \
    -M 16000 \
    > "${OUT_DIR}/cdhit90.log" 2>&1

mv "${TMP_DIR}/resfinder_cdhit90.fsa.clstr" "${OUT_DIR}/resfinder_cdhit90.clstr"
rm -rf "${TMP_DIR}"

echo "Clusters: $(grep -c '^>Cluster' "${OUT_DIR}/resfinder_cdhit90.clstr")"
