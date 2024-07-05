#!/bin/bash
#SBATCH --job-name=multi_script_job
#SBATCH --partition=its-2a30-01-part
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16GB
#SBATCH --gpus-per-task=1
#SBATCH --gpu-bind=single:1
#SBATCH --time=02:00:00
#SBATCH -e /home/mra23/output/slurm-%x-%j.err
#SBATCH -o /home/mra23/output/slurm-%x-%j.out

# Load the necessary module and run the script
module load rootless-docker
bash run_docker.sh
