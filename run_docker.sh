#!/bin/bash

# Start rootless Docker daemon
module load rootless-docker
start_rootless_docker.sh --quiet

# Variables
IMAGE_NAME="my-custom-image"
REPO_DIR="$(pwd)"
MAIN_SCRIPT_PATH="/app/ips_attention_masking/main.py"
DATA_SCRIPT_PATH="/app/ips_attention_masking/data/megapixel_mnist/make_mnist.py"
DATA_DIR="/app/ips_attention_masking/data/megapixel_mnist/dsets/megapixel_mnist_1500"
OUTPUT_FILE="/app/results_regularized_28_28.txt"

# Ensure the repository directory exists
if [ ! -d "$REPO_DIR" ]; then
  echo "Repository directory $REPO_DIR does not exist. Please clone it before running this script."
  exit 1
fi

# 1. Build the Docker image
docker build -t $IMAGE_NAME .

# 2. Run the Docker container and mount the repository
docker run --gpus all --shm-size=2g -it --rm -v "$REPO_DIR:/app/ips_attention_masking" $IMAGE_NAME bash -c "
  cd /app/ips_attention_masking
  # 3. Run the data script to ensure data is downloaded
  python3 $DATA_SCRIPT_PATH --width 1500 --height 1500 $DATA_DIR

  # 4. Run the main script and capture the output
  unbuffer python3 $MAIN_SCRIPT_PATH | tee $OUTPUT_FILE
"
