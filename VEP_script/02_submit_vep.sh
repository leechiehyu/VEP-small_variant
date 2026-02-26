#!/bin/bash
#SBATCH -p ngs7G
#SBATCH -c 1
#SBATCH --mem=7g
#SBATCH -A MST109178
#SBATCH -J VEPsubmit_sample_name
#SBATCH --mail-user=
#SBATCH --mail-type=FAIL

SAMPLE="sample_name"
OUTPUT_VCF_PATH="output_vcf_path"
SCRIPT_PATH="${OUTPUT_VCF_PATH}/script"
NFILES_FILE="${OUTPUT_VCF_PATH}/vcf_file_list.txt"

# log file
TIME=`date +%Y%m%d%H%M`
logfile=${OUTPUT_VCF_PATH}/logs/${TIME}_${SAMPLE}_submit_vep.log

# Redirect standard output and error to the log file
exec > "$logfile" 2>&1

#################
# VEP array job #
#################
# Calculate last index for SLURM array
NFILES=$(cat "$NFILES_FILE" | wc -l)

if [ "$NFILES" -eq 0 ]; then
    echo "Info: No VCF files were generated during preprocessing. Skipping VEP annotation"
    exit 0
fi

LAST_INDEX=$((NFILES - 1))

# Submit the VEP array job
echo "Submitting $NFILES VEP tasks (Array: 0-$LAST_INDEX) using ${SCRIPT_PATH}/${SAMPLE}_vep.sh..."
VEP_ARRAY_ID=$(sbatch --parsable --array=0-$LAST_INDEX ${SCRIPT_PATH}/${SAMPLE}_vep.sh)

if [ -z "$VEP_ARRAY_ID" ]; then
    echo "Error: Failed to submit VEP array job 02_vep.sh"
    exit 1
fi

echo "VEP Array Job ID: $VEP_ARRAY_ID"


###################
# VCF combine job #
###################
# Submit the final merge job dependent on the VEP array completion
echo "Submitting final merge task with dependency on VEP Array $VEP_ARRAY_ID..."

MERGE_JOB_ID=$(sbatch --parsable --depend=afterok:$VEP_ARRAY_ID ${SCRIPT_PATH}/${SAMPLE}_post_vep.sh)

if [ -z "$MERGE_JOB_ID" ]; then
    echo "Error: Failed to submit merge job 03_post_vep.sh"
    exit 1
fi

echo "Merge Job ID: $MERGE_JOB_ID"
echo "Pipeline control complete. All tasks chained successfully."