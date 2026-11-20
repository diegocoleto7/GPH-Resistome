#!/bin/bash
set -euo pipefail

INPUT_DIR="${1}"
OUT_DIR="${2}"
THREADS=32
mkdir -p "${OUT_DIR}"

echo "Start: $(date)"
for R1 in "${INPUT_DIR}"/*_hostclean_R1.fastq.gz; do
    base=$(basename "${R1}" _hostclean_R1.fastq.gz)
    echo "Procesing sample: ${base}"

    viromeQC.py \
        -i "${R1}" \
        -o "${OUT_DIR}/report_${base}.txt" \
        --bowtie2_threads "${THREADS}" \
        --diamond_threads "${THREADS}" \
        --minlen 0 \
        --minqual 0
done
echo "End: $(date)"
