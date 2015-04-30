#########################################################################
# Brainfuck Interpreter
# John Tomko
# Dan Brotman
# David Merriman
# Joe Jensen
# Lucas Flowers
# Project UI
#########################################################################

.globl main

#########################################################################
# Data Variables
#########################################################################
.data

newLine: .asciiz "\n"
inputPrompt: .asciiz "Enter a valid brainfuck file path: "
readPrompt: .asciiz "Enter a single byte of data: "
fileErr: .asciiz "Oops! There was an error processing your input file!"

inputBuffer: .space 512
transferBuffer: .space 512
data: .space 4096
instructions: .space 4096

ascii_instruction_table: 
	.word no_op # (null)
	.word no_op # (start of heading)
	.word no_op # (start of text)
	.word finish # (end of text)
	.word finish # (end of transmission)
	.word no_op # (enquiry)
	.word no_op # (acknowledge)
	.word no_op # (bell)
	.word no_op # (backspace)
	.word no_op # (horizontal tab)
	.word no_op # (NL line feed, new line)
	.word no_op # (vertical tab)
	.word no_op # (NP form feed, new page)
	.word no_op # (carriage return)
	.word no_op # (shift out)
	.word no_op # (shift in)
	.word no_op # (data link escape)
	.word no_op # (device control 1)
	.word no_op # (device control 2)
	.word no_op # (device control 3)
	.word no_op # (device control 4)
	.word no_op # (negative acknowledge)
	.word no_op # (synchronous idle)
	.word no_op # (end of transmission block)
	.word no_op # (cancel)
	.word no_op # (end of medium)
	.word no_op # (substitute)
	.word no_op # (escape)
	.word no_op # (file separator)
	.word no_op # (group separator)
	.word no_op # (record separator)
	.word no_op # (unit separator)
	.word no_op # (space)
	.word no_op # !
	.word no_op # "
	.word no_op # #
	.word no_op # $
	.word no_op # %
	.word no_op # &
	.word no_op # '
	.word no_op # (
	.word no_op # )
	.word no_op # *
	.word increment_data # +
	.word take_input # ,
	.word decrement_data # -
	.word print # .
	.word no_op # /
	.word no_op # 0
	.word no_op # 1
	.word no_op # 2
	.word no_op # 3
	.word no_op # 4
	.word no_op # 5
	.word no_op # 6
	.word no_op # 7
	.word no_op # 8
	.word no_op # 9
	.word no_op # :
	.word no_op # ;
	.word decrement_pointer # < 
	.word no_op # =
	.word increment_pointer # >
	.word no_op # ?
	.word no_op # @
	.word no_op # A
	.word no_op # B
	.word no_op # C
	.word no_op # D
	.word no_op # E
	.word no_op # F
	.word no_op # G
	.word no_op # H
	.word no_op # I
	.word no_op # J
	.word no_op # K
	.word no_op # L
	.word no_op # M
	.word no_op # N
	.word no_op # O
	.word no_op # P
	.word no_op # Q
	.word no_op # R
	.word no_op # S
	.word no_op # T
	.word no_op # U
	.word no_op # V
	.word no_op # W
	.word no_op # X
	.word no_op # Y
	.word no_op # Z
	.word start_loop # [
	.word no_op # \
	.word end_loop # ] 
	.word no_op # ^
	.word no_op # _
	.word no_op # `
	.word no_op # a
	.word no_op # b
	.word no_op # c
	.word no_op # d
	.word no_op # e
	.word no_op # f
	.word no_op # g
	.word no_op # h
	.word no_op # i
	.word no_op # j
	.word no_op # k
	.word no_op # l
	.word no_op # m
	.word no_op # n
	.word no_op # o
	.word no_op # p
	.word no_op # q
	.word no_op # r
	.word no_op # s
	.word no_op # t
	.word no_op # u
	.word no_op # v
	.word no_op # w
	.word no_op # x
	.word no_op # y
	.word no_op # z
	.word no_op # {
	.word no_op # |
	.word no_op # }
	.word no_op # ~
	.word no_op # (delete)

