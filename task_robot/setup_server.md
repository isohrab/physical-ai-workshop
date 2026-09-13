# Server setup — shared GPU for the workshop

Everything needed to stand this workshop up from scratch: server, security group, Hugging
Face resources, and what each participant needs on their own laptop.

1. **One server is enough.** One GPU box runs the policy for both tables — it's the same
   checkpoint (`sohrabark/smolvla_abc_mhp_v2_merged_20260805`) served twice, once per port, so
   the two tables' traffic never mixes. A single L4 (24GB) handles two SmolVLA (~500M params)
   inference streams at 30Hz without contention. No need to spin up a second box.
2. **Participants need an SSH key, and you must hand it out.** Their tunnel command
   (`ssh -N -L <PORT>:localhost:<PORT> ubuntu@<SERVER_IP>`) needs a private key that can log
   into the server. Nobody has one until you give it to them — see step 3, don't skip it.

---

## 1. Hugging Face resources used

| What                                                | Repo                                                                                                                  |
| --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Recorded demo dataset (Part 2)                      | [`sohrabark/abc_mhp_v2_merged_20260805`](https://huggingface.co/datasets/sohrabark/abc_mhp_v2_merged_20260805)        |
| Pretrained base policy, before fine-tuning (Part 3) | [`lerobot/smolvla_base`](https://huggingface.co/lerobot/smolvla_base)                                                 |
| Fine-tuned policy actually served (Part 3 & 4)      | [`sohrabark/smolvla_abc_mhp_v2_merged_20260805`](https://huggingface.co/sohrabark/smolvla_abc_mhp_v2_merged_20260805) |
| Dataset visualizer (Part 2)                         | [`lerobot/visualize_dataset`](https://huggingface.co/spaces/lerobot/visualize_dataset) Space                          |

All public — no HF token needed to run the workshop as-is (only needed if you re-record a
dataset or re-train and want to push your own repo to the Hub).

## 2. Provision the GPU box (once)

Any cloud GPU instance with an NVIDIA T4/L4/A10G (16GB+) or better, Ubuntu 22.04, works. Two
concurrent SmolVLA streams comfortably fit in 16GB. Concrete example on AWS:

```bash
# any region with GPU capacity; example below is illustrative, not a script to run verbatim
aws ec2 run-instances \
  --image-id <latest "Deep Learning Base OSS Nvidia Driver" AMI for your region> \
  --instance-type g6.xlarge \
  --key-name <your-key-pair> \
  --security-group-ids <sg-from-step-3> \
  --associate-public-ip-address \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":80,"VolumeType":"gp3"}}]'
```

Any other provider (GCP, Lambda Labs, RunPod, on-prem) works the same way — the only
requirements are: Ubuntu, one GPU, and root/sudo to write `~/.ssh/authorized_keys` for the
`ubuntu` (or equivalent) user. Note the box's public IP — that's `<SERVER_IP>` in both
notebooks.

## 3. Security group / firewall

Open **port 22 (SSH) to `0.0.0.0/0`** — any IP, not just the organizer's. Participants connect
from whatever network they're on (venue wifi, phone hotspot, hotel wifi), and that set of IPs
isn't known ahead of time, so there's nothing useful to lock the source IP to.

This is safe because of what's _not_ open: the policy server ports (8080, 8081) stay bound to
`localhost` on the box and are never exposed to the internet — participants only ever reach
them through their SSH tunnel. And the SSH key handed out (step 4) is itself restricted to
port-forwarding only, no shell. So an open port 22 doesn't buy an attacker anything beyond
what a restricted, temporary key already allows — and that key + instance both get killed
after the workshop (step 6).

## 4. Install lerobot + fetch the checkpoint

```bash
ssh ubuntu@<SERVER_IP>

sudo apt-get update && sudo apt-get install -y python3-venv tmux
python3 -m venv ~/lerobot-env
source ~/lerobot-env/bin/activate
pip install lerobot torch --extra-index-url https://download.pytorch.org/whl/cu121

# sanity check GPU is visible
python -c "import torch; print(torch.cuda.is_available())"   # must print True
```

The checkpoint (`sohrabark/smolvla_abc_mhp_v2_merged_20260805`) downloads automatically on
first request — no need to pre-fetch it, but doing a dry run once (below) avoids everyone's
first inference call eating the download time simultaneously.

## 5. Create a restricted SSH key and hand it to participants — DO NOT SKIP

Participants only need to **port-forward**, never a shell. Give them a key that can't do
anything else, so it's safe to hand to a whole room:

```bash
# on the server, as ubuntu
ssh-keygen -t ed25519 -f ~/workshop_key -N "" -C "workshop-participant"

cat >> ~/.ssh/authorized_keys <<EOF
no-pty,no-agent-forwarding,no-X11-forwarding,permitopen="localhost:8080",permitopen="localhost:8081",command="echo tunnel-only" $(cat ~/workshop_key.pub)
EOF
```

That restricted line means: even with this key, nobody gets a shell, agent forwarding, or
X11 — only local port-forwarding to 8080/8081. Safe to distribute widely, and it's why
opening SSH to any IP (step 3) isn't a risk.

**Distribute `workshop_key` (the private half) before people need it:**

- Send it the morning of / right before the session, not days ahead — shorter the key is
  "live," less exposure. Regular email is fine _because_ the key is forwarding-only and you
  revoke it after (next step) — don't reuse it for future workshops.
- If you have a Slack/Teams/Discord channel for the session, dropping it there as a file
  works just as well and is faster to reach everyone at once.
- Tell participants explicitly: save it as `workshop_key`, then `chmod 600 workshop_key`, then
  `ssh -i workshop_key -N -L <PORT>:localhost:<PORT> ubuntu@<SERVER_IP>`.

## 6. Start the two policy servers (one per table)

```bash
tmux new -s policy-a
source ~/lerobot-env/bin/activate
python -m lerobot.async_inference.policy_server --host=0.0.0.0 --port=8080
# Ctrl-B D to detach

tmux new -s policy-b
source ~/lerobot-env/bin/activate
python -m lerobot.async_inference.policy_server --host=0.0.0.0 --port=8081
# Ctrl-B D to detach
```

tmux keeps both running after you disconnect. `tmux attach -t policy-a` to check on one,
`tmux ls` to see both are alive.

## 7. What each participant needs on their own laptop

- **Hardware:** an SO-101 follower arm (+ leader arm if they'll record their own data),
  a USB camera, both connected to their laptop.
- **Software:** Python 3, `pip install lerobot`, and — only for Part 1 — [LeLab](https://github.com/huggingface/lelab)
  if they want to try recording/calibration themselves.
- **From the organizer:** `<SERVER_IP>`, their table's port (8080 or 8081), and
  `workshop_key` (step 5).
- Calibration IDs / camera index / robot port are specific to each participant's own arm —
  LeLab prints these out during calibration, they're not something the organizer provides.

## 8. Day-of checklist

- [ ] Both `tmux` sessions running, GPU visible (`nvidia-smi` shows two processes once
      participants connect)
- [ ] `<SERVER_IP>` and the table→port mapping (Table A → 8080, Table B → 8081) written
      somewhere participants can see
- [ ] `workshop_key` distributed to everyone before Part 4 starts

## 9. Teardown (after the workshop)

- [ ] Remove the `workshop_key` line from `~/.ssh/authorized_keys`
- [ ] `tmux kill-session -t policy-a` / `-t policy-b`
- [ ] Terminate the instance (or at least stop it) if it won't be reused
