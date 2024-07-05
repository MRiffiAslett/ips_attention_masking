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

LOGFILE=/home/mra23/ips_attention_masking/output/job_start.log
echo "Starting job script" > $LOGFILE

# Load the necessary module
module load rootless-docker
echo "Loaded rootless-docker module" >> $LOGFILE

# Navigate to the working directory
cd /home/mra23/ips_attention_masking
echo "Changed directory to /home/mra23/ips_attention_masking" >> $LOGFILE

echo "Starting Docker setup" >> $LOGFILE

# Start rootless Docker daemon
start_rootless_docker.sh --quiet

# Check if Docker started successfully
if ! docker info > /dev/null 2>&1; then
  echo "Docker did not start successfully" >> $LOGFILE
  exit 1
fi

echo "Docker started successfully" >> $LOGFILE

# Variables
IMAGE_NAME="my-custom-image"
REPO_DIR="$(pwd)"
RESULTS_DIR="$REPO_DIR/results"
SCRIPT_DIR="/app/ips_attention_masking"
MAIN_SCRIPT_1_PATH="$SCRIPT_DIR/main_1.py"
MAIN_SCRIPT_2_PATH="$SCRIPT_DIR/main_2.py"
MAIN_SCRIPT_3_PATH="$SCRIPT_DIR/main_3.py"
DATA_SCRIPT_PATH="$SCRIPT_DIR/data/megapixel_mnist/make_mnist.py"
DATA_DIR="$SCRIPT_DIR/data/megapixel_mnist/dsets/megapixel_mnist_1500"
OUTPUT_FILE_1="/app/results/results_masked_01_28_main_1.txt"
OUTPUT_FILE_2="/app/results/results_masked_01_28_main_2.txt"
OUTPUT_FILE_3="/app/results/results_masked_01_28_main_3.txt"

# Ensure the repository and results directories exist
if [ ! -d "$REPO_DIR" ]; then
  echo "Repository directory $REPO_DIR does not exist. Please clone it before running this script." >> $LOGFILE
  exit 1
fi

mkdir -p "$RESULTS_DIR"
echo "Repository and results directories are set up" >> $LOGFILE

# 1. Build the Docker image
docker build -t $IMAGE_NAME .
# Check if Docker image build was successful
if [ $? -ne 0 ]; then
  echo "Docker image build failed" >> $LOGFILE
  exit 1
fi

echo "Docker image built successfully" >> $LOGFILE

# 2. Run the Docker container and mount the repository and results directory
docker run --gpus all --shm-size=4g -it --rm -v "$REPO_DIR:/app/ips_attention_masking" -v "$RESULTS_DIR:/app/results" $IMAGE_NAME bash -c "
  cd /app/ips_attention_masking
  echo 'Running data script'
  # 3. Run the data script to ensure data is downloaded (if not already done)
  python3 $DATA_SCRIPT_PATH --width 1500 --height 1500 $DATA_DIR
  if [ $? -ne 0 ]; then
    echo 'Data script failed'
    exit 1
  fi
  echo 'Data script completed'

  echo 'Running main scripts'
  # 4. Run the main scripts sequentially and capture the output
  unbuffer python3 $MAIN_SCRIPT_1_PATH | tee $OUTPUT_FILE_1
  if [ $? -ne 0 ]; then
    echo 'Main script 1 failed'
    exit 1
  fi
  unbuffer python3 $MAIN_SCRIPT_2_PATH | tee $OUTPUT_FILE_2
  if [ $? -ne 0 ]; then
    echo 'Main script 2 failed'
    exit 1
  fi
  unbuffer python3 $MAIN_SCRIPT_3_PATH | tee $OUTPUT_FILE_3
  if [ $? -ne 0 ]; then
    echo 'Main script 3 failed'
    exit 1
  fi
  echo 'Main scripts completed'
" >> $LOGFILE 2>&1

echo "Completed Docker container run" >> $LOGFILE
