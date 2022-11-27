    ;;    game state memory location
    .equ CURR_STATE, 0x1000              ; current game state
    .equ GSA_ID, 0x1004                  ; gsa currently in use for drawing
    .equ PAUSE, 0x1008                   ; is the game paused or running
    .equ SPEED, 0x100C                   ; game speed
    .equ CURR_STEP,  0x1010              ; game current step
    .equ SEED, 0x1014                    ; game seed
    .equ GSA0, 0x1018                    ; GSA0 starting address
    .equ GSA1, 0x1038                    ; GSA1 starting address
    .equ SEVEN_SEGS, 0x1198              ; 7-segment display addresses
    .equ CUSTOM_VAR_START, 0x1200        ; Free range of addresses for custom variable definition
    .equ CUSTOM_VAR_END, 0x1300
    .equ LEDS, 0x2000                    ; LED address
    .equ RANDOM_NUM, 0x2010              ; Random number generator address
    .equ BUTTONS, 0x2030                 ; Buttons addresses

    ;; states
    .equ INIT, 0
    .equ RAND, 1
    .equ RUN, 2

    ;; constants
    .equ N_SEEDS, 4
    .equ N_GSA_LINES, 8
    .equ N_GSA_COLUMNS, 12
    .equ MAX_SPEED, 10
    .equ MIN_SPEED, 1
    .equ PAUSED, 0x00
    .equ RUNNING, 0x01

; BEGIN:main
main:
	addi sp, zero, 0x1300
	call reset_game
	call get_input
	addi s0, v0, 0
	addi s1, zero, 0
	addi s2, zero, 1
	while:
		addi a0, s0, 0
		call select_action
		addi a0, s0, 0
		call update_state
		call update_gsa
		call mask
		call draw_gsa
		call wait
		call decrement_step
		addi s1, v0, 0
		call get_input
		addi s0, v0, 0
		bne s1, s2, while
	br main
; END:main

; BEGIN:clear_leds
clear_leds:
    stw zero, LEDS(zero)
	stw zero, LEDS+4(zero)
	stw zero, LEDS+8(zero)
    ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
	slli a0, a0, 3          
	add a0, a0, a1       ; a0 = 8x + y
	addi t0, zero, 32    ; t0 = 32
	addi t1, zero, 64	 ; t1 = 64
	bge a0, t1, case_led2
	bge a0, t0, case_led1
	case_led0:
		addi t4, zero, LEDS
		br set_pixel_end
	case_led1:
		addi t4, zero, LEDS+4
		br set_pixel_end
	case_led2:
		addi t4, zero, LEDS+8
	set_pixel_end:
		ldw t2, 0(t4)     
		addi t3, zero, 1             ; t3 = 1
		andi a0, a0, 31             ; 8x + y mod 32
		sll t3, t3, a0                ; mask 1 << 8x + y mod 32
		or t2, t2, t3                ; mask | leds
		stw t2, 0(t4)			  ; new leds into leds
		ret
; END:set_pixel

; BEGIN:wait
wait: 
	addi t1, zero, 1
	addi t2, zero, 1 ; 
	slli t2, t2, 21   ;2^22
	addi t3, zero, 1
	slli t3, t3, 20
	add t2, t2, t3
	
	add t3, zero, zero
	wait1:
		ldw t4, SPEED(zero)
		add t3, t3, t4
		cmpge t0, t3, t2
		bne t0, t1, wait1 
		ret
; END:wait

; BEGIN:get_gsa
get_gsa:
	addi t0, zero, -4
	addi t1, zero,-1
	ldw t2, GSA_ID(zero)	

 	countGet:
		addi t0, t0, 4
		addi t1, t1, 1
		bne t1, a0, countGet

	addi t1, zero, 1
	beq t1, t2, caseID1Get

	caseID0Get:
		ldw v0, GSA0(t0) 
		ret
	caseID1Get:
		ldw v0, GSA1(t0)
		ret
; END:get_gsa

; BEGIN:set_gsa
set_gsa: 
	addi t0, zero, -4
	addi t1, zero, -1
	ldw t2, GSA_ID(zero)
 	countSet:
		addi t0, t0, 4
		addi t1, t1, 1
		bne t1, a1, countSet

	addi t1, zero, 1
	beq t1, t2, caseID1Set
	caseIDOSet:
		stw a0, GSA0(t0) 
		ret
	caseID1Set:
		stw a0, GSA1(t0)
		ret
; END:set_gsa

