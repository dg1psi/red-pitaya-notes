source projects/base_system/block_design.tcl

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset:5.0 rst_0

# Create c_counter_binary
cell xilinx.com:ip:c_counter_binary:12.0 cntr_0 {
  Output_Width 32
} {
  CLK pll_0/clk_out1
}

# Create port_slicer
cell pavel-demin:user:port_slicer:1.0 slice_0 {
  DIN_FROM 26
  DIN_TO 26
} {
  din cntr_0/Q
}

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register:1.0 cfg_0 {
  CFG_DATA_WIDTH 1024
  AXI_ADDR_WIDTH 7
  AXI_DATA_WIDTH 32
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins cfg_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]
set_property OFFSET 0x40000000 [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]

# Create port_slicer
cell pavel-demin:user:port_slicer:1.0 slice_1 {
  DIN_WIDTH 1024 DIN_FROM 134 DIN_TO 128
} {
  din cfg_0/cfg_data
}

# Create xlconcat
cell xilinx.com:ip:xlconcat:2.1 concat_0 {
  IN1_WIDTH 7
} {
  In0 slice_0/dout
  In1 slice_1/dout
  dout led_o
}
