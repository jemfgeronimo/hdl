# LTC235x attributes

set ADC_LVDS_CMOS_N     0
set CHIP_SELECT_N       0
set ADC_LANE_0_ENABLE   1
set ADC_LANE_1_ENABLE   1
set ADC_LANE_2_ENABLE   1
set ADC_LANE_3_ENABLE   1
set ADC_LANE_4_ENABLE   1
set ADC_LANE_5_ENABLE   1
set ADC_LANE_6_ENABLE   1
set ADC_LANE_7_ENABLE   1
set ADC_NUM_CHANNELS    8
set ADC_DATA_WIDTH      18
set ADC_EXTERNAL_CLK    0

# ltc235x interface

add_interface ltc235x_if conduit end
add_interface_port ltc235x_if scki              scki            output  1
add_interface_port ltc235x_if scko              scko            input   1
add_interface_port ltc235x_if sdo_0             sdo_0           input   1
add_interface_port ltc235x_if sdo_1             sdo_1           input   1
add_interface_port ltc235x_if sdo_2             sdo_2           input   1
add_interface_port ltc235x_if sdo_3             sdo_3           input   1
add_interface_port ltc235x_if sdo_4             sdo_4           input   1
add_interface_port ltc235x_if sdo_5             sdo_5           input   1
add_interface_port ltc235x_if sdo_6             sdo_6           input   1
add_interface_port ltc235x_if sdo_7             sdo_7           input   1
add_interface_port ltc235x_if sdi               sdi             output  1
add_interface_port ltc235x_if cnv               cnv             output  1
add_interface_port ltc235x_if lvds_cmos_n       lvds_cmos_n     output  1
add_interface_port ltc235x_if cs_n              cs_n            output  1
add_interface_port ltc235x_if system_cpu_clk    system_cpu_clk  output  1

# axi_ltc235x

add_instance axi_ltc235x axi_ltc235x
set_instance_parameter_value axi_ltc235x {ID} {0}
set_instance_parameter_value axi_ltc235x {LVDS_CMOS_N} $ADC_LVDS_CMOS_N
set_instance_parameter_value axi_ltc235x {LANE_0_ENABLE} $ADC_LANE_0_ENABLE
set_instance_parameter_value axi_ltc235x {LANE_1_ENABLE} $ADC_LANE_1_ENABLE
set_instance_parameter_value axi_ltc235x {LANE_2_ENABLE} $ADC_LANE_2_ENABLE
set_instance_parameter_value axi_ltc235x {LANE_3_ENABLE} $ADC_LANE_3_ENABLE
set_instance_parameter_value axi_ltc235x {LANE_4_ENABLE} $ADC_LANE_4_ENABLE
set_instance_parameter_value axi_ltc235x {LANE_5_ENABLE} $ADC_LANE_5_ENABLE
set_instance_parameter_value axi_ltc235x {LANE_6_ENABLE} $ADC_LANE_6_ENABLE
set_instance_parameter_value axi_ltc235x {LANE_7_ENABLE} $ADC_LANE_7_ENABLE
set_instance_parameter_value axi_ltc235x {NUM_CHANNELS} $ADC_NUM_CHANNELS
set_instance_parameter_value axi_ltc235x {DATA_WIDTH} $ADC_DATA_WIDTH
set_instance_parameter_value axi_ltc235x {EXTERNAL_CLK} $ADC_EXTERNAL_CLK

# pwm gen

add_instance axi_ltc235x_pwm_gen pwm_gen
set_instance_parameter_value axi_ltc235x_pwm_gen {ID} {0}
set_instance_parameter_value axi_ltc235x_pwm_gen {ASYNC_CLK_EN} {0}
set_instance_parameter_value axi_ltc235x_pwm_gen {N_PWMS} {1}
set_instance_parameter_value axi_ltc235x_pwm_gen {PWM_EXT_SYNC} {0}
set_instance_parameter_value axi_ltc235x_pwm_gen {PULSE_0_WIDTH} {7}
set_instance_parameter_value axi_ltc235x_pwm_gen {PULSE_0_PERIOD} {10}
set_instance_parameter_value axi_ltc235x_pwm_gen {PULSE_0_OFFSET} {0}

# cpack

add_instance axi_ltc235x_cpack util_cpack2
set_instance_parameter_value axi_ltc235x_cpack {NUM_OF_CHANNELS} {$ADC_NUM_CHANNELS}
set_instance_parameter_value axi_ltc235x_cpack {SAMPLES_PER_CHANNEL} {1}
set_instance_parameter_value axi_ltc235x_cpack {SAMPLE_DATA_WIDTH} {32}

# dmac
add_instance axi_ltc235x_dma axi_dmac
set_instance_parameter_value axi_ad463x_dma {DMA_TYPE_SRC} {2}
set_instance_parameter_value axi_ad463x_dma {DMA_TYPE_DEST} {0}
set_instance_parameter_value axi_ad463x_dma {CYCLIC} {0}
set_instance_parameter_value axi_ad463x_dma {SYNC_TRANSFER_START} {1}
set_instance_parameter_value axi_ad463x_dma {AXI_SLICE_SRC} {0}
set_instance_parameter_value axi_ad463x_dma {AXI_SLICE_DEST} {0}
set_instance_parameter_value axi_ad463x_dma {DMA_2D_TRANSFER} {0}
set_instance_parameter_value axi_ad463x_dma {DMA_DATA_WIDTH_SRC} {256}
set_instance_parameter_value axi_ad463x_dma {DMA_DATA_WIDTH_DEST} {64}

# connections

# axi_ltc235x - ltc235x


# pwm_gen - ltc235x

# cpack - axi_ltc235x

# dma - axi_ltc235x

# interrupts / cpu interrupts

# cpu interconnects / address map

# mem interconnects / dma interconnects

# gpio ?

# clocks and resets ?