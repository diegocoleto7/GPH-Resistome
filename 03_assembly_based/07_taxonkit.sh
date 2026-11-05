#!/bin/bash
#SBATCH --job-name=taxonkit
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH -t 02:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 07_taxonkit.sh <kraken2_all_samples.tsv> <out_dir>
#   kraken2_all_samples.tsv: salida de 06_merge_kraken2.py
#   out_dir: kraken2_unique_taxids.txt y kraken2_taxonomy.tsv (taxid, domain..species; NA si falta el rango)
# Usa el taxdump de NCBI en el directorio por defecto de taxonkit.

set -euo pipefail

KRAKEN_TABLE="${1:?Uso: sbatch 07_taxonkit.sh <kraken2_all_samples.tsv> <out_dir>}"
OUT_DIR="${2:?Uso: sbatch 07_taxonkit.sh <kraken2_all_samples.tsv> <out_dir>}"
TAXIDS="${OUT_DIR}/kraken2_unique_taxids.txt"
OUT="${OUT_DIR}/kraken2_taxonomy.tsv"
mkdir -p "${OUT_DIR}"

set +u; eval "$(conda shell.bash hook)"; conda activate taxonkit; set -u

# taxids únicos: "Alistipes communis (taxid 2585118)" -> 2585118
tail -n +2 "${KRAKEN_TABLE}" \
    | awk -F '\t' '{print $4}' \
    | sed -E 's/.*\(taxid ([0-9]+)\)$/\1/' \
    | sort -n -u > "${TAXIDS}"
echo "taxids únicos: $(wc -l < "${TAXIDS}")"

taxonkit reformat2 --miss-rank-repl "NA" \
    --format "{domain|acellular root|superkingdom}\t{phylum}\t{class}\t{order}\t{family}\t{genus}\t{species}" \
    -o "${OUT}" --threads "${SLURM_CPUS_PER_TASK:-4}" "${TAXIDS}"
