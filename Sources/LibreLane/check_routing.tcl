
# The final ODB contains the detailed-route wires and the connected hierarchy.
read_db "./final/odb/top_model.odb"

puts ""
puts "================================================================"
puts ""
puts "Checking Final Routing"
puts ""
puts "================================================================"
puts ""
puts "Design routing status:"
set routing_status [design_is_routed]
if {$routing_status} {
	puts "  COMPLETE"
} else {
	puts "  INCOMPLETE"
}



puts ""
puts "Routed wire length by module:"

set module_lengths [dict create]
set routed_nets {}
set net_module_names [dict create]
set net_z_category [dict create]
set z_lengths [dict create]
set z_counts [dict create]
# Iterate over all nets in the design and collect routing information
foreach net [[ord::get_db_block] getNets] {
	set wire [$net getWire]
	if {$wire eq "NULL" || [$net isSpecial] || [$net getSigType] eq "POWER" || [$net getSigType] eq "GROUND" || [llength [$net getSWires]] > 0 || [$net isConnectedByAbutment]} {
		continue
	}

	set module_names {}
	foreach iterm [$net getITerms] {
		set inst [$iterm getInst]
		set inst_name [$inst getName]

		# Extract the deep hierarchical path up to the module container name.
		if {[regexp {^(.*)\.[^.]+$} $inst_name -> full_hierarchy_path]} {
			
            # Match for MBIST and SRAM instances
			if {[string match -nocase "*mbist*" $full_hierarchy_path]} {
				set module_name "MBIST"
			} elseif {[string match -nocase "*sram_macro*" $full_hierarchy_path] || [[$inst getMaster] getType] eq "BLOCK"} {
				set module_name "SRAM"
			} else {
				# Fallback to the top-level MEMx label for everything else
				regexp {^([^.]+)\.} $inst_name -> module_name
			}
			
			if {[lsearch -exact $module_names $module_name] < 0 && $module_name ne ""} {
				lappend module_names $module_name
			}
		}
	}
	if {[llength $module_names] == 0} {
		set module_label Z.OTHER

		# Classify a top-level net into one coarse category from the cells it touches.
		# Priority order: clock, output, input, repeaters/fix buffers, port only, other logic.
		set has_clock 0
		set has_output 0
		set has_input 0
		set has_repeater 0
		foreach iterm [$net getITerms] {
			set inst_base [regsub -all {[0-9]+} [[$iterm getInst] getName] N]
			if {[regexp {^(clkbuf|clkload|clkinv|delaybuf|clknet)} $inst_base]} {
				set has_clock 1
			} elseif {[regexp {^output} $inst_base]} {
				set has_output 1
			} elseif {[regexp {^input} $inst_base]} {
				set has_input 1
			} elseif {[regexp {^(wire|load_slew|max_cap|rebuffer|split|hold|fanout|ANTENNA)} $inst_base]} {
				set has_repeater 1
			}
		}
		set has_port [expr {[llength [$net getBTerms]] > 0}]
		if {$has_clock} {
			set z_category "Clock tree"
		} elseif {$has_output} {
			set z_category "Output buffer nets"
		} elseif {$has_input} {
			set z_category "Input buffer nets"
		} elseif {$has_repeater} {
			set z_category "Repeaters / fix buffers / antenna diodes"
		} elseif {$has_port} {
			set z_category "Port-only nets"
		} else {
			set z_category "Other top-level logic"
		}
	} else {
		set module_label [join [lsort $module_names] "+"]
		set z_category ""
	}
	# Look up by raw and backslash-free name, since the report may print either
	set net_name [$net getName]
	dict set net_module_names $net_name $module_label
	dict set net_module_names [string map [list "\\" ""] $net_name] $module_label
	if {$z_category ne ""} {
		dict set net_z_category $net_name $z_category
		dict set net_z_category [string map [list "\\" ""] $net_name] $z_category
	}
	lappend routed_nets $net
}

set wire_report_file "./routing_wirelength.log"
suppress_message GRT 240
grt::create_wl_report_file $wire_report_file 0
foreach net $routed_nets {
	grt::report_net_wire_length $net 0 1 0 $wire_report_file
}
unsuppress_message GRT 240

# Read the wire length report and process each line to associate nets with their modules and lengths.
set report_channel [open $wire_report_file r]
while {[gets $report_channel line] >= 0} {
	if {![regexp {^drt: ([^ ]+) ([0-9.]+)} $line -> net_name wire_length_um]} {
		continue
	}

	if {[dict exists $net_module_names $net_name]} {
		set module_key [dict get $net_module_names $net_name]
	} else {
		set module_key Z.OTHER
	}

	if {[dict exists $module_lengths $module_key]} {
		set current_length [dict get $module_lengths $module_key]
	} else {
		set current_length 0.0
	}
	dict set module_lengths $module_key [expr {$current_length + $wire_length_um}]

	if {$module_key eq "Z.OTHER"} {
		if {[dict exists $net_z_category $net_name]} {
			set z_key [dict get $net_z_category $net_name]
		} else {
			set z_key "(unknown)"
		}
		if {![dict exists $z_lengths $z_key]} {
			dict set z_lengths $z_key 0.0
			dict set z_counts $z_key 0
		}
		dict set z_lengths $z_key [expr {[dict get $z_lengths $z_key] + $wire_length_um}]
		dict incr z_counts $z_key
	}
}
close $report_channel

foreach module_name [lsort [dict keys $module_lengths]] {
	puts [format "  %-12s %.2fum" $module_name [dict get $module_lengths $module_name]]
}

puts ""
puts "Z.OTHER breakdown:"
set z_sorted {}
dict for {z_key z_len} $z_lengths {
	lappend z_sorted [list $z_key $z_len [dict get $z_counts $z_key]]
}
set z_sorted [lsort -real -decreasing -index 1 $z_sorted]
foreach entry $z_sorted {
	lassign $entry z_key z_len z_count
	puts [format "  %-42s %14.2fum %7d nets" $z_key $z_len $z_count]
}



puts ""
report_wire_length -net * -detailed_route -summary
puts ""
report_design_area
puts ""
puts "================================================================"
puts ""