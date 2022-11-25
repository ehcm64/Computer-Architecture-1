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
	addi sp, sp, CUSTOM_VAR_END
    call clear_leds
	;addi t7, zero, 0b011101010101
	;addi t6, zero, 0b000001010101
	;stw t6, GSA0(zero)
	;stw t6, GSA0+4(zero)
	;stw t7, GSA0+8(zero)
	;stw t7, GSA0+12(zero)
	;stw t7, GSA0+16(zero)
	;stw t7, GSA0+20(zero)
	;stw t7, GSA0+24(zero)
	;stw t7, GSA0+28(zero)	
	
	;addi t0, zero, 0
	addi t0, zero, INIT
	stw t0, CURR_STEP(zero)
	addi t0, zero, 1
	stw t0, SEED(zero)
	call increment_seed
	addi a0, zero, 4
	call get_gsa
	call draw_gsa
	
	

;	BEGIN:clear_leds
clear_leds:
    stw zero, LEDS(zero)
	stw zero, LEDS+4(zero)
	stw zero, LEDS+8(zero)
    ret
;	END:clear_leds

;	BEGIN:set_pixel
set_pixel:
				;set_pixel(a0: x, a0: y):
					;n = 8*x + y mod 32
	addi t0, zero, 0
	addi t1, a0, 0
	addi t2, a1, 0
	multiply_loop:
		addi t3, zero, 3
		add t1, t1, t1
		addi t0, t0, 1
		bne t0, t3, multiply_loop
	add t1, t1, t2
	slli t4, t1, 26 ; 1 if Led1
	srli t4, t4, 31
	slli t5, t1, 25 ; 1 if Led2
	srli t5, t5, 31
	slli t1, t1, 27 ; calculate led to activate
	srli t1, t1, 27

	addi t0, zero, 1
	beq t0, t4, case_led1
	beq t0, t5, case_led2
	br case_led0
	case_led0:
		ldw t6, LEDS(zero)
		srl t0, t0, t1
		or t6, t6, t0
		stw t6, LEDS(zero)
		ret
	case_led1:
		ldw t6, LEDS+4(zero)
		srl t0, t0, t1
		or t6, t6, t0
		stw t6, LEDS+4(zero)
		ret
	case_led2:
		ldw t6, LEDS+8(zero)
		srl t0, t0, t1
		or t6, t6, t0
		stw t6, LEDS+8(zero)
		ret

;	END:set_pixel

; BEGIN:wait
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
;	END:get_gsa

;	BEGIN:set_gsa
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
;	END:set_gsa

;	BEGIN:draw_gsa
draw_gsa:
	addi sp, sp, -12
	stw s0, 8(sp)
	stw s1, 4(sp)
	stw s2, 0(sp)
	
	addi t0, zero, 0 ; y
	addi s0, zero, 8 ; max 
	addi t1, zero, 0 ; x
	addi s1, zero, 12 ; max x
	addi t2, zero, 0 ; GSA = counter
	
	addi s2, zero, 0
	addi t6, zero, 0
	addi t7, zero, 0
 	
	drawLoop1: ; on y
		addi t5, zero, 0
		addi t1, zero, 0
		bne t0, s0, drawLoop2
		stw s2, LEDS(zero)
		stw t6, LEDS+4(zero)
		stw t7, LEDS+8(zero)
		ldw s2, 0(sp)
		ldw s1, 4(sp)
		ldw s0, 8(sp)
		addi sp, sp, 12
		ret

		drawLoop2: ; on x
			
			ldw t3, GSA0(t2) ; word loaded from GSA0
			addi t4, zero, 1	; mask
			sll t4, t4, t1
			and t4, t3, t4	; bit at position x
			srl t4, t4, t1  ; bit at position 0
			
			addi t3, zero, 0  ; 8x + y
			add t3, t3, t1
			slli t3, t3, 3 
			add t3, t3, t0
			
			addi t5, zero, 32
			bge t3, t5, drawCase1
			
			drawCase0:
				sll t4, t4, t3
				or s2, s2, t4
				br drawGsaSmartLoop	
			drawCase1:
				addi t5, zero, 64
				bge t3, t5, drawCase2
				andi t3, t3, 31
				sll t4, t4, t3
				or t6, t6, t4
				br drawGsaSmartLoop	
	    	drawCase2:
				andi t3, t3, 31
				sll t4, t4, t3
				or t7, t7, t4
				br drawGsaSmartLoop
				
			drawGsaSmartLoop:
				addi t1, t1, 1
				bne t1, s1, drawLoop2
				addi t0, t0, 1
				addi t2, t2, 4
				br drawLoop1
				
