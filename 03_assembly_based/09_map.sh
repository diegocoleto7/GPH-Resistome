#!/bin/bash
# Uso: bash 09_map.sh <map_pipeline_dir> <samplesheet.csv> <work_dir>   (Nextflow; lanzar dentro de screen/tmux)
#   map_pipeline_dir: clon de EBI-Metagenomics/mobilome-annotation-pipeline
#   samplesheet.csv:  salida de 08_map_samplesheet.sh
#   work_dir:         carpeta donde se ejecuta Nextflow (results/ queda dentro)
# MAP incluye la anotación de plásmidos y virus con geNomad.

set -euo pipefail

PIPELINE="${1:?Uso: bash 09_map.sh <map_pipeline_dir> <samplesheet.csv> <work_dir>}"
SAMPLESHEET="${2:?Uso: bash 09_map.sh <map_pipeline_dir> <samplesheet.csv> <work_dir>}"
WORK_DIR="${3:?Uso: bash 09_map.sh <map_pipeline_dir> <samplesheet.csv> <work_dir>}"
SAMPLESHEET=$(realpath "${SAMPLESHEET}")
mkdir -p "${WORK_DIR}"

set +u; eval "$(conda shell.bash hook)"; conda activate fungigut; set -u

cd "${WORK_DIR}"

nextflow run "${PIPELINE}/main.nf" \
    --input "${SAMPLESHEET}" \
    -c "${PIPELINE}/nextflow.config" \
    -profile docker,singularity
