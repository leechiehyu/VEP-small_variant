# Annotation scripts

## Directory structure
- `00_vep_batch_submitter.py`: Submit the slurm job(s) for annotating the VCFs under the given directory
- `01_preprocess.sh`: Normalize the input VCF and split the input VCF by chromosomes
- `02_submit_vep.py`: Submit array job according to the number of VCFs
- `02_vep.sh`: Annotate small variants with Ensembl VEP
- `03_post_vep.sh`: Remove the temporary files and merge the annotation files
- `utils/`
  - `job_utils.sh`: Log file print information setting
  - `mane_plus_clinical.wchr.buffer5000bp.bed`: 65 MANE Plus Clinical transcript region (with chr)
  - `mane_plus_clinical.wochr.buffer5000bp.bed`: 65 MANE Plus Clinical transcript region (without chr)

## Usage
### Required data
- Small variant (SNV, indel) VCF(s), both sample-level and joint-called VCFs are supported.
  > The VCFs must be placed in the same directory if multiple VCFs are being processed at the same time.

### Running pipeline
```
module load Python/3.12.2
python 00_vep_batch_submitter.py <input_vcf_directory> <output_directory>
```
It will create a subdirectory `VEP_output` under the <output_directory>

## Output
### Directory structure
```
VEP_output
  │⎯ sample1_submit.sh
  │⎯ sample1/
  │     │⎯ script/
  │     │     │⎯ sample1_preprocess.sh
  │     │     │⎯ sample1_submit_vep.sh
  │     │     │⎯ sample1_vep.sh
  │     │     ╵⎯ sample1_post_vep.sh
  │     │⎯ logs/
  │     │     │⎯ DATETIME_sample1_preprocess.log
  │     │     │⎯ DATETIME_sample1_submit_vep.log
  │     │     │⎯ DATETIME_sample1_chr1_vep.log
  │     │     │⎯ ...
  │     │     ╵⎯ DATETIME_sample1_concat.log
  │     │⎯ sample1.cleaned.vcf.gz
  │     │⎯ sample1.cleaned.vcf.gz.tbi
  │     │⎯ sample1.vep.tsv
  │     │⎯ sample1.vep.vcf.gz
  │     │⎯ sample1.vep.vcf.gz.tbi
  │     │⎯ sample1.vep.mane_plus_clinical.tsv
  │     │⎯ sample1.vep.mane_plus_clinical.vcf.gz
  │     ╵⎯ sample1.vep.mane_plus_clinical.vcf.gz.tbi
  │⎯ sample2_submit.sh
  │⎯ sample2/
  ┊
```

### Result files
- `{sample}.cleaned.vcf.gz`: The VCF after normalization and remains only chr1-22, X, Y, M.
- `{sample}.vep.tsv`, `{sample}.vep.vcf.gz`: All variants, MANE Select transcripts are prioritized over MANE Plus Clinical when selecting transcripts.
- `{sample}.vep.mane_plus_clinical.tsv`, `{sample}.vep.mane_plus_clinical.vcf.gz`: Only variants located in the genes that have both MANE Select and MANE Plus Clinical transcripts; the selected transcripts in this file remain the MANE Plus Clinical transcript rather than the MANE Select transcripts.
