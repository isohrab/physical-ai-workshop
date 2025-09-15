#!/usr/bin/env bash
LOG=script.log
exec > >(tee -a "$LOG") 2>&1
# Setup script for workshop instances on Ubuntu 22.04
# Working dir: ~/workspace (override with WORKDIR)
# Optional env: HF_TOKEN, MODEL_S3_URI, GR00T_REPO, LEISAAC_REPO, ISAACLAB_REPO, MINICONDA_DIR

set -Eeuo pipefail

# --- refuse being sourced (bash/zsh) ---
if [ -n "${ZSH_EVAL_CONTEXT:-}" ]; then
  case $ZSH_EVAL_CONTEXT in *:file)
    echo "Do not 'source' this script. Run it: ./setup_workshop.sh"; return 1 2>/dev/null || exit 1;;
  esac
fi
if [ -n "${BASH_SOURCE:-}" ] && [ "${BASH_SOURCE[0]}" != "$0" ]; then
  echo "Do not 'source' this script. Run it: ./setup_workshop.sh"; return 1 2>/dev/null || exit 1
fi

### --- Config --- ###
WORKDIR="${WORKDIR:-$HOME/workspace}"
MINICONDA_DIR="${MINICONDA_DIR:-$HOME/miniconda3}"

# HF dataset
HF_DATASET_REPO="youliangtan/so101-table-cleanup"
DATASET_DIR="$WORKDIR/demo_data/so101-table-cleanup"


# Repos
GR00T_REPO="${GR00T_REPO:-https://github.com/NVIDIA/Isaac-GR00T.git}"
LEISAAC_REPO="${LEISAAC_REPO:-https://github.com/LightwheelAI/leisaac.git}"
ISAACLAB_REPO="${ISAACLAB_REPO:-https://github.com/isaac-sim/IsaacLab.git}"
ISAACLAB_VERSION_TAG="v2.1.1"   # for Isaac Sim 4.5

# Python/CUDA
PY310="3.10"
CUDA_TOOLKIT_LABEL="nvidia/label/cuda-11.8.0"
PYTORCH_WHL_INDEX="https://download.pytorch.org/whl/cu118"
PYTORCH_VER="2.5.1"
TORCHVISION_VER="0.20.1"

log()  { printf "\n[\033[1;34mINFO\033[0m] %s\n" "$*"; }
warn() { printf "\n[\033[1;33mWARN\033[0m] %s\n" "$*"; }
die()  { printf "\n[\033[1;31mERROR\033[0m] %s\n" "$*"; exit 1; }

mkdir -p "$WORKDIR"

### --- System packages --- ###
log "Installing base system packages…"
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  git curl wget ca-certificates tar unzip build-essential cmake pkg-config \
  python3-venv python3-pip gnupg lsb-release

### --- Miniconda (robust, no 'source' false positive) --- ###
#!/bin/bash

### Install cuda toolkit 12.4 
# 1) Add NVIDIA CUDA repo
DISTRO=ubuntu2204
wget https://developer.download.nvidia.com/compute/cuda/repos/$DISTRO/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update

# 2) Install the CUDA toolkit (nvcc, libs, tools)
sudo apt install -y cuda-toolkit-12-4

# 3) Set environment (bash/zsh init file)
echo 'export CUDA_HOME=/usr/local/cuda' >> ~/.bashrc
echo 'export PATH="$CUDA_HOME/bin:$PATH"' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH}"' >> ~/.bashrc
source ~/.bashrc


# Set the installation directory specifically for the ubuntu user
MINICONDA_DIR="/home/ubuntu/miniconda3"

# 1. Install Miniconda if it's not already there
if [ -d "$MINICONDA_DIR" ]; then
    echo "Miniconda is already installed at $MINICONDA_DIR. Skipping installation."
