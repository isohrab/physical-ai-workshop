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

This workshop teaches you to work with robot foundation models through practical, hands-on
experience. It has two tracks:

- **Simulation** ([`task_simulation/`](task_simulation/)) — meet Isaac Sim, understand how a
  manipulation scene and task are defined, then run a fine-tuned **GR00T N1.5** policy on a
  simulated SO-101 arm and watch it attempt a pick-and-place task.
- **Real robot** ([`task_robot/`](task_robot/)) — walk the LeRobot pipeline end to end (record
  demonstrations → dataset → fine-tune **SmolVLA** → run the policy), then drive a real SO-101 arm
  with a trained policy.

Between them you'll see the same idea on two embodiments: a vision-language-action model, given
camera images and a plain-English instruction, producing joint targets — and the tooling
(Isaac Sim, Isaac Lab, LeRobot dataset formats, GR00T, SmolVLA) that makes that practical.

## Workshop Structure

**Simulation track** — [`task_simulation/notebooks/`](task_simulation/notebooks/), in order:

| Notebook | What it covers | Hands-on? |
| --- | --- | --- |
| `01_isaac_sim.ipynb` | Isaac Sim basics: build a tiny scene, try NVIDIA's pre-trained policies | ✅ yes |
| `02_sim_scene.ipynb` | The `kitchen_with_orange` scene — how static geometry becomes physics objects | 📖 reading |
| `03_sim_task.ipynb` | The `PickOrange` task — success conditions, observations, domain randomization | 📖 reading |
| `04_inference.ipynb` | **Run the fine-tuned GR00T N1.5 policy in the simulator and evaluate it** | ✅ yes |
| `05_challenges.ipynb` | Teleoperation, RL rewards, gripper physics — pick one and explore | ✅ yes |

**Real robot track** — [`task_robot/`](task_robot/): `01_lerobot_pipeline.ipynb`, then
`02_challenge.ipynb`.

## Run the notebooks

After completing the setup, open a terminal and launch Jupyter (or use VS Code):

```bash
conda activate base
jupyter notebook
# or
jupyter lab
```
