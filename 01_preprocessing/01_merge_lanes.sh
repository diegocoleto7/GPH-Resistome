#!/bin/bash

set -euo pipefail

RAW_DIR="${1:?bash 01_merge_lanes.sh <raw_dir> <out_dir>}"
OUT_DIR="${2:?bash 01_merge_lanes.sh <raw_dir> <out_dir>}"
mkdir -p "${OUT_DIR}"

for dir in "${RAW_DIR}"/*/; do
    sample=$(basename "${dir}")
    files_1=( "${dir}"*_1.fq.gz )
    files_2=( "${dir}"*_2.fq.gz )

    if [[ ${#files_1[@]} -eq 1 ]]; then
        ln -sf "$(realpath "${files_1[0]}")" "${OUT_DIR}/${sample}_1.fq.gz"
        ln -sf "$(realpath "${files_2[0]}")" "${OUT_DIR}/${sample}_2.fq.gz"
        echo "${sample}: symlink OK"
    else
        cat "${files_1[@]}" > "${OUT_DIR}/${sample}_1.fq.gz"
        cat "${files_2[@]}" > "${OUT_DIR}/${sample}_2.fq.gz"
        echo "${sample}: merged OK"
    fi
done
