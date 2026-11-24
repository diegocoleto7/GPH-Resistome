#!/bin/bash
set -euo pipefail

ASM_DIR="${1}"
OUT_DIR="${2}"
mkdir -p "${OUT_DIR}"


seqkit stats -a -T -j 4 "${ASM_DIR}"/*.contigs.fa > "${OUT_DIR}/assembly_stats.tsv"

for f in "${ASM_DIR}"/*.contigs.fa; do
    s=$(basename "${f}" .contigs.fa)
    grep '>' "${f}" | sed "s/^>/${s}\t/"
done > "${OUT_DIR}/contig_headers.tsv"