; BEGIN:draw_gsa
draw_gsa:
	addi sp, sp, -4
	stw ra, 0(sp)

	call clear_leds
	
	addi t5, zero, 0         ; line counter
	addi t7, zero, N_GSA_LINES
	addi t6, zero, N_GSA_COLUMNS

	draw_gsa_y_loop:
		addi a0, t5, 0
		addi sp, sp, -12
		stw t5, 0(sp)
		stw t6, 4(sp)
		stw t7, 8(sp)
		call get_gsa        ;gsa line in v0
		ldw t5, 0(sp)
		ldw t6, 4(sp)
		ldw t7, 8(sp)
		addi sp, sp, 12
		addi t4, zero, 0    ;x counter
		draw_gsa_x_loop:
			addi t3, zero, 1    ; 1 for mask
			sll t3, t3, t4       ; 0...1.00 mask at x-th bit of gsa line
			and t3, t3, v0		;and the mask and gsa line
			bne t3, zero, draw_pixel   ; if and != 0 then draw pixel
			br end_x_loop
			draw_pixel:
				addi a0, t4, 0  ;x
				addi a1, t5, 0  ;y
				addi sp, sp, -20
				stw t3, 0(sp)
				stw t4, 4(sp)
				stw t5, 8(sp)
				stw t6, 12(sp)
				stw t7, 16(sp)
				call set_pixel
				ldw t3, 0(sp)
				ldw t4, 4(sp)
				ldw t5, 8(sp)
				ldw t6, 12(sp)
				ldw t7, 16(sp)
				addi sp, sp, 20
			end_x_loop:
			addi t4, t4, 1      ; x++
			bne t4, t6, draw_gsa_x_loop
		addi t5, t5, 1         ; y++
		bne t5, t7, draw_gsa_y_loop

	ldw ra, 0(sp)
	addi sp, sp, 4
	ret 
; END:draw_gsa

; BEGIN:random_gsa
random_gsa:
	addi sp, sp, -4
	stw ra, 0(sp)

	addi t5, zero, 0 ; y counter
	random_gsa_loop1:
	addi t6, zero, N_GSA_COLUMNS	
	addi t4, zero, 0      ; x counter
	addi a0, zero, 0      ; gsa line for set gsa
	random_gsa_loop2:
		ldw t3, RANDOM_NUM(zero)    ; random number
		andi t3, t3, 1           	 ; random number mod 2
		sll t3, t3, t4                ; shift left the 1 or 0 in LSB to x-coord value of counter
		or a0, a0, t3				 ; or the mask with the line
		addi t4, t4, 1				 ; i++
		bne t4, t6, random_gsa_loop2	 ; while i != 12			    
	add a1, zero, t5

	addi sp, sp, -4
	stw t5, 0(sp)
	call set_gsa
	ldw t5, 0(sp)
	addi sp, sp, 4

	addi t5, t5, 1
	addi t7, zero, N_GSA_LINES
	bne t5, t7, random_gsa_loop1

	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
; END:random_gsa

; BEGIN:change_speed	
change_speed:
	ldw t0, SPEED(zero)
	addi t1, zero, 0

	beq a0, t1, speedIncr	
	speedDecr:
		addi t0, t0, -1
		addi t1, zero, MIN_SPEED
		bge t1, t0, minSpeed
		stw t0, SPEED(zero)
		ret
		minSpeed:
			stw t1, SPEED(zero)
			ret
	speedIncr: 
		addi t0, t0, 1
		addi t1, zero, MAX_SPEED 	
		bge t0, t1, maxSpeed
		stw t0, SPEED(zero)
		ret
		maxSpeed:
			stw t1, SPEED(zero)
			ret
; END:change_speed

; BEGIN:pause_game
pause_game:
	ldw t0, PAUSE(zero)
	xori t0, t0, 1
	stw t0, PAUSE(zero)
	ret
; END:pause_game

; BEGIN:change_steps
change_steps:
	ldw t0, CURR_STEP(zero)
	addi t1, zero, 1
	
	bne a2, t1, addTen
	addi t0, t0, 0x100
	addTen:
		bne a1, t1, addUnit
		addi t0, t0, 0x10
	addUnit:
		bne a0, t1, changeStepsFin
		addi t0, t0, 0x1
	changeStepsFin:
		andi t0, t0, 0xFFF
		stw t0, CURR_STEP(zero)
		ret
; END:change_steps

