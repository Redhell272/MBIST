read_db ./28-openroad-globalplacement/top_model.odb

set total_area 0.0
set cell_count 0
foreach inst [[ord::get_db_block] getInsts] {
    set name [$inst getName]
    if {[string match -nocase "*mbist*" $name]} {
        set master [$inst getMaster]
        if {[$master getType] != "BLOCK"} {

            set w_um [expr {[$master getWidth] / 1000.0}]
            set h_um [expr {[$master getHeight] / 1000.0}]
            set cell_area [expr {$w_um * $h_um}]
            
            set total_area [expr {$total_area + $cell_area}]
            incr cell_count
        }
    }
}
puts ""
puts "================================================================"
puts [format "     MBISTs Cell Count: %d" $cell_count]
puts [format "  MBISTs Physical Area: %.4f um^2" $total_area]
puts "================================================================"

set total_area 0.0
set cell_count 0
foreach inst [[ord::get_db_block] getInsts] {
    set name [$inst getName]
    if {[string match -nocase "*mem*" $name]} {
        if {!([string match -nocase "*mbist*" $name])} {
            set master [$inst getMaster]
            if {[$master getType] != "BLOCK"} {

                set w_um [expr {[$master getWidth] / 1000.0}]
                set h_um [expr {[$master getHeight] / 1000.0}]
                set cell_area [expr {$w_um * $h_um}]
                
                set total_area [expr {$total_area + $cell_area}]
                incr cell_count
            }
        }
    }
}
puts ""
puts "================================================================"
puts [format "     non-MBIST MEMx Cell Count: %d" $cell_count]
puts [format "  non-MBIST MEMx Physical Area: %.4f um^2" $total_area]
puts "================================================================"

set total_area 0.0
set cell_count 0
foreach inst [[ord::get_db_block] getInsts] {
    set name [$inst getName]
    if {[string match -nocase "*mem1*" $name]} {
        set master [$inst getMaster]
        if {[$master getType] != "BLOCK"} {
            
            set w_um [expr {[$master getWidth] / 1000.0}]
            set h_um [expr {[$master getHeight] / 1000.0}]
            set cell_area [expr {$w_um * $h_um}]
            
            set total_area [expr {$total_area + $cell_area}]
            incr cell_count
        }
    }
}
puts ""
puts "================================================================"
puts [format "     MEM1 Cell Count: %d" $cell_count]
puts [format "  MEM1 Physical Area: %.4f um^2" $total_area]
puts "================================================================"

set total_area 0.0
set cell_count 0
foreach inst [[ord::get_db_block] getInsts] {
    set name [$inst getName]
    if {[string match -nocase "*mem2*" $name]} {
        set master [$inst getMaster]
        if {[$master getType] != "BLOCK"} {
            
            set w_um [expr {[$master getWidth] / 1000.0}]
            set h_um [expr {[$master getHeight] / 1000.0}]
            set cell_area [expr {$w_um * $h_um}]
            
            set total_area [expr {$total_area + $cell_area}]
            incr cell_count
        }
    }
}
puts ""
puts "================================================================"
puts [format "     MEM2 Cell Count: %d" $cell_count]
puts [format "  MEM2 Physical Area: %.4f um^2" $total_area]
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
puts "================================================================"
puts [format "     non-BLOCK Cell Count: %d" $cell_count]
puts [format "  non-BLOCK Physical Area: %.4f um^2" $total_area]
puts "================================================================"

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
puts "================================================================"
puts [format "     BLOCK Cell Count: %d" $cell_count]
puts [format "  BLOCK Physical Area: %.4f um^2" $total_area]
puts "================================================================"

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
puts "================================================================"
puts [format "     Total Cell Count: %d" $cell_count]
puts [format "  Total Physical Area: %.4f um^2" $total_area]
puts "================================================================"

puts ""
