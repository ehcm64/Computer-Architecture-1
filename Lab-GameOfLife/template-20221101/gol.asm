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

main:
    call clear_leds
	addi a0, zero, 2
	addi a1, zero, 4
	call set_pixel
	

;	BEGIN:clear_leds
clear_leds:
    stw zero, LEDS[0](zero)
	stw zero, LEDS[1](zero)
	stw zero, LEDS[2](zero)
    ret
;	END:clear_leds

;	BEGIN:set_pixel
set_pixel:
				;set_pixel(a0: x, a0: y):
					;n = 8*x + y mod 32
	slli a0, a0, 3          
	add a0, a0, a1       ; a0 = 8x + y
	
	addi t0, zero, 32    ; t0 = 32
	addi t1, zero, 64	 ; t1 = 64
	
	bge a0, t1, case_led2
	bge a0, t0, case_led1
	br case_led0
	case_led0:
		ldw t2, LEDS(zero)     
		addi t3, zero, 1             ; t3 = 1
		slli a0, a0, 27				 
		srli a0, a0, 27                ; 8x + y mod 32
		sll t3, t3, a0                ; mask 1 << 8x + y mod 32
		or t2, t2, t3                ; mask | leds
		stw t2, LEDS(zero)			  ; new leds into leds
		ret
	case_led1:
		ldw t2, LEDS+4(zero)
		addi t3, zero, 1
		slli a0, a0, 27
		srli a0, a0, 27
		sll t3, t3, a0
		or t2, t2, t3
		stw t2, LEDS+4(zero)
		ret
	case_led2:
		ldw t2, LEDS+4(zero)
		addi t3, zero, 1
		slli a0, a0, 27
		srli a0, a0, 27
		sll t3, t3, a0
		or t2, t2, t3
		stw t2, LEDS+4(zero)
		ret
;	END:set_pixel

;	BEGIN:wait
wait: 
	addi t1, zero, 1
	addi t2, zero, 1 ; 
	slli t2, t2, 19     ;2^19
	
	add s0, zero, zero
	wait1:
		cmpge t0, s0, t2
		addi s0, s0, SPEED
		bne t0 ,t1, wait1 
		ret
;   END:wait

;	BEGIN:get_gsa
get_gsa:
	addi t0, zero, -4
	addi t1, zero,-1
	addi t2, zero, GSA_ID	

 	countGet:
		addi t0, t0, 4
		addi t1, t1, 1
		bne t1, a0, countGet
	addi t1, zero, 1
	beq t1, t2, caseID1Get
	caseID0Get:
		addi v0, t0, GSA0 
	caseID1Get:
		addi v0, t0, GSA1 
;	END:get_gsa

;	BEGIN:set_gsa
set_gsa: 
	addi t0, zero, -4
	addi t1, zero, -1
	addi t2, zero, GSA_ID
 	countSet:
		addi t0, t0, 4
		addi t1, t1, 1
		bne t1, a1, countSet

	addi t1, zero, 1
	beq t1, t2, caseID1Set
	caseIDOSet:
		stw a0, GSA0(t0) 
	caseID1Set:
		stw a0, GSA1(t0)
;	END:set_gsa

;	BEGIN:draw_gsa
draw_gsa:
	addi s0, zero, 1 ; mask 0
	addi s1, zero, 1 ; mask 1
	slli s1, s1, 4 
	addi s2, zero, 1 ; mask 2
	slli s2, s2, 8

	addi t0, zero, 0 ; counter
	addi s3, zero, 7 ; max

	loop0:
		ldw t3, GSA0(t0)
		and t0, s0, t3
		and t1, s1, t3
		and t2, s2, t3
		 
;	END:draw_gsa

;	BEGIN:random_gsa
random_gsa:
	addi sp, sp, -4
	stw ra, 0(sp)
	addi t5, zero, 8
	addi t4, zero, 0
	random_gsa_loop1:
	addi a0, zero, t4
	call get_gsa	
	add t2, zero, v0     ; the line
	add t0, t0, zero      ; counter
	addi t3, zero, 12	   ; max counter value
	random_gsa_loop2:
		ldw t1, RANDOM_NUM(zero)    ; random number
		andi t1, t1, 1           	 ; random number mod 2
		sll t1, t1, t0                ; shift left the 1 or 0 in LSB to x-coord value of counter
		or t2, t2, t1				 ; or the mask with the line
		addi t0, t0, 1				 ; i++
		bne t0, t3, random_gsa_loop2	 ; while i != 12
	add a0, zero, t2			    
	addi a1, zero, t4
	call set_gsa
	addi t4, t4, 1
	bne t4, t5, random_gsa_loop1
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
;	END:random_gsa


;	BEGIN:cell_fate
cell_fate:
	; a0 = number of live neighbouring cells
	; a1 = examined cell state
	addi t1, zero, 1
	addi t2, zero, 2
	addi t3, zero, 3
	beq a1, t1, living
	br dead
	living:
		blt a0, t2, underpopulation
		bge a0, t3, overpopulation
		br stasis
		underpopulation:
			addi v0, zero, 0
			ret
		overpopulation:
			addi v0, zero, 0
			ret
		stasis:
			addi v0, a1, 0
			ret
	dead:
		beq a0, t3, reproduction
		ret
		reproduction:
			addi v0, zero, 1
			ret
;	END:cell_fate

