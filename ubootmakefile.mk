#
# SPDX-License-Identifier:	GPL-2.0+
#

VERSION = 2018			#版本号
PATCHLEVEL = 05			#补丁版本
SUBLEVEL =			#次版本号
EXTRAVERSION = -rc1		#附加信息
NAME =

# *文档*
# 查看make典型的规则目标请执行 "make help"
# 更多的信息可以查看 ./README
# 这个文件中的注释只针对开发者，不要指望学习如何构建读取这个文件的内核。

# 不要使用内置的规则和变量。
#   (这会提高性能并避免难以调试的行为);
# o Look for make include files relative to root of kernel src
MAKEFLAGS += -rR --include-dir=$(CURDIR)

#-I DIR
#--include-dir=DIR
#指定被包含makefile文件的搜索目录。在Makefile中出现“include”另外一个文件时,将在“DIR”目录下搜索。
#多个“-I”指定目录时,搜索目录按照指定顺序进行。
#
#-r
#--no-builtin-rules
#取消所有内嵌的隐含规则,不过你可以在Makefile中使用模式规则来定义规则。
#同时选项“-r”会取消所有支持后追规则的隐含后缀列表,同样我们也可以在
#Makefile中使用“.SUFFIXES”定义我们自己的后缀规则。“-r”选项不会取消
#make内嵌的隐含变量。

# 避免奇怪的字符集依赖关系，去除所有本地化的设置LC_ALL，让命令能正确执行。
# 不希望将一个变量传递给子 makefile 时,可以使用指示符“unexport”来声明这个变量(变量与递归)
unexport LC_ALL
LC_COLLATE=C
LC_NUMERIC=C
export LC_COLLATE LC_NUMERIC

# 避免干扰shell的环境变量设置
unexport GREP_OPTIONS

# makefile 文件使用了递归构建
#
#最重要提示：子Makefile只能修改自己目录中的文件。 
#如果在某个目录中，我们依赖另一个目录中的文件（这种情况不常发生，但当链接built-in.o目标最终变成vmlinux通常是不可避免的），
#我们将在基它目录中调用一个子make，之后我们确信其目录中的所有内容都更新到最新的。
#
#我们需要修改具有全局效果的文件的唯一情况是在递归降序开始之前分离出来并完成的。 现在它们明确列为准备规则。


#Makefile支持的选项（最常用到的）
#选项V，用于开启或者关闭执行make时编译信息的打印，V=1 打印信息
#--------------------------------------------------------------------------------------------------------
V=XXX
ifeq ("$(origin V)", "command line")
  KBUILD_VERBOSE = $(V)
endif
ifndef KBUILD_VERBOSE
  KBUILD_VERBOSE = 0
endif

ifeq ($(KBUILD_VERBOSE),1)
  quiet =
  Q =
else
  quiet=quiet_
  Q = @ #在make中，一条命令前加@表示执行该命令的时候，不打印出执行的命令。
endif
#---------------------------------------------------------------------------------------------------------

# 如果用户执行 make -s ,则禁用makefile中的命令输出。
ifneq ($(filter 4.%,$(MAKE_VERSION)),)	# make-4
ifneq ($(filter %s ,$(firstword x$(MAKEFLAGS))),)
  quiet=silent_
endif
else					# make-3.8x
ifneq ($(filter s% -s%,$(MAKEFLAGS)),)
  quiet=silent_
endif
endif
#上层定义的变量传递给子 make，全局的
export quiet Q KBUILD_VERBOSE

# 1)<=========选项O/KBUILD_OUTPUT，指定out-of-build时的输出路径
# Kbuild支持在一个单独的路径下保存输出文件。
# 设置输出文件在一个单独的路径有两种方法。在这两种情况下的工作路径必须是内核源码的根路径。
#1)使用"make O=dir/to/store/output/files/"
#2)设置kbuild_output

#设置环境变量KBUILD_OUTPUT 来指向输出文件应放置的路径
# export KBUILD_OUTPUT=dir/to/store/output/files/
# make
# 使用O = 分配优先于KBUILD_OUTPUT环境

# KBUILD_SRC is set on make的调用 in OBJ 路径
# KBUILD_SRC 不打算被普通用户使用（现在） (for now)

ifeq ($(KBUILD_SRC),)

# OK, Make called in directory where kernel src resides
# Do we want to locate output files in a separate directory?
ifeq ("$(origin O)", "command line")
  KBUILD_OUTPUT := $(O)
endif

# 当make指令没有指定目标时，默认的目标规则    <==================================all
PHONY := _all
_all:

# 空命令，取消顶层Makefile中的隐式规则
$(CURDIR)/Makefile Makefile: ;

ifneq ($(KBUILD_OUTPUT),)
# 调用输出路径中的第二个元素，传递相关变量
# 检查输出路径是否实际存在
saved-output := $(KBUILD_OUTPUT)
KBUILD_OUTPUT := $(shell mkdir -p $(KBUILD_OUTPUT) && cd $(KBUILD_OUTPUT) \
								&& /bin/pwd)
$(if $(KBUILD_OUTPUT),, \
     $(error failed to create output directory "$(saved-output)"))
# make 在执行时设置一个特殊变量“MAKECMDGOALS”,此变量记录了命令行参数指定的终极目标列表
PHONY += $(MAKECMDGOALS) sub-make

$(filter-out _all sub-make $(CURDIR)/Makefile, $(MAKECMDGOALS)) _all: sub-make
	@:

sub-make: FORCE
    $(Q)$(MAKE) -C $(KBUILD_OUTPUT) KBUILD_SRC=$(CURDIR) \
	-f $(CURDIR)/Makefile $(filter-out _all sub-make,$(MAKECMDGOALS))

# 离开第一层make的调用。
# 跳出makefile
skip-makefile := 1
endif # ifneq ($(KBUILD_OUTPUT),)
endif # ifeq ($(KBUILD_SRC),)


# 第二层进入makefile 时调用。
ifeq ($(skip-makefile),)

#
# -w   --print-directory
# 在 make 进入一个目录读取 Makefile 之前打印工作目录。这个选项可以帮助我
# 们调试 Makefile,跟踪定位错误。使用“-C”选项时默认打开这个选项。
# --no-print-directory
# 取消“-w”选项。可以是用在递归的 make 调用过程中,取消“-C”参数的默认打开“-w”功能。
MAKEFLAGS += --no-print-directory

#选项C，用于开启或者关闭静态代码检查
#调用源代码检查器（默认情况下，“sparse”）C编译的一部分
#使用 'make C=1' 使只重新编译的文件检查。
#使用 'make C=2'使所有源文件检查，无论是否重新编译。
#看文件"Documentation/sparse.txt"的更多细节，包括哪里有"sparse"的效用。
ifeq ("$(origin C)", "command line")
  KBUILD_CHECKSRC = $(C)
endif
ifndef KBUILD_CHECKSRC
  KBUILD_CHECKSRC = 0
endif


# 旧语法 make ... SUBDIRS=$PWD 依然支持
ifdef SUBDIRS
  KBUILD_EXTMOD ?= $(SUBDIRS)
endif
#选项M/SUBDIRS，源码外模块编译时会用到
# 使用make M=dir 指定要构建的外部模块的路径
# 预先设置环境变量KBUILD_EXTMOD
ifeq ("$(origin M)", "command line")
  KBUILD_EXTMOD := $(M)
endif

#如果建立一个外部模块我们不在乎 all:的规则,而_all取决于modules
PHONY += all
ifeq ($(KBUILD_EXTMOD),)
_all: all
else
_all: modules
endif
#定义相关路径
ifeq ($(KBUILD_SRC),)#变量KBUILD_SRC为空时，srctree为当前目录 
        srctree := .
else
        ifeq ($(KBUILD_SRC)/,$(dir $(CURDIR)))
                # 在源树的子目录中构建
                srctree := ..
        else
                srctree := $(KBUILD_SRC)
        endif
endif
objtree		:= .
src		:= $(srctree)
obj		:= $(objtree)
#GNU make 可以识别一个特殊变量“VPATH”。通过变量“VPATH”可以指定依赖
#文件的搜索路径,当规则的依赖文件在当前目录不存在时,make 会在此变量所指定的
#目录下去寻找这些依赖文件
VPATH		:= $(srctree)$(if $(KBUILD_EXTMOD),:$(KBUILD_EXTMOD))
#全局化变量 srctree objtree VPATH 让子make 可见
export srctree objtree VPATH

# 确保 CDPATH 设置不干扰
unexport CDPATH
#########################################################################
# 获取主机类型和主机系统
# 执行shell命令  uname -m 查看主机类型
# sed -e命令进行替换，比如将i386替换成i.86，并将结果放入变量HOSTARCH 。
HOSTARCH := $(shell uname -m | \
	sed -e s/i.86/x86/ \
	    -e s/sun4u/sparc64/ \
	    -e s/arm.*/arm/ \
	    -e s/sa110/arm/ \
	    -e s/ppc64/powerpc/ \
	    -e s/ppc/powerpc/ \
	    -e s/macppc/powerpc/\
	    -e s/sh.*/sh/)
# uname -s 查看主机操作系统，tr '[:upper:]' '[:lower:]'将所有大写变小写，
#然后假如有cygwin，替换成cygwin.*，并将结果放入变量HOSTOS 
HOSTOS := $(shell uname -s | tr '[:upper:]' '[:lower:]' | \
	    sed -e 's/\(cygwin\).*/cygwin/')

export	HOSTARCH HOSTOS

#########################################################################

# 为本地构建设置默认值为零
ifeq ($(HOSTARCH),$(ARCH))
CROSS_COMPILE ?=
endif
#引入.config文件，并将.config文件环境变量设为全局可见。
KCONFIG_CONFIG	?= .config
export KCONFIG_CONFIG

# 选择/bin/bash
CONFIG_SHELL := $(shell if [ -x "$$BASH" ]; then echo $$BASH; \
	  else if [ -x /bin/bash ]; then echo /bin/bash; \
	  else echo sh; fi ; fi)

HOSTCC       = cc
HOSTCXX      = c++
HOSTCFLAGS   = -Wall -Wstrict-prototypes -O2 -fomit-frame-pointer \
		$(if $(CONFIG_TOOLS_DEBUG),-g)
