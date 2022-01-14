
vlog ../rtl/Coefficient.svh \
     ../rtl/Dwt97.sv \
     ../rtl/ProcessingUnit1D.sv  \
     ../../common/rtl/Adder.sv \
     ../../common/rtl/Bram.sv \
     ../../common/rtl/Counter.sv \
     ../../common/rtl/Multiplier.sv \
     ../../common/rtl/AxisReg.sv \
     ./tb_dwt.sv

vsim -novopt work.tb_dwt
log * -r
add wave *
add wave DUT/*
# add wave -position insertpoint  \
#      sim:/tb_dwt/DUT/D1RamInst/ram  \
#      sim:/tb_dwt/DUT/D2RamInst/ram

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