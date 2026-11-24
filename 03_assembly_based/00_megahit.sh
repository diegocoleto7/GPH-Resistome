#!/bin/bash

set -euo pipefail

IN_DIR="${1}"
OUT_DIR="${2}"
T=40
mkdir -p "${OUT_DIR}"

for R1 in "${IN_DIR}"/*_hostclean_R1.fastq.gz; do
    sample=$(basename "${R1}" _hostclean_R1.fastq.gz)
    R2="${IN_DIR}/${sample}_hostclean_R2.fastq.gz"
    echo ">>> ${sample}"

    megahit -1 "${R1}" -2 "${R2}" -o "${OUT_DIR}/${sample}" -t "${T}"
done

for asm in "${OUT_DIR}"/*/final.contigs.fa; do
    sample=$(basename "$(dirname "${asm}")")
    ln -sf "$(realpath "${asm}")" "${OUT_DIR}/${sample}.contigs.fa"
done
