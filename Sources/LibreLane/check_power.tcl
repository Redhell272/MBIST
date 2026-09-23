puts ""
puts "================================================================"
puts ""
puts "Checking Power..."
puts ""
puts "================================================================"
puts ""

# 1. Propagate your SDC clock constraints to establish the base frequency (e.g. 50MHz or 100MHz)
# (Ensure your config's SDC path is correctly pointed to here)
read_sdc ./final/sdc/top_model.sdc

# 2. Inject a standard default toggle activity rate across all unannotated nets
# This tells the tool that pins toggle on 10% of all clock cycles (a standard industry estimation)
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_1 [all_inputs]
set_data_check -setup 0.0 [all_outputs]
set_power_activity -input -activity 0.1

# 3. Explicitly force a toggle rate directly onto your 32 SRAM clock input pins
# This ensures OpenSTA knows the memory internal clock trees are swinging at full speed
set_power_activity -pins [get_pins -hierarchical *sram_macro/clk0] -activity 1.0

# 4. Execute the power extraction loop
report_power
report_power -hierarchy

puts ""
puts "================================================================"
puts ""