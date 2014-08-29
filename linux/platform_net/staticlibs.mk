
PLATFORM_NET_CSOURCES=$(wildcard $(SHOTODOL_NET_HOME)/$(PLATFORM)/platform_net/csrc/*.c)
PLATFORM_NET_VSOURCE_BASE=$(basename $(notdir $(PLATFORM_NET_CSOURCES)))
OBJECTS+=$(addprefix $(SHOTODOL_NET_HOME)/$(OBJDIR_COMMON)/, $(addsuffix .o,$(PLATFORM_NET_VSOURCE_BASE)))
ifeq ("$(LINUX_BLUETOOTH)", "y") 
LIBS+=-lbluetooth
endif

