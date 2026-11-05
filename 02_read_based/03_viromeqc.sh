#!/bin/bash
#SBATCH --job-name=viromeqc
#SBATCH --cpus-per-task=40
#SBATCH --mem=120G
#SBATCH -t 150:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 03_viromeqc.sh <hostclean_dir> <out_dir>
#   hostclean_dir: <muestra>_hostclean_R1.fastq.gz
#   out_dir:       report_<muestra>.txt
# ViromeQC sobre R1, sin filtros de longitud ni calidad (las lecturas ya vienen de fastp).

set -euo pipefail

INPUT_DIR="${1:?Uso: sbatch 03_viromeqc.sh <hostclean_dir> <out_dir>}"
OUT_DIR="${2:?Uso: sbatch 03_viromeqc.sh <hostclean_dir> <out_dir>}"
THREADS="${SLURM_CPUS_PER_TASK:-32}"
mkdir -p "${OUT_DIR}"

set +u; eval "$(conda shell.bash hook)"; conda activate ViromeQC_py38; set -u

echo "Inicio: $(date)"
for R1 in "${INPUT_DIR}"/*_hostclean_R1.fastq.gz; do
    base=$(basename "${R1}" _hostclean_R1.fastq.gz)
    echo "Procesando muestra: ${base}"

    viromeQC.py \
        -i "${R1}" \
        -o "${OUT_DIR}/report_${base}.txt" \
        --bowtie2_threads "${THREADS}" \
        --diamond_threads "${THREADS}" \
        --minlen 0 \
        --minqual 0
done
echo "Fin: $(date)"