HOSTCXXFLAGS = -O2

ifeq ($(HOSTOS),cygwin)
HOSTCFLAGS	+= -ansi
endif

#------------------------------------------------------------------------------------------
# Mac OS X / Darwin的C预处理器是苹果专用。它产生大量的错误和警告。
#我们想绕过它使用GNU C的CPP。为此我们通过-traditional-cpp选项编译。
#请注意，传统的CPP标志与GNU C的标志没有相同的语义，
#它所做的只是在现有ANSI/ISO C的风格下调用GNU预处理程序。
#苹果的连接器类似，由于新的2级链接多个符号定义被视为错误，因此用 - multiply_defined抑制选择关闭这个错误。
ifeq ($(HOSTOS),darwin)
DARWIN_MAJOR_VERSION	= $(shell sw_vers -productVersion | cut -f 1 -d '.')
DARWIN_MINOR_VERSION	= $(shell sw_vers -productVersion | cut -f 2 -d '.')
os_x_before	= $(shell if [ $(DARWIN_MAJOR_VERSION) -le $(1) -a \
	$(DARWIN_MINOR_VERSION) -le $(2) ] ; then echo "$(3)"; else echo "$(4)"; fi ;)
HOSTCC       = $(call os_x_before, 10, 5, "cc", "gcc")
HOSTCFLAGS  += $(call os_x_before, 10, 4, "-traditional-cpp")
HOSTLDFLAGS += $(call os_x_before, 10, 5, "-multiply_defined suppress")
HOSTLDFLAGS += $(call os_x_before, 10, 7, "", "-Xlinker -no_pie")
endif
#------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------
#决定是否建立内置、模块或两者。通常只是做内置。
#如果我们只有“make modules”，不编译内置对象。
#当我们用 modversions 构建模块，我们需要在递归下降时考虑内置对象，
#为了确保校验是在我们记录他们之前更新。
KBUILD_MODULES :=
KBUILD_BUILTIN := 1
ifeq ($(MAKECMDGOALS),modules)
  KBUILD_BUILTIN := $(if $(CONFIG_MODVERSIONS),1)
endif
#------------------------------------------------------------------------------------------

export KBUILD_MODULES KBUILD_BUILTIN
export KBUILD_CHECKSRC KBUILD_SRC KBUILD_EXTMOD

# 我们需要一些通用的定义（不要试图重新创建文件）
scripts/Kbuild.include: ;
include scripts/Kbuild.include

#------------------------------------------------------------------------------------------
# 定义交叉编译链工具
AS		= $(CROSS_COMPILE)as
# 总是使用 GNU ld
ifneq ($(shell $(CROSS_COMPILE)ld.bfd -v 2> /dev/null),)
LD		= $(CROSS_COMPILE)ld.bfd
else
LD		= $(CROSS_COMPILE)ld
endif
CC		= $(CROSS_COMPILE)gcc
CPP		= $(CC) -E
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm
LDR		= $(CROSS_COMPILE)ldr
STRIP		= $(CROSS_COMPILE)strip
OBJCOPY		= $(CROSS_COMPILE)objcopy
OBJDUMP		= $(CROSS_COMPILE)objdump
AWK		= awk
PERL		= perl
PYTHON		?= python
DTC		?= $(objtree)/scripts/dtc/dtc
CHECK		= sparse

CHECKFLAGS     := -D__linux__ -Dlinux -D__STDC__ -Dunix -D__unix__ \
		  -Wbitwise -Wno-return-void -D__CHECK_ENDIAN__ $(CF)

KBUILD_CPPFLAGS := -D__KERNEL__ -D__UBOOT__

KBUILD_CFLAGS   := -Wall -Wstrict-prototypes \
		   -Wno-format-security \
		   -fno-builtin -ffreestanding
KBUILD_CFLAGS	+= -fshort-wchar
KBUILD_AFLAGS   := -D__ASSEMBLY__
#--------------------------------------------------------------------------------------------


# 从 include/config/uboot.release读取 UBOOTRELEASE  (如果存在的话)
UBOOTRELEASE = $(shell cat include/config/uboot.release 2> /dev/null)
UBOOTVERSION = $(VERSION)$(if $(PATCHLEVEL),.$(PATCHLEVEL)$(if $(SUBLEVEL),.$(SUBLEVEL)))$(EXTRAVERSION)

#以下这些环境变量在.config文件中定义了
export VERSION PATCHLEVEL SUBLEVEL UBOOTRELEASE UBOOTVERSION
export ARCH CPU BOARD VENDOR SOC CPUDIR BOARDDIR
export CONFIG_SHELL HOSTCC HOSTCFLAGS HOSTLDFLAGS CROSS_COMPILE AS LD CC
export CPP AR NM LDR STRIP OBJCOPY OBJDUMP
export MAKE AWK PERL PYTHON
export HOSTCXX HOSTCXXFLAGS CHECK CHECKFLAGS DTC DTC_FLAGS

export KBUILD_CPPFLAGS NOSTDINC_FLAGS UBOOTINCLUDE OBJCOPYFLAGS LDFLAGS
export KBUILD_CFLAGS KBUILD_AFLAGS

#编译时出树模块，把 MODVERDIR 置于模块中树而不是在内核树。内核树可能甚至是只读的。
export MODVERDIR := $(if $(KBUILD_EXTMOD),$(firstword $(KBUILD_EXTMOD))/).tmp_versions

#在查找中忽略这些文件。。。
export RCS_FIND_IGNORE := \( -name SCCS -o -name BitKeeper -o -name .svn -o    \
			  -name CVS -o -name .pc -o -name .hg -o -name .git \) \
			  -prune -o
export RCS_TAR_IGNORE := --exclude SCCS --exclude BitKeeper --exclude .svn \
			 --exclude CVS --exclude .pc --exclude .hg --exclude .git

# ===========================================================================
# 规则共享 *config 目标和构建目标

PHONY += scripts_basic
scripts_basic:
	$(Q)$(MAKE) $(build)=scripts/basic
	$(Q)rm -f .tmp_quiet_recordmcount


# 为了避免出现任何隐含规则，定义一个空命令。
scripts/basic/%: scripts_basic ;

PHONY += outputmakefile
# outputmakefile生成Makefile文件的输出目录，如果使用一个单独的输出目录。这允许在输出目录中方便地使用。
outputmakefile:
ifneq ($(KBUILD_SRC),)
	$(Q)ln -fsn $(srctree) source
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/mkmakefile \
	    $(srctree) $(objtree) $(VERSION) $(PATCHLEVEL)
endif


version_h := include/generated/version_autogenerated.h
timestamp_h := include/generated/timestamp_autogenerated.h

#看UBOOT系统架构文档第二章

# uboot 通过阅读上面的文档知，uboot构建的目标分为与.config有关的目标
# 和与.config 无关的目标两大类。除了这两大类，还有一类特殊的称 single-targets.
# 而与.config有关的目标又分为产生.config文件的配置目标（称之为config-targets）
# 和需要.config文件的构建目标（称为build-targets）。
# 把与.config无关的目标称为no-dot-config_targets
# uboot makefile 下与.config 无关的目标有：clean clobber mrproper等这些目标，
# 例如：命令行下执行make help 或者 make clean
# 此时 目标help 或者 目标 clean 等是不依赖于.config 文件的。
# 这些目标既不需要.config 文件而又不产生.config文件
# 当我们执行命令 make [all] 或者 make menuconfig时
# 此时 目标 all 是需要.config 文件，或者menuconfig目标是生成.config文件的。
# 对于变量mixed-targets表示两个以上目标中含有配置目标（config-target）的目标。
# 此时mixed-targets 中的多个目标中必须有一个以上是配置目标，否则不能称为混合目标。
##
no-dot-config-targets := clean clobber mrproper distclean \
			 help %docs check% coccicheck \
			 ubootversion backup tests

config-targets := 0
mixed-targets  := 0
dot-config     := 1
# 功能：有且仅有no-dot-config-targets目标时 dot-config清0
# 判断 make [TARGET] 目标是否有no-dot-config-targets 有的话，进入判断里面
ifneq ($(filter $(no-dot-config-targets), $(MAKECMDGOALS)),)
    #判断 make [TARGET]是否有除了no-dot-config-targets以外的目标，没有的话，进
    #入把dot-config 清0
	ifeq ($(filter-out $(no-dot-config-targets), $(MAKECMDGOALS)),)
		dot-config := 0
	endif
endif

ifeq ($(KBUILD_EXTMOD),)
        #判断是否有配置目标，有进入置config-targets 为1
        ifneq ($(filter config %config,$(MAKECMDGOALS)),)
                config-targets := 1
            #判断是否为多个目标。若为多个目标，则为混合目标。置位mixed-targets
                ifneq ($(words $(MAKECMDGOALS)),1)
                        mixed-targets := 1
                endif
        endif
endif

# 判断是否是混合目标
ifeq ($(mixed-targets),1)
# 是混合目标，执行下面的脚本 

PHONY += $(MAKECMDGOALS) __build_one_by_one

$(filter-out __build_one_by_one, $(MAKECMDGOALS)): __build_one_by_one
	@:

__build_one_by_one:
	$(Q)set -e; \
	for i in $(MAKECMDGOALS); do \
		$(MAKE) -f $(srctree)/Makefile $$i; \
	done

else # 不是混合目标

ifeq ($(config-targets),1)
# 若仅是配置目标时执行以下脚本


KBUILD_DEFCONFIG := sandbox_defconfig
export KBUILD_DEFCONFIG KBUILD_KCONFIG

config: scripts_basic outputmakefile FORCE
	$(Q)$(MAKE) $(build)=scripts/kconfig $@

%config: scripts_basic outputmakefile FORCE
	$(Q)$(MAKE) $(build)=scripts/kconfig $@

else
# 不是混合目标，也不是配置目标。包含 no-dot-config-targets build-targets 等 
PHONY += scripts
scripts: scripts_basic include/config/auto.conf
	$(Q)$(MAKE) $(build)=$(@)

ifeq ($(dot-config),1)
# Read in config
-include include/config/auto.conf

