# Set core clock definition
create_clock -name clk -period 40.0000 [get_ports {clk}]

# Define achievable transition thresholds (0.5ns)
# - Entries in macro .lib files have been adjusted to at least 0.2
set_max_transition 0.5000 [current_design]

# Specify generic boundary constraints
set_input_delay 0.2000 -clock clk [all_inputs]
set_output_delay 0.2000 -clock clk [all_outputs]
set_load 0.0334 [all_outputs]

# Ignore timing for reset path
set_false_path -from [get_ports {nres}]
