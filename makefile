# ******* project, board and chip name *******
PROJECT = dvi
BOARD = ulx3s
FPGA_SIZE = 25

# ******* design files *******
CONSTRAINTS = ulx3s_v20_segpdi.lpf
TOP_MODULE = top_dvitest_lpf
TOP_MODULE_FILE = $(TOP_MODULE).v
VERILOG_FILES = $(TOP_MODULE_FILE) DVI_test.v TMDS_encoder.v OBUFDS.v clk_25_125_250_25_83.v
VHDL_TO_VERILOG_FILES = vhdl_blink.v

# synthesis options
YOSYS_OPTIONS = -noccu2

include scripts/ulx3s_trellis.mk
