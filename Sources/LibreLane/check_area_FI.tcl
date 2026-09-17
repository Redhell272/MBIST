
read_db ./52-openroad-fillinsertion/top_model.odb

puts ""
puts "================================================================"
puts ""
puts "Checking Area after Fill Insertion"
puts ""
puts "================================================================"

set total_area 0.0
set cell_count 0
foreach inst [[ord::get_db_block] getInsts] {
    set master [$inst getMaster]
    if {[$master getType] != "BLOCK"} {
        set w_um [expr {[$master getWidth] / 1000.0}]
        set h_um [expr {[$master getHeight] / 1000.0}]
        set cell_area [expr {$w_um * $h_um}]
        
        set total_area [expr {$total_area + $cell_area}]
        incr cell_count
    }
}
puts ""
puts [format "     non-BLOCK Cell Count: %d" $cell_count]
puts [format "  non-BLOCK Physical Area: %.4f um^2" $total_area]

set total_area 0.0
set cell_count 0
foreach inst [[ord::get_db_block] getInsts] {
    set master [$inst getMaster]
    if {[$master getType] == "BLOCK"} {
        set w_um [expr {[$master getWidth] / 1000.0}]
        set h_um [expr {[$master getHeight] / 1000.0}]
        set cell_area [expr {$w_um * $h_um}]
        
        set total_area [expr {$total_area + $cell_area}]
        incr cell_count
    }
}
puts ""
puts [format "     BLOCK Cell Count: %d" $cell_count]
puts [format "  BLOCK Physical Area: %.4f um^2" $total_area]

set total_area 0.0
set cell_count 0
foreach inst [[ord::get_db_block] getInsts] {
    set master [$inst getMaster]
    set w_um [expr {[$master getWidth] / 1000.0}]
    set h_um [expr {[$master getHeight] / 1000.0}]
    set cell_area [expr {$w_um * $h_um}]
    
    set total_area [expr {$total_area + $cell_area}]
    incr cell_count
}
puts ""
puts [format "     Total Cell Count: %d" $cell_count]
puts [format "  Total Physical Area: %.4f um^2" $total_area]

puts ""
puts "================================================================"

puts ""
