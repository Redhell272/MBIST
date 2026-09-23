
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
report_wire_length -net * -detailed_route -summary
puts ""
report_design_area
puts ""
puts "================================================================"
puts ""