# Configuration
TEST			?= smoke
TOP       = tb_top

RTL_DIR   = ../rtl
TB_DIR    = ../tb

#RTL_SRCS  = $(wildcard $(RTL_DIR)/*.sv)
#TB_SRCS   = $(wildcard $(TB_DIR)/*.sv)

#SRCS      = $(RTL_SRCS) $(TB_SRCS)
SRCS = \
    $(RTL_DIR)/axi_crossbar_pkg.sv \
    $(RTL_DIR)/axi_fifo.sv \
    $(RTL_DIR)/axi_decoder.sv \
    $(RTL_DIR)/round_robin_arbiter.sv \
    $(RTL_DIR)/aw_dummy_slave.sv \
    $(RTL_DIR)/aw_channel.sv \
    $(RTL_DIR)/w_channel.sv \
    $(RTL_DIR)/b_channel.sv \
		$(RTL_DIR)/write_path.sv \
		$(RTL_DIR)/ar_dummy_slave.sv \
		$(RTL_DIR)/ar_channel.sv \
		$(RTL_DIR)/r_channel.sv \
		$(RTL_DIR)/read_path.sv \
		$(TB_DIR)/axi_if.sv \
		$(TB_DIR)/axi_slave_model.sv \
		$(TB_DIR)/axi_test_lib_pkg.sv \
		$(TB_DIR)/tb_top.sv \

XVLOG     = xvlog
XELAB     = xelab
XSIM      = xsim

SNAPSHOT  = $(TOP)_snap

# Default Target

all: compile elaborate simulate

# Compile

compile:
	$(XVLOG) --sv $(SRCS)

# Elaborate

elaborate:
	$(XELAB) $(TOP) -snapshot $(SNAPSHOT)

# Simulate (Batch Mode)

simulate:
	$(XSIM) $(SNAPSHOT) -runall --testplusarg $(TEST)

# GUI Mode

gui:
	$(XSIM) $(SNAPSHOT) --gui

# Clean

clean:
	rm -rf xsim.dir *.jou *.log *.pb *.wdb

# Rebuild

rebuild: clean all

.PHONY: all compile elaborate simulate gui clean rebuild
