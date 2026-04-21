#!/bin/bash
#SBATCH -p ngs7G
#SBATCH -c 1
#SBATCH --mem=7g
#SBATCH -A MST109178
#SBATCH -J CONCAT_sample_name
#SBATCH --mail-user=
#SBATCH --mail-type=FAIL,END

SAMPLE="sample_name"
OUTPUT_VCF_PATH="output_vcf_path"
UTILS_PATH="input_script_path"

# modules and environment setting
module load biology
module load BCFtools/1.18
# log file print info setting
source $UTILS_PATH/utils/job_utils.sh
set -euo pipefail

TIME=`date +%Y%m%d%H%M`
logfile=${OUTPUT_VCF_PATH}/logs/${TIME}_${SAMPLE}_concat.log
start_job


#############################
echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Starting to concatenate VCFs\n"
#############################
cd $OUTPUT_VCF_PATH
rm -rf $OUTPUT_VCF_PATH/temp_chr
rm $OUTPUT_VCF_PATH/vcf_file_list.txt

# concat all annotated VCFs
echo -e "--- Concatenating annotated VCFs ---"

VEP_FILES=($(ls ${SAMPLE}.vep.chr*.vcf.gz | sort -V | sed '/chrM/{H;d}; $G' | sed '/^$/d'))
FINAL_VCF=${SAMPLE}.vep.vcf.gz

bcftools concat --naive-force -f <(printf "%s\n" "${VEP_FILES[@]}") -Oz -o $FINAL_VCF
bcftools index -t -f $FINAL_VCF

echo -e "$(date '+%Y-%m-%d %H:%M:%S') - Concat complete. Saving to $FINAL_VCF\n"

rm -rf ${SAMPLE}.vep.chr*.vcf.gz

variant_count=$(bcftools view -H "$FINAL_VCF" | wc -l)
echo -e "[INFO] - Total variants in final VEP annotated VCF: $variant_count"

FINAL_VCF_MANE=${SAMPLE}.vep.mane_plus_clinical.vcf.gz
bcftools index -t -f $FINAL_VCF_MANE
variant_count=$(bcftools view -H "$FINAL_VCF_MANE" | wc -l)
echo -e "[INFO] - Total variants with both MANE select and MANE plus clinical in VEP annotated VCF: ${variant_count}\n"


# generate tsv
bcftools +split-vep -H -f '%CHROM\t%POS\t%REF\t%ALT\t%FILTER\t%CSQ\n' -A tab $FINAL_VCF | \
    sed -E '1s/\[[0-9]+\]//g' | sed 's/\#//' > ${SAMPLE}.vep.tsv

bcftools +split-vep -H -f '%CHROM\t%POS\t%REF\t%ALT\t%FILTER\t%CSQ\n' -A tab $FINAL_VCF_MANE | \
    sed -E '1s/\[[0-9]+\]//g' | sed 's/\#//' > ${SAMPLE}.vep.mane_plus_clinical.tsv

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') Generate TSV done"


# clean up warning files
mkdir -p ${OUTPUT_VCF_PATH}/warnings
find . -maxdepth 1 -type f -name '*warnings.txt' -exec mv {} warnings/ \;
rmdir --ignore-fail-on-non-empty ${OUTPUT_VCF_PATH}/warnings

rm -f $UTILS_PATH/slurm*.out
