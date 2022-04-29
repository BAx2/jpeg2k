vlib work
vlog ../rtl/Multiplier.sv \
     ../sim/tb_Multiplier.sv

vsim -novopt work.tb_Multiplyer
log * -r

add wave *
add wave -divider -height 40
add wave DUT/*
add wave -divider -height 40

run 100ns

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