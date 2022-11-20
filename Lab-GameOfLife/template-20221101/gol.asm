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
    jmp clear_leds
	addi a0, zero, 5
	addi a1, zero, 1 
	set_pixel

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
		ldw t6, LEDS[0](zero)
		srl t0, t0, t1
		or t6, t6, t0
		stw t6, LEDS[0](zero)
		ret
	case_led1:
		ldw t6, LEDS[1](zero)
		srl t0, t0, t1
		or t6, t6, t0
		stw t6, LEDS[1](zero)
		ret
	case_led2:
		ldw t6, LEDS[2](zero)
		srl t0, t0, t1
		or t6, t6, t0
		stw t6, LEDS[2](zero)
		ret

;	END:set_pixel

; BEGIN: wait
addi t1, zero, 1
add s0, zero, zero
wait: 
	cmpgei t0, s0, 524288
	add s0, s0, SPEED
	bne t0,t1, wait 
	ret
;   END: wait


; BEGIN set_gsa 


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
