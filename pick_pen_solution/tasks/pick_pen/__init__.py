import gymnasium as gym

gym.register(
    id="LeIsaac-SO101-PickPen-v0",
    entry_point="isaaclab.envs:ManagerBasedRLEnv",
    disable_env_checker=True,
    kwargs={
        "env_cfg_entry_point": f"{__name__}.pick_pen_env_cfg:PickPenEnvCfg",
    },
)

gym.register(
    id="LeIsaac-SO101-PickPen-Mimic-v0",
    entry_point=f"leisaac.enhance.envs:ManagerBasedRLLeIsaacMimicEnv",
    disable_env_checker=True,
    kwargs={
        "env_cfg_entry_point": f"{__name__}.pick_pen_mimic_env_cfg:PickPenMimicEnvCfg",
    },
)
