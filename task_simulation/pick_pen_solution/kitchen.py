from pathlib import Path

from leisaac.utils.constant import ASSETS_ROOT

import isaaclab.sim as sim_utils
from isaaclab.assets import AssetBaseCfg


"""Configuration for the Kitchen Scene"""
SCENES_ROOT = Path(ASSETS_ROOT) / "scenes"

KITCHEN_WITH_PEN_USD_PATH = str(SCENES_ROOT / "kitchen_with_pen" / "scene.usd")

KITCHEN_WITH_PEN_CFG = AssetBaseCfg(
    spawn=sim_utils.UsdFileCfg(
        usd_path=KITCHEN_WITH_PEN_USD_PATH,
    )
)
