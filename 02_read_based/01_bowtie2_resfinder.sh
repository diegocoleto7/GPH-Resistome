#!/bin/bash
#SBATCH --job-name=bowtie2_resfinder
#SBATCH --cpus-per-task=32
#SBATCH --mem=120G
#SBATCH -t 150:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 01_bowtie2_resfinder.sh <hostclean_dir> <resfinder_bt2_index> <out_dir>
#   hostclean_dir:       <muestra>_hostclean_R1.fastq.gz / _R2.fastq.gz
#   resfinder_bt2_index: prefijo del índice bowtie2 de ResFinder (all.fsa, sin clusterizar)
#   out_dir:             bam/<muestra>.bam (incluye las lecturas sin mapear) + logs/<muestra>.bowtie2.log

set -euo pipefail

INPUT_DIR="${1:?Uso: sbatch 01_bowtie2_resfinder.sh <hostclean_dir> <resfinder_bt2_index> <out_dir>}"
INDEX="${2:?Uso: sbatch 01_bowtie2_resfinder.sh <hostclean_dir> <resfinder_bt2_index> <out_dir>}"
OUT_DIR="${3:?Uso: sbatch 01_bowtie2_resfinder.sh <hostclean_dir> <resfinder_bt2_index> <out_dir>}"

mkdir -p "${OUT_DIR}/bam"
mkdir -p "${OUT_DIR}/logs"

set +u; eval "$(conda shell.bash hook)"; conda activate bowtie2_env; set -u

echo "Inicio: $(date)"
shopt -s nullglob

for R1 in "${INPUT_DIR}"/*_hostclean_R1.fastq.gz; do
    base=$(basename "${R1}" _hostclean_R1.fastq.gz)
    R2="${INPUT_DIR}/${base}_hostclean_R2.fastq.gz"

    if [[ ! -f "${R2}" ]]; then
        echo "ERROR: no existe el par para ${R1}"
        continue
    fi

    BAM_OUT="${OUT_DIR}/bam/${base}.bam"
    LOG_OUT="${OUT_DIR}/logs/${base}.bowtie2.log"
    echo "Procesando muestra: ${base}"

    bowtie2 \
        --mm \
        --very-sensitive \
        -x "${INDEX}" \
        -1 "${R1}" \
        -2 "${R2}" \
        -p "${SLURM_CPUS_PER_TASK}" \
        2> "${LOG_OUT}" \
      | samtools view -b -@ 4 -o "${BAM_OUT}" -
done

echo "Fin: $(date)"
