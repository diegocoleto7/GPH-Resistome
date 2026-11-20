#!/bin/bash
set -euo pipefail

DB="${1}"
OUT_DIR="${2}"
mkdir -p "${OUT_DIR}"
TMP_DIR=$(mktemp -d "${OUT_DIR}/tmp.XXXX")


cd-hit-est \
    -i "${DB}" \
    -o "${TMP_DIR}/resfinder_cdhit90.fsa" \
    -c 0.9 \
    -T 8 \
    -M 16000 \
    > "${OUT_DIR}/cdhit90.log" 2>&1

mv "${TMP_DIR}/resfinder_cdhit90.fsa.clstr" "${OUT_DIR}/resfinder_cdhit90.clstr"
rm -rf "${TMP_DIR}" # We want just the .clstr file

echo "Clusters: $(grep -c '^>Cluster' "${OUT_DIR}/resfinder_cdhit90.clstr")"
