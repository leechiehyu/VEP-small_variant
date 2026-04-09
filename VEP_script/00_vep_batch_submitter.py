import os
import sys
import subprocess
import time

"""
This script automates the submission of VEP annotation jobs for multiple samples. 
It generates bash scripts for each VCF file in the input directory. 

Usage:
    module load Python/3.12.2
    python 00_vep_batch_submitter.py <input_vcf_directory> <output_directory>

It will create a subdirectory `VEP_output` under the <output_directory>
"""

if len(sys.argv) != 3:
    print("\n" + "="*75)
    print("Error: Incorrect number of arguments.")
    print("\nUsage:")
    print(" python 00_vep_batch_submitter.py <input_vcf_directory> <output_directory>")
    print("\nExample:")
    print(" python 00_vep_batch_submitter.py /path/to/vcfs /path/to/output")
    print("="*75 + "\n")
    
    sys.exit(1)

# === Arguments ===
input_vcf_path = os.path.abspath(sys.argv[1])
input_script_path = os.path.dirname(os.path.abspath(__file__))
output_vcf_path = os.path.abspath(os.path.join(sys.argv[2], "VEP_output"))
script_output_dir = output_vcf_path
os.makedirs(script_output_dir, exist_ok=True)

vcf_files = [f for f in os.listdir(input_vcf_path) if f.endswith(".vcf.gz")]

# === Bash Script Template ===
bash_template = """#!/bin/bash

SAMPLE_ID={sample_id}
INPUT_VCF={input_vcf_path}/${{SAMPLE_ID}}.vcf.gz
INPUT_SCRIPT_PATH={input_script_path}
OUTPUT_VCF_PATH={output_vcf_path}/${{SAMPLE_ID}}
SCRIPT_PATH=${{OUTPUT_VCF_PATH}}/script

mkdir -p ${{SCRIPT_PATH}}

##########################
# sample specific script #
##########################
## Copy and customize preprocess script
cp ${{INPUT_SCRIPT_PATH}}/01_preprocess.sh ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_preprocess.sh
sed -i 's|sample_name|'${{SAMPLE_ID}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_preprocess.sh
sed -i 's|input_vcf|'${{INPUT_VCF}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_preprocess.sh
sed -i 's|output_vcf_path|'${{OUTPUT_VCF_PATH}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_preprocess.sh
sed -i 's|input_script_path|'${{INPUT_SCRIPT_PATH}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_preprocess.sh

## Copy and customize VEP submission script
cp ${{INPUT_SCRIPT_PATH}}/02_submit_vep.sh ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_submit_vep.sh
sed -i 's|sample_name|'${{SAMPLE_ID}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_submit_vep.sh
sed -i 's|output_vcf_path|'${{OUTPUT_VCF_PATH}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_submit_vep.sh

## Copy and customize VEP script
cp ${{INPUT_SCRIPT_PATH}}/02_vep.sh ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_vep.sh
sed -i 's|sample_name|'${{SAMPLE_ID}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_vep.sh
sed -i 's|output_vcf_path|'${{OUTPUT_VCF_PATH}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_vep.sh
sed -i 's|input_script_path|'${{INPUT_SCRIPT_PATH}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_vep.sh

## Copy and customize post-VEP script
cp ${{INPUT_SCRIPT_PATH}}/03_post_vep.sh ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_post_vep.sh
sed -i 's|sample_name|'${{SAMPLE_ID}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_post_vep.sh
sed -i 's|output_vcf_path|'${{OUTPUT_VCF_PATH}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_post_vep.sh
sed -i 's|input_script_path|'${{INPUT_SCRIPT_PATH}}'|g' ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_post_vep.sh


########################
# preprocess input VCF #
########################
echo "--- Stage 1: Submit 01_preprocess.sh for ${{SAMPLE_ID}} ---"

# Use --parsable to get Job ID
JOB_ID_01=$(sbatch --parsable ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_preprocess.sh)

if [ -z "${{JOB_ID_01}}" ]; then
    echo "Error: Failed to submit 01_preprocess.sh"
    exit 1
fi

echo "Stage 1 Job ID: ${{JOB_ID_01}}"


################################
# submit vep array control job #
################################
echo "--- Stage 2: Submit 02_submit_vep.sh for ${{SAMPLE_ID}} ---"

# Execute the VEP control job only after Stage 1 completes successfully
JOB_ID_02=$(sbatch --parsable --depend=afterok:${{JOB_ID_01}} ${{SCRIPT_PATH}}/${{SAMPLE_ID}}_submit_vep.sh)

if [ -z "${{JOB_ID_02}}" ]; then
    echo "Error: Failed to submit 02_submit_vep.sh"
    scancel "${{JOB_ID_01}}"
    exit 1
fi

echo "Stage 2 Job ID: ${{JOB_ID_02}}"
"""

# === Write the bash scripts and run them ===
for vcf in vcf_files:
    sample_id = vcf.replace(".vcf.gz", "")
    bash_path = os.path.join(script_output_dir, f"{sample_id}_submit.sh")

    with open(bash_path, "w") as f:
        f.write(bash_template.format(
            sample_id=sample_id,
            input_vcf_path=input_vcf_path,
            output_vcf_path=output_vcf_path,
            input_script_path=input_script_path
        ))

    subprocess.run(["sh", bash_path])
    time.sleep(1)
