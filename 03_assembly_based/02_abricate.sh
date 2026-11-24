#!/bin/bash
set -euo pipefail

DATA_DIR="${1}"
OUT_DIR="${2}"
DBS=( resfinder vfdb plasmidfinder )


for db in "${DBS[@]}"; do
    mkdir -p "${OUT_DIR}/${db}"
done

for asb in "${DATA_DIR}"/*.contigs.fa; do
    sample=$(basename "${asb}" .contigs.fa)
    for db in "${DBS[@]}"; do
        echo "Running ${db}: ${sample}"
        abricate --threads 30 \
            --db "${db}" \
            "${asb}" > "${OUT_DIR}/${db}/${sample}.abricate_${db}.out"
    done
done
