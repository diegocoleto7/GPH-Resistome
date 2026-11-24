#!/bin/bash

set -euo pipefail


ABRICATE_DIR="${1}"
OUTPUT_DIR="${2}"
IDS_DIR="${OUTPUT_DIR}/contig_ids"

mkdir -p "$IDS_DIR"

SUMMARY="${OUTPUT_DIR}/ARG_contig_extraction_summary.tsv"

printf "sample\tassembly\tabricate_hits\tunique_ARG_contigs\tmatched_contigs\toutput_fasta\n" > "$SUMMARY"

shopt -s nullglob

reports=("${ABRICATE_DIR}"/*.abricate_resfinder.out)

for report in "${reports[@]}"; do

    sample=$(basename "${report}" .abricate_resfinder.out)

    ids_file="${IDS_DIR}/${sample}.ARG_contig_ids.txt"
    output_fasta="${OUTPUT_DIR}/${sample}.ARG_contigs.fa"

    echo "Processing ${sample}..."

    n_hits=$(sed '/^#/d; /^$/d' "${report}" | wc -l)


    sed '/^#/d; s/\r$//' "${report}" |
    cut -s -f2 |
    sed '/^$/d' |
    sort -u > "${ids_file}"

    n_unique=$(wc -l < "$ids_file")


    assembly=$(
        sed '/^#/d; s/\r$//' "${report}" |
        cut -s -f1 |
        sed '/^$/d' |
        sort -u
    )


    seqkit grep \
        --pattern-file "$ids_file" \
        "$assembly" \
        --out-file "$output_fasta"

    n_matched=$(grep -c '^>' "${output_fasta}")

    printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$sample" \
        "$assembly" \
        "$n_hits" \
        "$n_unique" \
        "$n_matched" \
        "$output_fasta" \
        >> "$SUMMARY"

done

echo "Summary:"
echo "  ${SUMMARY}"
