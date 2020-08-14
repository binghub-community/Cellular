########################################################################
# COMP1521 20T2 --- assignment 1: a cellular automaton renderer
#
# Written by <<YOU>>, July 2020.

	.data

# `cells' is used to store successive generations.  Each byte will be 1
# if the cell is alive in that generation, and 0 otherwise.

cells:	.byte 0:32896				# (MAX_GENERATIONS + 1) * MAX_WORLD_SIZE


# Some strings you'll need to use:

prompt_world_size:	    .asciiz "Enter world size: "
error_world_size:	    .asciiz "Invalid world size\n"
prompt_rule:		    .asciiz "Enter rule: "
error_rule:		        .asciiz "Invalid rule\n"
prompt_n_generations:	.asciiz "Enter how many generations: "
error_n_generations:	.asciiz "Invalid number of generations\n"

# Test strings

success:			    .asciiz "success\n"
test:				    .asciiz "test"

# Maximum and minimum values for the 3 parameters.

MIN_WORLD_SIZE:		    .word 1
MAX_WORLD_SIZE:		    .word 128
MIN_GENERATIONS:	    .word -256
MAX_GENERATIONS:	    .word 256
MIN_RULE:		        .word 0
MAX_RULE:		        .word 255

# Characters used to print alive/dead cells.

ALIVE_CHAR:		        .byte '#'
DEAD_CHAR:		        .byte '.'

# Maximum number of bytes needs to store all generations of cells.

MAX_CELLS_BYTES:		.word 32896		# (MAX_GENERATIONS + 1) * MAX_WORLD_SIZE


	.text

	#
	# REPLACE THIS COMMENT WITH A LIST OF THE REGISTERS USED IN
	# `main', AND THE PURPOSES THEY ARE ARE USED FOR
    # $tX = temporary registers for storing temporary values that will not retain their original values when run_generation/print_generation finishes
	# $aX = argument registers that will not retain their original values when run_generation/print_generation finishes
	# $s0 = store world size
	# $s1 = store rule
	# $s2 = store number of generations
	# $s3 = store whether the generations are in reverse or not
	# $sp = store stack pointer to save $ra
	# YOU SHOULD ALSO NOTE WHICH REGISTERS DO NOT HAVE THEIR
	# ORIGINAL VALUE WHEN `run_generation' FINISHES
	#

main:
	
	sub 	$sp, $sp, 4				        # move stack pointer down to make room
	sw	    $ra, 0($sp)				        # save $ra onto $stack
	
	
	# READ 3 INTEGER PARAMETERS FROM STDIN
	
	
	la 	    $a0, prompt_world_size			# printf("Enter world size: ")
	li 	    $v0, 4
	syscall
	li 	    $v0, 5					        # scanf("%d", world_size)
	syscall
	
	move 	$t0, $v0				        # $t0 = world_size
	lw 	    $t1, MIN_WORLD_SIZE			    # $t1 = 1
	blt 	$t0, $t1, world_end			    # if (world_size < 1) goto world_end
	lw	    $t1, MAX_WORLD_SIZE			    # $t1 = 128
	bgt  	$t0, $t1, world_end		    	# if (world_size > 128) goto world_end
	
	move	$s0, $t0			        	# $s0 = world_size
	
	la 	    $a0, prompt_rule		    	# printf("Enter rule: ")
	li 	    $v0, 4
	syscall
	li 	    $v0, 5					        # scanf("%d", rule)
	syscall
	
	move	$t0, $v0				        # $t0 = rule
	lw	    $t1, MIN_RULE			    	# $t1 = 0
	blt 	$t0, $t1, rule_end		    	# if (rule < 0) goto rule_end
	lw	    $t1, MAX_RULE			    	# $t1 = 255
	bgt  	$t0, $t1, rule_end		    	# if (rule > 255) goto rule_end
	
	move	$s1, $t0				        # $s1 = rule
	
	la	    $a0, prompt_n_generations		# printf("Enter how many generations: ")
	li	    $v0, 4
	syscall
	li	    $v0, 5				        	# scanf("%d", n_generations)
	syscall
	
	move	$t0, $v0				        # $t0 = n_generations
	lw	    $t1, MIN_GENERATIONS			# $t1 = -256
	blt 	$t0, $t1, generation_end		# if (rule < -256) goto rule_end
	lw	    $t1, MAX_GENERATIONS			# $t1 = 256
	bgt  	$t0, $t1, generation_end		# if (rule > 256) goto rule_end
	
	move    $s2, $t0				        # $s2 = n_generations
	
	li  	$a0, '\n'    			    	# printf("%c", '\n');
    li  	$v0, 11
    syscall
    	
    	# NEGATIVE GENERATIONS MEANS SHOW THE GENERATIONS IN REVERSE
    							            # $s3 = int reverse = 0
	bge	    $s2, $zero, start_building		# if (n_generations >= 0) goto start_building
	addi	$s3, $s3, 1				        # reverse = 1
	mul	    $s2, $s2, -1				    # n_generations = -n_generations
	