; BEGIN:increment_seed
increment_seed: 
	addi sp, sp, -4
	stw ra, 0(sp)

	ldw t7, CURR_STATE(zero)
	ldw t6, SEED(zero)  ; current Seed
	addi t4, zero, INIT
	addi t5, zero, RAND
	beq t7, t5, incr_seed_rand_state
	beq t7, t4, incr_seed_init_state
	incr_seed_init_state:
		addi t7, zero, 3
		beq t6, t7, seed_3_or_4_or_rand ; if seed == 3 and state == init
		addi t7, zero, 4
		beq t6, t7, seed_3_or_4_or_rand ; if seed == 4 and state == init
		
		addi t6, t6, 1      ; seed + 1
		stw t6, SEED(zero)  ; store new seed
		slli t6, t6 , 2     ; n-th seed : n*4
		addi t5, zero, 0   ; line counter
		addi t7, zero, N_GSA_LINES  ; max lines
		ldw t6, SEEDS(t6)
		setNewGsa:
			ldw a0, 0(t6)  ; address of new seed
			addi a1, t5, 0
			addi sp, sp, -12
			stw t5, 0(sp)
			stw t6, 4(sp)
			stw t7, 8(sp)
			call set_gsa
			ldw t5, 0(sp)
			ldw t6, 4(sp)
			ldw t7, 8(sp)
			addi sp, sp, 12
			addi t6, t6, 4
			addi t5, t5, 1
			bne t5, t7, setNewGsa
			br incrSeedEnd
	seed_3_or_4_or_rand:
		addi t7, zero, 4
		stw t7, SEED(zero)
		call random_gsa
		br incrSeedEnd
	incr_seed_rand_state:
		addi t7, zero, 4
		beq t6, t7, seed_3_or_4_or_rand
	incrSeedEnd:
		ldw ra, 0(sp)
		addi sp, sp, 4
		ret
; END:increment_seed

; BEGIN:update_state
update_state:
	addi sp, sp, -4
	stw ra, 0(sp)

	ldw t0, CURR_STATE(zero) ; current state
	addi t1, zero, RUN
	beq t0, t1, updateRun
	addi t1, zero, RAND
	beq t0, t1, updateRand
	updateInit:
		ldw t0, SEED(zero)
		addi t1, zero, N_SEEDS
		beq t0, t1, changeToRand
		addi t1, zero, 2     ; to test if button 1 is activated
		beq a0, t1, changeToRun
 		br updateEnd
	updateRand:
		addi t1, zero, 2     ; to test if button 1 is activated
		beq a0, t1, changeToRun
		br updateEnd
	updateRun:
		addi t1, zero, 8     ; to test if button 3 is activated
		beq a0, t1, changeToInit
		ldw t2, CURR_STEP(zero)
		beq t2, zero, changeToInit
		br updateEnd
	changeToInit:
		addi t0, zero, INIT
		stw t0, CURR_STATE(zero)
		addi t0 , zero, PAUSED
		stw t0, PAUSE(zero)
		call reset_game
		br updateEnd
	changeToRand:
		addi t0, zero, RAND
		stw t0, CURR_STATE(zero)
		br updateEnd
	changeToRun:
		addi t0, zero, RUN
		stw t0, CURR_STATE(zero)
		addi t0, zero, RUNNING
		stw t0, PAUSE(zero)
		br updateEnd
	updateEnd:
		ldw ra, 0(sp)
		addi sp, sp, 4
		ret
; END:update_state

; BEGIN:select_action
select_action:
		addi sp, sp, -4
		stw ra, 0(sp)

		ldw t7, CURR_STATE(zero)
		addi t0, zero, 1
		addi t1, zero, 2
		addi t2, zero, 4
		addi t3, zero, 8
		addi t4, zero, 16
		addi t6, zero, RUN
		beq t7, t6, select_action_case_run

		select_action_case_init_and_rand:
			beq a0, t0, init_b0
			beq a0, t2, init_b2
			beq a0, t3, init_b3
			beq a0, t4, init_b4
			br select_action_end

			init_b0:
				call increment_seed
				br select_action_end
			init_b2:
				addi a2, zero, 1
				addi a1, zero, 0
				addi a0, zero, 0
				br init_b2_b3_b4
			init_b3:
				addi a2, zero, 0
				addi a1, zero, 1
				addi a0, zero, 0
				br init_b2_b3_b4
			init_b4:
				addi a2, zero, 0
				addi a1, zero, 0
				addi a0, zero, 1
				br init_b2_b3_b4
			init_b2_b3_b4:
				call change_steps
				br select_action_end
		
		select_action_case_run:
			beq a0, t0, run_b0
			beq a0, t1, run_b1
			beq a0, t2, run_b2
			beq a0, t4, run_b4
			br select_action_end
			run_b0:
				call pause_game
				br select_action_end
			run_b1:
				addi a0, zero, 0
				br run_change_speed
			run_b2:
				addi a0, zero, 1
				br run_change_speed
			run_change_speed:
				call change_speed
				br select_action_end
			run_b4:
				call random_gsa
				br select_action_end

		select_action_end:
			ldw ra, 0(sp)
			addi sp, sp, 4
			ret
