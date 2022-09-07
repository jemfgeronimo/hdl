
# ad7606b

set_property -dict {PACKAGE_PIN N19     IOSTANDARD LVCMOS25} [get_ports adc_db[0] ]         ; ## FMC_LPC_LA01_CC_P
set_property -dict {PACKAGE_PIN N20     IOSTANDARD LVCMOS25} [get_ports adc_db[1] ]         ; ## FMC_LPC_LA01_CC_N
set_property -dict {PACKAGE_PIN P18     IOSTANDARD LVCMOS25} [get_ports adc_db[2] ]         ; ## FMC_LPC_LA02_N
set_property -dict {PACKAGE_PIN P22     IOSTANDARD LVCMOS25} [get_ports adc_db[3] ]         ; ## FMC_LPC_LA03_N
set_property -dict {PACKAGE_PIN M22     IOSTANDARD LVCMOS25} [get_ports adc_db[4] ]         ; ## FMC_LPC_LA04_N
set_property -dict {PACKAGE_PIN T17     IOSTANDARD LVCMOS25} [get_ports adc_db[5] ]         ; ## FMC_LPC_LA07_N
set_property -dict {PACKAGE_PIN J22     IOSTANDARD LVCMOS25} [get_ports adc_db[6] ]         ; ## FMC_LPC_LA08_N
set_property -dict {PACKAGE_PIN M20     IOSTANDARD LVCMOS25} [get_ports adc_db[7] ]         ; ## FMC_LPC_LA00_CC_N
set_property -dict {PACKAGE_PIN L22     IOSTANDARD LVCMOS25} [get_ports adc_db[8] ]         ; ## FMC_LPC_LA06_N
set_property -dict {PACKAGE_PIN J18     IOSTANDARD LVCMOS25} [get_ports adc_db[9] ]         ; ## FMC_LPC_LA05_P
set_property -dict {PACKAGE_PIN R20     IOSTANDARD LVCMOS25} [get_ports adc_db[10]]         ; ## FMC_LPC_LA09_P
set_property -dict {PACKAGE_PIN N22     IOSTANDARD LVCMOS25} [get_ports adc_db[11]]         ; ## FMC_LPC_LA03_P
set_property -dict {PACKAGE_PIN N18     IOSTANDARD LVCMOS25} [get_ports adc_db[12]]         ; ## FMC_LPC_LA11_N
set_property -dict {PACKAGE_PIN P21     IOSTANDARD LVCMOS25} [get_ports adc_db[13]]         ; ## FMC_LPC_LA12_N
set_property -dict {PACKAGE_PIN L17     IOSTANDARD LVCMOS25} [get_ports adc_db[14]]         ; ## FMC_LPC_LA13_P
set_property -dict {PACKAGE_PIN M17     IOSTANDARD LVCMOS25} [get_ports adc_db[15]]         ; ## FMC_LPC_LA13_N

set_property -dict {PACKAGE_PIN M19     IOSTANDARD LVCMOS25} [get_ports adc_rd_n]           ; ## FMC_LPC_LA00_CC_P
set_property -dict {PACKAGE_PIN R21     IOSTANDARD LVCMOS25} [get_ports adc_wr_n]           ; ## FMC_LPC_LA09_N

# control lines
set_property -dict {PACKAGE_PIN T16     IOSTANDARD LVCMOS25} [get_ports adc_busy]           ; ## FMC_LPC_LA07_P
set_property -dict {PACKAGE_PIN K18     IOSTANDARD LVCMOS25} [get_ports adc_cnvst_n]         ; ## FMC_LPC_LA05_N
set_property -dict {PACKAGE_PIN M21     IOSTANDARD LVCMOS25} [get_ports adc_cs_n]           ; ## FMC_LPC_LA04_P
set_property -dict {PACKAGE_PIN J21     IOSTANDARD LVCMOS25} [get_ports adc_first_data]       ; ## FMC_LPC_LA08_P
