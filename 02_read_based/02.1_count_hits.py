#!/usr/bin/env python3

import sys
import pysam
from collections import Counter
from pathlib import Path

bam_file = sys.argv[1]
count_file = sys.argv[2]
stats_file = sys.argv[3]

sample = Path(bam_file).stem

library_size = 0
mapped_primary = 0

seen = set()
counts = Counter()

with pysam.AlignmentFile(bam_file, "rb", threads=4) as bam:

    for read in bam.fetch(until_eof=True):

        if read.is_secondary or read.is_supplementary:
            continue

        library_size += 1

        if read.is_unmapped:
            continue

        mapped_primary += 1

        gene = read.reference_name
        key = (read.query_name, gene)

        if key not in seen:
            seen.add(key)
            counts[gene] += 1


total_hits = sum(counts.values())
detected_genes = len(counts)


with open(count_file, "w") as fh:
    for gene, hits in sorted(counts.items()):
        fh.write(f"{gene}\t{hits}\n")


with open(stats_file, "a") as fh:
    fh.write(
        f"{sample}\t"
        f"{library_size}\t"
        f"{mapped_primary}\t"
        f"{total_hits}\t"
        f"{detected_genes}\n")
