
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

set module_lengths [dict create]
set routed_net_names {}
set net_module_names [dict create]

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
		if {[regexp {^([^.]+)\.} $inst_name -> module_name]} {
			if {[lsearch -exact $module_names $module_name] < 0} {
				lappend module_names $module_name
			}
		}
	}
	if {[llength $module_names] == 0} {
		set module_label OTHER
	} else {
		set module_label [join [lsort $module_names] "+"]
	}
	dict set net_module_names [$net getName] $module_label
	lappend routed_net_names [$net getName]
}

set wire_report_file "./routing_wirelength.log"
tee -quiet -file $wire_report_file [list report_wire_length -net $routed_net_names -detailed_route -file $wire_report_file]

# Read the wire length report and process each line to associate nets with their modules and lengths.
set report_channel [open $wire_report_file r]
while {[gets $report_channel line] >= 0} {
	if {![regexp {^drt: ([^ ]+) ([0-9.]+)} $line -> net_name wire_length_um]} {
		continue
	}

	if {[dict exists $net_module_names $net_name]} {
		set module_key [dict get $net_module_names $net_name]
	} else {
		set module_key OTHER
	}

	if {[dict exists $module_lengths $module_key]} {
		set current_length [dict get $module_lengths $module_key]
	} else {
		set current_length 0.0
	}
	dict set module_lengths $module_key [expr {$current_length + $wire_length_um}]
}
close $report_channel

puts ""
puts "Routed wire length by module:"
foreach module_name [lsort [dict keys $module_lengths]] {
	puts [format "  %-16s %.2fum" $module_name [dict get $module_lengths $module_name]]
}
puts ""
report_wire_length -net * -detailed_route -summary
puts ""
report_design_area
puts ""
puts "================================================================"
puts ""