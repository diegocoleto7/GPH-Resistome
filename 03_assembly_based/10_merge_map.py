#!/usr/bin/env python3

from pathlib import Path
import sys
from urllib.parse import unquote
import pandas as pd

results_dir = Path(sys.argv[1])
output_file =  results_dir / "MAP_all_mobilome_annotations.tsv"

gff_columns = [
    "contig_id",
    "annotation_source",
    "feature_type",
    "start",
    "end",
    "score",
    "strand",
    "phase",
    "attributes"
]

def parse_attributes(text):
    attributes = {}
    for attribute in text.split(";"):
        if "=" in attribute:
            key, value = attribute.split("=", 1)
            attributes[f"attr_{key.strip()}"] = unquote(
                value.strip()
            )
    return attributes


all_tables = []

for gff_file in sorted(
    results_dir.glob("GPH_*/gff/GPH_*_mobilome.gff.gz")
):

    sample_id = gff_file.name.removesuffix("_mobilome.gff.gz")

    table = pd.read_csv(
        gff_file,
        sep="\t",
        comment="#",
        header=None,
        names=gff_columns,
        compression="gzip",
        dtype=str,
        keep_default_na=False
    )

    if table.empty:
        continue

    table.insert(0, "sample_id", sample_id)

    table["start"] = table["start"].astype(int)
    table["end"] = table["end"].astype(int)

    attributes = pd.DataFrame(
        table["attributes"].map(parse_attributes).tolist(),
        index=table.index
    )

    table = pd.concat(
        [table, attributes],
        axis=1
    )

    all_tables.append(table)


combined_table = pd.concat(
    all_tables,
    ignore_index=True
)

combined_table.to_csv(
    output_file,
    sep="\t",
    index=False,
    na_rep="NA"
)
