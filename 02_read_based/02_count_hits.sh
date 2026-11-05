#!/bin/bash
#SBATCH --job-name=count_hits
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH -t 48:00:00
#SBATCH --output=logs/%x_%j.log
#SBATCH --error=logs/%x_%j.log

# Uso: sbatch 02_count_hits.sh <bam_dir> <out_dir> [sample]
#   bam_dir: <muestra>.bam (salida de 01_bowtie2_resfinder.sh)
#   out_dir: hits_matrix.tsv (genes × muestras), library_sizes.tsv, per_sample/<muestra>.counts.tsv
#   sample (opcional): procesa solo esa muestra
#
# Se excluyen secondary (0x100) y supplementary (0x800): -F 2304.
# Sobre los registros primarios (mapped + unmapped, R1 y R2):
#   - library_size = nº de registros primarios
#   - hits = registros mapeados (sin 0x4), contando cada (QNAME, gen) una vez
#     -> R1 y R2 en el mismo gen = 1 hit; en genes distintos = 1 hit a cada gen

set -euo pipefail

BAM_DIR="${1:?Uso: sbatch 02_count_hits.sh <bam_dir> <out_dir> [sample]}"
OUT_DIR="${2:?Uso: sbatch 02_count_hits.sh <bam_dir> <out_dir> [sample]}"
TEST_SAMPLE="${3:-}"
PER_SAMPLE_DIR="${OUT_DIR}/per_sample"
STATS_FILE="${OUT_DIR}/library_sizes.tsv"
MATRIX_FILE="${OUT_DIR}/hits_matrix.tsv"
THREADS="${SLURM_CPUS_PER_TASK:-4}"
EXCLUDE_FLAGS=2304
mkdir -p "${PER_SAMPLE_DIR}"

set +u; eval "$(conda shell.bash hook)"; conda activate samtools_env; set -u

shopt -s nullglob
FILES=( "${BAM_DIR}"/*.bam )
if [[ -n "${TEST_SAMPLE}" ]]; then
    FILES=( "${BAM_DIR}/${TEST_SAMPLE}.bam" )
fi
if [[ ${#FILES[@]} -eq 0 || ! -f "${FILES[0]}" ]]; then
    echo "ERROR: no hay BAMs en ${BAM_DIR}" >&2
    exit 1
fi

echo -e "sample\tlibrary_size\tmapped_primary\ttotal_hits\tdetected_genes" > "${STATS_FILE}"

for F in "${FILES[@]}"; do
    SAMPLE=$(basename "${F}" .bam)
    COUNT_FILE="${PER_SAMPLE_DIR}/${SAMPLE}.counts.tsv"
    echo ">>> ${SAMPLE}"

    samtools view -@ "${THREADS}" -F "${EXCLUDE_FLAGS}" "${F}" \
      | awk -v count_file="${COUNT_FILE}" -v sample="${SAMPLE}" '
            BEGIN{OFS="\t"}
            {
                lib++
                if (int($2/4) % 2 == 1) next      # unmapped
                mapped++
                key=$1 SUBSEP $3
                if (!(key in seen)) {
                    seen[key]=1
                    count[$3]++
                    hits++
                }
            }
            END {
                for (g in count) { print g, count[g] | "sort -k1,1 > " count_file; n++ }
                close("sort -k1,1 > " count_file)
                if (n == 0) printf "" > count_file
                print sample, lib+0, mapped+0, hits+0, n+0
            }' >> "${STATS_FILE}"
done

python3 - "${PER_SAMPLE_DIR}" "${MATRIX_FILE}" <<'PY'
import os, sys, glob

per_sample_dir, out = sys.argv[1], sys.argv[2]

samples, all_genes = {}, set()
for f in glob.glob(os.path.join(per_sample_dir, "*.counts.tsv")):
    s = os.path.basename(f).replace(".counts.tsv", "")
    d = {}
    with open(f) as fh:
        for line in fh:
            gene, hits = line.rstrip("\n").split("\t")
            d[gene] = hits
            all_genes.add(gene)
    samples[s] = d

def natural(s):
    head, _, num = s.rpartition("_")
    return (head, int(num)) if num.isdigit() else (s, 0)

names = sorted(samples, key=natural)
with open(out, "w") as fh:
    fh.write("gene\t" + "\t".join(names) + "\n")
    for g in sorted(all_genes):
        fh.write(g + "\t" + "\t".join(samples[s].get(g, "0") for s in names) + "\n")
print(f"Matriz: {out} | {len(all_genes)} genes x {len(names)} muestras")
PY