; END:select_action

; BEGIN:cell_fate
cell_fate:
	addi t0, zero, 1
	beq a1, t0, currently_living
	currently_dead:
		addi t0, zero, 3
		beq a0, t0, next_alive
		br next_dead
	currently_living:
		addi t0, zero, 2
		blt a0, t0, next_dead
		addi t0, zero, 4
		bge a0, t0, next_dead
		br next_alive
	next_dead:
		addi v0, zero, 0
		ret
	next_alive:
		addi v0, zero, 1
		ret
; END:cell_fate

; BEGIN:find_neighbours
find_neighbours:
	addi sp, sp, -4
	stw ra, 0(sp)

	addi t1, a0, 0
	addi t4, a1, 0
	addi t3, t4, -1
	andi t3, t3, 7
	addi t5, t4, 1
	andi t5, t5, 7
	addi t0, t1, -1
	addi t2, t1, 1
	addi t6, zero, N_GSA_COLUMNS
	addi t7, zero, -1
	beq t0, t6, mod_12_minus_t0
	beq t0, t7, mod_12_plus_t0
	br body_find_neighbours
	mod_12_minus_t0:
		addi t0, t0, -N_GSA_COLUMNS
		br body_2_find_neighbours
	mod_12_plus_t0:
		addi t0, t0, N_GSA_COLUMNS
		br body_2_find_neighbours
	body_find_neighbours:
		beq t2, t6, mod_12_minus_t2
		beq t2, t7, mod_12_plus_t2
		br body_2_find_neighbours
	mod_12_minus_t2:
		addi t2, t2, -N_GSA_COLUMNS
		br body_2_find_neighbours
	mod_12_plus_t2:
		addi t2, t2, N_GSA_COLUMNS
		br body_2_find_neighbours
	body_2_find_neighbours:
		addi sp, sp, -32
		stw t0, 0(sp)
		stw t1, 4(sp)
		stw t2, 8(sp)
		stw t3, 12(sp)
		stw t4, 16(sp)
		stw t5, 20(sp)
		stw t6, 24(sp)
		stw t7, 28(sp)

		addi a0, t3, 0
		call get_gsa
		stw v0, 12(sp)

		ldw a0, 16(sp)
		call get_gsa
		stw v0, 16(sp)

		ldw a0, 20(sp)
		call get_gsa
		stw v0, 20(sp)

		ldw t0, 0(sp)
		ldw t1, 4(sp)
		ldw t2, 8(sp)
		ldw t3, 12(sp)
		ldw t4, 16(sp)
		ldw t5, 20(sp)
		ldw t6, 24(sp)
		ldw t7, 28(sp)
		addi sp, sp, 32

		addi v0, zero, 0
		addi t6, zero, 1

		sll t7, t6, t0     ;top left neighbour
		and t7, t7, t3
		srl t7, t7, t0
		add v0, v0, t7

		sll t7, t6, t1     ; top center neighbour
		and t7, t7, t3
		srl t7, t7, t1
		add v0, v0, t7

		sll t7, t6, t2    ; top right neighbour
		and t7, t7, t3
		srl t7, t7, t2
		add v0, v0, t7
		
		sll t7, t6, t0    ; mid left neighbour
		and t7, t7, t4 
		srl t7, t7, t0
		add v0, v0, t7

		sll t7, t6, t2   ; mid right neighbour
		and t7, t7, t4
		srl t7, t7, t2
		add v0, v0, t7
		
		sll t7, t6, t0   ; low left neighbour
		and t7, t7, t5
		srl t7, t7, t0
		add v0, v0, t7

		sll t7, t6, t1   ; low center neighbour
		and t7, t7, t5
		srl t7, t7, t1
		add v0, v0, t7
		
		sll t7, t6, t2   ; low right neighbour
		and t7, t7, t5
		srl t7, t7, t2
		add v0, v0, t7

		sll t7, t6, t1   ; middle center cell for state
		and t7, t7, t4
		srl t7, t7, t1
		add v1, t7, zero

		ldw ra, 0(sp)
		addi sp, sp, 4
		ret 
