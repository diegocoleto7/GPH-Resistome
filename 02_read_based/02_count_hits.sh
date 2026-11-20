#!/bin/bash
set -euo pipefail

BAM_DIR="${1}"
OUT_DIR="${2}"
PER_SAMPLE_DIR="${OUT_DIR}/per_sample"
STATS_FILE="${OUT_DIR}/library_sizes.tsv"
MATRIX_FILE="${OUT_DIR}/hits_matrix.tsv"
THREADS=4
EXCLUDE_FLAGS=2304
mkdir -p "${PER_SAMPLE_DIR}"

shopt -s nullglob
FILES=( "${BAM_DIR}"/*.bam )

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