;	BEGIN:find_neighbours
find_neighbours:
	addi sp, sp, -4
	stw ra, 0(sp)
	addi t1, a0, 0
	addi t4, a1, 0
	addi t3, t4, -1
	andi t3, t3, 7
	addi t5, t2, 1
	andi t5, t5, 7
	addi t0, t1, -1
	addi t2, t1, 1
	addi t6, zero, 12
	addi t7, zero, -1
	beq t0, t6, mod_12_minus_t0
	beq t0, t7, mod_12_plus_t0
	br body_find_neighbours
	mod_12_minus_t0:
		addi t0, t0, -12
		br body_find_neighbours
	mod_12_plus_t0:
		addi t0, t0, 12
		br body_find_neighbours
	body_find_neighbours:
		beq t2, t6, mod_12_minus_t2
		beq t2, t7, mod_12_plus_t2
	mod_12_minus_t2:
		addi t2, t2, -12
		br body_2_find_neighbours
	mod_12_plus_t2:
		addi t2, t2, 12
		br body_2_find_neighbours
	body_2_find_neighbours:
		addi sp, sp, -12
		stw t0, 8(sp)
		stw t1, 4(sp)
		stw t2, 0(sp)
		addi a0, t3, 0
		call get_gsa
		addi t3, zero, v0
		addi a0, t4, 0
		call get_gsa
		addi t4, zero, v0
		addi a0, t5, 0
		call get_gsa
		addi t5, zero, v0

		ldw t0, 8(sp)
		ldw t1, 4(sp)
		ldw t2, 0(sp)
		addi sp, sp, 12

		addi v0, zero, 0
		addi t6, zero, 1

		sll t7, t6, t0
		and t7, t7, t3
		srl t7, t7, t0
		add v0, v0, t7

		sll t7, t6, t1
		and t7, t7, t3
		srl t7, t7, t1
		add v0, v0, t7

		sll t7, t6, t2
		and t7, t7, t3
		srl t7, t7, t2
		add v0, v0, t7
		
		sll t7, t6, t0
		and t7, t7, t4
		srl t7, t7, t0
		add v0, v0, t7

		sll t7, t6, t2
		and t7, t7, t4
		srl t7, t7, t2
		add v0, v0, t7
		
		sll t7, t6, t0
		and t7, t7, t5
		srl t7, t7, t0
		add v0, v0, t7

		sll t7, t6, t1
		and t7, t7, t5
		srl t7, t7, t1
		add v0, v0, t7
		
		sll t7, t6, t2
		and t7, t7, t5
		srl t7, t7, t2
		add v0, v0, t7

		sll t7, t6, t1
		and t7, t7, t4
		srl t7, t7, t1
		add v1, t7, zero
		ldw ra, 0(sp)
		addi sp, sp, 4
		ret 
;	END:find_neighbours

;	BEGIN:update_gsa
update_gsa:
	ldw t0, PAUSE(zero)
	addi t1, zero, PAUSED
	beq t0, t1, update_gsa_ret
	stw ra, 0(sp)
	addi t1, zero, 0
	addi t0, zero, 0
	addi t6, zero, 12
	addi t7, zero, 8 
	addi t3, zero, 0
	update_gsa_loop_y:
	ldw t4, GSA_ID(zero)
	addi a0, t1, 0
	addi sp, sp, -4
	call get_gsa
	addi t2, v0, 0
		update_gsa_loop_x:
		addi a0, t0, 0
		addi a1, t1, 0
		call find_neighbours
		addi a0, v0, 0
		addi a1, v1, 0
		call cell_fate
		addi t5, v0, 0
		sll t5, t5, t0
		or t3, t3, t5
		addi t0, t0, 1
		bne t0, t6, update_gsa_loop_x
	addi a0, t3, 0
	addi a1, t1, 0
	xori t4, t4, 1
	stw t4, GSA_ID(zero)
	call set_gsa
	xori t4, t4, 1
	stw t4, GSA_ID(zero)
	addi t1, t1, 1
	bne t1, t7, update_gsa_loop_y
	update_gsa_ret:
		ldw ra, 0(sp)
		addi sp, sp, 4
		xori t4, t4, 1
		stw t4, GSA_ID(zero)
		ret
;	END:update_gsa

;	BEGIN:mask
mask:
	addi sp, sp, -4
	stw ra, 0(sp)
	addi t0, zero, 3
	addi t1, zero, 1
	addi t2, zero, 2
	addi t3, zero, 0
	addi t7, zero, 8
	ldw t4, CURR_STATE(zero)
	bne t4, t1, mask_normal_state
	mask_rand_state:
		addi t6, zero, mask4
		br mask_use_mask
	mask_normal_state:
		ldw t5, SEED(zero)
		beq t5, zero, set_mask0
		beq t5, t1, set_mask1
		beq t5, t2, set_mask2
		beq t5, t0, set_mask3
		set_mask0:
			addi t6, zero, mask0
			br mask_use_mask
		set_mask1:
			addi t6, zero, mask1
			br mask_use_mask
		set_mask2:
			addi t6, zero, mask2
			br mask_use_mask
		set_mask3:
			addi t6, zero, mask3
			br mask_use_mask
	mask_use_mask:
		addi a0, t3, 0
		call get_gsa
		addi a0, v0, 0
		ldw t4, 0(t6)
		and a0, a0, t4
		addi a1, t3, 0
		call set_gsa
		addi t3, t3, 4
		addi t6, t6, 4   ; to put in first line of this label if needed + 4 for ldw 5 lines up
		bne t3, t7, mask_use_mask
		ldw ra, 0(sp)
		addi sp, sp, 4
		ret
;	END:mask



							
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
