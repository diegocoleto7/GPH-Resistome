#!/usr/bin/env python3

from pathlib import Path
import sys
import pandas as pd

input_dir = Path(sys.argv[1])

output_file = input_dir/"kraken2_all_samples.tsv"

column_names = [
    "classification_status",
    "contig_id",
    "assigned_taxon",
    "contig_length",
    "taxonomic_kmer_mapping"
]

all_tables = []

for kraken_file in sorted(input_dir.glob("GPH_*.kraken.tsv")):

    sample_id = kraken_file.name.removesuffix(".kraken.tsv")

    table = pd.read_csv(
        kraken_file,
        sep="\t",
        header=None,
        names=column_names,
        dtype=str
    )

    table.insert(0, "sample_id", sample_id)

    all_tables.append(table)


combined_table = pd.concat(
    all_tables,
    ignore_index=True
)

combined_table["contig_length"] = pd.to_numeric(
    combined_table["contig_length"],
    errors="coerce"
)

combined_table.to_csv(
    output_file,
    sep="\t",
    index=False
)

print(f"\nOutput file: {output_file}")