else
    echo "Installing Miniconda to $MINICONDA_DIR..."
    INSTALLER_PATH="/tmp/miniconda.sh"

    # Download the installer
    curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o "$INSTALLER_PATH"
    
    # Run the installer in batch mode to auto-accept the license
    # -b : Runs in non-interactive "batch" mode
    # -p : Specifies the installation path
    bash "$INSTALLER_PATH" -b -p "$MINICONDA_DIR"
    
    # Clean up the installer file
    rm -f "$INSTALLER_PATH"

    # 2. Make conda available in the user's BASH shell permanently
    # This command modifies /home/ubuntu/.bashrc
    echo "Initializing Conda for the BASH shell..."
    "$MINICONDA_DIR/bin/conda" init bash
    
    echo "Installation complete. Start a new shell or run 'source /home/ubuntu/.bashrc' for changes to take effect."
fi

# 3. Configure Conda for non-interactive use
# First, make the 'conda' command available in this current script session
source "$MINICONDA_DIR/etc/profile.d/conda.sh"
conda activate base

# Auto-approve all future conda actions
conda config --set always_yes true >/dev/null

# Auto-accept the Anaconda Repository Terms of Service (for Conda 24.1+)
conda tos accept >/dev/null

echo "Conda configuration updated."

### --- CLI tools in base env --- ###
log "Upgrading pip and installing CLI tools (huggingface_hub & awscli)…"
conda activate base
python -m pip install -U pip setuptools wheel
python -m pip install -U "huggingface_hub[cli]" awscli

### --- Hugging Face login (optional) --- ###
if [ -n "${HF_TOKEN:-}" ]; then
  log "Logging in to Hugging Face with HF_TOKEN…"
  huggingface-cli login --token "$HF_TOKEN" --add-to-git-credential >/dev/null || \
    warn "huggingface-cli login failed; proceeding unauthenticated."
else
  warn "HF_TOKEN not set. If the dataset is gated, export HF_TOKEN first."
fi

### --- 1) Download dataset --- ###
log "Downloading dataset $HF_DATASET_REPO → $DATASET_DIR…"
mkdir -p "$DATASET_DIR"
huggingface-cli download \
  --repo-type dataset "$HF_DATASET_REPO" \
  --local-dir "$DATASET_DIR" \
  --local-dir-use-symlinks False


### --- 3 & 4) gr00t env + install --- ###
log "Creating conda env 'gr00t' (Python $PY310)…"
if conda env list | grep -qE '^\s*gr00t\s'; then
  log "Environment 'gr00t' already exists."
else
  conda create -n gr00t "python=$PY310"
fi

log "Cloning gr00t…"
cd "$WORKDIR"
if [ -d "$WORKDIR/gr00t/.git" ]; then
  log "gr00t already cloned."
else
  git clone "$GR00T_REPO" gr00t
fi
cd "$WORKDIR/gr00t"
git fetch origin  # make sure the commit is present
git checkout 542df54fa6494611db89e7aafb85defcbf8aaeda


log "Installing gr00t…"
conda activate gr00t
python -m pip install -U pip setuptools
python -m pip install -e "$WORKDIR/gr00t[base]"

log "Installing flash-attn==2.7.1.post4 (no-build-isolation)…"
if ! python -m pip install --no-build-isolation "flash-attn==2.7.1.post4"; then
  warn "flash-attn install failed. Ensure CUDA/PyTorch compatibility; continuing."
fi

### --- 4) IsaacLab / Isaac Sim env --- ###
log "Creating conda env 'leisaac' (Python $PY310)…"
if conda env list | grep -qE '^\s*leisaac\s'; then
  log "Environment 'leisaac' already exists."
else
  conda create -n leisaac "python=$PY310"
fi

conda activate leisaac
log "Installing CUDA Toolkit 11.8 via conda…"
conda install -c "$CUDA_TOOLKIT_LABEL" cuda-toolkit

log "Installing PyTorch $PYTORCH_VER / torchvision $TORCHVISION_VER (cu118)…"
python -m pip install -U pip
python -m pip install "torch==$PYTORCH_VER" "torchvision==$TORCHVISION_VER" --index-url "$PYTORCH_WHL_INDEX"

