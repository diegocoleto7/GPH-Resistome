#!/bin/bash

set -euo pipefail

KRAKEN_TABLE="${1}"
OUT_DIR="${2}"
TAXIDS="${OUT_DIR}/kraken2_unique_taxids.txt"
OUT="${OUT_DIR}/kraken2_taxonomy.tsv"

mkdir -p "${OUT_DIR}"

tail -n +2 "${KRAKEN_TABLE}" \
    | cut -f4 \
    | sed -E 's/.*\(taxid ([0-9]+)\)$/\1/' \
    | sort -n -u > "${TAXIDS}"

taxonkit reformat2 --miss-rank-repl "NA" \
    --format "{domain|acellular root|superkingdom}\t{phylum}\t{class}\t{order}\t{family}\t{genus}\t{species}" \
    -o "${OUT}" --threads "${SLURM_CPUS_PER_TASK:-4}" "${TAXIDS}"
