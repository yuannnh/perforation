The program modify the all the for loop increment in a target from i+=1 (or other increment expression) to i+=2, which applys therefore a perforation on the target file.

How to build

1. Modify three variables in the makefile, they depend on where your llvm source is:
	LLVM_SRC_PATH := $$HOME/Yuan/project/llvm
	LLVM_BUILD_PATH := $$HOME/Yuan/project/build
	LLVM_BIN_PATH 	:= $(LLVM_BUILD_PATH)/bin
	
2. make

3. build/for_loop_test inputs/c_if_and_for.c

then you can see the modified file in the terminal.
	