log "Installing Isaac Sim 4.5.0…"
python -m pip install 'isaacsim[all,extscache]==4.5.0' --extra-index-url https://pypi.nvidia.com

log "Installing build tools for IsaacLab…"
sudo apt-get install -y --no-install-recommends cmake build-essential

log "Cloning IsaacLab and checking out $ISAACLAB_VERSION_TAG…"
cd "$WORKDIR"
if [ -d "$WORKDIR/IsaacLab/.git" ]; then
  log "IsaacLab already cloned."
else
  git clone "$ISAACLAB_REPO" IsaacLab
fi
cd "$WORKDIR/IsaacLab"
git fetch --tags
git checkout "$ISAACLAB_VERSION_TAG"

log "Running IsaacLab installer…"
chmod +x ./isaaclab.sh
./isaaclab.sh --install

### --- 5,6) leisaac repo + installs --- ###
log "Cloning leisaac…"
cd "$WORKDIR"
if [ -d "$WORKDIR/leisaac/.git" ]; then
  log "leisaac already cloned."
else
  git clone "$LEISAAC_REPO" leisaac
fi

log "Installing leisaac extras…"
cd "$WORKDIR/leisaac"
python -m pip install -e "source/leisaac"
python -m pip install -e "source/leisaac[gr00t]"
python -m pip install -e "source/leisaac[lerobot-async]"

### --- 7) Download Lightwheel assets (placeholder) --- ###
# Example (adjust as needed):
# aws s3 sync s3://lightwheel-assets/path "$WORKDIR/leisaac/assets"
warn "Asset download not configured. Add your command to fetch Lightwheel assets."

### --- 8) GNOME Mutter timeout to 120s --- ###
if command -v gsettings >/dev/null 2>&1; then
  log "Setting GNOME Mutter check-alive-timeout to 120000 ms…"
  gsettings set org.gnome.mutter check-alive-timeout 120000 || \
    warn "Failed to set GNOME setting (headless or schema missing)."
else
  warn "gsettings not found; skipping GNOME tweak."
fi

### --- 9) Clone workshop repository --- ###
log "Cloning workshop repository…"
cd "$WORKDIR"
if [ -d "$WORKDIR/physical-ai-workshop/.git" ]; then
  log "Workshop repository already cloned."
else
  git clone https://github.com/isohrab/physical-ai-workshop.git physical-ai-workshop
fi

### --- 10) Copy pick_pen task to leisaac --- ###
log "Copying pick_pen task to leisaac tasks directory…"
PICK_PEN_SOURCE="$WORKDIR/physical-ai-workshop/pick_pen/tasks/pick_pen"
PICK_PEN_DEST="$WORKDIR/leisaac/source/leisaac/leisaac/tasks"

if [ -d "$PICK_PEN_SOURCE" ]; then
  mkdir -p "$PICK_PEN_DEST"
  cp -r "$PICK_PEN_SOURCE" "$PICK_PEN_DEST/"
  log "pick_pen task copied successfully to $PICK_PEN_DEST/pick_pen"
else
  warn "pick_pen task source directory not found at $PICK_PEN_SOURCE"
fi

### --- 11) Install Jupyter and register kernels --- ###
log "Installing Jupyter in base conda environment…"
conda activate base
python -m pip install -U jupyterlab jupyter ipykernel

log "Registering gr00t environment as Jupyter kernel…"
conda activate gr00t
python -m pip install ipykernel
python -m ipykernel install --user --name gr00t --display-name "Python (gr00t)"

log "Registering leisaac environment as Jupyter kernel…"
conda activate leisaac
python -m pip install ipykernel
python -m ipykernel install --user --name leisaac --display-name "Python (leisaac)"

conda activate base

### --- 12) First-run notice --- ###
cat <<'NOTE'

================================================================================
Isaac Sim first launch may take 10–30 minutes. For the first run, wait until:
   Isaac Sim Full App is loaded.
================================================================================

NOTE

log "Setup completed successfully."
