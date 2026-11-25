#!/bin/bash

set -euo pipefail

PIPELINE="${1:?Uso: bash 09_map.sh <map_pipeline_dir> <samplesheet.csv> <work_dir>}"
SAMPLESHEET="${2:?Uso: bash 09_map.sh <map_pipeline_dir> <samplesheet.csv> <work_dir>}"
WORK_DIR="${3:?Uso: bash 09_map.sh <map_pipeline_dir> <samplesheet.csv> <work_dir>}"
SAMPLESHEET=$(realpath "${SAMPLESHEET}")
mkdir -p "${WORK_DIR}"

cd "${WORK_DIR}"

nextflow run "${PIPELINE}/main.nf" \
    --input "${SAMPLESHEET}" \
    -c "${PIPELINE}/nextflow.config" \
    -profile docker,singularity
