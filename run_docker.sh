#!/bin/bash

# Start rootless Docker daemon
module load rootless-docker
start_rootless_docker.sh --quiet

# Set Docker host environment variable
export DOCKER_HOST=unix:///var/tmp/xdg_runtime_dir_$UID/docker.sock

# Variables
IMAGE_NAME="my-custom-image"
REPO_URL="https://github.com/MRiffiAslett/ips_attention_masking.git"
REPO_DIR="/app/ips_attention_masking"
MAIN_SCRIPT_PATH="/app/ips_attention_masking/main.py"
DATA_SCRIPT_PATH="/app/ips_attention_masking/data/megapixel_mnist/make_mnist.py"
DATA_DIR="/app/ips_attention_masking/data/megapixel_mnist/dsets/megapixel_mnist_1500"
OUTPUT_FILE="/app/results_regularized_28_28.txt"

# 1. Build the Docker image
docker build -t $IMAGE_NAME .

# 2. Run the Docker container and mount the repository
docker run --gpus all --runtime=nvidia -it --rm -v "$(pwd)":/app $IMAGE_NAME bash -c "
  # 3. Clone the repository inside the container
  if [ ! -d $REPO_DIR ]; then
    git clone $REPO_URL $REPO_DIR
  fi

  # 4. Run the data script to ensure data is downloaded
  python3 $DATA_SCRIPT_PATH --width 1500 --height 1500 $DATA_DIR

  # 5. Run the main script and capture the output
  unbuffer python3 $MAIN_SCRIPT_PATH | tee $OUTPUT_FILE
"
