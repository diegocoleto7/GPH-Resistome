#!/bin/bash

set -euo pipefail

IN_DIR="${1}"
OUT_DIR="${2}"
DB_DIR="${3}"

INDEX="mpa_vJan25_CHOCOPhlAnSGB_202503"
T=12

mkdir -p "${OUT_DIR}"

shopt -s nullglob

for R1 in "${IN_DIR}"/*_hostclean_R1.fastq.gz; do

    sample=$(basename "${R1}" _hostclean_R1.fastq.gz)
    R2="${IN_DIR}/${sample}_hostclean_R2.fastq.gz"

    PROFILE="${OUT_DIR}/${sample}_profile.tsv"

    metaphlan "${R1},${R2}" \
        --input_type fastq \
        --nproc "${T}" \
        --db_dir "${DB_DIR}" \
        --index "${INDEX}" \
        --mapout "${OUT_DIR}/${sample}.map.bz2" \
        -t rel_ab \
        -o "${PROFILE}"
done
