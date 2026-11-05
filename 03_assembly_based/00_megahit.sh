#!/bin/bash
#SBATCH --job-name=megahit
#SBATCH --cpus-per-task=40
#SBATCH -t 200:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 00_megahit.sh <hostclean_dir> <out_dir>
#   hostclean_dir: <muestra>_hostclean_R1.fastq.gz / _R2.fastq.gz (salida de 01_preprocessing/03_host_removal.sh)
#   out_dir:       <muestra>/final.contigs.fa (MEGAHIT) y <muestra>.contigs.fa en la raiz
#
# MEGAHIT escribe cada ensamblado en su propia carpeta como final.contigs.fa, mientras que los
# pasos siguientes (01_assembly_stats.sh en adelante) esperan <out_dir>/<muestra>.contigs.fa.
# El bucle final hace ese puente con enlaces simbolicos; si prefieres copiarlos, cambia ln -sf por cp.

set -euo pipefail

IN_DIR="${1:?Uso: sbatch 00_megahit.sh <hostclean_dir> <out_dir>}"
OUT_DIR="${2:?Uso: sbatch 00_megahit.sh <hostclean_dir> <out_dir>}"
T="${SLURM_CPUS_PER_TASK:-40}"
mkdir -p "${OUT_DIR}"

module load python/python-3.9-intelr
module load megahit/1.2.9

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
