#!/usr/bin/env bash
# Uso: bash 04_extract_arg_contigs.sh <abricate_resfinder_dir> <out_dir>
#   abricate_resfinder_dir: GPH_*.abricate_resfinder.out (la ruta del assembly se lee de la columna #FILE)
#   out_dir: GPH_*.ARG_contigs.fa, contig_ids/ y ARG_contig_extraction_summary.tsv

set -euo pipefail

# ============================================================
# Directorios
# ============================================================

ABRICATE_DIR="${1:?Uso: bash 04_extract_arg_contigs.sh <abricate_resfinder_dir> <out_dir>}"

OUTPUT_DIR="${2:?Uso: bash 04_extract_arg_contigs.sh <abricate_resfinder_dir> <out_dir>}"

IDS_DIR="${OUTPUT_DIR}/contig_ids"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$IDS_DIR"


set +u; eval "$(conda shell.bash hook)"; conda activate fungigut; set -u


# ============================================================
# Comprobar dependencias
# ============================================================

if ! command -v seqkit >/dev/null 2>&1; then
    echo "ERROR: seqkit no está disponible en el PATH." >&2
    exit 1
fi


# ============================================================
# Archivo resumen del filtrado
# ============================================================

SUMMARY="${OUTPUT_DIR}/ARG_contig_extraction_summary.tsv"

printf "sample\tassembly\tabricate_hits\tunique_ARG_contigs\tmatched_contigs\toutput_fasta\n" \
    > "$SUMMARY"


# ============================================================
# Procesar cada archivo de ABRicate
# ============================================================

shopt -s nullglob

reports=("${ABRICATE_DIR}"/GPH_*.abricate_resfinder.out)

if (( ${#reports[@]} == 0 )); then
    echo "ERROR: no se encontraron archivos de ABRicate en:" >&2
    echo "       ${ABRICATE_DIR}" >&2
    exit 1
fi


for report in "${reports[@]}"; do

    filename=$(basename "$report")

    # GPH_1.abricate_resfinder.out -> GPH_1
    sample=${filename%.abricate_resfinder.out}

    ids_file="${IDS_DIR}/${sample}.ARG_contig_ids.txt"
    output_fasta="${OUTPUT_DIR}/${sample}.ARG_contigs.fa"

    echo "Procesando ${sample}..."


    # --------------------------------------------------------
    # Número total de hits de ABRicate
    #
    # Un mismo contig puede aparecer varias veces si contiene:
    #   - varios ARG;
    #   - varios hits del mismo ARG;
    #   - hits parcialmente solapantes.
    # --------------------------------------------------------

    n_hits=$(
        awk -F '\t' '
            !/^#/ && NF >= 2 {
                n++
            }
            END {
                print n + 0
            }
        ' "$report"
    )


    # --------------------------------------------------------
    # Extraer IDs únicos de contigs con ARG
    #
    # Columna 2 de ABRicate = SEQUENCE
    # --------------------------------------------------------

    awk -F '\t' '
        !/^#/ && NF >= 2 && $2 != "" {
            print $2
        }
    ' "$report" |
        sed 's/\r$//' |
        sort -u \
        > "$ids_file"

    n_unique=$(wc -l < "$ids_file")


    # --------------------------------------------------------
    # Si no hay hits, no existe un assembly en la columna FILE
    # y no hay contigs que extraer.
    # --------------------------------------------------------

    if (( n_unique == 0 )); then

        echo "  Sin ARG detectados. Se omite la extracción."

        printf "%s\tNA\t%s\t0\t0\tNA\n" \
            "$sample" \
            "$n_hits" \
            >> "$SUMMARY"

        rm -f "$output_fasta"

        continue
    fi


    # --------------------------------------------------------
    # Recuperar la ruta del assembly desde la columna #FILE
    #
    # Todos los hits de un informe individual deberían proceder
    # del mismo archivo.
    # --------------------------------------------------------

    mapfile -t assembly_paths < <(
        awk -F '\t' '
            !/^#/ && NF >= 2 && $1 != "" {
                print $1
            }
        ' "$report" |
            sed 's/\r$//' |
            sort -u
    )


    if (( ${#assembly_paths[@]} != 1 )); then
        echo "ERROR: ${report} contiene ${#assembly_paths[@]} rutas de assembly diferentes." >&2
        printf "Rutas encontradas:\n" >&2
        printf "  %s\n" "${assembly_paths[@]}" >&2
        exit 1
    fi

    assembly="${assembly_paths[0]}"


    # --------------------------------------------------------
    # Comprobar que el assembly existe
    # --------------------------------------------------------

    if [[ ! -f "$assembly" ]]; then
        echo "ERROR: no se encuentra el assembly indicado por ABRicate:" >&2
        echo "       ${assembly}" >&2
        echo "Informe: ${report}" >&2
        exit 1
    fi


    # --------------------------------------------------------
    # Contar los IDs encontrados en el assembly
    #
    # seqkit grep usa por defecto el ID de la secuencia:
    #
    # >k141_104967 flag=1 multi=...
    #  \_________/
    #       ID
    # --------------------------------------------------------

    n_matched=$(
        seqkit grep \
            --pattern-file "$ids_file" \
            "$assembly" \
            -C
    )


    # --------------------------------------------------------
    # Extraer los contigs completos
    # --------------------------------------------------------

    seqkit grep \
        --pattern-file "$ids_file" \
        "$assembly" \
        --out-file "$output_fasta"


    # --------------------------------------------------------
    # Control de consistencia
    # --------------------------------------------------------

    if (( n_matched != n_unique )); then

        echo "ADVERTENCIA: no se encontraron todos los contigs."

        echo "  IDs únicos de ABRicate: ${n_unique}"
        echo "  Contigs encontrados:    ${n_matched}"

        assembly_ids="${IDS_DIR}/${sample}.assembly_ids.tmp"
        missing_ids="${IDS_DIR}/${sample}.missing_ARG_contig_ids.txt"

        seqkit seq \
            --name \
            --only-id \
            "$assembly" |
            sort -u \
            > "$assembly_ids"

        comm -23 \
            "$ids_file" \
            "$assembly_ids" \
            > "$missing_ids"

        rm -f "$assembly_ids"

        echo "  IDs no encontrados guardados en:"
        echo "  ${missing_ids}"

    else
        echo "  Todos los contigs fueron encontrados: ${n_matched}"
    fi


    # --------------------------------------------------------
    # Añadir al resumen
    # --------------------------------------------------------

    printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$sample" \
        "$assembly" \
        "$n_hits" \
        "$n_unique" \
        "$n_matched" \
        "$output_fasta" \
        >> "$SUMMARY"

done


echo
echo "Extracción terminada."
echo "Contigs con ARG:"
echo "  ${OUTPUT_DIR}"
echo
echo "Resumen:"
echo "  ${SUMMARY}"
