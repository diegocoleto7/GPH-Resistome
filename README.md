# GPH gut resistome

Analysis code for a study of the gut resistome of 166 healthy Spanish adults following a habitual omnivorous,
vegetarian or vegan diet (56 / 51 / 59). Shotgun faecal metagenomes are profiled for antimicrobial resistance
genes (ARGs) in two ways: read mapping against ResFinder, and annotation of assembled contigs for ARGs,
putative hosts and mobile genetic elements.

The repository holds the pipeline only. It contains no participant data and no manuscript.

## Layout

| Directory | What it does |
|---|---|
| `01_preprocessing` | Merge lanes, quality filtering with fastp, removal of human reads against GRCh38. |
| `02_read_based` | Mapping against the unclustered ResFinder database, hit counting, ViromeQC, clustering of the database at 90 % identity. |
| `03_assembly_based` | Assembly with MEGAHIT, assembly statistics, ARG annotation with ABRicate, extraction of ARG-carrying contigs, taxonomic classification with Kraken2 and TaxonKit, mobilome annotation with MAP. |
| `04_taxonomic_profiling` | Species profiles with MetaPhlAn 4. |
| `05_analysis` | The R project: everything from the pipeline outputs to the result tables. |

Steps 01 to 04 are bash and Python, written for a SLURM cluster. Every script takes its input and output
directories as arguments and prints its usage if called without them; nothing is hard-coded to one machine.
Scripts with an `#SBATCH` header are meant for `sbatch`, the rest for `bash`.

Step 05 is an RStudio project. `Rscript run_all.R` runs the 27 analysis scripts in order, each in its own R
process, writing a log per script to `logs/`. A single script can be run by pattern, for example
`Rscript run_all.R "2.-Microbiome"`.

## Order of execution

```
01_preprocessing/01_merge_lanes.sh        raw reads            -> <sample>_1.fq.gz / _2.fq.gz
01_preprocessing/02_fastp.sh                                   -> <sample>_filtered_R{1,2}.fastq.gz
01_preprocessing/03_host_removal.sh                            -> <sample>_hostclean_R{1,2}.fastq.gz

02_read_based/01_bowtie2_resfinder.sh     host-filtered reads  -> bam/<sample>.bam
02_read_based/02_count_hits.sh                                 -> hits_matrix.tsv, library_sizes.tsv
02_read_based/03_viromeqc.sh                                   -> report_<sample>.txt
02_read_based/04_merge_viromeqc.sh                             -> ViromeQC_all_reports.tsv
02_read_based/05_cdhit90_resfinder.sh     ResFinder all.fsa    -> resfinder_cdhit90.clstr

03_assembly_based/00_megahit.sh           host-filtered reads  -> <sample>.contigs.fa
03_assembly_based/01_assembly_stats.sh                         -> assembly_stats.tsv, contig_headers.tsv
03_assembly_based/02_abricate.sh                               -> <sample>.abricate_<db>.out
03_assembly_based/03_abricate_summary.sh                       -> <db>_summary.tsv
03_assembly_based/04_extract_arg_contigs.sh                    -> <sample>.ARG_contigs.fa
03_assembly_based/05_kraken2.sh           ARG contigs          -> <sample>.kraken.tsv
03_assembly_based/06_merge_kraken2.py                          -> kraken2_all_samples.tsv
03_assembly_based/07_taxonkit.sh                               -> taxonkit_results.tsv
03_assembly_based/08_map_samplesheet.sh   ARG contigs          -> samplesheet.csv
03_assembly_based/09_map.sh                                    -> results/<sample>/gff/*_mobilome.gff.gz
03_assembly_based/10_merge_map.py                              -> MAP_all_mobilome_annotations.tsv

04_taxonomic_profiling/01_metaphlan.sh    host-filtered reads  -> <sample>_profile.tsv
```

The R analysis then expects these files under `05_analysis/Data/Raw/`:

| Path | Produced by |
|---|---|
| `Counts/resfinder_hits_matrix_unclustered.tsv` | `02_read_based/02_count_hits.sh` |
| `ViromeQC/ViromeQC_all_reports.tsv` | `02_read_based/04_merge_viromeqc.sh` |
| `Assembly/assembly_stats.tsv`, `Assembly/contig_headers.tsv` | `03_assembly_based/01_assembly_stats.sh` |
| `Assembly/Abricate_resfinder/<sample>.abricate_resfinder.out` | `03_assembly_based/02_abricate.sh` |
| `Assembly/Kraken2/kraken2_all_samples.tsv` | `03_assembly_based/06_merge_kraken2.py` |
| `Assembly/Kraken2/taxonkit_results.tsv` | `03_assembly_based/07_taxonkit.sh` |
| `Assembly/MAP/MAP_all_mobilome_annotations.tsv` | `03_assembly_based/10_merge_map.py` |
| `Metaphlan/physeq_gtdb_species_decontam.rds` | see *Steps not included* below |
| `Metadata/GPH_metadata_completo.xlsx`, `Metadata/df_ffq_cleaned.csv` | study records, not in this repository |

