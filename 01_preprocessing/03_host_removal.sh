#!/bin/bash
set -euo pipefail

IN_DIR="${1}"
OUT_DIR="${2}"
INDEX="${3}"
T=16
mkdir -p "${OUT_DIR}/log"

for R1 in "${IN_DIR}"/*_filtered_R1.fastq.gz; do
    id=$(basename "${R1}" _filtered_R1.fastq.gz)
    R2="${IN_DIR}/${id}_filtered_R2.fastq.gz"
    echo ">>> ${id}"

    bowtie2 -x "${INDEX}" \
        -1 "${R1}" -2 "${R2}" \
        --un-conc-gz "${OUT_DIR}/${id}_hostclean_R%.fastq.gz" \
        -p "${T}" -S /dev/null --met-file "${OUT_DIR}/log/${id}_hostclean.log"
done
