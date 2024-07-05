#!/bin/bash
#SBATCH --job-name=test_job
#SBATCH --partition=its-2a30-01-part
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2GB
#SBATCH --time=00:10:00
#SBATCH --chdir=/home/mra23/ips_attention_masking
#SBATCH -e /home/mra23/ips_attention_masking/output/slurm-test-%j.err
#SBATCH -o /home/mra23/ips_attention_masking/output/slurm-test-%j.out

echo "Starting test job script"
sleep 60
echo "Test job script completed"
