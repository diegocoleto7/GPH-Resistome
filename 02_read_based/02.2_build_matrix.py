#!/usr/bin/env python3

import os
import sys
import glob


per_sample_dir = sys.argv[1]
out = sys.argv[2]

samples = {}
all_genes = set()

files = glob.glob(os.path.join(per_sample_dir, "*.counts.tsv"))

for f in files:
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
    if num.isdigit():
        return (head, int(num))
    return (s, 0)


names = sorted(samples, key=natural)


with open(out, "w") as fh:
    fh.write("gene\t" + "\t".join(names) + "\n")
    for g in sorted(all_genes):
        values = [samples[s].get(g, "0") for s in names]
        fh.write(g + "\t" + "\t".join(values) + "\n")


print(f"Matriz: {out} | "f"{len(all_genes)} genes x {len(names)} muestras")
