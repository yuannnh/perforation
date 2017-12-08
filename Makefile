#-------------------------------------------------------------------------------
# Sample makefile for building the code samples. Read inline comments for
# documentation.
#
# Eli Bendersky (eliben@gmail.com)
# This code is in the public domain
#-------------------------------------------------------------------------------

UNAME := $(shell uname -s)

# The following variables will likely need to be customized, depending on where
# and how you built LLVM & Clang. They can be overridden by setting them on the
# make command line: "make VARNAME=VALUE", etc.

# LLVM_SRC_PATH is the path to the root of the checked out source code. This
# directory should contain the configure script, the include/ and lib/
# directories of LLVM, Clang in tools/clang/, etc.
#
# The most recent build from source of LLVM I did used the following cmake
# invocation:
#
# $ cmake -DCMAKE_BUILD_TYPE=Release \
#         -DLLVM_ENABLE_ASSERTIONS=ON \
#         -DCMAKE_C_FLAGS=-DLLVM_ENABLE_DUMP \
#         -DCMAKE_CXX_FLAGS=-DLLVM_ENABLE_DUMP \
#         -DLLVM_TARGETS_TO_BUILD="X86" \
#         -G Ninja
#
# Note that this is a release build with assertions enabled, and with
# LLVM_ENABLE_DUMP explicitly passed. This is required to get the LLVM IR-level
# 'dump' methods to work. With debug builds, assertions should be enabled by
# default. Also note that a fairly recent version of cmake is required; the
# latest I've been using is 3.5.2
#
# It is recommended to use a recent Clang to build LLVM itself. For example if
# you have a Clang binary release in $CLANGDIR, cmake should be run with:
#
# $ CC=$CLANGDIR/bin/clang CXX=$CLANGDIR/bin/clang++ cmake ....
#
# Alternatively, if you're building vs. a binary distribution of LLVM
# (downloaded from llvm.org), then LLVM_SRC_PATH can point to the main untarred
# directory of the binary download (the directory that has bin/, lib/, include/
# and other directories inside).
# See the build_vs_released_binary.sh script for an example.
BINARY_DIR_PATH ?= $$HOME/Yuan/project/clang+llvm
LLVM_SRC_PATH := $(BINARY_DIR_PATH)

# LLVM_BUILD_PATH is the directory in which you built LLVM - where you ran
# configure or cmake.
# For linking vs. a binary build of LLVM, point to the main untarred directory.
# LLVM_BIN_PATH is the directory where binaries are placed by the LLVM build
# process. It should contain the tools like opt, llc and clang. The default
# reflects a release build with CMake and Ninja. binary build of LLVM, point it
# to the bin/ directory.
LLVM_BUILD_PATH := $(BINARY_DIR_PATH)/bin
LLVM_BIN_PATH 	:= $(BINARY_DIR_PATH)/bin

$(info -----------------------------------------------)
$(info Using BINARY_DIR_PATH = $(BINARY_DIR_PATH))
$(info Using LLVM_SRC_PATH = $(LLVM_SRC_PATH))
$(info Using LLVM_BUILD_PATH = $(LLVM_BUILD_PATH))
$(info Using LLVM_BIN_PATH = $(LLVM_BIN_PATH))
$(info -----------------------------------------------)

CXX := $(BINARY_DIR_PATH)/bin/clang++
CXXFLAGS := -fno-rtti -O0 -g
PLUGIN_CXXFLAGS := -fpic

LLVM_CXXFLAGS := `$(LLVM_BIN_PATH)/llvm-config --cxxflags`
LLVM_LDFLAGS := `$(LLVM_BIN_PATH)/llvm-config --ldflags --libs --system-libs`

# Plugins shouldn't link LLVM and Clang libs statically, because they are
# already linked into the main executable (opt or clang). LLVM doesn't like its
# libs to be linked more than once because it uses globals for configuration
# and plugin registration, and these trample over each other.
LLVM_LDFLAGS_NOLIBS := `$(LLVM_BIN_PATH)/llvm-config --ldflags`
PLUGIN_LDFLAGS := -shared -Wl,-undefined,dynamic_lookup

# These are required when compiling vs. a source distribution of Clang. For
# binary distributions llvm-config --cxxflags gives the right path.
CLANG_INCLUDES := \
	-I$(LLVM_SRC_PATH)/tools/clang/include \
	-I$(LLVM_BUILD_PATH)/tools/clang/include

# List of Clang libraries to link. The proper -L will be provided by the
# call to llvm-config
# Note that I'm using -Wl,--{start|end}-group around the Clang libs; this is
# because there are circular dependencies that make the correct order difficult
# to specify and maintain. The linker group options make the linking somewhat
# slower, but IMHO they're still perfectly fine for tools that link with Clang.
ifneq ($(UNAME),Darwin)
  CLANG_LIBS += \
    -Wl,--start-group
endif
CLANG_LIBS += \
	-lclangAST \
	-lclangAnalysis \
	-lclangBasic \
	-lclangDriver \
	-lclangEdit \
	-lclangFrontend \
	-lclangFrontendTool \
	-lclangLex \
	-lclangParse \
	-lclangSema \
	-lclangRewrite \
	-lclangTooling \
	-lclangSerialization

ifneq ($(UNAME),Darwin)
  CLANG_LIBS += \
    -Wl,--end-group
endif


# Internal paths in this project: where to find sources, and where to put
# build artifacts.
SRC_DIR := src_clang
BUILDDIR := build

$(BUILDDIR)/mutation: $(SRC_DIR)/mutation.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(CLANG_LIBS) $(LLVM_LDFLAGS) -o $@
		
$(BUILDDIR)/for_loop_test: $(SRC_DIR)/for_loop_test.cpp
	$(CXX) $(CXXFLAGS) $(LLVM_CXXFLAGS) $(CLANG_INCLUDES) $^ \
		$(CLANG_LIBS) $(LLVM_LDFLAGS) -o $@



.PHONY: clean format

clean:
	rm -rf $(BUILDDIR)/* *.dot test/*.pyc test/__pycache__

format:
	find . -name "*.cpp" | xargs clang-format -style=file -i
