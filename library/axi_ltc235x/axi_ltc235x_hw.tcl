# ip

package require qsys 14.0
package require quartus::device

source ../../scripts/adi_env.tcl
source ../scripts/adi_ip_intel.tcl

ad_ip_create axi_ltc235x {AXI LTC235x Interface}
set_module_property AUTHOR {Geronimo, John Erasmus Mari F.}
set_module_property VALIDATION_CALLBACK info_param_validate
ad_ip_files axi_ltc235x [list \
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
# add_documentation_link <title> <path>

# parameters

ad_ip_parameter ID INTEGER 0
ad_ip_parameter LVDS_CMOS_N STD_LOGIC 0
ad_ip_parameter LANE_0_ENABLE STD_LOGIC 1
ad_ip_parameter LANE_1_ENABLE STD_LOGIC 1
ad_ip_parameter LANE_2_ENABLE STD_LOGIC 1
ad_ip_parameter LANE_3_ENABLE STD_LOGIC 1
ad_ip_parameter LANE_4_ENABLE STD_LOGIC 1
ad_ip_parameter LANE_5_ENABLE STD_LOGIC 1
ad_ip_parameter LANE_6_ENABLE STD_LOGIC 1
ad_ip_parameter LANE_7_ENABLE STD_LOGIC 1
ad_ip_parameter NUM_CHANNELS INTEGER 8
ad_ip_parameter DATA_WIDTH INTEGER 18
ad_ip_parameter EXTERNAL_CLK STD_LOGIC 0

adi_add_auto_fpga_spec_params

# interfaces

# physical interface
add_interface device_if conduit end
# common
add_interface_port device_if busy busy Input 1
add_interface_port device_if lvds_cmos_n lvds_cmos_n Output 1
add_interface_port device_if cs_n cs_n Output 1
# cmos
add_interface_port device_if scki scki Output 1
add_interface_port device_if scko scko Input 1
add_interface_port device_if sdi sdi Output 1
add_interface_port device_if lane_0 lane_0 Input 1
add_interface_port device_if lane_1 lane_1 Input 1
add_interface_port device_if lane_2 lane_2 Input 1
add_interface_port device_if lane_3 lane_3 Input 1
add_interface_port device_if lane_4 lane_4 Input 1
add_interface_port device_if lane_5 lane_5 Input 1
add_interface_port device_if lane_6 lane_6 Input 1
add_interface_port device_if lane_7 lane_7 Input 1
# lvds
#add_interface_port device_if scki_p scki_p Output 1
#add_interface_port device_if scki_n scki_n Output 1
#add_interface_port device_if scko_p scko_p Input 1
#add_interface_port device_if scko_n scko_n Input 1
#add_interface_port device_if sdi_p sdi_p Output 1
#add_interface_port device_if sdi_n sdi_n Output 1
#add_interface_port device_if sdo_p sdo_p Input 1
#add_interface_port device_if sdo_n sdo_n Input 1

# clock
ad_interface clock external_clk input 1

# axi
ad_ip_intf_s_axi s_axi_aclk s_axi_aresetn

# others
ad_interface signal adc_dovf Input 1

for {set i 0} {$i < 8} {incr i} {
    add_interface adc_ch_$i conduit end
    add_interface_port adc_ch_$i adc_enable_$i enable Output 1
    add_interface_port adc_ch_$i adc_valid_$i valid Input 1
    add_interface_port adc_ch_$i adc_data_$i data Output 32
}
