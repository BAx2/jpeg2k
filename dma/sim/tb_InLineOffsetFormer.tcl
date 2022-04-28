vlib work
vlog ../rtl/InLineOffsetFormer.sv
vlog ./tb_InLineOffsetFormer.sv

vsim -novopt work.tb_InLineOffsetFormer
log * -r

add wave -divider -height 40 
add wave *
add wave -divider -height 40 
add wave DUT/*
add wave -divider -height 40 

run 650ns

configure wave -namecolwidth 160
configure wave -valuecolwidth 91
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

wave zoom full
