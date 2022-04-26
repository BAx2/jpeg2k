vlib work
vlog ../rtl/*
vlog ./*.sv

vsim -novopt work.tb_Dma
log * -r

add wave -divider -height 40 AR
add wave m_mm2s_axi_ar*
add wave -divider -height 40 R
add wave m_mm2s_axi_r*
add wave -divider -height 40 AW
add wave m_s2mm_axi_aw*
add wave -divider -height 40 W
add wave m_s2mm_axi_w*
add wave -divider -height 40 B
add wave m_s2mm_axi_b*

add wave -divider -height 40 {Read Ctrl}
add wave read_*
add wave -divider -height 40 {Write Ctrl}
add wave write_*

add wave -divider -height 40 Memory
add wave AxiMemInst/mem
add wave -divider -height 40

run 500ns

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