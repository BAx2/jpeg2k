
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
# add wave DUT/*
# add wave -position insertpoint  \
#      sim:/tb_dwt/DUT/D1RamInst/ram  \
#      sim:/tb_dwt/DUT/D2RamInst/ram
add wave -divider -height 40
add wave -divider -height 40

add wave -position insertpoint  \
sim:/tb_dwt/DUT/clk_i \
sim:/tb_dwt/DUT/rst_i
add wave -divider -height 40

add wave -position insertpoint  \
sim:/tb_dwt/DUT/s_ready_o \
sim:/tb_dwt/DUT/s_valid_i \
sim:/tb_dwt/DUT/s_sof_i \
sim:/tb_dwt/DUT/s_eol_i \
sim:/tb_dwt/DUT/s_data_i
add wave -divider -height 40

add wave -position insertpoint  \
sim:/tb_dwt/DUT/col_ready \
sim:/tb_dwt/DUT/col_valid \
sim:/tb_dwt/DUT/col_sof \
sim:/tb_dwt/DUT/col_eol \
sim:/tb_dwt/DUT/col_data
add wave -divider -height 40

add wave -position insertpoint  \
sim:/tb_dwt/DUT/exp_ready \
sim:/tb_dwt/DUT/exp_valid \
sim:/tb_dwt/DUT/exp_sof \
sim:/tb_dwt/DUT/exp_eol \
sim:/tb_dwt/DUT/exp_data
add wave -divider -height 40

add wave -position insertpoint  \
sim:/tb_dwt/DUT/transpose_ready \
sim:/tb_dwt/DUT/transpose_valid \
sim:/tb_dwt/DUT/transpose_sof \
sim:/tb_dwt/DUT/transpose_eol \
sim:/tb_dwt/DUT/transpose_data
add wave -divider -height 40

add wave -position insertpoint  \
sim:/tb_dwt/DUT/row_ready \
sim:/tb_dwt/DUT/row_valid \
sim:/tb_dwt/DUT/row_sof \
sim:/tb_dwt/DUT/row_eol \
sim:/tb_dwt/DUT/row_data
add wave -divider -height 40

add wave -position insertpoint  \
sim:/tb_dwt/DUT/m_ready_i \
sim:/tb_dwt/DUT/m_valid_o \
sim:/tb_dwt/DUT/m_sof_o \
sim:/tb_dwt/DUT/m_eol_o \
sim:/tb_dwt/DUT/m_data_o
add wave -divider -height 40

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