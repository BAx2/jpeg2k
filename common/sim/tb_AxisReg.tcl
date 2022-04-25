vlib work
vlog ../rtl/AxisReg.sv \
     ../rtl/Dffren.sv \
     ./tb_AxisReg.sv

vsim -novopt work.tb_AxisReg
log * -r

add wave *
add wave test_dout
add wave -divider -height 40
add wave DUT/*
add wave -divider -height 40
add wave -position insertpoint  \
    sim:/tb_AxisReg/DUT/genblk1/genblk1/*

run 500ns

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