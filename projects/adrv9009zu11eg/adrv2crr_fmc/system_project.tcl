source ../../../scripts/adi_env.tcl
source $ad_hdl_dir/projects/scripts/adi_project_xilinx.tcl
source $ad_hdl_dir/projects/scripts/adi_board.tcl

set project_name [get_env_param ADI_PROJECT_NAME adrv9009zu11eg]

adi_project_create $project_name 0 [list \
  JESD_RX_M 8 \
  JESD_RX_L 4 \
  JESD_RX_S 1 \
  JESD_TX_M 8 \
  JESD_TX_L 8 \
  JESD_TX_S 1 \
  JESD_OBS_M 4 \
  JESD_OBS_L 4 \
  JESD_OBS_S 1 \
] "xczu11eg-ffvf1517-2-i"

adi_project_files $project_name [list \
  "system_top.v" \
  "../common/adrv9009zu11eg_spi.v" \
  "../common/adrv9009zu11eg_constr.xdc" \
  "../common/adrv2crr_fmc_constr.xdc" \
  "$ad_hdl_dir/library/common/ad_iobuf.v" ]

adi_project_run $project_name
