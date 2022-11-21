set REQUIRED_QUARTUS_VERSION 21.1.0
set QUARTUS_PRO_ISUSED 0
source ../../../scripts/adi_env.tcl
source ../../scripts/adi_project_intel.tcl

adi_project dc2677a_c5soc

source $ad_hdl_dir/projects/common/c5soc/c5soc_system_assign.tcl

# ltc235x interface

set_location_assignment PIN_K12 -to lvds_cmos_n ; # lvds_cmos_n 54 lvds_rxp1
set_location_assignment PIN_G12 -to cnv         ; # cnv 48 lvds_rxp0
set_location_assignment PIN_F9 -to busy         ; # busy 90 lvds_rxp7
set_location_assignment PIN_F8 -to cs_n         ; # cs_n 92 lvds_rxn7
set_location_assignment PIN_G11 -to pd          ; # pd 50 lvds_rxn0

set_location_assignment PIN_J12 -to lane_0      ; # sdo0 56 lvds_rxn1
set_location_assignment PIN_G10 -to lane_1      ; # sdo1 60 lvds_rxp2 / sdi_p
set_location_assignment PIN_F10 -to lane_2      ; # sdo2 62 lvds_rxn2 / sdi_n
set_location_assignment PIN_J10 -to lane_3      ; # sdo3 66 lvds_rxp3 / scki_p
set_location_assignment PIN_K8 -to lane_4       ; # sdo4 74 lvds_rxn4 / scko_n
set_location_assignment PIN_J7 -to lane_5       ; # sdo5 78 lvds_rxp5 / sdo_p
set_location_assignment PIN_H7 -to lane_6       ; # sdo6 80 lvds_rxn5 / sdo_n
set_location_assignment PIN_H8 -to lane_7       ; # sdo7 84 lvds_rxp6
set_location_assignment PIN_J9 -to scki         ; # scki 68 lvds_rxn3 / scki_n
set_location_assignment PIN_K7 -to sck0         ; # scko 72 lvds_rxp4 / scko_p
set_location_assignment PIN_G8 -to sdi          ; # sdi 86 lvds_rxn6

# TODO
# set_instance_assignment

execute_flow -compile