## What ships with the repository

Only the reference tables that are not participant data, under `05_analysis/Data/Raw/`:

- `Phenotypes/phenotypes.tsv` — the ResFinder phenotype table, one row per database variant.
- `Phenotypes/resfinder_cdhit90.clstr` — the CD-HIT-EST clustering of ResFinder at 90 % identity.
- `Phenotypes/gene_family_curation.tsv` — the manual decisions that name 25 of the clusters. Together with the
  two files above this defines `gene_family`, the unit of every read-based ARG metric in the study.
- `WHO/who_mia_2024_antibiotics.tsv` — the 2024 WHO List of Medically Important Antimicrobials, used to flag
  the families encoding resistance to the top tiers.
- `Food_resistome/list_cia.txt` and `Food_resistome/gene_list.txt` — the gene list of the MASTER food-production
  resistome, applied as a complementary classification.

Everything else has to be regenerated. The sequencing data and the participant records are not here: the raw
reads are deposited in a public repository (accession in the paper) and the questionnaire and anthropometric
records are personal data.

`05_analysis/Data/Docs/Gene_family_curation.Rmd` documents the gene-family naming rule and prints every
decision; it is knitted at the end of `run_all.R`.

## Steps not included

Two things sit between the pipeline and the R analysis and are not in this repository:

1. **Merging the MetaPhlAn profiles** into a single species table.
2. **The decontamination step** that produces `Metaphlan/physeq_gtdb_species_decontam.rds`, the phyloseq object
   that `05_analysis/Data/Scripts/05.Prepare_phyloseq.Rmd` starts from.

Note also that MEGAHIT writes each assembly as `<sample>/final.contigs.fa` while every later step expects
`<sample>.contigs.fa`. `00_megahit.sh` bridges that with symbolic links at the end of the run.

## Software

Versions are fixed where a script pins them:

- MEGAHIT 1.2.9 and MetaPhlAn 4.2.2 with the index `mpa_vJan25_CHOCOPhlAnSGB_202503` (GTDB nomenclature), both
  loaded as cluster modules.
- Mobilome annotation through [EBI-Metagenomics/mobilome-annotation-pipeline](https://github.com/EBI-Metagenomics/mobilome-annotation-pipeline),
  run with Nextflow. It calls geNomad for plasmids and proviruses, ICEfinder2-lite for integrative and
  conjugative elements, IntegronFinder for integrons and ISEScan for insertion sequences.
- Kraken2 is run against the PlusPFP database, ABRicate against ResFinder, VFDB and PlasmidFinder.
- The remaining tools (fastp, Bowtie2, SAMtools, seqkit, CD-HIT-EST, ViromeQC, TaxonKit, aria2c) are loaded
  from conda environments named in each script; their versions are reported in the paper.

The R analysis was run on R 4.4.3 and needs: `tidyverse`, `here`, `knitr`, `data.table`, `readxl`, `broom`,
`broom.mixed`, `emmeans`, `glmmTMB`, `vegan`, `phyloseq`, `Maaslin2`, `patchwork`, `ggpubr`, `ggrepel`,
`ggh4x`, `ggpattern`, `ggalluvial`, `viridis`, `randomcoloR`.

## Key definitions

- **Gene family.** ResFinder stores many near-identical allelic variants of one determinant, so variants are
  clustered at 90 % nucleotide identity and each cluster is named by a fixed rule. The gene family, not the
  variant, is the unit of every read-based analysis.
- **CPM.** Hits per million host-filtered read pairs. A read pair whose mates fall on the same gene counts as
  one hit; a pair whose mates fall on two genes counts once for each.
- **WHO-critical.** A family is WHO-critical when more than half of its variants encode resistance to an
  antimicrobial in the top tiers of the 2024 WHO list: critically important, highest-priority critically
  important, or authorized for human use only.
- **Mobile element annotation.** A predicted element co-occurring with an ARG on the same assembled contig.
  This is co-location, not evidence that a gene has moved or can move.
