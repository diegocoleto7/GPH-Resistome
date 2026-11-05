#!/bin/bash
#SBATCH --job-name=fastp
#SBATCH --cpus-per-task=16
#SBATCH --mem=16G
#SBATCH -t 48:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 02_fastp.sh <in_dir> <out_dir> <report_dir>
#   in_dir:     <muestra>_1.fq.gz / <muestra>_2.fq.gz
#   out_dir:    <muestra>_filtered_R1.fastq.gz / _R2.fastq.gz
#   report_dir: <muestra>_fastp.json / <muestra>.html
# Recorte en 5' y 3' con ventana deslizante (Q20), filtro de longitud mínima 50 pb.

set -euo pipefail

IN_DIR="${1:?Uso: sbatch 02_fastp.sh <in_dir> <out_dir> <report_dir>}"
OUT_DIR="${2:?Uso: sbatch 02_fastp.sh <in_dir> <out_dir> <report_dir>}"
REPORT_DIR="${3:?Uso: sbatch 02_fastp.sh <in_dir> <out_dir> <report_dir>}"
T="${SLURM_CPUS_PER_TASK:-16}"
mkdir -p "${OUT_DIR}" "${REPORT_DIR}"

set +u; eval "$(conda shell.bash hook)"; conda activate fungigut; set -u

for R1 in "${IN_DIR}"/*_1.fq.gz; do
    id=$(basename "${R1}" _1.fq.gz)
    R2="${IN_DIR}/${id}_2.fq.gz"
    echo ">>> ${id}"

    fastp -i "${R1}" -I "${R2}" \
        -o "${OUT_DIR}/${id}_filtered_R1.fastq.gz" -O "${OUT_DIR}/${id}_filtered_R2.fastq.gz" \
        --json "${REPORT_DIR}/${id}_fastp.json" --html "${REPORT_DIR}/${id}.html" \
        --cut_front -l 50 \
        -3 -M 20 -r -w "${T}"
done
