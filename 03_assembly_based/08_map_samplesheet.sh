#!/usr/bin/env bash
# Uso: bash 08_map_samplesheet.sh <arg_contigs_dir> <out_csv>
# Samplesheet de mobilome-annotation-pipeline (MAP) con los contigs portadores de ARG.

set -euo pipefail

CONTIG_DIR="${1:?Uso: bash 08_map_samplesheet.sh <arg_contigs_dir> <out_csv>}"
OUTPUT="${2:?Uso: bash 08_map_samplesheet.sh <arg_contigs_dir> <out_csv>}"

printf "sample,assembly,user_proteins_gff,virify_gff\n" > "$OUTPUT"

for fasta in "$CONTIG_DIR"/GPH_*.ARG_contigs.fa; do

    [[ -e "$fasta" ]] || continue

    sample=$(basename "$fasta" .ARG_contigs.fa)
    assembly=$(realpath "$fasta")

    printf "%s,%s,,\n" \
        "$sample" \
        "$assembly" \
        >> "$OUTPUT"

done

echo "Samplesheet generado: $OUTPUT"