start_building:
	# THE FIRST GENERATION ALWAYS HAS AN ONLY SINGLE CELL WHICH IS ALIVE
	# THIS CELL IS IN THE MIDDLE OF THE WORLD
	la	    $s4, cells				        # $s4 = cells
	div	    $t1, $s0, 2				        # $t1 = $s0 / 2 to get the index number
	
	li	    $t0, 1					        # $t0 = 1
	sb 	    $t0, cells($t1)			    	# cells[$t1] = 1
	
#	li	    $t0, 0	
#print_array:						        # testing the first line of the array
#	bge	    $t0, $s0, func_end
#	lb 	    $a0, cells($t0)
#	li	    $v0, 1
#	syscall
#	addi	$t0, $t0, 1
#	j       print_array

	li	    $t0, 1					        # int g = 1	
start_generating:
	bgt	    $t0, $s2, print_generations_reverse	# while (g <= n_generations){
	la	    $a0, ($s0)
	la	    $a1, ($t0)
	la	    $a2, ($s1)
	jal	    run_generation				    # 	run_generation(world_size($a0), g($t0), rule($s1))
	addi	$t0, $t0, 1			        	# 	g++
	j       start_generating				# } restart loop

print_generations_reverse:
	add	    $t0, $s2, $zero			    	# $t0 = n_generations + 0
start_pgr_loop:
	bne 	$s3, 1, print_generations_normal    # if (reverse){
	bltz 	$t0, func_end			    	# 	while (g >= 0){
	la	    $a0, ($s0)
	la	    $a1, ($t0)
	jal	    print_generation			    #		print_generation(world_size($a0), g($t0))
	sub	    $t0, $t0, 1				        #		g--
	j	    start_pgr_loop				    #	}
	

print_generations_normal:				    # } else {
	li	    $t0, 0					        # int g = 0
start_pgn_loop:
	bgt	    $t0, $s2, func_end			    #	while (g <= n_generations){
	la	    $a0, ($s0)
	la	    $a1, ($t0)
	jal	    print_generation			    #		print_generation(world_size($a0), g($t0))
	addi	$t0, $t0, 1				        #		g++
	j	    start_pgn_loop				    #	}


func_end:
	lw	    $ra, 0($sp)				        # restore ra
	li	    $v0, 0
	jr	    $ra					

world_end:
	la 	    $a0, error_world_size			# printf("Invalid world size\n")
	li 	    $v0, 4 
	syscall
	li 	    $v0, 1					
	jr 	    $ra
rule_end:
	la 	    $a0, error_rule				    # printf("Invalid rule\n")
	li 	    $v0, 4 
	syscall
	li 	    $v0, 1					
	jr 	    $ra
generation_end:
	la 	    $a0, error_n_generations		# printf("Invalid number of generations\n")
	li 	    $v0, 4 
	syscall
	li 	    $v0, 1					
	jr 	    $ra

	#
	# Given `world_size', `which_generation', and `rule', calculate
	# a new generation according to `rule' and store it in `cells'.
	#

	#
	# REPLACE THIS COMMENT WITH A LIST OF THE REGISTERS USED IN
	# `run_generation', AND THE PURPOSES THEY ARE ARE USED FOR
    # $tX = temporary registers for storing temporary values that will not retain their original values when run_generation/print_generation finishes
	# $s0 = world_size
	# $t0 = which_generation (DO NOT TOUCH)
	# $s1 = rule
	# $s5 - $s7 = used to store the increment values to getting to respective parents of the array
	# YOU SHOULD ALSO NOTE WHICH REGISTERS DO NOT HAVE THEIR
	# ORIGINAL VALUE WHEN `run_generation' FINISHES
	#

run_generation:
	li	    $t1, 0					        # int x = 0
	addi	$s7, $s0, 1				        # increment to get to left parent
	addi	$s6, $s7, -1				    # increment to get to center parent
	addi	$s5, $s7, -2				    # incrememnt to get to right parent
	mul  	$t7, $t0, $s0				    # this finds which index in the array that current gen starts at
