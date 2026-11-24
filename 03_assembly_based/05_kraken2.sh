#!/bin/bash

set -euo pipefail

DATA_DIR="${1}"
DB="${2}"
OUT_DIR="${3}"
mkdir -p "${OUT_DIR}/output" "${OUT_DIR}/report"

for asb in "${DATA_DIR}"/*.ARG_contigs.fa; do
    sample=$(basename "${asb}" .ARG_contigs.fa)
    echo "Running kraken2: ${sample}"
    k2 classify --db "${DB}" --use-names --threads 24 \
        --output "${OUT_DIR}/output/${sample}.kraken.tsv" \
        --report "${OUT_DIR}/report/${sample}.report.txt" \
        --use-daemon \
        "${asb}"
done
k2 clean --stop-daemon
