# ip

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

adi_ip_create axi_ltc235x
adi_ip_files axi_ltc235x [list \
    "$ad_hdl_dir/library/common/up_axi.v" \
    "$ad_hdl_dir/library/common/up_adc_common.v" \
    "$ad_hdl_dir/library/common/ad_rst.v" \
    "$ad_hdl_dir/library/common/up_xfer_cntrl.v" \
    "$ad_hdl_dir/library/common/up_xfer_status.v" \
    "$ad_hdl_dir/library/common/up_clock_mon.v" \
    "$ad_hdl_dir/library/common/up_adc_channel.v" \
    "axi_ltc235x_cmos_tb.v" \
    "axi_ltc235x_tb.v" \
    "axi_ltc235x_cmos.v" \
    "axi_ltc235x.v" ]

adi_ip_properties axi_ltc235x

set_property company_url {https://wiki.analog.com/resources/fpga/docs/axi_ltc235x} [ipx::current_core]

ipx::save_core [ipx::current_core]

