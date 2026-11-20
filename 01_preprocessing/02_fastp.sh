#!/bin/bash

set -euo pipefail

IN_DIR="${1}"
OUT_DIR="${2}"
REPORT_DIR="${3}"
T=16
mkdir -p "${OUT_DIR}" "${REPORT_DIR}"

for R1 in "${IN_DIR}"/*_1.fq.gz; do
    id=$(basename "${R1}" _1.fq.gz)
    R2="${IN_DIR}/${id}_2.fq.gz"
    echo ">>> ${id}"

    fastp -i "${R1}" -I "${R2}" \
        -o "${OUT_DIR}/${id}_filtered_R1.fastq.gz" -O "${OUT_DIR}/${id}_filtered_R2.fastq.gz" \
        --json "${REPORT_DIR}/${id}_fastp.json" --html "${REPORT_DIR}/${id}.html" \
        --cut_front -l 50 \
        -3 -M 20 -r -w "${T}"
done
