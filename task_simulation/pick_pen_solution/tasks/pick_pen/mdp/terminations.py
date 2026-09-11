from __future__ import annotations

import torch
from typing import List

from isaaclab.assets import RigidObject
from isaaclab.managers import SceneEntityCfg
from isaaclab.envs import ManagerBasedRLEnv

from leisaac.utils.robot_utils import is_so101_at_rest_pose


def task_done(
    env: ManagerBasedRLEnv,
    pens_cfg: List[SceneEntityCfg],
    plate_cfg: SceneEntityCfg,
    x_range: tuple[float, float] = (-0.10, 0.10),
    y_range: tuple[float, float] = (-0.10, 0.10),
    height_range: tuple[float, float] = (-0.07, 0.07),
) -> torch.Tensor:
    """Determine if the pen picking task is complete.

    This function checks whether all success conditions for the task have been met:
    1. pen is within the target x/y range
    2. pen is below a minimum height
    3. robot come back to the rest pose

    Args:
        env: The RL environment instance.
        pens_cfg: Configuration for the pen entities.
        plate_cfg: Configuration for the plate entity.
        x_range: Range of x positions of the object for task completion.
        y_range: Range of y positions of the object for task completion.
        height_range: Range of height (z position) of the object for task completion.
    Returns:
        Boolean tensor indicating which environments have completed the task.
    """
    done = torch.ones(env.num_envs, dtype=torch.bool, device=env.device)
    plate: RigidObject = env.scene[plate_cfg.name]
    plate_x = plate.data.root_pos_w[:, 0] - env.scene.env_origins[:, 0]
    plate_y = plate.data.root_pos_w[:, 1] - env.scene.env_origins[:, 1]
    plate_height = plate.data.root_pos_w[:, 2] - env.scene.env_origins[:, 2]

    for pen_cfg in pens_cfg:
        pen: RigidObject = env.scene[pen_cfg.name]
        pen_x = pen.data.root_pos_w[:, 0] - env.scene.env_origins[:, 0]
        pen_y = pen.data.root_pos_w[:, 1] - env.scene.env_origins[:, 1]
        pen_height = pen.data.root_pos_w[:, 2] - env.scene.env_origins[:, 2]

        done = torch.logical_and(done, pen_x < plate_x + x_range[1])
        done = torch.logical_and(done, pen_x > plate_x + x_range[0])
        done = torch.logical_and(done, pen_y < plate_y + y_range[1])
        done = torch.logical_and(done, pen_y > plate_y + y_range[0])
        done = torch.logical_and(done, pen_height < plate_height + height_range[1])
        done = torch.logical_and(done, pen_height > plate_height + height_range[0])

    joint_pos = env.scene["robot"].data.joint_pos
    joint_names = env.scene["robot"].data.joint_names
    done = torch.logical_and(done, is_so101_at_rest_pose(joint_pos, joint_names))

    return done
