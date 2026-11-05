#!/bin/bash
# Uso: bash 03_abricate_summary.sh <abricate_dir>
#   abricate_dir: salida de 02_abricate.sh
# Tabla muestra × gen (% de identidad) para cada base: <abricate_dir>/<db>/<db>_summary.tsv

set -euo pipefail

ABR_DIR="${1:?Uso: bash 03_abricate_summary.sh <abricate_dir>}"

set +u; eval "$(conda shell.bash hook)"; conda activate abricate; set -u

for db in resfinder vfdb plasmidfinder; do
    (cd "${ABR_DIR}/${db}" && abricate --summary GPH_*.abricate_${db}.out) > "${ABR_DIR}/${db}/${db}_summary.tsv"
    echo "${db}: ${ABR_DIR}/${db}/${db}_summary.tsv"
done
