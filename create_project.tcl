set script_path [ file dirname [ file normalize [ info script ] ] ]
puts $script_path 

set single_bram_ip_path $script_path/../single_bram_controller
puts $single_bram_ip_path

set multiple_ip [format "%s %s" $script_path $single_bram_ip_path]
puts $multiple_ip

create_project data_collection $script_path -part xczu3eg-sfvc784-1-e
add_files -norecurse $script_path/src/data_collection.v
update_compile_order -fileset sources_1


ipx::package_project -root_dir $script_path -vendor user.org -library user -taxonomy /UserIP

ipx::merge_project_changes files [ipx::current_core]

set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  $script_path [current_project]
update_ip_catalog

close_project

create_project data_collection $script_path/../test_data_collection -part xczu3eg-sfvc784-1-e

create_bd_design "design_1"
update_compile_order -fileset sources_1

set_property  ip_repo_paths  $multiple_ip [current_project]
update_ip_catalog

create_bd_cell -type ip -vlnv user.org:user:data_collection:1.0 data_collection_0
create_bd_cell -type ip -vlnv user.org:user:single_bram_controller:1.0 single_bram_controller_0

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
endgroup
set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Enable_32bit_Address {false} CONFIG.Use_Byte_Write_Enable {false} CONFIG.Byte_Size {9} CONFIG.Write_Depth_A {1024} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Use_RSTA_Pin {false} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {0} CONFIG.Port_B_Enable_Rate {100} CONFIG.use_bram_block {Stand_Alone} CONFIG.EN_SAFETY_CKT {false}] [get_bd_cells blk_mem_gen_0]

create_bd_cell -type ip -vlnv user.org:user:single_bram_controller:1.0 single_bram_controller_1

connect_bd_net [get_bd_pins data_collection_0/bram_write_run] [get_bd_pins single_bram_controller_0/i_run]
connect_bd_net [get_bd_pins data_collection_0/bram_mode] [get_bd_pins single_bram_controller_0/i_mode]
connect_bd_net [get_bd_pins data_collection_0/bram_addr] [get_bd_pins single_bram_controller_0/i_bramAddr]
connect_bd_net [get_bd_pins data_collection_0/bram_data] [get_bd_pins single_bram_controller_0/i_write_data]
connect_bd_net [get_bd_pins single_bram_controller_0/o_idle] [get_bd_pins data_collection_0/bram_write_idle]
connect_bd_net [get_bd_pins single_bram_controller_0/bramAddr] [get_bd_pins blk_mem_gen_0/addra]
connect_bd_net [get_bd_pins single_bram_controller_0/bramCe] [get_bd_pins blk_mem_gen_0/ena]
connect_bd_net [get_bd_pins single_bram_controller_0/bramWe] [get_bd_pins blk_mem_gen_0/wea]
connect_bd_net [get_bd_pins single_bram_controller_0/bramWriteData] [get_bd_pins blk_mem_gen_0/dina]
connect_bd_net [get_bd_pins single_bram_controller_1/bramAddr] [get_bd_pins blk_mem_gen_0/addrb]
connect_bd_net [get_bd_pins single_bram_controller_1/bramCe] [get_bd_pins blk_mem_gen_0/enb]
connect_bd_net [get_bd_pins blk_mem_gen_0/doutb] [get_bd_pins single_bram_controller_1/bramReadData]

startgroup
make_bd_pins_external  [get_bd_cells data_collection_0]
make_bd_intf_pins_external  [get_bd_cells data_collection_0]
endgroup

connect_bd_net [get_bd_ports system_clk_0] [get_bd_pins single_bram_controller_0/clk]
connect_bd_net [get_bd_ports reset_0] [get_bd_pins single_bram_controller_0/reset_n]
connect_bd_net [get_bd_ports system_clk_0] [get_bd_pins single_bram_controller_1/clk]
connect_bd_net [get_bd_ports reset_0] [get_bd_pins single_bram_controller_1/reset_n]
connect_bd_net [get_bd_ports system_clk_0] [get_bd_pins blk_mem_gen_0/clka]
connect_bd_net [get_bd_ports system_clk_0] [get_bd_pins blk_mem_gen_0/clkb]

startgroup
make_bd_pins_external  [get_bd_pins single_bram_controller_1/o_read_valid]
endgroup

startgroup
make_bd_pins_external  [get_bd_pins single_bram_controller_1/o_read_data]
endgroup

startgroup
make_bd_pins_external  [get_bd_pins single_bram_controller_1/i_run]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins single_bram_controller_1/i_mode]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins single_bram_controller_1/i_bramAddr]
endgroup

regenerate_bd_layout

make_wrapper -files [get_files $script_path/../test_data_collection/data_collection.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse $script_path/../test_data_collection/data_collection.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse $script_path/src/tb_data_collection.v
update_compile_order -fileset sim_1

save_bd_design