; END:find_neighbours

; BEGIN:update_gsa
update_gsa:
	addi sp, sp, -4
	stw ra, 0(sp)

	addi sp, sp, -32
	stw s0, 0(sp)
	stw s1, 4(sp)
	stw s2, 8(sp)
	stw s3, 12(sp)
	stw s4, 16(sp)
	stw s5, 20(sp)
	stw s6, 24(sp)
	stw s7, 28(sp)

	ldw s0, PAUSE(zero)
	addi s1, zero, PAUSED
	beq s0, s1, update_gsa_ret
	addi s1, zero, 0    ; y counter
	addi s0, zero, 0    ; x counter
	addi s6, zero, N_GSA_COLUMNS
	addi s7, zero, N_GSA_LINES
	update_gsa_loop_y:
	ldw s4, GSA_ID(zero)     ; current gsa
	addi s0, zero, 0
	addi s3, zero, 0
		update_gsa_loop_x:
		addi a0, s0, 0
		addi a1, s1, 0
		call find_neighbours
		addi a0, v0, 0
		addi a1, v1, 0
		call cell_fate
		addi s5, v0, 0    ; 1 or 0 if cell to live or die
		sll s5, s5, s0    ; create mask 
		or s3, s3, s5     ; or mask with new line being created
		addi s0, s0, 1    ; x++
		bne s0, s6, update_gsa_loop_x
	addi a0, s3, 0        ; line to set in gsa
	addi a1, s1, 0        ; y coord
	xori s4, s4, 1        
	stw s4, GSA_ID(zero)  ; next gsa
	call set_gsa
	xori s4, s4, 1
	stw s4, GSA_ID(zero)  ; current gsa
	addi s1, s1, 1        ; y++
	bne s1, s7, update_gsa_loop_y 
	xori s4, s4, 1        ; current gsa = next gsa
	stw s4, GSA_ID(zero)

	update_gsa_ret:
		ldw s0, 0(sp)
		ldw s1, 4(sp)
		ldw s2, 8(sp)
		ldw s3, 12(sp)
		ldw s4, 16(sp)
		ldw s5, 20(sp)
		ldw s6, 24(sp)
		ldw s7, 28(sp)
		addi sp, sp, 32

		ldw ra, 0(sp)
		addi sp, sp, 4
		ret
; END:update_gsa

; BEGIN:mask
mask:
	addi sp, sp, -4
	stw ra, 0(sp)

	addi t1, zero, 1
	addi a1, zero, 0     ; y coord
	ldw t4, CURR_STATE(zero)
	bne t4, t1, mask_normal_state
	mask_rand_state:
		addi t6, zero, mask4  
		addi t0, zero, 0
		br mask_use_mask
	mask_normal_state:
		ldw t5, SEED(zero)
		slli t5, t5, 2
		ldw t6, MASKS(t5)
		addi t0, zero, 0
	mask_use_mask:
		addi a0, t0, 0
		addi sp, sp, -8
		stw t0, 0(sp)
		stw t6, 4(sp)
		call get_gsa
		ldw t0, 0(sp)
		ldw t6, 4(sp)
		addi a0, v0, 0
		ldw t4, 0(t6)
		and a0, a0, t4
		addi a1, t0, 0
		stw t0, 0(sp)
		stw t6, 4(sp)
		call set_gsa
		ldw t0, 0(sp)
		ldw t6, 4(sp)
		addi sp, sp, 8
		addi t0, t0, 1
		addi t6, t6, 4   
		addi t7, zero, N_GSA_LINES
		bne t0, t7, mask_use_mask

		ldw ra, 0(sp)
		addi sp, sp, 4
		ret
; END:mask

; BEGIN:get_input
get_input:
	addi t0, zero, 0
	ldw t1, BUTTONS+4(zero)
	addi t4, zero, 5
	get_input_loop:
		addi t2, zero, 1
		sll t2, t2, t0
		and t3, t1, t2
		bne t3, zero, get_input_ith_bit_set 
		addi t0, t0, 1
		bne t0, t4, get_input_loop
	get_input_ith_bit_set:
		addi v0, t3, 0
		stw zero, BUTTONS+4(zero)
		ret
; END:get_input

