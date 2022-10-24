# ip

if [info exists ::env(ADI_HDL_DIR)] {
  set ADI_HDL_DIR $::env(ADI_HDL_DIR)
  source $ADI_HDL_DIR/scripts/adi_env.tcl
} else {
  source ../../../scripts/adi_env.tcl
}

source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

global VIVADO_IP_LIBRARY

adi_ip_create axi_ltc235x
adi_ip_files axi_ltc235x [list \
    "$ad_hdl_dir/library/common/up_axi.v" \
    "axi_ltc235x_tb.v" \
    "axi_ltc235x_cmos.v" \
    "axi_ltc235x.v" ]

adi_ip_properties axi_ltc235x

set_property company_url {https://wiki.analog.com/resources/fpga/docs/axi_ltc235x} [ipx::current_core]

set cc [ipx::current_core]

ipx::save_core [ipx::current_core]

