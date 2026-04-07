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
- **RepeatMasker**, download from UCSC Table Browser
- **gnomAD exome**, version 4.1
- **gnomAD genome**, version 4.1
- **gnomAD genome coverage**, version 3
- **Taiwan Biobank** SNV and indel, called by Jacob's lab
- **Taiwan Biobank** SNV and indel, released by Taiwan Biobank
- **MitoMap**
- **Taiwan Biobank** mitochondria SNV and indel, called by Jacob's lab
- **gnomAD mitochondria**, version 3.1
