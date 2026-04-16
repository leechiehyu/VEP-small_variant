# VEP-small_variant
A workflow for genomic small variant annotation using Ensembl VEP and the GRCh38 reference genome.

## Overview
This repository contains scripts to automatically annotate VCF files, which includes preprocessing, batch submission to VEP, and final result aggregation.

## Directory Structure
- `VEP_script/`: Core annotation logic and submission scripts.
- `VEP_script/utils/`: Helper functions and shared utilities.

## Requirements
- Python 3.12.2
- BCFtools 1.18
- Anaconda3 23.3.1
- Ensembl VEP v115.1

## Quick start
For detailed information regarding this annotation workflow, please refer to the [VEP_script documentation](VEP_script/README.md)

Example usage: 
```bash
module load Python/3.12.2

cd VEP_script/
python 00_vep_batch_submitter.py /path/to/input/vcf/ /output/path/
```

## Reference Genomes
The workflow automatically detects the chromosome naming convention and applies the appropriate reference during normalization:
- **UCSC Style (with "chr" prefix):** Uses `Homo_sapiens_assembly38.fasta`.
- **Ensembl Style (without "chr" prefix):** Uses `Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz`.

### Customization: Changing Reference Genomes
If you need to use a different reference FASTA, you must manually update the `REF_FASTA` variable in `01_preprocess.sh`. 

> [!IMPORTANT]
> The script uses a conditional check to handle chromosome naming conventions (with or without the "chr" prefix). Ensure you update the correct path within the `if-else` block:
> - **With "chr" prefix**: Update `REF_FASTA` inside the `if` block.
> - **Without "chr" prefix**: Update `REF_FASTA` inside the `else` block.

**Example in `01_preprocess.sh`:**
```bash
if [[ "$checkCHR" =~ ^chr ]]; then
    # Update this path for 'chr' prefixed VCFs
    REF_FASTA=/path/to/your/custom_hg38_with_chr.fasta
else
    # Update this path for non-'chr' prefixed VCFs
    REF_FASTA=/path/to/your/custom_GRCh38_no_chr.fa.gz
fi
```

## Databases and plugins
### Data in the VEP cache
- **Ensembl database (VEP)**, version 115.1
- **MANE**, version 1.4

### Plugins
- **dbscSNV**, version 1.1
- **dbNSFP**, version 4.9a
  - **SIFT** ensembl 66, released Jan, 2015
  - **PROVEAN** ensembl 66, version 1.1, released Jan, 2015
  - **Polyphen-2**, version 2.2.2, released Feb, 2012
  - **LRT**, released November, 2009
  - **MutationTaster 2**, data retrieved in 2015
  - **MutationAssessor**, release 3
  - **FATHMM**, version 2.3
  - **fathmm-MKL**
  - **CADD**, version 1.7
  - **DANN**
  - **MetaSVM** and **MetaLR**
  - **M-CAP**, version 1.3
  - **GERP++**
- **SpliceAI** SNV and indel, version 1.3
- **LOEUF**, based on gnomAD v2.1.1, liftover from GRCh37
- **PrimateAI**, version 0.2
- **MaxEntScan**
- **DosageSensitivity**
- **satMutMPRA**
- **LoFtool**
- **pLI**
- **NMD**

### Custom datasets
- **DVD**, version 9.2
- **ClinVar**, released 20251109
- **RepeatMasker**, download from UCSC Table Browser, data last updated: 2022-10-18
- **gnomAD exome**, version 4.1
- **gnomAD genome**, version 4.1
- **gnomAD genome coverage**, version 3
- **Taiwan Biobank** SNV and indel, called by Jacob's lab
- **Taiwan Biobank** SNV and indel, released by Taiwan Biobank
- **MitoMap**
- **Taiwan Biobank** mitochondria SNV and indel, called by Jacob's lab
- **gnomAD mitochondria**, version 3.1
