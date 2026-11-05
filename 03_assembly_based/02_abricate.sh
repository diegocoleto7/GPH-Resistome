#!/bin/bash
#SBATCH --job-name=abricate
#SBATCH --cpus-per-task=30
#SBATCH -t 150:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 02_abricate.sh <assembly_dir> <out_dir>
#   assembly_dir: <muestra>.contigs.fa
#   out_dir:      <db>/<muestra>.abricate_<db>.out para resfinder, vfdb y plasmidfinder

set -euo pipefail

DATA_DIR="${1:?Uso: sbatch 02_abricate.sh <assembly_dir> <out_dir>}"
OUT_DIR="${2:?Uso: sbatch 02_abricate.sh <assembly_dir> <out_dir>}"
DBS=( resfinder vfdb plasmidfinder )

set +u; eval "$(conda shell.bash hook)"; conda activate abricate; set -u

for db in "${DBS[@]}"; do
    mkdir -p "${OUT_DIR}/${db}"
done

for asb in "${DATA_DIR}"/*.contigs.fa; do
    sample=$(basename "${asb}" .contigs.fa)
    for db in "${DBS[@]}"; do
        echo "Running ${db}: ${sample}"
        abricate --threads 30 \
            --db "${db}" \
            "${asb}" > "${OUT_DIR}/${db}/${sample}.abricate_${db}.out"
    done
done
