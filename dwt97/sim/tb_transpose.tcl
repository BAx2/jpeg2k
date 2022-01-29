
vlog ../rtl/Transpose.sv \
     ./tb_transpose.sv

vsim -novopt work.tb_transpose
log * -r
add wave clk_i
add wave rst_i
add wave -divider
add wave s_*
add wave -divider
add wave m_*
add wave -divider
add wave din
add wave dout
add wave -divider
add wave DUT/*
add wave DUT/odd_reg
add wave -divider

run 400ns

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