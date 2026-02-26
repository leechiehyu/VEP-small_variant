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


############################
# Extract max runtime from VEP array job logs
############################
MAX_RUNTIME_SEC=0
MAX_RUNTIME_HUMAN=""

echo "Message: Starting to search for log files of VEP array jobs in ${OUTPUT_VCF_PATH}/logs/*_sample_name_*_vep.log"

# find all relevant log files to extract the run time of vep
for LOG_FILE in ${OUTPUT_VCF_PATH}/logs/*_${SAMPLE}_*_vep.log; do
    if [ -f "$LOG_FILE" ]; then
        # 1. Use grep/awk/sed to find and extract the "Total runtime" line
        RUNTIME_LINE=$(grep "Total runtime:" "$LOG_FILE" || true)

        if [ -n "$RUNTIME_LINE" ]; then
            # 2. Extract hours, minutes, and seconds
            HOURS=$(echo "$RUNTIME_LINE" | awk '{print $3}' | tr -d ',')
            MINUTES=$(echo "$RUNTIME_LINE" | awk '{print $5}' | tr -d ',')
            SECONDS=$(echo "$RUNTIME_LINE" | awk '{print $7}')
            
            # 3. Transform to total seconds
            CURRENT_RUNTIME_SEC=$(( 10#$HOURS * 3600 + 10#$MINUTES * 60 + 10#$SECONDS ))
            
            # 4. Compare and store the maximum
            if [ "$CURRENT_RUNTIME_SEC" -gt "$MAX_RUNTIME_SEC" ]; then
                MAX_RUNTIME_SEC="$CURRENT_RUNTIME_SEC"
                MAX_RUNTIME_HUMAN="$RUNTIME_LINE (from $LOG_FILE)"
            fi
        # else: 如果找不到 Total runtime 行，則忽略這個 log
        fi
    fi
done

# 5. Print the result to the log file
if [ "$MAX_RUNTIME_SEC" -gt 0 ]; then    
    echo "==================================================================="
    echo "Max VEP Runtime:"
    echo "${MAX_RUNTIME_HUMAN}"
    echo -e "===================================================================\n"
else
    echo "Warning: No valid 'Total runtime:' record found in VEP array logs."
fi


#############################
echo -e "--- VEP annotation complete, start concat ---\n"
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

echo -e "--- Concat complete. Saving to $FINAL_VCF ---"

rm -rf ${SAMPLE}.vep.chr*.vcf.gz

variant_count=$(bcftools view -H "$FINAL_VCF" | wc -l)
echo -e "\n--- Total variants in final VEP annotated VCF: $variant_count ---"

FINAL_VCF_MANE=${SAMPLE}.vep.mane_plus_clinical.vcf.gz
bcftools index -t -f $FINAL_VCF_MANE
variant_count=$(bcftools view -H "$FINAL_VCF_MANE" | wc -l)
echo -e "--- Total variants with both MANE select and MANE plus clinical in VEP annotated VCF: $variant_count ---\n"


# generate tsv
bcftools +split-vep -H -f '%CHROM\t%POS\t%REF\t%ALT\t%FILTER\t%AC\t%CSQ\n' -A tab $FINAL_VCF | \
    sed -E '1s/\[[0-9]+\]//g' | sed 's/\#//' > ${SAMPLE}.vep.tsv

bcftools +split-vep -H -f '%CHROM\t%POS\t%REF\t%ALT\t%FILTER\t%AC\t%CSQ\n' -A tab $FINAL_VCF_MANE | \
    sed -E '1s/\[[0-9]+\]//g' | sed 's/\#//' > ${SAMPLE}.vep.mane_plus_clinical.tsv

echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') Generate TSV done"


# clean up warning files
mkdir -p ${OUTPUT_VCF_PATH}/warnings
find . -maxdepth 1 -type f -name '*warnings.txt' -exec mv {} warnings/ \;
rmdir --ignore-fail-on-non-empty ${OUTPUT_VCF_PATH}/warnings

rm -f $UTILS_PATH/slurm*.out