; END: draw_gsa
				
; BEGIN: change_speed	
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
; END: change_speed

; BEGIN: pause_game
pause_game:
	ldw t0, PAUSE(zero)
	addi t1, zero, PAUSED
	beq t0, t1, isPaused
	isRunning:
		stw t1, PAUSE(zero)
	isPaused:
		addi t1, zero, 1
		stw t1, PAUSE(zero)
; END: pause_game	

; BEGIN: change_steps
change_steps:
	ldw t0, CURR_STEP(zero)
	addi t1, zero, 1
	
	bne a2, t1, addTen
	addi t0, t0, 256
	addTen:
		bne a1, t1, addUnit
		addi t0, t0, 16 
	addUnit:
		bne a0, t1, changeStepsFin
		addi t0, t0, 1
	changeStepsFin:
		andi t0, t0, 0xFFF
		stw t0, CURR_STEP(zero)
		ret
; END: change_steps

; BEGIN: increment seed
increment_seed: 
	ldw t0, CURR_STATE(zero)
	addi t1, zero, INIT
	bne t0, t1, RandState
	addi sp, sp, -4
	stw ra, 0(sp)
	InitState:
		ldw t3, SEED(zero)  ; current Seed
		addi t1, zero, 3
		beq t3, t1, gameSeed3 ; if seed == 3
		addi t1, zero, 4
		beq t3, t1, N_SEEDS ; if seed == 4
		
		addi t3, t3, 1      ; seed + 1
		stw t3, SEED(zero)  ; store new seed
		slli t3, t3 , 2
		
		addi a1, zero, 0   ; line counter
		addi t4, zero, N_GSA_LINES  ; max lines
		ldw t3, SEEDS(t3)
		setNewGsa:
			ldw a0, 0(t3)  ; address of new seed
			call set_gsa
			addi t3, t3, 4
			addi a1, a1, 1
			bne a1, t4, setNewGsa
			br incrSeedEnd
		gameSeed3:
			addi t1, t1, 1
			stw t1, SEED(zero)
			;call random_gsa
		gameSeed4:
			;call random_gsa

	RandState:
		ldw t0, SEED(zero)
		addi t1, zero, 4
		bne t0, t1, incrSeedEnd
		;call random_gsa
		
	incrSeedEnd:
		ldw t3, 0(sp)
		addi sp, sp, 4
		jmp t3

; END: incremeent_seed

; BEGIN: update_state
update_state:
	addi sp, sp, -4
	stw ra, 0(sp)
	ldw t0, CURR_STATE(zero) ; current state
	addi t1, zero, RUN
	beq t0, t3, updateRun
	addi t1, zero, RAND
	beq t0, t3, updateRand
	updateInit:
		ldw t0, SEED(zero)
		addi t1, zero, N_SEEDS
		beq t0, t1, changeToRand
		addi t0, zero, 2    ; mask to get button 1
		and t0, t0, a0
		addi t1, zero, 1
		beq t0, t1, changeToRun
 		br updateEnd
	updateRand:
		addi t0, zero, 2    ; mask to get button 1
		and t0, t0, a0
		addi t1, zero, 1
		beq t0, t1, changeToRun
	updateRun:
		addi t0, zero, 8    ; mask to get button 1
		and t0, t0, a0
		addi t1, zero, 1
		beq t0, t1, changeToInit

	changeToInit:
		addi t0, zero, INIT
		stw t0, CURR_STATE(zero)
		;call reset_game
		br updateEnd
	changeToRand:
		addi t0, zero, RAND
		stw t0, CURR_STATE(zero)
		br updateEnd
	changeToRun:
		addi t0, zero, RUN
		stw t0, CURR_STATE(zero)
		br updateEnd
	updateEnd:
		ldw t0, 0(sp)
		addi sp, sp, 4
		jmp t0
	
		
		
		
	
		
		
	
		
								
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
