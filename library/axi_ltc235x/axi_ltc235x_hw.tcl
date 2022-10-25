# ip

package require qsys 14.0
package require quartus::device

source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_intel.tcl

adi_ip_create axi_ltc235x {AXI LTC235x Interface}
adi_ip_files axi_ltc235x [list \
    $ad_hdl_dir/library/common/up_axi.v \
    $ad_hdl_dir/library/common/up_adc_common.v \
    $ad_hdl_dir/library/common/ad_rst.v \
    $ad_hdl_dir/library/common/up_xfer_cntrl.v \
    $ad_hdl_dir/library/common/up_xfer_status.v \
    $ad_hdl_dir/library/common/up_clock_mon.v \
    $ad_hdl_dir/library/common/up_adc_channel.v \
    axi_ltc235x_cmos_tb.v \
    axi_ltc235x_tb.v \
    axi_ltc235x_cmos.v \
    axi_ltc235x.v]

# interfaces?