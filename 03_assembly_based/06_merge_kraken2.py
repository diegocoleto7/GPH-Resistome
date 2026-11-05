#!/usr/bin/env python3
# Uso: python3 06_merge_kraken2.py <input_dir> [output_file]   (por defecto <input_dir>/kraken2_all_samples.tsv)

from pathlib import Path
import sys
import pandas as pd
import re

# Directorio donde están los archivos GPH_*.kraken.tsv
if len(sys.argv) < 2:
    sys.exit("Uso: python3 06_merge_kraken2.py <input_dir> [output_file]")
input_dir = Path(sys.argv[1])

# Archivo de salida
output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else input_dir / "kraken2_all_samples.tsv"

column_names = [
    "classification_status",
    "contig_id",
    "assigned_taxon",
    "contig_length",
    "taxonomic_kmer_mapping"
]

all_tables = []

for kraken_file in sorted(input_dir.glob("GPH_*.kraken.tsv")):

    # Extraer GPH_100, GPH_101, etc.
    match = re.match(r"(GPH_\d+)\.kraken\.tsv$", kraken_file.name)

    if match is None:
        print(f"Ignorando archivo con nombre inesperado: {kraken_file.name}")
        continue

    sample_id = match.group(1)

    print(f"Leyendo {kraken_file.name}")

    try:
        table = pd.read_csv(
            kraken_file,
            sep="\t",
            header=None,
            names=column_names,
            dtype=str
        )

    except pd.errors.EmptyDataError:
        print(f"Archivo vacío, se omite: {kraken_file.name}")
        continue

    # Añadir sample_id como primera columna
    table.insert(0, "sample_id", sample_id)

    all_tables.append(table)

if not all_tables:
    raise RuntimeError(
        "No se encontraron archivos GPH_*.kraken.tsv con datos."
    )

combined_table = pd.concat(
    all_tables,
    ignore_index=True
)

# Convertir la longitud a numérico
combined_table["contig_length"] = pd.to_numeric(
    combined_table["contig_length"],
    errors="coerce"
)

combined_table.to_csv(
    output_file,
    sep="\t",
    index=False
)

print(f"\nArchivo generado: {output_file}")
print(
    f"Número de muestras: "
    f"{combined_table['sample_id'].nunique()}"
)
print(f"Número total de contigs: {len(combined_table)}")
print("\nEstados de clasificación:")
print(combined_table["classification_status"].value_counts())
