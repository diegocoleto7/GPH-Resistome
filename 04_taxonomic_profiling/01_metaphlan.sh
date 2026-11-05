#!/bin/bash
#SBATCH --job-name=metaphlan
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH -t 24:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch --array=0-<N-1> 01_metaphlan.sh <hostclean_dir> <out_dir> <metaphlan_db_dir>
#   hostclean_dir:    <muestra>_hostclean_R1.fastq.gz / _R2.fastq.gz (salida de 01_preprocessing/03_host_removal.sh)
#   out_dir:          <muestra>_profile.tsv y <muestra>.map.bz2
#   metaphlan_db_dir: carpeta de bases de datos de MetaPhlAn que contiene el indice
#   --array: una tarea por muestra, de 0 a N-1 (N = numero de ficheros *_hostclean_R1.fastq.gz)
# Perfil de abundancia relativa con MetaPhlAn 4.2.2 sobre el indice mpa_vJan25_CHOCOPhlAnSGB_202503 (GTDB).
# Si el perfil de una muestra ya existe, la tarea se salta: el array se puede relanzar.

set -euo pipefail

USAGE="Uso: sbatch --array=0-<N-1> 01_metaphlan.sh <hostclean_dir> <out_dir> <metaphlan_db_dir>"
IN_DIR="${1:?${USAGE}}"
OUT_DIR="${2:?${USAGE}}"
DB_DIR="${3:?${USAGE}}"
INDEX="mpa_vJan25_CHOCOPhlAnSGB_202503"
T="${SLURM_CPUS_PER_TASK:-12}"
mkdir -p "${OUT_DIR}"

module load metaphlan/4.2.2

mapfile -t SAMPLES < <(find "${IN_DIR}" -maxdepth 1 -type f -name "*_hostclean_R1.fastq.gz" \
    -printf "%f\n" | sed -E 's/_hostclean_R1\.fastq\.gz$//' | sort -V)

TOTAL=${#SAMPLES[@]}
if (( TOTAL == 0 )); then
    echo "ERROR: no hay *_hostclean_R1.fastq.gz en ${IN_DIR}" >&2
    exit 1
fi

TASK_ID="${SLURM_ARRAY_TASK_ID:-0}"
if (( TASK_ID >= TOTAL )); then
    echo "ERROR: TASK_ID=${TASK_ID} excede el numero de muestras (${TOTAL}). Revisa --array." >&2
    exit 1
fi

SID="${SAMPLES[$TASK_ID]}"
R1="${IN_DIR}/${SID}_hostclean_R1.fastq.gz"
R2="${IN_DIR}/${SID}_hostclean_R2.fastq.gz"
PROFILE="${OUT_DIR}/${SID}_profile.tsv"

if [[ ! -s "${R1}" || ! -s "${R2}" ]]; then
    echo "ERROR: falta R1 o R2 para ${SID}" >&2
    exit 1
fi

if [[ -s "${PROFILE}" ]]; then
    echo "[SKIP] ya existe ${PROFILE}"
    exit 0
fi

echo ">>> ${SID}"
metaphlan "${R1},${R2}" \
    --input_type fastq \
    --nproc "${T}" \
    --db_dir "${DB_DIR}" \
    --index "${INDEX}" \
    --mapout "${OUT_DIR}/${SID}.map.bz2" \
    -t rel_ab \
    -o "${PROFILE}"
