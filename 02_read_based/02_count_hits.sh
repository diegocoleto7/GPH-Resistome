#!/bin/bash
set -euo pipefail

BAM_DIR="${1}"
OUT_DIR="${2}"
PER_SAMPLE_DIR="${OUT_DIR}/per_sample"
STATS_FILE="${OUT_DIR}/library_sizes.tsv"
MATRIX_FILE="${OUT_DIR}/hits_matrix.tsv"
THREADS=4
EXCLUDE_FLAGS=2304
mkdir -p "${PER_SAMPLE_DIR}"

shopt -s nullglob
FILES=( "${BAM_DIR}"/*.bam )

echo -e "sample\tlibrary_size\tmapped_primary\ttotal_hits\tdetected_genes" > "${STATS_FILE}"

for F in "${FILES[@]}"; do

    SAMPLE=$(basename "${F}" .bam)
    COUNT_FILE="${PER_SAMPLE_DIR}/${SAMPLE}.counts.tsv"

    echo ">>> ${SAMPLE}"

    python3 "${SCRIPT_DIR}/02.1_count_hits.py" \
        "${F}" \
        "${COUNT_FILE}" \
        "${STATS_FILE}"

done

python3 "${SCRIPT_DIR}/02.2_build_matrix.py" \
    "${PER_SAMPLE_DIR}" \
    "${MATRIX_FILE}"
