
vlog ../rtl/Coefficient.svh \
     ../rtl/ProcessingUnit1D.sv  \
     ../../common/rtl/Adder.sv \
     ../../common/rtl/Bram.sv \
     ../../common/rtl/Counter.sv \
     ../../common/rtl/Multiplier.sv \
     ../../common/rtl/AxisReg.sv \
     ./tb_pu.sv

vsim -novopt work.tb_pu
log * -r
add wave *
add wave DUT/*
# add wave -position insertpoint  \
#      sim:/tb_pu/DUT/D1RamInst/ram  \
#      sim:/tb_pu/DUT/D2RamInst/ram

run 2800ns

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