# Read in dependencies to all Kconfig* files, make sure to run
# oldconfig if changes are detected.
-include include/config/auto.conf.cmd

# To avoid any implicit rule to kick in, define an empty command
$(KCONFIG_CONFIG) include/config/auto.conf.cmd: ;

# If .config is newer than include/config/auto.conf, someone tinkered
# with it and forgot to run make oldconfig.
# if auto.conf.cmd is missing then we are probably in a cleaned tree so
# we execute the config step to be sure to catch updated Kconfig files
include/config/%.conf: $(KCONFIG_CONFIG) include/config/auto.conf.cmd
	$(Q)$(MAKE) -f $(srctree)/Makefile silentoldconfig
	@# If the following part fails, include/config/auto.conf should be
	@# deleted so "make silentoldconfig" will be re-run on the next build.
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.autoconf || \
		{ rm -f include/config/auto.conf; false; }
	@# include/config.h has been updated after "make silentoldconfig".
	@# We need to touch include/config/auto.conf so it gets newer
	@# than include/config.h.
	@# Otherwise, 'make silentoldconfig' would be invoked twice.
	$(Q)touch include/config/auto.conf

u-boot.cfg spl/u-boot.cfg tpl/u-boot.cfg: include/config.h FORCE
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.autoconf $(@)

-include include/autoconf.mk
-include include/autoconf.mk.dep

# We want to include arch/$(ARCH)/config.mk only when include/config/auto.conf
# is up-to-date. When we switch to a different board configuration, old CONFIG
# macros are still remaining in include/config/auto.conf. Without the following
# gimmick, wrong config.mk would be included leading nasty warnings/errors.
ifneq ($(wildcard $(KCONFIG_CONFIG)),)
ifneq ($(wildcard include/config/auto.conf),)
autoconf_is_old := $(shell find . -path ./$(KCONFIG_CONFIG) -newer \
						include/config/auto.conf)
ifeq ($(autoconf_is_old),)
include config.mk
include arch/$(ARCH)/Makefile
endif
endif
endif

# These are set by the arch-specific config.mk. Make sure they are exported
# so they can be used when building an EFI application.
export EFI_LDS		# Filename of EFI link script in arch/$(ARCH)/lib
export EFI_CRT0		# Filename of EFI CRT0 in arch/$(ARCH)/lib
export EFI_RELOC	# Filename of EFU relocation code in arch/$(ARCH)/lib
export CFLAGS_EFI	# Compiler flags to add when building EFI app
export CFLAGS_NON_EFI	# Compiler flags to remove when building EFI app
export EFI_TARGET	# binutils target if EFI is natively supported

# If board code explicitly specified LDSCRIPT or CONFIG_SYS_LDSCRIPT, use
# that (or fail if absent).  Otherwise, search for a linker script in a
# standard location.

ifndef LDSCRIPT
	#LDSCRIPT := $(srctree)/board/$(BOARDDIR)/u-boot.lds.debug
	ifdef CONFIG_SYS_LDSCRIPT
		# need to strip off double quotes
		LDSCRIPT := $(srctree)/$(CONFIG_SYS_LDSCRIPT:"%"=%)
	endif
endif

# If there is no specified link script, we look in a number of places for it
ifndef LDSCRIPT
	ifeq ($(wildcard $(LDSCRIPT)),)
		LDSCRIPT := $(srctree)/board/$(BOARDDIR)/u-boot.lds
	endif
	ifeq ($(wildcard $(LDSCRIPT)),)
		LDSCRIPT := $(srctree)/$(CPUDIR)/u-boot.lds
	endif
	ifeq ($(wildcard $(LDSCRIPT)),)
		LDSCRIPT := $(srctree)/arch/$(ARCH)/cpu/u-boot.lds
	endif
endif

else
# Dummy target needed, because used as prerequisite
include/config/auto.conf: ;
endif # $(dot-config)

#
# Xtensa linker script cannot be preprocessed with -ansi because of
# preprocessor operations on strings that don't make C identifiers.
#
ifeq ($(CONFIG_XTENSA),)
LDPPFLAGS	+= -ansi
endif

ifdef CONFIG_CC_OPTIMIZE_FOR_SIZE
KBUILD_CFLAGS	+= -Os
else
KBUILD_CFLAGS	+= -O2
endif

KBUILD_CFLAGS += $(call cc-option,-fno-stack-protector)
KBUILD_CFLAGS += $(call cc-option,-fno-delete-null-pointer-checks)

KBUILD_CFLAGS	+= -g
# $(KBUILD_AFLAGS) sets -g, which causes gcc to pass a suitable -g<format>
# option to the assembler.
KBUILD_AFLAGS	+= -g

# Report stack usage if supported
ifeq ($(shell $(CONFIG_SHELL) $(srctree)/scripts/gcc-stack-usage.sh $(CC)),y)
	KBUILD_CFLAGS += -fstack-usage
endif

KBUILD_CFLAGS += $(call cc-option,-Wno-format-nonliteral)

# turn jbsr into jsr for m68k
ifeq ($(ARCH),m68k)
ifeq ($(findstring 3.4,$(shell $(CC) --version)),3.4)
KBUILD_AFLAGS += -Wa,-gstabs,-S
endif
endif

# Prohibit date/time macros, which would make the build non-deterministic
KBUILD_CFLAGS   += $(call cc-option,-Werror=date-time)

include scripts/Makefile.extrawarn

# Add user supplied CPPFLAGS, AFLAGS and CFLAGS as the last assignments
KBUILD_CPPFLAGS += $(KCPPFLAGS)
KBUILD_AFLAGS += $(KAFLAGS)
KBUILD_CFLAGS += $(KCFLAGS)

# Use UBOOTINCLUDE when you must reference the include/ directory.
# Needed to be compatible with the O= option
UBOOTINCLUDE    := \
		-Iinclude \
		$(if $(KBUILD_SRC), -I$(srctree)/include) \
		$(if $(CONFIG_$(SPL_)SYS_THUMB_BUILD), \
			$(if $(CONFIG_HAS_THUMB2),, \
				-I$(srctree)/arch/$(ARCH)/thumb1/include),) \
		-I$(srctree)/arch/$(ARCH)/include \
		-include $(srctree)/include/linux/kconfig.h

NOSTDINC_FLAGS += -nostdinc -isystem $(shell $(CC) -print-file-name=include)
CHECKFLAGS     += $(NOSTDINC_FLAGS)

# FIX ME
cpp_flags := $(KBUILD_CPPFLAGS) $(PLATFORM_CPPFLAGS) $(UBOOTINCLUDE) \
							$(NOSTDINC_FLAGS)
c_flags := $(KBUILD_CFLAGS) $(cpp_flags)

#########################################################################
# U-Boot objects....order is important (i.e. start must be first)

HAVE_VENDOR_COMMON_LIB = $(if $(wildcard $(srctree)/board/$(VENDOR)/common/Makefile),y,n)

libs-y += lib/
libs-$(HAVE_VENDOR_COMMON_LIB) += board/$(VENDOR)/common/
libs-$(CONFIG_OF_EMBED) += dts/
libs-y += fs/
libs-y += net/
libs-y += disk/
libs-y += drivers/
libs-y += drivers/dma/
libs-y += drivers/gpio/
libs-y += drivers/i2c/
libs-y += drivers/mtd/
libs-$(CONFIG_CMD_NAND) += drivers/mtd/nand/
libs-y += drivers/mtd/onenand/
libs-$(CONFIG_CMD_UBI) += drivers/mtd/ubi/
libs-y += drivers/mtd/spi/
libs-y += drivers/net/
libs-y += drivers/net/phy/
libs-y += drivers/pci/
libs-y += drivers/power/ \
	drivers/power/domain/ \
	drivers/power/fuel_gauge/ \
	drivers/power/mfd/ \
	drivers/power/pmic/ \
	drivers/power/battery/ \
	drivers/power/regulator/
libs-y += drivers/spi/
libs-$(CONFIG_FMAN_ENET) += drivers/net/fm/
libs-$(CONFIG_SYS_FSL_DDR) += drivers/ddr/fsl/
libs-$(CONFIG_SYS_FSL_MMDC) += drivers/ddr/fsl/
libs-$(CONFIG_ALTERA_SDRAM) += drivers/ddr/altera/
libs-y += drivers/serial/
libs-y += drivers/usb/dwc3/
libs-y += drivers/usb/common/
libs-y += drivers/usb/emul/
libs-y += drivers/usb/eth/
libs-y += drivers/usb/gadget/
libs-y += drivers/usb/gadget/udc/
libs-y += drivers/usb/host/
libs-y += drivers/usb/musb/
libs-y += drivers/usb/musb-new/
libs-y += drivers/usb/phy/
libs-y += drivers/usb/ulpi/
libs-y += cmd/
libs-y += common/
libs-y += env/
libs-$(CONFIG_API) += api/
libs-$(CONFIG_HAS_POST) += post/
libs-y += test/
libs-y += test/dm/
libs-$(CONFIG_UT_ENV) += test/env/
libs-$(CONFIG_UT_OVERLAY) += test/overlay/

libs-y += $(if $(BOARDDIR),board/$(BOARDDIR)/)

libs-y := $(sort $(libs-y))

u-boot-dirs	:= $(patsubst %/,%,$(filter %/, $(libs-y))) tools examples

u-boot-alldirs	:= $(sort $(u-boot-dirs) $(patsubst %/,%,$(filter %/, $(libs-))))

libs-y		:= $(patsubst %/, %/built-in.o, $(libs-y))

u-boot-init := $(head-y)
u-boot-main := $(libs-y)


# Add GCC lib
ifeq ($(CONFIG_USE_PRIVATE_LIBGCC),y)
PLATFORM_LIBGCC = arch/$(ARCH)/lib/lib.a
else
PLATFORM_LIBGCC := -L $(shell dirname `$(CC) $(c_flags) -print-libgcc-file-name`) -lgcc
endif
PLATFORM_LIBS += $(PLATFORM_LIBGCC)
export PLATFORM_LIBS
export PLATFORM_LIBGCC

