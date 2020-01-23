#make_bin#

; BIN is plain binary format similar to .com format, but not limited to 1 segment;
; All values between # are directives, these values are saved into a separate .binf file.
; Before loading .bin file emulator reads .binf file with the same file name.

; All directives are optional, if you don't need them, delete them.

; set loading address, .bin file will be loaded to this address:
#LOAD_SEGMENT=0000h#
#LOAD_OFFSET=0000h#

; set entry point:
#CS=0000h#	; same as loading segment
#IP=0000h#	; same as loading offset

; set segment registers
#DS=0000h#	; same as loading segment
#ES=0000h#	; same as loading segment

; set stack
#SS=0000h#	; same as loading segment
#SP=0000h#	; set to top of loading segment

; set general registers (optional)
#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here    

        db 512 dup(0)
		
		mov ax, 0
		mov es,ax
		mov al,10h
		mov bl,4h
		mul bl
		mov bx,ax
		mov si,offset[ac_isr]
		mov es:[bx], si
		add bx, 2
		mov ax, 0000
		mov es:[bx], ax
		
				
		

		var	db 	01h			;indicating the initial value of water level
		creg	equ 	06h			;control register for 8255
		porta 	equ 	00h
		portb 	equ 	02h
		portc 	equ 	04h
		cnt0 	equ 	08h
		creg2 	equ 	0Eh			;control register for 8253


     
		cli  					; disable the interrupt

      		
    	mov 	al,90h					;initializing porta as input and portb as output
    	out 	creg,al
    	mov 	al,00h
    	out 	portb,al 				;output low at portb
		  

;Control word for 8253 for initializing the time in mode3
	    mov       al,00010110b      
	    out       0Eh,al
	    mov 	    al, 0feh			;initializing timer for 254
        out 	    cnt0, al
  
; initialize 8259a
							; ICW1 (edge triggered, single 8259a, 80x86 cpu)
		mov al, 00010111b
		out 10h, al

							; ICW2 (base interrupt number 0x00)
		mov al, 00010000b
		out 12h, al
		
							; ICW4 (not special fully nested, non-buffered, auto EOI, 80x86 cpu)
		mov al, 00000001b	
		out 12h, al
		
							; OCW1 (unmask all interrupt bits)
		mov al, 00h
		out 12h, al

							; enable interrupts
		sti

							; reset port c
        mov al, 0
		out 04h, al
	
    	mov	cx,0					;intialising the counter to check the time of day
    	mov	bl,10h					;extra register for letting the motors be in same state till a change occurs in the input
		
next:	in 	al, porta 			;Reading value of porta
		and 	al,07h				;masking other inputs from porta
		cmp 	al,var	    			;comparing with the existing output needed
		jz 	x4
		ja 	x2
		jb 	x3
		
x2: 	cmp	bl,04h				;segment if the water level is more than desired
		jz	x5
		
		mov	al,01100011b			;switching inlet valve off and outlet valve on
		out	portb,al
		mov	bl,04h
		jmp	x5

x3:		cmp	bl,01h				;segment if the water level is less than the desired level
		jz	x5
		
		mov 	al,00110110b			;switching inlet valve on and outlet valve off
		out 	portb, al
		mov	bl,01h
		jmp 	x5 
		
x4:		cmp	bl,00h				;segment if the water level is equal to desired level
		jz	x5
		
		mov 	al,00110011b			;switching the valves off 
		mov	bl,00h
		out 	portb, al
		
x5:		jmp 	next
							;loop here till a interrupt occurs							


                
ac_isr:  					
				

							; OCW2 (non-specific EOI command) for resetting ISR 
		mov al, 00100000b
		out 10h, al

		inc cx					;increment counter register and check for the time of day
		
		cmp cx,5
		jz	x8
		cmp cx,9
		jz	x7
		cmp cx,16
		jz	x8
		cmp cx,18
		jz	x7
		cmp cx,24
		jz	x6
		jmp x9
	
x6:		mov var,01h				;low level of water in tank
		mov cx,00h				;reset the 24 hours clock
		jmp x9
	
x7:		mov var,03h				;medium level of water in tank
		jmp x9

x8:		mov var,05h				;peak level of water in tank
		
	
x9:		iret					;return 
		                 		 

.EXIT
END

    

HLT           ; halt!


