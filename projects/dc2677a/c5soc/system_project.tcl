set REQUIRED_QUARTUS_VERSION 21.1.0
set QUARTUS_PRO_ISUSED 0
source ../../../scripts/adi_env.tcl
source ../../scripts/adi_project_intel.tcl

adi_project dc2677a_c5soc

source $ad_hdl_dir/projects/common/c5soc/c5soc_system_assign.tcl

execute_flow -compile