# Special flags for CPP when processing the linker script.
# Pass the version down so we can handle backwards compatibility
# on the fly.
LDPPFLAGS += \
	-include $(srctree)/include/u-boot/u-boot.lds.h \
	-DCPUDIR=$(CPUDIR) \
	$(shell $(LD) --version | \
	  sed -ne 's/GNU ld version \([0-9][0-9]*\)\.\([0-9][0-9]*\).*/-DLD_MAJOR=\1 -DLD_MINOR=\2/p')

#########################################################################
#########################################################################

ifneq ($(CONFIG_BOARD_SIZE_LIMIT),)
BOARD_SIZE_CHECK = \
	@actual=`wc -c $@ | awk '{print $$1}'`; \
	limit=`printf "%d" $(CONFIG_BOARD_SIZE_LIMIT)`; \
	if test $$actual -gt $$limit; then \
		echo "$@ exceeds file size limit:" >&2 ; \
		echo "  limit:  $$limit bytes" >&2 ; \
		echo "  actual: $$actual bytes" >&2 ; \
		echo "  excess: $$((actual - limit)) bytes" >&2; \
		exit 1; \
	fi
else
BOARD_SIZE_CHECK =
endif

# Statically apply RELA-style relocations (currently arm64 only)
# This is useful for arm64 where static relocation needs to be performed on
# the raw binary, but certain simulators only accept an ELF file (but don't
# do the relocation).
ifneq ($(CONFIG_STATIC_RELA),)
# $(1) is u-boot ELF, $(2) is u-boot bin, $(3) is text base
DO_STATIC_RELA = \
	start=$$($(NM) $(1) | grep __rel_dyn_start | cut -f 1 -d ' '); \
	end=$$($(NM) $(1) | grep __rel_dyn_end | cut -f 1 -d ' '); \
	tools/relocate-rela $(2) $(3) $$start $$end
else
DO_STATIC_RELA =
endif

# Always append ALL so that arch config.mk's can add custom ones
ALL-y += u-boot.srec u-boot.bin u-boot.sym System.map binary_size_check

ALL-$(CONFIG_ONENAND_U_BOOT) += u-boot-onenand.bin
ifeq ($(CONFIG_SPL_FSL_PBL),y)
ALL-$(CONFIG_RAMBOOT_PBL) += u-boot-with-spl-pbl.bin
else
ifneq ($(CONFIG_SECURE_BOOT), y)
# For Secure Boot The Image needs to be signed and Header must also
# be included. So The image has to be built explicitly
ALL-$(CONFIG_RAMBOOT_PBL) += u-boot.pbl
endif
endif
ALL-$(CONFIG_SPL) += spl/u-boot-spl.bin
ifeq ($(CONFIG_MX6)$(CONFIG_SECURE_BOOT), yy)
ALL-$(CONFIG_SPL_FRAMEWORK) += u-boot-ivt.img
else
ALL-$(CONFIG_SPL_FRAMEWORK) += u-boot.img
endif
ALL-$(CONFIG_TPL) += tpl/u-boot-tpl.bin
ALL-$(CONFIG_OF_SEPARATE) += u-boot.dtb
ifeq ($(CONFIG_SPL_FRAMEWORK),y)
ALL-$(CONFIG_OF_SEPARATE) += u-boot-dtb.img
endif
ALL-$(CONFIG_OF_HOSTFILE) += u-boot.dtb
ifneq ($(CONFIG_SPL_TARGET),)
ALL-$(CONFIG_SPL) += $(CONFIG_SPL_TARGET:"%"=%)
endif
ALL-$(CONFIG_REMAKE_ELF) += u-boot.elf
ALL-$(CONFIG_EFI_APP) += u-boot-app.efi
ALL-$(CONFIG_EFI_STUB) += u-boot-payload.efi

ifneq ($(BUILD_ROM)$(CONFIG_BUILD_ROM),)
ALL-$(CONFIG_X86_RESET_VECTOR) += u-boot.rom
endif

# Build a combined spl + u-boot image for sunxi
ifeq ($(CONFIG_ARCH_SUNXI)$(CONFIG_SPL),yy)
ALL-y += u-boot-sunxi-with-spl.bin
endif

# enable combined SPL/u-boot/dtb rules for tegra
ifeq ($(CONFIG_TEGRA)$(CONFIG_SPL),yy)
ALL-y += u-boot-tegra.bin u-boot-nodtb-tegra.bin
ALL-$(CONFIG_OF_SEPARATE) += u-boot-dtb-tegra.bin
endif

# Add optional build target if defined in board/cpu/soc headers
ifneq ($(CONFIG_BUILD_TARGET),)
ALL-y += $(CONFIG_BUILD_TARGET:"%"=%)
endif

ifneq ($(CONFIG_SYS_INIT_SP_BSS_OFFSET),)
ALL-y += init_sp_bss_offset_check
endif

LDFLAGS_u-boot += $(LDFLAGS_FINAL)

# Avoid 'Not enough room for program headers' error on binutils 2.28 onwards.
LDFLAGS_u-boot += $(call ld-option, --no-dynamic-linker)

ifeq ($(CONFIG_ARC)$(CONFIG_NIOS2)$(CONFIG_X86)$(CONFIG_XTENSA),)
LDFLAGS_u-boot += -Ttext $(CONFIG_SYS_TEXT_BASE)
endif

# Normally we fill empty space with 0xff
quiet_cmd_objcopy = OBJCOPY $@
cmd_objcopy = $(OBJCOPY) --gap-fill=0xff $(OBJCOPYFLAGS) \
	$(OBJCOPYFLAGS_$(@F)) $< $@

# Provide a version which does not do this, for use by EFI
quiet_cmd_zobjcopy = OBJCOPY $@
cmd_zobjcopy = $(OBJCOPY) $(OBJCOPYFLAGS) $(OBJCOPYFLAGS_$(@F)) $< $@

quiet_cmd_efipayload = OBJCOPY $@
cmd_efipayload = $(OBJCOPY) -I binary -O $(EFIPAYLOAD_BFDTARGET) -B $(EFIPAYLOAD_BFDARCH) $< $@

MKIMAGEOUTPUT ?= /dev/null

quiet_cmd_mkimage = MKIMAGE $@
cmd_mkimage = $(objtree)/tools/mkimage $(MKIMAGEFLAGS_$(@F)) -d $< $@ \
	$(if $(KBUILD_VERBOSE:1=), >$(MKIMAGEOUTPUT))

quiet_cmd_mkfitimage = MKIMAGE $@
cmd_mkfitimage = $(objtree)/tools/mkimage $(MKIMAGEFLAGS_$(@F)) -f $(U_BOOT_ITS) -E $@ \
	$(if $(KBUILD_VERBOSE:1=), >$(MKIMAGEOUTPUT))

quiet_cmd_cat = CAT     $@
cmd_cat = cat $(filter-out $(PHONY), $^) > $@

append = cat $(filter-out $< $(PHONY), $^) >> $@

quiet_cmd_pad_cat = CAT     $@
cmd_pad_cat = $(cmd_objcopy) && $(append) || rm -f $@

cfg: u-boot.cfg

quiet_cmd_cfgcheck = CFGCHK  $2
cmd_cfgcheck = $(srctree)/scripts/check-config.sh $2 \
		$(srctree)/scripts/config_whitelist.txt $(srctree)

all:		$(ALL-y) cfg
ifeq ($(CONFIG_DM_I2C_COMPAT)$(CONFIG_SANDBOX),y)
	@echo "===================== WARNING ======================"
	@echo "This board uses CONFIG_DM_I2C_COMPAT. Please remove"
	@echo "(possibly in a subsequent patch in your series)"
	@echo "before sending patches to the mailing list."
	@echo "===================================================="
endif
	@# Check that this build does not use CONFIG options that we do not
	@# know about unless they are in Kconfig. All the existing CONFIG
	@# options are whitelisted, so new ones should not be added.
	$(call cmd,cfgcheck,u-boot.cfg)

PHONY += dtbs
dtbs: dts/dt.dtb
	@:
dts/dt.dtb: u-boot
	$(Q)$(MAKE) $(build)=dts dtbs

quiet_cmd_copy = COPY    $@
      cmd_copy = cp $< $@

ifeq ($(CONFIG_MULTI_DTB_FIT),y)

fit-dtb.blob: dts/dt.dtb FORCE
	$(call if_changed,mkimage)