#########################################################################
# Code text
#
# Functions:
# Take input file path
# Open file at input path 
# Read file text
# Send program to correct functions based on input characters
#
# Registers used:
#	$s0: Characters in the file path string
#	$s1: The file descriptor
#	$s2: The number of characters in the .bf file
#	$s3: The end of the file data
#	$s4: The address of the data
#	$s5: The address of the input instructions
#
#	$t0: A counter counting how many characters are in the file path
#	$t1: Flag determining whether to end or not
#	$t2: The .bf character being handled
#	$t3: The literal 4
#	$t4: The weighted memory address of the current .bf character
#	$t5: The actual number of characters in the file path
#	$t6: A counting counting the number of actual file path characters
#
#	$a0: Syscall parameters
#	$a1: Syscall parameters
#	$a2: Syscall parameters
#
#	$v0: Syscall commands
#########################################################################
.text

main: 
	# Prompt user for the input file path
	li $v0, 4
	la $a0, inputPrompt
	syscall

	# Read the input file path
	li $v0, 8
	la $a0, inputBuffer
	li $a1, 512
	syscall

	# Initialize the count to zero
	add $t0, $zero, $zero

	j str_length

str_length:
	# Load next character
	lb $s0, 0($a0)

	# Exit loop if finished with string
	beqz $s0, remove_final_char

	# Increment character and counter
	addi $a0, $a0, 1
	addi $t0, $t0, 1
	
	# Continue counting
	j str_length # return to the top of the loop

# For cutting off the UNIX-added new line character at the end of the file path (Y U DO DIS SPIM)
remove_final_char:
	addi $t5, $t0, -1
	add $t6, $zero, $zero
	
	la $a0, inputBuffer
	la $a1, transferBuffer

remove_loop:
	# Transfers the letter from the input buffer to the replacement buffer
	lb $s0, 0($a0)
	sb $s0, 0($a1)
	
	# Increment the counter and word position in both buffers
	addi $t6, $t6, 1
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	
	# When all letters but the new line character are added, open the file
	beq $t5, $t6, open_file

	j remove_loop

open_file:
	# Open the file
	li $v0, 13
	la $a0, transferBuffer
	add $a1, $zero, $zero
	add $a2, $zero, $zero
	syscall
	
	# Store the file descriptor
	move $s1, $v0
	
	bgtz $s1, read_file

	j error

read_file:
	# Read the contents of the file
	li $v0, 14
	add $a0, $s1, $zero
	la $a1, instructions
	li $a2, 2048
	syscall

	# Branch if an error occurred
	blez $v0, error
	
	# Store the number of characters in the input file
	add $s2, $v0, $zero

	# Save the end of the file data
	add $s3, $s2, $a1

	j begin_brainfuck

begin_brainfuck:
	# The addresses of the data pointer and the instructions stored in registers
	la $s4, data
	la $s5, instructions

loop:
	# If the instructions left are less than how many are at the end, stop
	slt $t1, $s5, $s3
	beq $t1, $zero, finish
	
	# Get a brainfuck character
	lb $t2, 0($s5)

	# Store the location of the data pointer and instructions in new registers	
	move $a0, $s5
	move $a1, $s4
	
	# Adjust the position of the character to reflect its location in memory
	addi $t3, $zero, 4
	mul $t4, $t3, $t2

	# Get the brainfuck instruction to use for the character
	lw $t5, ascii_instruction_table($t4)

	# Perform that instruction
	jr $t5
	

error:
	# An error occurred
	li $v0, 4
	la $a0, fileErr
	syscall

	j finish

finish:
	li $v0, 10
	syscall	

############################################################################
# Brainfuck Commands
#
# no-op: No meaningful operation
# increment_pointer (>): Increments the position of the brainfuck pointer
# decrement_pointer (<): Decrements the position of the brainfuck pointer
# increment_data (+): Increments the data stored in the address the pointer
#		      is at
# decrement_data (-): Decrements the data stored in the address the pointer
#		      is at
# print (.): Prints the byte located at the current pointer location
# take_input (,): Allows the user to input a byte of data
# start_loop ([): Begins a while loop--while (byte at pointer /= 0)
#	Helper Functions:
#		find_matching_end_bracket: Finds the end bracket that
#					   matches the start bracket.
#		found_left_begin: While looping, if an open bracket is
#				  found, increment counter.
#		found_right_begin: While looping, if a closing bracket is
#				   found, decrement counter.
# end_loop (]): End of while loop
#	Helper Functions:
#		find_matching_begin_bracket: Finds the open bracket that
#					     matches the closing bracket.
#		found_left_end: While looping, if an open bracket is found,
#				increment counter.
#		found_right_end: While looping, if a clpsing bracket is
#				 found, decrement counter.
#		found_matching_bracket: The matching bracket is found.
############################################################################

