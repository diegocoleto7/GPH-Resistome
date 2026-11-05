#!/bin/bash
#SBATCH --job-name=kraken2
#SBATCH --cpus-per-task=24
#SBATCH --mem=250G
#SBATCH -t 48:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 05_kraken2.sh <arg_contigs_dir> <kraken2_db> <out_dir>
#   arg_contigs_dir: <muestra>.ARG_contigs.fa (salida de 04_extract_arg_contigs.sh)
#   kraken2_db:      base de datos de Kraken2 (PlusPFP)
#   out_dir:         output/<muestra>.kraken.tsv y report/<muestra>.report.txt
# Confidence por defecto (0).

set -euo pipefail

DATA_DIR="${1:?Uso: sbatch 05_kraken2.sh <arg_contigs_dir> <kraken2_db> <out_dir>}"
DB="${2:?Uso: sbatch 05_kraken2.sh <arg_contigs_dir> <kraken2_db> <out_dir>}"
OUT_DIR="${3:?Uso: sbatch 05_kraken2.sh <arg_contigs_dir> <kraken2_db> <out_dir>}"
mkdir -p "${OUT_DIR}/output" "${OUT_DIR}/report"

set +u; eval "$(conda shell.bash hook)"; conda activate kraken2; set -u

for asb in "${DATA_DIR}"/*.ARG_contigs.fa; do
    sample=$(basename "${asb}" .ARG_contigs.fa)
    echo "Running kraken2: ${sample}"
    k2 classify --db "${DB}" --use-names --threads 24 \
        --output "${OUT_DIR}/output/${sample}.kraken.tsv" \
        --report "${OUT_DIR}/report/${sample}.report.txt" \
        --use-daemon \
        "${asb}"
done
k2 clean --stop-daemon
