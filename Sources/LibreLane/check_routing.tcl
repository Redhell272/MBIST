
read_db "./final/odb/top_model.odb"

puts ""
puts "================================================================"
puts ""
puts "  Checking Routing Reports"
puts ""

puts "Design routing status:"
design_is_routed -verbose

puts ""
puts "Detailed routed wire length:"
report_wire_length -detailed_route -verbose

puts ""
puts "Routed wire length by layer:"
report_wire_length -detailed_route -summary

puts ""
puts "Placement density / design utilization:"
report_design_area

puts ""
puts "================================================================"
puts ""