no_op:
	# Increment the instruction
	addi $s5, $a0, 1

	# Keep the pointer where it is
	add $s4, $a1, $zero

	# Go to next instruction
	j loop

increment_pointer:
	# Increment the instruction
	addi $s5, $a0, 1

	# Increments the pointer
	addi $s4, $a1, 1

	# Go to next instruction
	j loop

decrement_pointer:
	# Increment the instruction
	addi $s5, $a0, 1

	# Decrements the pointer
	addi $s4, $a1, -1

	# Go to next instruction
	j loop
	
increment_data:
	 # Load the value stored at the pointer
	 lb $t0, 0($s4)
    	
    	# Increment that value
	addi $t0, $t0, 1
    
	# Store it back
	sb $t0, 0($s4)

	addi $s5, $a0, 1

	# Go to the next instruction
	j loop

decrement_data:
	# Load the value stored at the pointer
	lb $t0, 0($s4)

	# Decrement that value
	addi $t0, $t0, -1

	# Store it back
	sb $t0, 0($s4)
	
	addi $s5, $a0, 1

	# Go to the next instruction
	j loop
	
print:
	# Print character
	li $v0, 11
	lbu $a0, 0($s4)
	syscall
	
	# Increment instruction
	addi $s5, $s5, 1
	
	j loop
	
take_input:
	# prompt user
	li $v0, 4
	la $a0, readPrompt
	syscall
	
	# take a byte of input
	li $v0, 12
	syscall 
	sb $v0, 0($s4)
	
	# New line
	li $v0, 4
	la $a0, newLine
	syscall
	
	# Increment instruction
	addi $s5, $s5, 1
	
	j loop

start_loop:
	#check if current pointer value is 0, if yes find end bracket, otherwise execute loop
	lb $t4, 0($s4)
	
	bne $t4, $zero, found_matching_bracket
	#if 0, go to matching end bracket
	
	#t4 holds number of matching brackets required
	li $t4, 1 

find_matching_end_bracket:
	#increment instruction pointer
	addi $s5, $s5, 1

	#load value of instruction to t5
	lb $t5, 0($s5)
	
	#load ascii code for left, right brackets to t6 and t7
	li $t6, 91
	li $t7, 93
	
	beq $t5, $t6, found_left_begin
	beq $t5, $t7, found_right_begin
	
	j find_matching_end_bracket

found_left_begin:
	#increment number of matching brackets required
	addi $t4, $t4, 1
	
	j find_matching_end_bracket

found_right_begin:
	#decrement number of matching brackets required
	addi $t4, $t4, -1

	#check if t4 is 0, else keep looking for brackets
	beq $t4, $zero, found_matching_bracket
	
	j find_matching_end_bracket

found_matching_bracket: 
	#increment instruction pointer
	addi $s5, $s5, 1

	#keep pointer static
	add $s4, $a1, $zero

	#jump to loop
	j loop
	
#right bracket ']'
#uses t4, t5, t6, t7
end_loop:
	#load data byte into t4
	lb $t4, 0($s4)
	
	#check if byte is zero, exit loop if so, otherwise find beginning
	beq $t4, $zero, found_matching_bracket
	
	#t4 now stores the number of '[' needed
	li $t4, 1

find_matching_begin_bracket:
	#decrement instruction pointer
	addi $s5, $s5, -1
	
	#load byte val of instruction into t5
	lb $t5, 0($s5)
	
	#check instruction type, '[' in t6, '[' in t7
	li $t6, 91
	li $t7, 93
	
	beq $t5, $t6, found_left_end
	beq $t5, $t7, found_right_end

	j find_matching_begin_bracket
	
found_left_end:
	#decrement number of matching brackets required
	addi $t4, $t4, -1

	#check if t4 is 0, else keep looking for brackets
	beq $t4, $zero, found_matching_bracket
	
	j find_matching_begin_bracket

found_right_end:
	#increment number of matching brackets required
	addi $t4, $t4, 1
	
	j find_matching_begin_bracket
