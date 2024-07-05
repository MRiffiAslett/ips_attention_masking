#!/bin/bash
#SBATCH --job-name=multi_script_job
#SBATCH --partition=its-2a30-01-part
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16GB
#SBATCH --gpus=1
#SBATCH --time=02:00:00
#SBATCH -e /home/mra23/ips_attention_masking/output/slurm-%x-%j.err
#SBATCH -o /home/mra23/ips_attention_masking/output/slurm-%x-%j.out

echo "Starting job script"

# Load the necessary module
module load rootless-docker

echo "Loaded rootless-docker module"

# Navigate to the working directory
cd /home/mra23/ips_attention_masking

echo "Changed directory to /home/mra23/ips_attention_masking"

# Execute the run_docker.sh script
bash run_models.sh

echo "Executed run_docker.sh script"
