vlib work
vlog ../rtl/Adder.sv \
     ../sim/tb_Adder.sv

vsim -novopt work.tb_Adder
log * -r

add wave *
add wave -divider -height 40
add wave DUT/*
add wave -divider -height 40

add wave -position insertpoint  \
     sim:/tb_Adder/DUT/AWidth \
     sim:/tb_Adder/DUT/APoint \
     sim:/tb_Adder/DUT/BWidth \
     sim:/tb_Adder/DUT/BPoint \
     sim:/tb_Adder/DUT/OutWidth \
     sim:/tb_Adder/DUT/OutPoint

add wave -divider -height 40
add wave -position insertpoint  \
     sim:/tb_Adder/DUT/InternalPoint \
     sim:/tb_Adder/DUT/AIntPart \
     sim:/tb_Adder/DUT/BIntPart \
     sim:/tb_Adder/DUT/OutIntPart \
     sim:/tb_Adder/DUT/IntPartSize \
     sim:/tb_Adder/DUT/AOffset \
     sim:/tb_Adder/DUT/BOffset \
     sim:/tb_Adder/DUT/InternalWidth \
     sim:/tb_Adder/DUT/OutLsb
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