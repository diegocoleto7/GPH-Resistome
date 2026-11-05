#!/bin/bash
#SBATCH --job-name=host_removal
#SBATCH --cpus-per-task=16
#SBATCH --mem=16G
#SBATCH -t 72:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 03_host_removal.sh <in_dir> <out_dir> <grch38_bt2_index>
#   in_dir:           <muestra>_filtered_R1.fastq.gz / _R2.fastq.gz (salida de 02_fastp.sh)
#   out_dir:          <muestra>_hostclean_R1.fastq.gz / _R2.fastq.gz + log/<muestra>_hostclean.log
#   grch38_bt2_index: prefijo del índice bowtie2 de GRCh38
# Se conservan los pares que no alinean de forma concordante con el genoma humano.

set -euo pipefail

IN_DIR="${1:?Uso: sbatch 03_host_removal.sh <in_dir> <out_dir> <grch38_bt2_index>}"
OUT_DIR="${2:?Uso: sbatch 03_host_removal.sh <in_dir> <out_dir> <grch38_bt2_index>}"
INDEX="${3:?Uso: sbatch 03_host_removal.sh <in_dir> <out_dir> <grch38_bt2_index>}"
T="${SLURM_CPUS_PER_TASK:-16}"
mkdir -p "${OUT_DIR}/log"

set +u; eval "$(conda shell.bash hook)"; conda activate fungigut; set -u

for R1 in "${IN_DIR}"/*_filtered_R1.fastq.gz; do
    id=$(basename "${R1}" _filtered_R1.fastq.gz)
    R2="${IN_DIR}/${id}_filtered_R2.fastq.gz"
    echo ">>> ${id}"

    bowtie2 -x "${INDEX}" \
        -1 "${R1}" -2 "${R2}" \
        --un-conc-gz "${OUT_DIR}/${id}_hostclean_R%.fastq.gz" \
        -p "${T}" -S /dev/null --met-file "${OUT_DIR}/log/${id}_hostclean.log"
done