MKIMAGEFLAGS_fit-dtb.blob = -f auto -A $(ARCH) -T firmware -C none -O u-boot \
	-a 0 -e 0 -E \
	$(patsubst %,-b arch/$(ARCH)/dts/%.dtb,$(subst ",,$(CONFIG_OF_LIST))) -d /dev/null

u-boot-fit-dtb.bin: u-boot-nodtb.bin fit-dtb.blob
	$(call if_changed,cat)

u-boot.bin: u-boot-fit-dtb.bin FORCE
	$(call if_changed,copy)
else ifeq ($(CONFIG_OF_SEPARATE),y)
u-boot-dtb.bin: u-boot-nodtb.bin dts/dt.dtb FORCE
	$(call if_changed,cat)

u-boot.bin: u-boot-dtb.bin FORCE
	$(call if_changed,copy)
else
u-boot.bin: u-boot-nodtb.bin FORCE
	$(call if_changed,copy)
endif

%.imx: %.bin
	$(Q)$(MAKE) $(build)=arch/arm/mach-imx $@

%.vyb: %.imx
	$(Q)$(MAKE) $(build)=arch/arm/cpu/armv7/vf610 $@

quiet_cmd_copy = COPY    $@
      cmd_copy = cp $< $@

u-boot.dtb: dts/dt.dtb
	$(call cmd,copy)

OBJCOPYFLAGS_u-boot.hex := -O ihex

OBJCOPYFLAGS_u-boot.srec := -O srec

u-boot.hex u-boot.srec: u-boot FORCE
	$(call if_changed,objcopy)

OBJCOPYFLAGS_u-boot-elf.srec := $(OBJCOPYFLAGS_u-boot.srec)

u-boot-elf.srec: u-boot.elf FORCE
	$(call if_changed,objcopy)

OBJCOPYFLAGS_u-boot-spl.srec = $(OBJCOPYFLAGS_u-boot.srec)

spl/u-boot-spl.srec: spl/u-boot-spl FORCE
	$(call if_changed,objcopy)

OBJCOPYFLAGS_u-boot-nodtb.bin := -O binary \
		$(if $(CONFIG_X86_16BIT_INIT),-R .start16 -R .resetvec)

binary_size_check: u-boot-nodtb.bin FORCE
	@file_size=$(shell wc -c u-boot-nodtb.bin | awk '{print $$1}') ; \
	map_size=$(shell cat u-boot.map | \
		awk '/_image_copy_start/ {start = $$1} /_image_binary_end/ {end = $$1} END {if (start != "" && end != "") print "ibase=16; " toupper(end) " - " toupper(start)}' \
		| sed 's/0X//g' \
		| bc); \
	if [ "" != "$$map_size" ]; then \
		if test $$map_size -ne $$file_size; then \
			echo "u-boot.map shows a binary size of $$map_size" >&2 ; \
			echo "  but u-boot-nodtb.bin shows $$file_size" >&2 ; \
			exit 1; \
		fi \
	fi

ifneq ($(CONFIG_SYS_INIT_SP_BSS_OFFSET),)
ifneq ($(CONFIG_SYS_MALLOC_F_LEN),)
subtract_sys_malloc_f_len = space=$$(($${space} - $(CONFIG_SYS_MALLOC_F_LEN)))
else
subtract_sys_malloc_f_len = true
endif
# The 1/4 margin below is somewhat arbitrary. The likely initial SP usage is
# so low that the DTB could probably use 90%+ of the available space, for
# current values of CONFIG_SYS_INIT_SP_BSS_OFFSET at least. However, let's be
# safe for now and tweak this later if space becomes tight.
# A rejected alternative would be to check that some absolute minimum stack
# space was available. However, since CONFIG_SYS_INIT_SP_BSS_OFFSET is
# deliberately build-specific, to take account of build-to-build stack usage
# differences due to different feature sets, there is no common absolute value
# to check against.
init_sp_bss_offset_check: u-boot.dtb FORCE
	@dtb_size=$(shell wc -c u-boot.dtb | awk '{print $$1}') ; \
	space=$(CONFIG_SYS_INIT_SP_BSS_OFFSET) ; \
	$(subtract_sys_malloc_f_len) ; \
	quarter_space=$$(($${space} / 4)) ; \
	if [ $${dtb_size} -gt $${quarter_space} ]; then \
		echo "u-boot.dtb is larger than 1 quarter of " >&2 ; \
		echo "(CONFIG_SYS_INIT_SP_BSS_OFFSET - CONFIG_SYS_MALLOC_F_LEN)" >&2 ; \
		exit 1 ; \
	fi
endif

u-boot-nodtb.bin: u-boot FORCE
	$(call if_changed,objcopy)
	$(call DO_STATIC_RELA,$<,$@,$(CONFIG_SYS_TEXT_BASE))
	$(BOARD_SIZE_CHECK)

u-boot.ldr:	u-boot
		$(CREATE_LDR_ENV)
		$(LDR) -T $(CONFIG_CPU) -c $@ $< $(LDR_FLAGS)
		$(BOARD_SIZE_CHECK)

# binman
# ---------------------------------------------------------------------------
quiet_cmd_binman = BINMAN  $@
cmd_binman = $(srctree)/tools/binman/binman -d u-boot.dtb -O . \
		-I . -I $(srctree)/board/$(BOARDDIR) $<

OBJCOPYFLAGS_u-boot.ldr.hex := -I binary -O ihex

OBJCOPYFLAGS_u-boot.ldr.srec := -I binary -O srec

u-boot.ldr.hex u-boot.ldr.srec: u-boot.ldr FORCE
	$(call if_changed,objcopy)

#
# U-Boot entry point, needed for booting of full-blown U-Boot
# from the SPL U-Boot version.
#
ifndef CONFIG_SYS_UBOOT_START
CONFIG_SYS_UBOOT_START := 0
endif

# Create a file containing the configuration options the image was built with
quiet_cmd_cpp_cfg = CFG     $@
cmd_cpp_cfg = $(CPP) -Wp,-MD,$(depfile) $(cpp_flags) $(LDPPFLAGS) -ansi \
	-DDO_DEPS_ONLY -D__ASSEMBLY__ -x assembler-with-cpp -P -dM -E -o $@ $<

# Boards with more complex image requirments can provide an .its source file
# or a generator script
ifneq ($(CONFIG_SPL_FIT_SOURCE),"")
U_BOOT_ITS = $(subst ",,$(CONFIG_SPL_FIT_SOURCE))
else
ifneq ($(CONFIG_SPL_FIT_GENERATOR),"")
U_BOOT_ITS := u-boot.its
$(U_BOOT_ITS): FORCE
	$(srctree)/$(CONFIG_SPL_FIT_GENERATOR) \
	$(patsubst %,arch/$(ARCH)/dts/%.dtb,$(subst ",,$(CONFIG_OF_LIST))) > $@
endif
endif

ifdef CONFIG_SPL_LOAD_FIT
MKIMAGEFLAGS_u-boot.img = -f auto -A $(ARCH) -T firmware -C none -O u-boot \
	-a $(CONFIG_SYS_TEXT_BASE) -e $(CONFIG_SYS_UBOOT_START) \
	-n "U-Boot $(UBOOTRELEASE) for $(BOARD) board" -E \
	$(patsubst %,-b arch/$(ARCH)/dts/%.dtb,$(subst ",,$(CONFIG_OF_LIST)))
else
MKIMAGEFLAGS_u-boot.img = -A $(ARCH) -T firmware -C none -O u-boot \
	-a $(CONFIG_SYS_TEXT_BASE) -e $(CONFIG_SYS_UBOOT_START) \
	-n "U-Boot $(UBOOTRELEASE) for $(BOARD) board"
MKIMAGEFLAGS_u-boot-ivt.img = -A $(ARCH) -T firmware_ivt -C none -O u-boot \
	-a $(CONFIG_SYS_TEXT_BASE) -e $(CONFIG_SYS_UBOOT_START) \
	-n "U-Boot $(UBOOTRELEASE) for $(BOARD) board"
u-boot-ivt.img: MKIMAGEOUTPUT = u-boot-ivt.img.log
CLEAN_FILES += u-boot-ivt.img.log u-boot-dtb.imx.log SPL.log u-boot.imx.log
endif

MKIMAGEFLAGS_u-boot-dtb.img = $(MKIMAGEFLAGS_u-boot.img)

MKIMAGEFLAGS_u-boot.kwb = -n $(srctree)/$(CONFIG_SYS_KWD_CONFIG:"%"=%) \
	-T kwbimage -a $(CONFIG_SYS_TEXT_BASE) -e $(CONFIG_SYS_TEXT_BASE)

MKIMAGEFLAGS_u-boot-spl.kwb = -n $(srctree)/$(CONFIG_SYS_KWD_CONFIG:"%"=%) \
	-T kwbimage -a $(CONFIG_SYS_TEXT_BASE) -e $(CONFIG_SYS_TEXT_BASE) \
	$(if $(KEYDIR),-k $(KEYDIR))

MKIMAGEFLAGS_u-boot.pbl = -n $(srctree)/$(CONFIG_SYS_FSL_PBL_RCW:"%"=%) \
		-R $(srctree)/$(CONFIG_SYS_FSL_PBL_PBI:"%"=%) -T pblimage

u-boot-dtb.img u-boot.img u-boot.kwb u-boot.pbl u-boot-ivt.img: \
		$(if $(CONFIG_SPL_LOAD_FIT),u-boot-nodtb.bin dts/dt.dtb,u-boot.bin) FORCE
	$(call if_changed,mkimage)

u-boot.itb: u-boot-nodtb.bin dts/dt.dtb $(U_BOOT_ITS) FORCE
	$(call if_changed,mkfitimage)
	$(BOARD_SIZE_CHECK)

u-boot-spl.kwb: u-boot.img spl/u-boot-spl.bin FORCE
	$(call if_changed,mkimage)

u-boot.sha1:	u-boot.bin
		tools/ubsha1 u-boot.bin

u-boot.dis:	u-boot
		$(OBJDUMP) -d $< > $@

ifdef CONFIG_TPL
SPL_PAYLOAD := tpl/u-boot-with-tpl.bin
else
SPL_PAYLOAD := u-boot.bin
endif

OBJCOPYFLAGS_u-boot-with-spl.bin = -I binary -O binary \
				   --pad-to=$(CONFIG_SPL_PAD_TO)
u-boot-with-spl.bin: spl/u-boot-spl.bin $(SPL_PAYLOAD) FORCE
	$(call if_changed,pad_cat)

MKIMAGEFLAGS_lpc32xx-spl.img = -T lpc32xximage -a $(CONFIG_SPL_TEXT_BASE)

lpc32xx-spl.img: spl/u-boot-spl.bin FORCE
	$(call if_changed,mkimage)

OBJCOPYFLAGS_lpc32xx-boot-0.bin = -I binary -O binary --pad-to=$(CONFIG_SPL_PAD_TO)

lpc32xx-boot-0.bin: lpc32xx-spl.img FORCE
	$(call if_changed,objcopy)

OBJCOPYFLAGS_lpc32xx-boot-1.bin = -I binary -O binary --pad-to=$(CONFIG_SPL_PAD_TO)

lpc32xx-boot-1.bin: lpc32xx-spl.img FORCE
	$(call if_changed,objcopy)

lpc32xx-full.bin: lpc32xx-boot-0.bin lpc32xx-boot-1.bin u-boot.img FORCE
	$(call if_changed,cat)

CLEAN_FILES += lpc32xx-*

OBJCOPYFLAGS_u-boot-with-tpl.bin = -I binary -O binary \
				   --pad-to=$(CONFIG_TPL_PAD_TO)
tpl/u-boot-with-tpl.bin: tpl/u-boot-tpl.bin u-boot.bin FORCE
	$(call if_changed,pad_cat)

SPL: spl/u-boot-spl.bin FORCE
	$(Q)$(MAKE) $(build)=arch/arm/mach-imx $@

u-boot-with-spl.imx u-boot-with-nand-spl.imx: SPL u-boot.bin FORCE
	$(Q)$(MAKE) $(build)=arch/arm/mach-imx $@

MKIMAGEFLAGS_u-boot.ubl = -n $(UBL_CONFIG) -T ublimage -e $(CONFIG_SYS_TEXT_BASE)

u-boot.ubl: u-boot-with-spl.bin FORCE
	$(call if_changed,mkimage)

MKIMAGEFLAGS_u-boot-spl.ais = -s -n $(if $(CONFIG_AIS_CONFIG_FILE), \
	$(srctree)/$(CONFIG_AIS_CONFIG_FILE:"%"=%),"/dev/null") \
	-T aisimage -e $(CONFIG_SPL_TEXT_BASE)
spl/u-boot-spl.ais: spl/u-boot-spl.bin FORCE
	$(call if_changed,mkimage)

OBJCOPYFLAGS_u-boot.ais = -I binary -O binary --pad-to=$(CONFIG_SPL_PAD_TO)
u-boot.ais: spl/u-boot-spl.ais u-boot.img FORCE
	$(call if_changed,pad_cat)

u-boot-signed.sb: u-boot.bin spl/u-boot-spl.bin
	$(Q)$(MAKE) $(build)=arch/arm/cpu/arm926ejs/mxs u-boot-signed.sb
u-boot.sb: u-boot.bin spl/u-boot-spl.bin
	$(Q)$(MAKE) $(build)=arch/arm/cpu/arm926ejs/mxs u-boot.sb

# On x600 (SPEAr600) U-Boot is appended to U-Boot SPL.
# Both images are created using mkimage (crc etc), so that the ROM
# bootloader can check its integrity. Padding needs to be done to the
# SPL image (with mkimage header) and not the binary. Otherwise the resulting image
# which is loaded/copied by the ROM bootloader to SRAM doesn't fit.
# The resulting image containing both U-Boot images is called u-boot.spr
MKIMAGEFLAGS_u-boot-spl.img = -A $(ARCH) -T firmware -C none \
	-a $(CONFIG_SPL_TEXT_BASE) -e $(CONFIG_SPL_TEXT_BASE) -n XLOADER
spl/u-boot-spl.img: spl/u-boot-spl.bin FORCE
	$(call if_changed,mkimage)

OBJCOPYFLAGS_u-boot.spr = -I binary -O binary --pad-to=$(CONFIG_SPL_PAD_TO) \
			  --gap-fill=0xff
u-boot.spr: spl/u-boot-spl.img u-boot.img FORCE
	$(call if_changed,pad_cat)

ifneq ($(CONFIG_ARCH_SOCFPGA),)
quiet_cmd_socboot = SOCBOOT $@
cmd_socboot = cat	spl/u-boot-spl.sfp spl/u-boot-spl.sfp	\
			spl/u-boot-spl.sfp spl/u-boot-spl.sfp	\
			u-boot.img > $@ || rm -f $@
u-boot-with-spl.sfp: spl/u-boot-spl.sfp u-boot.img FORCE
	$(call if_changed,socboot)
endif

# x86 uses a large ROM. We fill it with 0xff, put the 16-bit stuff (including
# reset vector) at the top, Intel ME descriptor at the bottom, and U-Boot in
# the middle. This is handled by binman based on an image description in the
# board's device tree.
ifneq ($(CONFIG_X86_RESET_VECTOR),)
rom: u-boot.rom FORCE

refcode.bin: $(srctree)/board/$(BOARDDIR)/refcode.bin FORCE
	$(call if_changed,copy)

quiet_cmd_ldr = LD      $@
cmd_ldr = $(LD) $(LDFLAGS_$(@F)) \
	       $(filter-out FORCE,$^) -o $@

u-boot.rom: u-boot-x86-16bit.bin u-boot.bin \
		$(if $(CONFIG_SPL_X86_16BIT_INIT),spl/u-boot-spl.bin) \
		$(if $(CONFIG_HAVE_REFCODE),refcode.bin) FORCE
	$(call if_changed,binman)

OBJCOPYFLAGS_u-boot-x86-16bit.bin := -O binary -j .start16 -j .resetvec
u-boot-x86-16bit.bin: u-boot FORCE
	$(call if_changed,objcopy)
endif

ifneq ($(CONFIG_ARCH_SUNXI),)
ifeq ($(CONFIG_ARM64),)
u-boot-sunxi-with-spl.bin: spl/sunxi-spl.bin u-boot.img u-boot.dtb FORCE
	$(call if_changed,binman)
else
u-boot-sunxi-with-spl.bin: spl/sunxi-spl.bin u-boot.itb FORCE
	$(call if_changed,cat)
endif
endif

ifneq ($(CONFIG_TEGRA),)
ifneq ($(CONFIG_BINMAN),)
u-boot-dtb-tegra.bin u-boot-tegra.bin u-boot-nodtb-tegra.bin: \
		spl/u-boot-spl u-boot.bin FORCE
	$(call if_changed,binman)
else
OBJCOPYFLAGS_u-boot-nodtb-tegra.bin = -O binary --pad-to=$(CONFIG_SYS_TEXT_BASE)
u-boot-nodtb-tegra.bin: spl/u-boot-spl u-boot-nodtb.bin FORCE
	$(call if_changed,pad_cat)

OBJCOPYFLAGS_u-boot-tegra.bin = -O binary --pad-to=$(CONFIG_SYS_TEXT_BASE)
u-boot-tegra.bin: spl/u-boot-spl u-boot.bin FORCE
	$(call if_changed,pad_cat)

u-boot-dtb-tegra.bin: u-boot-tegra.bin FORCE
	$(call if_changed,copy)
endif  # binman
endif

OBJCOPYFLAGS_u-boot-app.efi := $(OBJCOPYFLAGS_EFI)
u-boot-app.efi: u-boot FORCE
	$(call if_changed,zobjcopy)

u-boot.bin.o: u-boot.bin FORCE
	$(call if_changed,efipayload)

u-boot-payload.lds: $(LDSCRIPT_EFI) FORCE
	$(call if_changed_dep,cpp_lds)

# Rule to link the EFI payload which contains a stub and a U-Boot binary
quiet_cmd_u-boot_payload ?= LD      $@
      cmd_u-boot_payload ?= $(LD) $(LDFLAGS_EFI_PAYLOAD) -o $@ \
      -T u-boot-payload.lds arch/x86/cpu/call32.o \
      lib/efi/efi.o lib/efi/efi_stub.o u-boot.bin.o \
      $(addprefix arch/$(ARCH)/lib/,$(EFISTUB))

u-boot-payload: u-boot.bin.o u-boot-payload.lds FORCE
	$(call if_changed,u-boot_payload)

OBJCOPYFLAGS_u-boot-payload.efi := $(OBJCOPYFLAGS_EFI)
u-boot-payload.efi: u-boot-payload FORCE
	$(call if_changed,zobjcopy)

u-boot-img.bin: spl/u-boot-spl.bin u-boot.img FORCE
	$(call if_changed,cat)

#Add a target to create boot binary having SPL binary in PBI format
#concatenated with u-boot binary. It is need by PowerPC SoC having
#internal SRAM <= 512KB.
MKIMAGEFLAGS_u-boot-spl.pbl = -n $(srctree)/$(CONFIG_SYS_FSL_PBL_RCW:"%"=%) \
		-R $(srctree)/$(CONFIG_SYS_FSL_PBL_PBI:"%"=%) -T pblimage \
		-A $(ARCH) -a $(CONFIG_SPL_TEXT_BASE)

spl/u-boot-spl.pbl: spl/u-boot-spl.bin FORCE
	$(call if_changed,mkimage)

ifeq ($(ARCH),arm)
UBOOT_BINLOAD := u-boot.img
else
UBOOT_BINLOAD := u-boot.bin
endif

OBJCOPYFLAGS_u-boot-with-spl-pbl.bin = -I binary -O binary --pad-to=$(CONFIG_SPL_PAD_TO) \
			  --gap-fill=0xff

u-boot-with-spl-pbl.bin: spl/u-boot-spl.pbl $(UBOOT_BINLOAD) FORCE
	$(call if_changed,pad_cat)

# PPC4xx needs the SPL at the end of the image, since the reset vector
# is located at 0xfffffffc. So we can't use the "u-boot-img.bin" target
# and need to introduce a new build target with the full blown U-Boot
# at the start padded up to the start of the SPL image. And then concat
# the SPL image to the end.

OBJCOPYFLAGS_u-boot-img-spl-at-end.bin := -I binary -O binary \
	--pad-to=$(CONFIG_UBOOT_PAD_TO) --gap-fill=0xff
u-boot-img-spl-at-end.bin: u-boot.img spl/u-boot-spl.bin FORCE
	$(call if_changed,pad_cat)

# Create a new ELF from a raw binary file.
ifndef PLATFORM_ELFENTRY
  PLATFORM_ELFENTRY = "_start"
endif
quiet_cmd_u-boot-elf ?= LD      $@
	cmd_u-boot-elf ?= $(LD) u-boot-elf.o -o $@ \
	--defsym=$(PLATFORM_ELFENTRY)=$(CONFIG_SYS_TEXT_BASE) \
	-Ttext=$(CONFIG_SYS_TEXT_BASE)
u-boot.elf: u-boot.bin
	$(Q)$(OBJCOPY) -I binary $(PLATFORM_ELFFLAGS) $< u-boot-elf.o
	$(call if_changed,u-boot-elf)

ARCH_POSTLINK := $(wildcard $(srctree)/arch/$(ARCH)/Makefile.postlink)

# Rule to link u-boot
# May be overridden by arch/$(ARCH)/config.mk
quiet_cmd_u-boot__ ?= LD      $@
      cmd_u-boot__ ?= $(LD) $(LDFLAGS) $(LDFLAGS_u-boot) -o $@ \
      -T u-boot.lds $(u-boot-init)                             \
      --start-group $(u-boot-main) --end-group                 \
      $(PLATFORM_LIBS) -Map u-boot.map;                        \
      $(if $(ARCH_POSTLINK), $(MAKE) -f $(ARCH_POSTLINK) $@, true)

quiet_cmd_smap = GEN     common/system_map.o
cmd_smap = \
	smap=`$(call SYSTEM_MAP,u-boot) | \
		awk '$$2 ~ /[tTwW]/ {printf $$1 $$3 "\\\\000"}'` ; \
	$(CC) $(c_flags) -DSYSTEM_MAP="\"$${smap}\"" \
		-c $(srctree)/common/system_map.c -o common/system_map.o

u-boot:	$(u-boot-init) $(u-boot-main) u-boot.lds FORCE
	+$(call if_changed,u-boot__)
ifeq ($(CONFIG_KALLSYMS),y)
	$(call cmd,smap)
	$(call cmd,u-boot__) common/system_map.o
endif

ifeq ($(CONFIG_RISCV),y)
	@tools/prelink-riscv $@ 0
endif

quiet_cmd_sym ?= SYM     $@
      cmd_sym ?= $(OBJDUMP) -t $< > $@
u-boot.sym: u-boot FORCE
	$(call if_changed,sym)

# The actual objects are generated when descending,
# make sure no implicit rule kicks in
$(sort $(u-boot-init) $(u-boot-main)): $(u-boot-dirs) ;

# Handle descending into subdirectories listed in $(vmlinux-dirs)
# Preset locale variables to speed up the build process. Limit locale
# tweaks to this spot to avoid wrong language settings when running
# make menuconfig etc.
# Error messages still appears in the original language

PHONY += $(u-boot-dirs)
$(u-boot-dirs): prepare scripts
	$(Q)$(MAKE) $(build)=$@

tools: prepare
# The "tools" are needed early
$(filter-out tools, $(u-boot-dirs)): tools
# The "examples" conditionally depend on U-Boot (say, when USE_PRIVATE_LIBGCC
# is "yes"), so compile examples after U-Boot is compiled.
examples: $(filter-out examples, $(u-boot-dirs))

define filechk_uboot.release
	echo "$(UBOOTVERSION)$$($(CONFIG_SHELL) $(srctree)/scripts/setlocalversion $(srctree))"
endef

# Store (new) UBOOTRELEASE string in include/config/uboot.release
include/config/uboot.release: include/config/auto.conf FORCE
	$(call filechk,uboot.release)


# Things we need to do before we recursively start building the kernel
# or the modules are listed in "prepare".
# A multi level approach is used. prepareN is processed before prepareN-1.
# archprepare is used in arch Makefiles and when processed asm symlink,
# version.h and scripts_basic is processed / created.

# Listed in dependency order
PHONY += prepare archprepare prepare0 prepare1 prepare2 prepare3

# prepare3 is used to check if we are building in a separate output directory,
# and if so do:
# 1) Check that make has not been executed in the kernel src $(srctree)
prepare3: include/config/uboot.release
ifneq ($(KBUILD_SRC),)
	@$(kecho) '  Using $(srctree) as source for U-Boot'
	$(Q)if [ -f $(srctree)/.config -o -d $(srctree)/include/config ]; then \
		echo >&2 "  $(srctree) is not clean, please run 'make mrproper'"; \
		echo >&2 "  in the '$(srctree)' directory.";\
		/bin/false; \
	fi;
endif

# prepare2 creates a makefile if using a separate output directory
prepare2: prepare3 outputmakefile

prepare1: prepare2 $(version_h) $(timestamp_h) \
                   include/config/auto.conf
ifeq ($(wildcard $(LDSCRIPT)),)
	@echo >&2 "  Could not find linker script."
	@/bin/false
endif

archprepare: prepare1 scripts_basic

prepare0: archprepare FORCE
	$(Q)$(MAKE) $(build)=.

# All the preparing..
prepare: prepare0

# Generate some files
# ---------------------------------------------------------------------------

define filechk_version.h
	(echo \#define PLAIN_VERSION \"$(UBOOTRELEASE)\"; \
	echo \#define U_BOOT_VERSION \"U-Boot \" PLAIN_VERSION; \
	echo \#define CC_VERSION_STRING \"$$(LC_ALL=C $(CC) --version | head -n 1)\"; \
	echo \#define LD_VERSION_STRING \"$$(LC_ALL=C $(LD) --version | head -n 1)\"; )
endef

# The SOURCE_DATE_EPOCH mechanism requires a date that behaves like GNU date.
# The BSD date on the other hand behaves different and would produce errors
# with the misused '-d' switch.  Respect that and search a working date with
# well known pre- and suffixes for the GNU variant of date.
define filechk_timestamp.h
	(if test -n "$${SOURCE_DATE_EPOCH}"; then \
		SOURCE_DATE="@$${SOURCE_DATE_EPOCH}"; \
		DATE=""; \
		for date in gdate date.gnu date; do \
			$${date} -u -d "$${SOURCE_DATE}" >/dev/null 2>&1 && DATE="$${date}"; \
		done; \
		if test -n "$${DATE}"; then \
			LC_ALL=C $${DATE} -u -d "$${SOURCE_DATE}" +'#define U_BOOT_DATE "%b %d %C%y"'; \
			LC_ALL=C $${DATE} -u -d "$${SOURCE_DATE}" +'#define U_BOOT_TIME "%T"'; \
			LC_ALL=C $${DATE} -u -d "$${SOURCE_DATE}" +'#define U_BOOT_TZ "%z"'; \
			LC_ALL=C $${DATE} -u -d "$${SOURCE_DATE}" +'#define U_BOOT_DMI_DATE "%m/%d/%Y"'; \
			LC_ALL=C $${DATE} -u -d "$${SOURCE_DATE}" +'#define U_BOOT_BUILD_DATE 0x%Y%m%d'; \
		else \
			return 42; \
		fi; \
	else \
		LC_ALL=C date +'#define U_BOOT_DATE "%b %d %C%y"'; \
		LC_ALL=C date +'#define U_BOOT_TIME "%T"'; \
		LC_ALL=C date +'#define U_BOOT_TZ "%z"'; \
		LC_ALL=C date +'#define U_BOOT_DMI_DATE "%m/%d/%Y"'; \
		LC_ALL=C date +'#define U_BOOT_BUILD_DATE 0x%Y%m%d'; \
	fi)
endef

$(version_h): include/config/uboot.release FORCE
	$(call filechk,version.h)

$(timestamp_h): $(srctree)/Makefile FORCE
	$(call filechk,timestamp.h)

# ---------------------------------------------------------------------------
quiet_cmd_cpp_lds = LDS     $@
cmd_cpp_lds = $(CPP) -Wp,-MD,$(depfile) $(cpp_flags) $(LDPPFLAGS) \
		-D__ASSEMBLY__ -x assembler-with-cpp -P -o $@ $<

u-boot.lds: $(LDSCRIPT) prepare FORCE
	$(call if_changed_dep,cpp_lds)

spl/u-boot-spl.bin: spl/u-boot-spl
	@:
spl/u-boot-spl: tools prepare \
		$(if $(CONFIG_OF_SEPARATE)$(CONFIG_OF_EMBED)$(CONFIG_SPL_OF_PLATDATA),dts/dt.dtb) \
		$(if $(CONFIG_OF_SEPARATE)$(CONFIG_OF_EMBED)$(CONFIG_TPL_OF_PLATDATA),dts/dt.dtb)
	$(Q)$(MAKE) obj=spl -f $(srctree)/scripts/Makefile.spl all

spl/sunxi-spl.bin: spl/u-boot-spl
	@:

spl/sunxi-spl-with-ecc.bin: spl/sunxi-spl.bin
	@:

spl/u-boot-spl.sfp: spl/u-boot-spl
	@:

spl/boot.bin: spl/u-boot-spl
	@:

tpl/u-boot-tpl.bin: tools prepare \
		$(if $(CONFIG_OF_SEPARATE)$(CONFIG_OF_EMBED)$(CONFIG_SPL_OF_PLATDATA),dts/dt.dtb)
	$(Q)$(MAKE) obj=tpl -f $(srctree)/scripts/Makefile.spl all

TAG_SUBDIRS := $(patsubst %,$(srctree)/%,$(u-boot-dirs) include)

FIND := find
FINDFLAGS := -L

tags ctags:
		ctags -w -o ctags `$(FIND) $(FINDFLAGS) $(TAG_SUBDIRS) \
						-name '*.[chS]' -print`
		ln -s ctags tags

etags:
		etags -a -o etags `$(FIND) $(FINDFLAGS) $(TAG_SUBDIRS) \
						-name '*.[chS]' -print`
cscope:
		$(FIND) $(FINDFLAGS) $(TAG_SUBDIRS) -name '*.[chS]' -print > \
						cscope.files
		cscope -b -q -k

SYSTEM_MAP = \
		$(NM) $1 | \
		grep -v '\(compiled\)\|\(\.o$$\)\|\( [aUw] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)' | \
		LC_ALL=C sort
System.map:	u-boot
		@$(call SYSTEM_MAP,$<) > $@

#########################################################################

# ARM relocations should all be R_ARM_RELATIVE (32-bit) or
# R_AARCH64_RELATIVE (64-bit).
checkarmreloc: u-boot
	@RELOC="`$(CROSS_COMPILE)readelf -r -W $< | cut -d ' ' -f 4 | \
		grep R_A | sort -u`"; \
	if test "$$RELOC" != "R_ARM_RELATIVE" -a \
		 "$$RELOC" != "R_AARCH64_RELATIVE"; then \
		echo "$< contains unexpected relocations: $$RELOC"; \
		false; \
	fi

envtools: scripts_basic $(version_h) $(timestamp_h)
	$(Q)$(MAKE) $(build)=tools/env

tools-only: scripts_basic $(version_h) $(timestamp_h)
	$(Q)$(MAKE) $(build)=tools

tools-all: export HOST_TOOLS_ALL=y
tools-all: envtools tools ;

cross_tools: export CROSS_BUILD_TOOLS=y
cross_tools: tools ;

.PHONY : CHANGELOG
CHANGELOG:
	git log --no-merges U-Boot-1_1_5.. | \
	unexpand -a | sed -e 's/\s\s*$$//' > $@

#########################################################################

###
# Cleaning is done on three levels.
# make clean     Delete most generated files
#                Leave enough to build external modules
# make mrproper  Delete the current configuration, and all generated files
# make distclean Remove editor backup files, patch leftover files and the like

# Directories & files removed with 'make clean'
CLEAN_DIRS  += $(MODVERDIR) \
	       $(foreach d, spl tpl, $(patsubst %,$d/%, \
			$(filter-out include, $(shell ls -1 $d 2>/dev/null))))

CLEAN_FILES += include/bmp_logo.h include/bmp_logo_data.h \
	       boot* u-boot* MLO* SPL System.map fit-dtb.blob

# Directories & files removed with 'make mrproper'
MRPROPER_DIRS  += include/config include/generated spl tpl \
		  .tmp_objdiff
MRPROPER_FILES += .config .config.old include/autoconf.mk* include/config.h \
		  ctags etags tags TAGS cscope* GPATH GTAGS GRTAGS GSYMS

# clean - Delete most, but leave enough to build external modules
#
clean: rm-dirs  := $(CLEAN_DIRS)
clean: rm-files := $(CLEAN_FILES)

clean-dirs	:= $(foreach f,$(u-boot-alldirs),$(if $(wildcard $(srctree)/$f/Makefile),$f))

clean-dirs      := $(addprefix _clean_, $(clean-dirs) doc/DocBook)

PHONY += $(clean-dirs) clean archclean
$(clean-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _clean_%,%,$@)

# TODO: Do not use *.cfgtmp
clean: $(clean-dirs)
	$(call cmd,rmdirs)
	$(call cmd,rmfiles)
	@find $(if $(KBUILD_EXTMOD), $(KBUILD_EXTMOD), .) $(RCS_FIND_IGNORE) \
		\( -name '*.[oas]' -o -name '*.ko' -o -name '.*.cmd' \
		-o -name '*.ko.*' -o -name '*.su' -o -name '*.cfgtmp' \
		-o -name '.*.d' -o -name '.*.tmp' -o -name '*.mod.c' \
		-o -name '*.symtypes' -o -name 'modules.order' \
		-o -name modules.builtin -o -name '.tmp_*.o.*' \
		-o -name 'dsdt.aml' -o -name 'dsdt.asl.tmp' -o -name 'dsdt.c' \
		-o -name '*.gcno' \) -type f -print | xargs rm -f

# mrproper - Delete all generated files, including .config
#
mrproper: rm-dirs  := $(wildcard $(MRPROPER_DIRS))
mrproper: rm-files := $(wildcard $(MRPROPER_FILES))
mrproper-dirs      := $(addprefix _mrproper_,scripts)

PHONY += $(mrproper-dirs) mrproper archmrproper
$(mrproper-dirs):
	$(Q)$(MAKE) $(clean)=$(patsubst _mrproper_%,%,$@)

mrproper: clean $(mrproper-dirs)
	$(call cmd,rmdirs)
	$(call cmd,rmfiles)
	@rm -f arch/*/include/asm/arch

# distclean
#
PHONY += distclean

distclean: mrproper
	@find $(srctree) $(RCS_FIND_IGNORE) \
		\( -name '*.orig' -o -name '*.rej' -o -name '*~' \
		-o -name '*.bak' -o -name '#*#' -o -name '.*.orig' \
		-o -name '.*.rej' -o -name '*%' -o -name 'core' \
		-o -name '*.pyc' \) \
		-type f -print | xargs rm -f
	@rm -f boards.cfg

backup:
	F=`basename $(srctree)` ; cd .. ; \
	gtar --force-local -zcvf `LC_ALL=C date "+$$F-%Y-%m-%d-%T.tar.gz"` $$F

help:
	@echo  'Cleaning targets:'
	@echo  '  clean		  - Remove most generated files but keep the config'
	@echo  '  mrproper	  - Remove all generated files + config + various backup files'
	@echo  '  distclean	  - mrproper + remove editor backup and patch files'
	@echo  ''
	@echo  'Configuration targets:'
	@$(MAKE) -f $(srctree)/scripts/kconfig/Makefile help
	@echo  ''
	@echo  'Other generic targets:'
	@echo  '  all		  - Build all necessary images depending on configuration'
	@echo  '  tests		  - Build U-Boot for sandbox and run tests'
	@echo  '* u-boot	  - Build the bare u-boot'
	@echo  '  dir/            - Build all files in dir and below'
	@echo  '  dir/file.[oisS] - Build specified target only'
	@echo  '  dir/file.lst    - Build specified mixed source/assembly target only'
	@echo  '                    (requires a recent binutils and recent build (System.map))'
	@echo  '  tags/ctags	  - Generate ctags file for editors'
	@echo  '  etags		  - Generate etags file for editors'
	@echo  '  cscope	  - Generate cscope index'
	@echo  '  ubootrelease	  - Output the release version string (use with make -s)'
	@echo  '  ubootversion	  - Output the version stored in Makefile (use with make -s)'
	@echo  "  cfg		  - Don't build, just create the .cfg files"
	@echo  "  envtools	  - Build only the target-side environment tools"
	@echo  ''
	@echo  'Static analysers'
	@echo  '  checkstack      - Generate a list of stack hogs'
	@echo  '  coccicheck      - Execute static code analysis with Coccinelle'
	@echo  ''
	@echo  'Documentation targets:'
	@$(MAKE) -f $(srctree)/doc/DocBook/Makefile dochelp
	@echo  ''
	@echo  '  make V=0|1 [targets] 0 => quiet build (default), 1 => verbose build'
	@echo  '  make V=2   [targets] 2 => give reason for rebuild of target'
	@echo  '  make O=dir [targets] Locate all output files in "dir", including .config'
	@echo  '  make C=1   [targets] Check all c source with $$CHECK (sparse by default)'
	@echo  '  make C=2   [targets] Force check of all c source with $$CHECK'
	@echo  '  make RECORDMCOUNT_WARN=1 [targets] Warn about ignored mcount sections'
	@echo  '  make W=n   [targets] Enable extra gcc checks, n=1,2,3 where'
	@echo  '		1: warnings which may be relevant and do not occur too often'
	@echo  '		2: warnings which occur quite often but may still be relevant'
	@echo  '		3: more obscure warnings, can most likely be ignored'
	@echo  '		Multiple levels can be combined with W=12 or W=123'
	@echo  ''
	@echo  'Execute "make" or "make all" to build all targets marked with [*] '
	@echo  'For further info see the ./README file'

tests:
	$(srctree)/test/run

# Documentation targets
# ---------------------------------------------------------------------------
%docs: scripts_basic FORCE
	$(Q)$(MAKE) $(build)=scripts build_docproc
	$(Q)$(MAKE) $(build)=doc/DocBook $@

endif #ifeq ($(config-targets),1)
endif #ifeq ($(mixed-targets),1)

PHONY += checkstack ubootrelease ubootversion

checkstack:
	$(OBJDUMP) -d u-boot $$(find . -name u-boot-spl) | \
	$(PERL) $(src)/scripts/checkstack.pl $(ARCH)

ubootrelease:
	@echo "$(UBOOTVERSION)$$($(CONFIG_SHELL) $(srctree)/scripts/setlocalversion $(srctree))"

ubootversion:
	@echo $(UBOOTVERSION)

# Single targets
# ---------------------------------------------------------------------------
# Single targets are compatible with:
# - build with mixed source and output
# - build with separate output dir 'make O=...'
# - external modules
#
#  target-dir => where to store outputfile
#  build-dir  => directory in kernel source tree to use

ifeq ($(KBUILD_EXTMOD),)
        build-dir  = $(patsubst %/,%,$(dir $@))
        target-dir = $(dir $@)
else
        zap-slash=$(filter-out .,$(patsubst %/,%,$(dir $@)))
        build-dir  = $(KBUILD_EXTMOD)$(if $(zap-slash),/$(zap-slash))
        target-dir = $(if $(KBUILD_EXTMOD),$(dir $<),$(dir $@))
endif

%.s: %.c prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.i: %.c prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.o: %.c prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.lst: %.c prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.s: %.S prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.o: %.S prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)
%.symtypes: %.c prepare scripts FORCE
	$(Q)$(MAKE) $(build)=$(build-dir) $(target-dir)$(notdir $@)

# Modules
/: prepare scripts FORCE
	$(cmd_crmodverdir)
	$(Q)$(MAKE) KBUILD_MODULES=$(if $(CONFIG_MODULES),1) \
	$(build)=$(build-dir)
%/: prepare scripts FORCE
	$(cmd_crmodverdir)
	$(Q)$(MAKE) KBUILD_MODULES=$(if $(CONFIG_MODULES),1) \
	$(build)=$(build-dir)
%.ko: prepare scripts FORCE
	$(cmd_crmodverdir)
	$(Q)$(MAKE) KBUILD_MODULES=$(if $(CONFIG_MODULES),1)   \
	$(build)=$(build-dir) $(@:.ko=.o)
	$(Q)$(MAKE) -f $(srctree)/scripts/Makefile.modpost

# Consistency checks
# ---------------------------------------------------------------------------

PHONY += coccicheck

coccicheck:
	$(Q)$(CONFIG_SHELL) $(srctree)/scripts/$@

# FIXME Should go into a make.lib or something
# ===========================================================================

quiet_cmd_rmdirs = $(if $(wildcard $(rm-dirs)),CLEAN   $(wildcard $(rm-dirs)))
      cmd_rmdirs = rm -rf $(rm-dirs)

quiet_cmd_rmfiles = $(if $(wildcard $(rm-files)),CLEAN   $(wildcard $(rm-files)))
      cmd_rmfiles = rm -f $(rm-files)

# read all saved command lines

targets := $(wildcard $(sort $(targets)))
cmd_files := $(wildcard .*.cmd $(foreach f,$(targets),$(dir $(f)).$(notdir $(f)).cmd))

ifneq ($(cmd_files),)
  $(cmd_files): ;	# Do not try to update included dependency files
  include $(cmd_files)
endif

endif	# skip-makefile

PHONY += FORCE
FORCE:

# Declare the contents of the .PHONY variable as phony.  We keep that
# information in a variable so we can use it in if_changed and friends.
.PHONY: $(PHONY)