; BEGIN:decrement_step
decrement_step:
	ldw t0, CURR_STATE(zero)
	ldw t1, CURR_STEP(zero)
	addi t2, zero, 2
	beq t0, t2, decrement_step_case_run
	br display_steps
	decrement_step_case_run:
		ldw t7, PAUSE(zero)
		beq t7, zero, display_steps
		bne t1, zero, decrement_and_ret0
		addi v0, zero, 1
		ret
		decrement_and_ret0:
			addi t1, t1, -1
			stw t1, CURR_STEP(zero)
			br display_steps
	display_steps:
		addi v0, zero, 0
		andi t3, t1, 0x0000F000
		srli t3, t3, 10
		ldw t3, font_data(t3)
		andi t4, t1, 0x00000F00
		srli t4, t4, 6
		ldw t4, font_data(t4)
		andi t5, t1, 0x000000F0
		srli t5, t5, 2
		ldw t5, font_data(t5)
		andi t6, t1, 0x0000000F
		slli t6, t6, 2
		ldw t6, font_data(t6)
		stw t3, SEVEN_SEGS(zero)
		stw t4, SEVEN_SEGS+4(zero)
		stw t5, SEVEN_SEGS+8(zero)
		stw t6, SEVEN_SEGS+12(zero)
		ret
; END:decrement_step

; BEGIN:reset_game
reset_game:
	addi sp, sp, -4
	stw ra, 0(sp)

	addi t1, zero, 1
	stw t1, CURR_STEP(zero)
	ldw t0, font_data(zero)
	ldw t2, font_data+4(zero)
	stw t0, SEVEN_SEGS(zero)
	stw t0, SEVEN_SEGS+4(zero)
	stw t0, SEVEN_SEGS+8(zero)
	stw t2, SEVEN_SEGS+12(zero)

	stw zero, SEED(zero)
	stw zero, CURR_STATE(zero)
	stw t1, CURR_STEP(zero)
	stw zero, GSA_ID(zero)
	stw zero, PAUSE(zero)
	stw t1, SPEED(zero)

	addi t0, zero, 0
	addi t1, zero, N_GSA_LINES
	reset_loop:         ; load seed 0 in GSA 0
	slli t3, t0, 2
	ldw t2, seed0(t3)
	add a0, t2, zero
	add a1, t0, zero
	addi sp, sp, -32
	stw t0, 0(sp)
	stw t1, 4(sp)
	stw t2, 8(sp)
	stw t3, 12(sp)
	stw t4, 16(sp)
	stw t5, 20(sp)
	stw t6, 24(sp)
	stw t7, 28(sp)
	
	call set_gsa

	ldw t0, 0(sp)
	ldw t1, 4(sp)
	ldw t2, 8(sp)
	ldw t3, 12(sp)
	ldw t4, 16(sp)
	ldw t5, 20(sp)
	ldw t6, 24(sp)
	ldw t7, 28(sp)
	addi sp, sp, 32
	addi t0, t0, 1
	bne t0, t1, reset_loop

	ldw ra, 0(sp)
	addi sp, sp, 4
	ret				
; END:reset_game
						
font_data:
    .word 0xFC ; 0
    .word 0x60 ; 1
    .word 0xDA ; 2
    .word 0xF2 ; 3
    .word 0x66 ; 4
    .word 0xB6 ; 5
    .word 0xBE ; 6
    .word 0xE0 ; 7
    .word 0xFE ; 8
    .word 0xF6 ; 9
    .word 0xEE ; A
    .word 0x3E ; B
    .word 0x9C ; C
    .word 0x7A ; D
    .word 0x9E ; E
    .word 0x8E ; F

seed0:
    .word 0xC00
    .word 0xC00
    .word 0x000
    .word 0x060
    .word 0x0A0
    .word 0x0C6
    .word 0x006
    .word 0x000

seed1:
    .word 0x000
    .word 0x000
    .word 0x05C
    .word 0x040
    .word 0x240
    .word 0x200
    .word 0x20E
    .word 0x000

seed2:
    .word 0x000
    .word 0x010
    .word 0x020
    .word 0x038
    .word 0x000
    .word 0x000
    .word 0x000
    .word 0x000

seed3:
    .word 0x000
    .word 0x000
    .word 0x090
    .word 0x008
    .word 0x088
    .word 0x078
    .word 0x000
    .word 0x000

    ;; Predefined seeds
SEEDS:
    .word seed0
    .word seed1
    .word seed2
    .word seed3

mask0:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF

mask1:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF

mask2:
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF

mask3:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

mask4:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000

MASKS:
    .word mask0
    .word mask1
    .word mask2
    .word mask3
    .word mask4
