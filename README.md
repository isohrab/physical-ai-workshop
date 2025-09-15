# Physical AI Workshop

Welcome to the Physical AI Workshop! This hands-on workshop bridges **physical AI** (robotics, control, and embodied intelligence) with **vision-language models** and simulation using NVIDIA Isaac Sim and Isaac GR00T.

## Quick Start

### Environment Setup

**⚠️ Important: Start this setup process immediately as it takes 20+ minutes to complete.**

1. Open a terminal in the repository root directory
2. Make the setup script executable and run it:

```bash
chmod +x setup.sh
./setup.sh
```

**Setup Notes:**

- Keep the terminal open until the script completes
- If you encounter permissions issues, try: `bash setup.sh`
- You can open additional terminals for other tasks while setup runs

## Workshop Overview

This workshop teaches you to work with robot foundation models through practical, hands-on experience. You'll learn to load and process robot demonstration datasets, fine-tune the Isaac GR00T N1.5 foundation model for new robotic embodiments, create custom simulation scenes in Isaac Sim, and build complete robotics tasks from scratch including pick-and-place scenarios.

The curriculum progresses from basic dataset handling and model inference to advanced topics like custom task creation, scene design, and policy evaluation. By the end, you'll have practical experience with the complete pipeline from data preparation through model deployment, using industry-standard tools like Isaac Sim for simulation, GR00T for robot reasoning, and LeRobot data formats for training modern robotic systems.

## Workshop Structure

The workshop is organized into sequential modules:

- **Module 0**: Isaac Sim basics
- **Module 1**: Loading and working with robot datasets
- **Module 2**: Understanding model fine-tuning processes
- **Module 3**: Creating custom simulation scenes
- **Module 4**: Building robotics tasks from scratch
- **Module 5**: Running model inference and evaluation
- **Module 6**: Challenge exercises and extensions

## Run the notebooks

After completing the setup, open a terminal and launch Jupyter (or use VS Code):

```bash
conda activate base
jupyter notebook
# or
jupyter lab
```
