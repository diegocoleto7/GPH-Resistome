#!/bin/bash
set -euo pipefail

ABR_DIR="${1}"

for db in resfinder vfdb plasmidfinder; do
    (cd "${ABR_DIR}/${db}" && abricate --summary GPH_*.abricate_${db}.out) > "${ABR_DIR}/${db}/${db}_summary.tsv"
    echo "${db}: ${ABR_DIR}/${db}/${db}_summary.tsv"
done
