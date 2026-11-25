#!/bin/bash
set -euo pipefail

CONTIG_DIR="${1}"
OUTPUT="${2}"

printf "sample,assembly,user_proteins_gff,virify_gff\n" > "$OUTPUT"

for fasta in "$CONTIG_DIR"/GPH_*.ARG_contigs.fa; do

    sample=$(basename "$fasta" .ARG_contigs.fa)
    assembly=$(realpath "$fasta")

    printf "%s,%s,,\n" \
        "$sample" \
        "$assembly" \
        >> "$OUTPUT"

done
