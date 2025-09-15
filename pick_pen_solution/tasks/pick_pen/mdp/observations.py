import torch

from isaaclab.managers import SceneEntityCfg
from isaaclab.sensors import FrameTransformer
from isaaclab.assets import Articulation, RigidObject
from isaaclab.envs import ManagerBasedRLEnv


def pen_grasped(
    env: ManagerBasedRLEnv,
    robot_cfg: SceneEntityCfg = SceneEntityCfg("robot"),
    ee_frame_cfg: SceneEntityCfg = SceneEntityCfg("ee_frame"),
    object_cfg: SceneEntityCfg = SceneEntityCfg("MechanicalPencil"),
    diff_threshold: float = 0.01,
    grasp_threshold: float = 0.40,
) -> torch.Tensor:
    """Check if an object(Pen) is grasped by the specified robot."""
    robot: Articulation = env.scene[robot_cfg.name]
    ee_frame: FrameTransformer = env.scene[ee_frame_cfg.name]
    object: RigidObject = env.scene[object_cfg.name]

    object_pos = object.data.root_pos_w
    end_effector_pos = ee_frame.data.target_pos_w[:, 1, :]
    pos_diff = torch.linalg.vector_norm(object_pos - end_effector_pos, dim=1)

    grasped = torch.logical_and(pos_diff < diff_threshold, robot.data.joint_pos[:, -1] < grasp_threshold)

    return grasped


def put_pen_to_plate(
    env: ManagerBasedRLEnv,
    robot_cfg: SceneEntityCfg = SceneEntityCfg("robot"),
    ee_frame_cfg: SceneEntityCfg = SceneEntityCfg("ee_frame"),
    object_cfg: SceneEntityCfg = SceneEntityCfg("MechanicalPencil"),
    plate_cfg: SceneEntityCfg = SceneEntityCfg("Plate"),
    x_range: tuple[float, float] = (-0.10, 0.10),
    y_range: tuple[float, float] = (-0.10, 0.10),
    diff_threshold: float = 0.05,
    grasp_threshold: float = 0.60,
) -> torch.Tensor:
    """Check if an object(pen) is placed on the specified plate."""
    robot: Articulation = env.scene[robot_cfg.name]
    ee_frame: FrameTransformer = env.scene[ee_frame_cfg.name]
    pen: RigidObject = env.scene[object_cfg.name]
    plate: RigidObject = env.scene[plate_cfg.name]

    plate_x, plate_y = plate.data.root_pos_w[:, 0], plate.data.root_pos_w[:, 1]
    pen_x, pen_y = pen.data.root_pos_w[:, 0], pen.data.root_pos_w[:, 1]
    pen_in_plate_x = torch.logical_and(pen_x < plate_x + x_range[1], pen_x > plate_x + x_range[0])
    pen_in_plate_y = torch.logical_and(pen_y < plate_y + y_range[1], pen_y > plate_y + y_range[0])
    pen_in_plate = torch.logical_and(pen_in_plate_x, pen_in_plate_y)

    end_effector_pos = ee_frame.data.target_pos_w[:, 1, :]
    pen_pos = pen.data.root_pos_w
    pos_diff = torch.linalg.vector_norm(pen_pos - end_effector_pos, dim=1)
    ee_near_to_pen = pos_diff < diff_threshold

    gripper_open = robot.data.joint_pos[:, -1] > grasp_threshold

    placed = torch.logical_and(pen_in_plate, ee_near_to_pen)
    placed = torch.logical_and(placed, gripper_open)

    return placed
