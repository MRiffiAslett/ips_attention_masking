#!/bin/bash

# Variables
IMAGE_NAME="my-custom-image"
REPO_URL="https://github.com/MRiffiAslett/ips_attention_masking.git"
REPO_DIR="ips_attention_masking"
MAIN_SCRIPT_PATH="main.py"
DATA_SCRIPT_PATH="$REPO_DIR/data/megapixel_mnist/make_mnist.py"
DATA_DIR="$REPO_DIR/data/megapixel_mnist/dsets/megapixel_mnist_1500"

# 1. Build the Docker image
docker build -t $IMAGE_NAME .



# 2. Run the Docker container and mount the repository
docker run --gpus all -it --rm -v "$(pwd)":/app $IMAGE_NAME bash -c "
  # 3. Clone the repository inside the container
  if [ ! -d /app/$REPO_DIR ]; then
    git clone $REPO_URL /app/$REPO_DIR
  fi

  # 4. Run the data script to ensure data is downloaded
  python3 $DATA_SCRIPT_PATH --width 1500 --height 1500 $DATA_DIR

  # 5. Run the main script
  python3 $MAIN_SCRIPT_PATH
"


# # 2. Run the Docker container and mount the repository
# docker run -it --rm -v "$(pwd)":/app $IMAGE_NAME bash -c "
#   # 3. Clone the repository inside the container
#   if [ ! -d /app/$REPO_DIR ]; then
#     git clone $REPO_URL /app/$REPO_DIR
#   fi

#   # 4. Run the data script to ensure data is downloaded
#   python3 $DATA_SCRIPT_PATH --width 1500 --height 1500 $DATA_DIR

#   # 5. Run the main script
#   python3 $MAIN_SCRIPT_PATH
# "