# Annotation scripts

## Directory structure
- `00_vep_batch_submitter.py`: Submit the slurm job(s) for annotating the VCFs under the given directory
- `01_preprocess.sh`: Normalize the input VCF and split the input VCF by chromosomes
- `02_submit_vep.sh`: Submit array job according to the number of VCFs
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
> [!NOTE]
> `00_vep_batch_submitter.py` is the entry point. It automatically generates sample-specific submission scripts (`sample_submit.sh`) and logs, then dispatches them to the Slurm scheduler. You **do not need** to run scripts 01-03 manually.

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

### Result columns
The final output is generated as a TSV file. Below are descriptions for some key columns:
| Column | Source | Description |
| :--- | :--- | :--- |
| CHROM <br/> POS <br/> REF <br/> ALT <br/> FILTER | Original input VCF | Variant information |
| Consequence <br/> IMPACT | VEP | The predicted effects that each allele of the variant may have on each transcript |
| SYMBOL <br/> Gene <br/> Feature_type <br/> Feature <br/> SYMBOL_SOURCE <br/> HGNC_ID | VEP <br/> (Ensembl, Refseq, HGNC, EntrezGene, RFAM...) | The gene symbol and its selected gene and transcript ID |
| EXON <br/> INTRON <br/> HGVSc <br/> HGVSp <br/> cDNA_position <br/> CDS_position <br/> Protein_position <br/> Amino_acids <br/> Codons | VEP <br/> (Ensembl, Refseq) | The coding and protein change nomenclature and other information if the variant affects the coding region of the selected transcript |
| Existing_variation <br/> CLIN_SIG <br/> SOMATIC <br/> PHENO | VEP | The known variants that are co-located with the variant |
| MANE <br/> MANE_SELECT <br/> MANE_PLUS_CLINICAL | VEP <br/> (MANE) | A flag indicating if the transcript is the MANE Select or MANE Plus Clinical transcript for the gene |
| SWISSPROT <br/> TREMBL <br/> UNIPARC <br/> UNIPROT_ISOFORM | VEP <br/> (UniProt) | The best match accessions for translated protein products from three UniProt-related databases (SWISSPROT, TREMBL and UniParc) |
