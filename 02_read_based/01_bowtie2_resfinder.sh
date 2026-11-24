#!/bin/bash

set -euo pipefail

INPUT_DIR="${1}"
INDEX="${2}"
OUT_DIR="${3}"
T=16
mkdir -p "${OUT_DIR}/bam"
mkdir -p "${OUT_DIR}/logs"


echo "Start: $(date)"
shopt -s nullglob

for R1 in "${INPUT_DIR}"/*_hostclean_R1.fastq.gz; do
    base=$(basename "${R1}" _hostclean_R1.fastq.gz)
    R2="${INPUT_DIR}/${base}_hostclean_R2.fastq.gz"

    BAM_OUT="${OUT_DIR}/bam/${base}.bam"
    LOG_OUT="${OUT_DIR}/logs/${base}.bowtie2.log"
    echo "Procesing sample: ${base}"

    bowtie2 \
        --mm \
        --very-sensitive \
        -x "${INDEX}" \
        -1 "${R1}" \
        -2 "${R2}" \
        -p "${T}" \
        2> "${LOG_OUT}" \
      | samtools view -b -@ 4 -o "${BAM_OUT}" -
done

echo "End: $(date)"
