#!/bin/bash
#SBATCH --job-name=assembly_stats
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH -t 04:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 01_assembly_stats.sh <assembly_dir> <out_dir>
#   assembly_dir: <muestra>.contigs.fa (MEGAHIT)
#   out_dir:      assembly_stats.tsv (seqkit stats -a) y contig_headers.tsv (muestra \t cabecera del contig)

set -euo pipefail

ASM_DIR="${1:?Uso: sbatch 01_assembly_stats.sh <assembly_dir> <out_dir>}"
OUT_DIR="${2:?Uso: sbatch 01_assembly_stats.sh <assembly_dir> <out_dir>}"
mkdir -p "${OUT_DIR}"

set +u; eval "$(conda shell.bash hook)"; conda activate fungigut; set -u

seqkit stats -a -T -j "${SLURM_CPUS_PER_TASK:-4}" "${ASM_DIR}"/*.contigs.fa > "${OUT_DIR}/assembly_stats.tsv"

for f in "${ASM_DIR}"/*.contigs.fa; do
    s=$(basename "${f}" .contigs.fa)
    grep '>' "${f}" | sed "s/^>/${s}\t/"
done > "${OUT_DIR}/contig_headers.tsv"
