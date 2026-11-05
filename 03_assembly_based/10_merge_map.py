#!/usr/bin/env python3
# Uso: python3 10_merge_map.py <results_dir> [output_file]   (por defecto <results_dir>/MAP_all_mobilome_annotations.tsv)

from pathlib import Path
import sys
from urllib.parse import unquote
import gzip
import re

import pandas as pd


# ============================================================
# Configuración
# ============================================================

if len(sys.argv) < 2:
    sys.exit("Uso: python3 10_merge_map.py <results_dir> [output_file]")
results_dir = Path(sys.argv[1])
output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else results_dir / "MAP_all_mobilome_annotations.tsv"

# Columnas estándar de un archivo GFF3
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


# ============================================================
# Localizar archivos
# ============================================================

gff_files = sorted(
    results_dir.glob("GPH_*/gff/GPH_*_mobilome.gff.gz"),
    key=lambda path: int(
        re.search(r"GPH_(\d+)", path.name).group(1)
    )
)

if not gff_files:
    raise RuntimeError(
        "No se encontraron archivos con el patrón:\n"
        "GPH_*/gff/GPH_*_mobilome.gff.gz"
    )

print(f"Archivos GFF encontrados: {len(gff_files)}")


# ============================================================
# Leer y combinar los GFF
# ============================================================

all_rows = []
malformed_lines = 0

for gff_file in gff_files:

    sample_match = re.match(
        r"(GPH_\d+)_mobilome\.gff\.gz$",
        gff_file.name
    )

    if sample_match is None:
        print(
            f"Nombre inesperado, se omite: {gff_file}"
        )
        continue

    sample_id = sample_match.group(1)

    print(f"Leyendo {sample_id}: {gff_file}")

    with gzip.open(gff_file, "rt", encoding="utf-8") as handle:

        for line_number, line in enumerate(handle, start=1):

            line = line.rstrip("\n")

            # Ignorar cabeceras, comentarios y líneas vacías
            if not line or line.startswith("#"):
                continue

            fields = line.split("\t")

            if len(fields) != 9:
                print(
                    f"Advertencia: línea con {len(fields)} columnas "
                    f"en {gff_file}, línea {line_number}. Se omite."
                )
                malformed_lines += 1
                continue

            row = dict(zip(gff_columns, fields))

            # sample_id como primera información identificativa
            row["sample_id"] = sample_id

            # Separar la columna de atributos:
            # ID=...;mobile_element_type=...;gc=...;conf=...
            attributes_text = row["attributes"]

            if attributes_text not in {"", "."}:

                for attribute in attributes_text.split(";"):

                    if not attribute:
                        continue

                    if "=" in attribute:
                        key, value = attribute.split("=", 1)

                        key = key.strip()
                        value = unquote(value.strip())

                        # Prefijo para evitar colisiones con columnas GFF
                        row[f"attr_{key}"] = value

                    else:
                        # Atributos sin "="
                        row[f"attr_{attribute.strip()}"] = True

            all_rows.append(row)


# ============================================================
# Crear tabla final
# ============================================================

if not all_rows:
    raise RuntimeError(
        "Los archivos fueron encontrados, pero no contenían "
        "anotaciones GFF válidas."
    )

combined_table = pd.DataFrame(all_rows)

# Convertir coordenadas a enteros
combined_table["start"] = pd.to_numeric(
    combined_table["start"],
    errors="coerce"
).astype("Int64")

combined_table["end"] = pd.to_numeric(
    combined_table["end"],
    errors="coerce"
).astype("Int64")


# ============================================================
# Ordenar columnas
# ============================================================

main_columns = [
    "sample_id",
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

attribute_columns = sorted(
    column
    for column in combined_table.columns
    if column.startswith("attr_")
)

combined_table = combined_table[
    main_columns + attribute_columns
]


# ============================================================
# Guardar resultado
# ============================================================

combined_table.to_csv(
    output_file,
    sep="\t",
    index=False,
    na_rep="NA"
)

print()
print(f"Archivo generado: {output_file}")
print(f"Muestras incluidas: {combined_table['sample_id'].nunique()}")
print(f"Anotaciones totales: {len(combined_table)}")
print(f"Contigs distintos: {combined_table['contig_id'].nunique()}")
print(f"Líneas mal formadas omitidas: {malformed_lines}")

print("\nNúmero de anotaciones por tipo:")
print(
    combined_table["feature_type"]
    .value_counts()
    .to_string()
)