start_run_generation:
	bge	    $t1, $s0, end_run_generation	# while (x < world_size)
	li	    $t3, 0					        # int left = 0
	ble	    $t1, $zero, skip_if_x_lte_0		# if (x <= 0) goto skip_if_x_lte_0
	sub	    $t3, $t7, $s7			    	# get the index of the left parent
	lb	    $t3, cells($t3)			    	# load the byte of the left parent into int left
skip_if_x_lte_0:
	sub	    $t4, $t7, $s6			    	# get index of centre parent
	lb	    $t4, cells($t4)				    # load byte of centre parent
	
	li	    $t2, 0					        # int right = 0
	sub	    $t5, $s0, 1				        # world_size - 1
	bge	    $t1, $t5, skip_if_x_gte_ws	    # if (x>= world_size - 1) goto skip_if_x_gte_ws
	sub	    $t2, $t7, $s5			    	# get the index of right parent
	lb	    $t2, cells($t2)			    	# load the byte of the right parent into int right
	
	
skip_if_x_gte_ws:
	# at this point: $t0, $t1, $t2, $t3, $t4, $t7 are off limits. Can still use $t5, $t6, $t8, $t9
	
	sll 	$t3, $t3, 2			    	    # left shift by 2
	sll	    $t4, $t4, 1			        	# left shift by 1
	sll	    $t2, $t2, 0			          	# left shift by 0
	or	    $t3, $t3, $t4		    		# int temp = left | centre
	or	    $t2, $t3, $t2			    	# int state = right | temp (equiv to left | centre | right)
	
	# consolidated $t2, $t3, $t4 into $t2 (state), $t3, $t4 freed up
	li	    $t3, 1
	sllv 	$t2, $t3, $t2			    	# int bit = 1 << state
	and 	$t2, $t2, $s1			    	# int set = rule & bit
	
	beqz 	$t2, skip_set_neq1		    	# if set == 0, go to next condition
	li	    $t3, 1
	sb	    $t3, cells($t7)
skip_set_neq1:
	
	addi	$t1, $t1, 1			    	    # x++
	addi	$t7, $t7, 1				        # next byte of the generation
	j	    start_run_generation		    # restart loop
	
end_run_generation:
    li      $s5, 0                          # restoring $s5 - $s7 to their original values
    li      $s6, 0
    li      $s7, 0
	jr	    $ra


	#
	# Given `world_size', and `which_generation', print out the
	# specified generation.
	#

	#
	# REPLACE THIS COMMENT WITH A LIST OF THE REGISTERS USED IN
	# `print_generation', AND THE PURPOSES THEY ARE ARE USED FOR
    # $tX = temporary registers for storing temporary values that will not retain their original values when run_generation/print_generation finishes
	# $s0 = world_size
	# $t0 = which_generation (DO NOT TOUCH)
	# $s3 = reversed or not
	# YOU SHOULD ALSO NOTE WHICH REGISTERS DO NOT HAVE THEIR
	# ORIGINAL VALUE WHEN `print_generation' FINISHES
	#

print_generation:
	move  	$a0, $t0				        # print which_generation
    li	    $v0, 1
    syscall
    li	    $t1, 0					        # int x = 0
    mul  	$t2, $t0, $s0			    	# this finds which index in the array that the prev gen ends at
#    	la	$a0, ($t2)				        # prints index to check if it starts at the correct generation
#    	li	$v0, 1
#    	syscall
#	beqz $s3, post_reverse_check			# if (reverse == 0) goto post_reverse_check
#	sub	$t2, $t2, $s0
post_reverse_check:
    li	    $a0, '\t'				        # print tab
    li	    $v0, 11
    syscall
start_print_generation:
	bge	    $t1, $s0, end_print_generation	# while (x < world_size)
	lb	    $t3, cells($t2)
	beqz 	$t3, cell_dead				    # if (cell[which_generation][x] == 0) goto cell_dead
	li	    $a0, '#'			 	        # putchar(ALIVE_CHAR)
	li	    $v0, 11
	syscall
	j	    end_loop
cell_dead:
	li	    $a0, '.'				        # putchar(DEAD_CHAR)
	li	    $v0, 11
	syscall
	
end_loop:
	addi	$t2, $t2, 1				        # next byte of the generation
	addi	$t1, $t1, 1				        # x++
	j	    start_print_generation

end_print_generation:
	li	    $a0, '\n'
	li	    $v0, 11
	syscall
	jr	    $ra
	

