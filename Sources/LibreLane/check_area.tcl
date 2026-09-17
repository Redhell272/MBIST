
#Launch three instances of openROAD for each .odb file that needs to be checked
if {[info exists ::env(MBIST_CHECK_AREA_ODB)]} {
    set odb_file $::env(MBIST_CHECK_AREA_ODB)
    read_db $odb_file
} else {
    set odb_files { "./28-openroad-globalplacement/top_model.odb" "./final/odb/top_model.odb" } 
    #"./52-openroad-fillinsertion/top_model.odb"

    set script_file [file normalize [info script]]

    foreach odb_file $odb_files {
        set ::env(MBIST_CHECK_AREA_ODB) $odb_file
        if {[catch {exec openroad -exit -no_init $script_file >@stdout 2>@stderr} error]} {
            puts stderr $error
            exit 1
        }
    }
    exit 0
}

puts ""
puts "================================================================"

puts ""
if {$odb_file eq "./28-openroad-globalplacement/top_model.odb"} {
    puts "Checking Area from Global Placement"
} elseif {$odb_file eq "./52-openroad-fillinsertion/top_model.odb"} {
    puts "Checking Area after Fill Insertion"
} elseif {$odb_file eq "./final/odb/top_model.odb"} {
    puts "Checking Final Area"
}
puts ""
puts "================================================================"



set mbist_area 0.0
set mbist_cells 0

set non_mbist_mem_area 0.0
set non_mbist_mem_cells 0

set mem1_area 0.0
set mem1_cells 0

set mem2_area 0.0
set mem2_cells 0

set non_mem_area 0.0
set non_mem_cells 0

set block_area 0.0
set block_cells 0

set total_area 0.0
set total_cells 0

foreach inst [[ord::get_db_block] getInsts] {

    set name [$inst getName]
    set master [$inst getMaster]

    set w_um [expr {[$master getWidth] / 1000.0}]
    set h_um [expr {[$master getHeight] / 1000.0}]
    set cell_area [expr {$w_um * $h_um}]

    if {[$master getType] != "BLOCK"} {
        if {[string match -nocase "*mbist*" $name]} {
            set mbist_area [expr {$mbist_area + $cell_area}]
            incr mbist_cells
        }

        if {[string match -nocase "*mem*" $name]} {
            if {!([string match -nocase "*mbist*" $name])} {
                set non_mbist_mem_area [expr {$non_mbist_mem_area + $cell_area}]
                incr non_mbist_mem_cells
            }
        }

        if {[string match -nocase "*mem1*" $name]} {
            set mem1_area [expr {$mem1_area + $cell_area}]
            incr mem1_cells
        }

        if {[string match -nocase "*mem2*" $name]} {
            set mem2_area [expr {$mem2_area + $cell_area}]
            incr mem2_cells
        }

        if {!([string match -nocase "*mem*" $name])} {
            set non_mem_area [expr {$non_mem_area + $cell_area}]
            incr non_mem_cells
        }
    } else {
        set block_area [expr {$block_area + $cell_area}]
        incr block_cells
    }

    set total_area [expr {$total_area + $cell_area}]
    incr total_cells
}



puts ""
puts [format "     MBISTs Cell Count: %d" $mbist_cells]
puts [format "  MBISTs Physical Area: %.4f um^2" $mbist_area]
puts ""
puts [format "     non-MBIST MEMx Cell Count: %d" $non_mbist_mem_cells]
puts [format "  non-MBIST MEMx Physical Area: %.4f um^2" $non_mbist_mem_area]
puts ""
puts "================================================================"
puts ""
puts [format "     MEM1 Cell Count: %d" $mem1_cells]
puts [format "  MEM1 Physical Area: %.4f um^2" $mem1_area]
puts ""
puts [format "     MEM2 Cell Count: %d" $mem2_cells]
puts [format "  MEM2 Physical Area: %.4f um^2" $mem2_area]
puts ""
puts [format "     non-MEM Cell Count: %d" $non_mem_cells]
puts [format "  non-MEM Physical Area: %.4f um^2" $non_mem_area]
puts ""
puts [format "     BLOCK Cell Count: %d" $block_cells]
puts [format "  BLOCK Physical Area: %.4f um^2" $block_area]
puts ""
puts "================================================================"
puts ""
puts [format "     Total Cell Count: %d" $total_cells]
puts [format "  Total Physical Area: %.4f um^2" $total_area]
puts ""
puts "================================================================"

puts ""