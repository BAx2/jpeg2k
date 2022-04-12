vlib work
vlog *.sv

vsim -novopt work.tb
log * -r

add wave *
add wave arr
add wave -divider -height 40
add wave DUT/*

add wave -divider -height 40
add wave DUT/ReorderBufferInst1/*
add wave -divider -height 40
add wave DUT/ReorderBufferInst1/in/*
add wave -divider -height 40
add wave DUT/ReorderBufferInst1/out/*
add wave -divider -height 40

add wave DUT/ReorderBufferInst1/BramInst/*
add wave DUT/ReorderBufferInst1/BramInst/ram
add wave -divider -height 40

run 1000ns

configure wave -namecolwidth 137
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
