;   EXAM4 2019 - MOUSE DROPPINGS 
;   Michael Stanaszak

Comment!
     This program uses int33h to attach to the system mouse 
     driver to control mouse movements.
	 
     Actions for mouse events are supplied by the student as 
     per EXAM4.DOC requirements. Refer to the external
     documentation in EXAM4DOC.DOCX for exceptions and
     enhancements. Non implemented components still under
     construction are identified in the external documentation
     EXAM4DOC.DOC and marked with comments in UPPERCASE within 
	 the modules below. 
     A separate file, EXAM4A.asm may contain an alternate 
     version of your program with code that "almost" works.

	 Assistance received:  (be very specific)

	 I am signing this document to verify that I 
	 have followed the Academic Honor Code without exception.


         HONOR CODE SIGNATURE:______________________ DATE:_______
	 
       !

; Set up the stack
SSEG    SEGMENT   PARA  STACK  'STACK'
    DB  551  DUP ('MY_STACK')   ; can find the stack under debug
SSEG    ENDS


CSEG    SEGMENT  PARA  PUBLIC
	; Tell TASM about our segment definitions.
	ASSUME  CS:CSEG, DS:CSEG, SS:SSEG

	; We are linking BIOS + INOUT10
	;place the EXTRN statements here
    EXTRN clrscr:near
	EXTRN getch:near, kbhit:near
    EXTRN putCstring10:near
	EXTRN putDec10:near
	EXTRN LOCATE:near
	EXTRN WRITEATTR:near
	EXTRN CURSOROFF:near
	EXTRN WRITE:near
	EXTRN READATTR:near

; Data placed with the code so that the mouse driver can easily find it.

error  db 'Cannot initialize mouse -- shutting down'
       db 0

CrapChar  db ' '     ; character used for droppings
                     ;changed in the main
CrapColor db 0F0h    ; color used for droppings
                     ; you will change this

mouseX  db  0        ; horizontal value for mouse pointer
mouseY  db  0        ; vertical value for mouse pointer
exit    dw  0        ; bool used to exit program - set by getch
                     ; or mouse
mouseFlag dw 0
mouseXLabel db "X:   ", 0
mouseYLabel	db "Y:   ", 0 
exitButton db "Exit[ ]", 0
eraseButton db "Eraser[ ]", 0
foregroundButton db "Foreground[ ]", 0
backgroundButton db "Background[ ]", 0
eraseToggle dw 0
radioButtonToggle dw 1
hi     db 'hi',0     ; used by dcp for debugging
; DATA ENDS HERE



MAIN: ; Life starts here.
	MOV   AX,CSEG   ; Make DS point to OUR code segment.
    MOV   DS,AX     ; Code and data live in one segment.
	
    call clrscr     
    mov  ax, 00h    ; initialize mouse
	int  33h        ; call mouse driver
	cmp  ax, 00h    ; mouse avail?
	jne   MAINinstalled       

	mov  SI, offset error  ; problems capturing our rodent
	call putCstring10
	jmp  MAINquit


MAINinstalled:      ; OK the mouse is allocated to our window.
    mov  ax, 01h    ; Let's make the little rat visible.
	int  33h

	call CURSOROFF
	; Good place to get your menu and status bars on the screen
	
;Start of menu & all background
	mov [CrapColor], 11110000b
	push dx
	push bx
	push ax
	push cx
	sub dx, dx
	mov dh, 0
	mov dl, 0
	mov al, 79d
	mov cx, 80d
	mov bl, 00010001b
BackgroundLoop1:
	call LOCATE
	call WRITEATTR ;Making the colored background at the top
	inc dh
	cmp dh, 6
	JNE BackgroundLoop1
	mov dh, 24d
	mov dl, 0
BackgroundLoop2: ;Making the colored background on the bottom
	call LOCATE
	call WRITEATTR
	inc dh
	cmp dh, 28
	JNE BackgroundLoop2

	mov dh, 6d
	mov dl, 0
	call LOCATE
	mov al, 205d
	mov cx, 80d
	mov bl, 00011011b
	call WRITEATTR
	mov dh, 23d
	call LOCATE
	call WRITEATTR
	sub dx, dx
	mov dh, 24d
	mov dl, 1
	call LOCATE
	push SI
	mov SI, offset mouseXLabel
	push bx
	mov bl, 00011111b
	call putCstring10
	pop bx
	pop SI
	mov dh, 25d
	mov dl, 1
	call LOCATE
	push SI
	mov SI, offset mouseYLabel
	push bx
	mov bl, 00011111b
	call putCstring10
	pop bx
	pop SI
	
	mov dh, 3d
	mov dl, 3d
	call LOCATE
	mov ah, -1d
	mov al, 79d
	mov cx, 1
DisplayColorLoop:
	inc ah	;Displaying all the possible colors in the loop
	mov bl, ah
	shl bl, 4
	or bl, ah
	call WRITEATTR
	inc dl
	call LOCATE
	call WRITEATTR
	inc dl
	call LOCATE
	cmp ah, 1111b
	JNE DisplayColorLoop
DisplayExitButton:  ;displaying the exit button
	mov dh, 0 
	mov dl, 72d
	call LOCATE
	mov bl, 00011111b
	mov SI, offset exitButton
	call putCstring10
	
	mov [mouseFlag], 1
	
	pop cx
	pop ax
	pop bx
	pop dx
	
    ; Now we install our mouse event handler.
	; When the mouse does anything as described in CX below, 
	; the driver will automatically call our MouseEvent callback function
     
        ;YOU NEED TO CHANGE CX IN ORDER TO HANDLE CLICKS
        mov  CX, 00001011b  ; call mouse event if moved
			; Look at the mask in the documentation
            ; for AX in MouseEvent.
	    push CS
        pop  ES                     ; ES must point to our CSEG
        mov  DX, offset MouseEvent  ; DX points to MouseEvent  
        mov  AX, 0Ch                ; Install our interrupt handler
	    int  33h                    ; for mouse events.
        ; From this point on, the function MouseEvent will be called
		; based on the CX mask.


       ; We change the CrapChar through a busy-wait loop.
       ; This is called polling. We keep asking about a key pressed.
       ; Compare this to the fcn MouseEvent which is called by the mouse interrupt.

MAINagain:
    cmp [exit], 0
	jne  MAINexit    ; exit program
	cmp mouseFlag, 1
	JNE MAINCont
	mov mouseFlag, 0
	call UpdateDisplay
MAINCont:
	call kbhit       ; check to see if we have a key
	jz  MAINagain
	
	call getch       ; if so, remove the char from the buffer
	cmp  al, 27      ; if ESC, we want to exit as well
    jne   MAINsetCrapChar
	jmp MAINagainExit
MAINsetCrapChar:
	mov [CrapChar], al
	mov [mouseFlag], 1
	jmp MAINagain
MAINagainExit:
	mov   [exit], 1  ; if ESC set the flag to leave
	
	jmp  MAINagain


MAINexit:           ; shutting down
	mov  ax, 02h    ; hide mouse pointer
	int  33h
    mov  ax, 00h    ; disconnect our mouse handler
	int  33h        

MAINquit:
	MOV   AX,4C00h              ; Return control to DOS.
	INT   21h                   ; End of MAIN program.


; ****************************************************************
	;Used to update the display
; ****************************************************************
UpdateDisplay Proc NEAR
	push dx
	sub dx, dx
	mov dh, 24d
	mov dl, 1
	call LOCATE
	push SI
	mov SI, offset mouseXLabel
	push bx
	mov bl, 00011111b
	call putCstring10
	pop bx
	pop SI
	;Putting the X value in the correct spot
	sub dx, dx
	mov dh, 24d
	mov dl, 4d
	call LOCATE
	sub dx,dx
	mov dl, [mouseX]
	call putDec10
	;Putting the label in the correct spot and overriding
	;the current coordinates that are displayed
	mov dh, 25d
	mov dl, 1
	call LOCATE
	push SI
	mov SI, offset mouseYLabel
	push bx
	mov bl, 00011111b
	call putCstring10
	pop bx
	pop SI
	;Putting the Y value in the correct spot
	mov dh, 25d
	mov dl, 4d
	call LOCATE
	sub dx,dx
	mov dl, [mouseY]
	call putDec10
EraseToggleButton: ;Setting up the toggle buttons 
	mov dh, 0 
	mov dl, 0
	mov al, 254
	call LOCATE
	mov bl, 00011111b
	mov SI, offset eraseButton
	call putCstring10
	cmp [eraseToggle], 1 ;Check if the erase is on
	JNE EraseToggleButtonNot 
	mov dl, 7
	call LOCATE
	mov bl, 00011111b
	mov cx, 1
	call WRITEATTR
	jmp RadioButtonDisplay
EraseToggleButtonNot:
	mov dl, 7
	call LOCATE
	mov bl, 00010001b
	mov cx, 1
	call WRITEATTR
RadioButtonDisplay: ;Displaying the first radio button
	mov dh, 0
	mov dl, 11
	call LOCATE
	mov bl, 00011111b
	mov SI, offset backgroundButton
	call putCstring10
	cmp [radioButtonToggle], 1 ;Checking if this one is selected
	JNE RadioButtonDisplay1
	mov dl, 22
	call LOCATE
	mov al, 254
	mov cx, 1
	call WRITEATTR
	jmp RadioButtonDisplay2
RadioButtonDisplay1:
	mov dl, 22
	call LOCATE
	mov al, 254
	mov bl, 00010001b
	mov cx, 1
	call WRITEATTR
RadioButtonDisplay2: ;Displaying the second radio button
	mov dl, 26
	call LOCATE
	mov bl, 00011111b
	mov SI, offset foregroundButton
	call putCstring10
	cmp [radioButtonToggle], 1 ;Checking if this one is selected
	JE RadioButtonDisplay3
	mov dl, 37
	call LOCATE
	mov al, 254
	mov cx, 1
	call WRITEATTR
	jmp UpdateChar
RadioButtonDisplay3:
	mov dl, 37
	call LOCATE
	mov al, 254
	mov bl, 00010001b
	mov cx, 1
	call WRITEATTR
UpdateChar: ;Update the current selected char with the value of crapchar and crapcolor
	mov dh, 3d
	mov dl, 38d
	call LOCATE
	push ax
	push cx
	mov al, [CrapChar]
	mov cx, 1
	mov bl, [CrapColor]
	call WRITEATTR
	pop cx
	pop ax
	pop dx
	ret
UpdateDisplay endP
; ****************************************************************
; ****************************************************************
LeftClick Proc NEAR
	cmp [mouseY], 6
	JG HandlePlacement
	cmp [mouseY], 0
	JE HandleButtons
	jmp HandleColorButton
HandleButtons:
	cmp [mouseX], 77
	JNE HandleButtons1
	mov [exit], 1
	jmp LeftClickret
HandleButtons1:
	cmp [mouseX], 7
	JNE HandleButtons2
	XOR [eraseToggle], 1
	mov [mouseFlag], 1
	jmp LeftClickret
HandleButtons2:
	cmp [mouseX], 22
	JNE HandleButtons3
	mov [radioButtonToggle], 1
	mov [mouseFlag], 1
	jmp LeftClickret
HandleButtons3:
	cmp [mouseX], 37
	JNE LeftClickreturn
	mov [radioButtonToggle], 0
	mov [mouseFlag], 1
	jmp LeftClickret
HandlePlacement:
	cmp [mouseY], 23
	JL HandlePlacement1
	jmp LeftClickret
HandlePlacement1:
	mov dh, [mouseY]
	mov dl, [mouseX]
	call LOCATE
	cmp [eraseToggle], 1
	JNE HandleNormalPlacement
	sub ax, ax
	sub bx, bx
	mov al, [CrapChar]
	mov cx, 1
	mov bl, 00000000b
	call WRITEATTR
	;jmp LeftClickret
LeftClickreturn:
	jmp LeftClickret
HandleNormalPlacement:
	sub ax, ax
	sub bx, bx
	mov al, [CrapChar]
	mov cx, 1
	mov bl, [CrapColor]
	call WRITEATTR
	jmp LeftClickret
HandleColorButton:
	cmp [mouseY], 3
	JE HandleColorButton1
	jmp LeftClickret
HandleColorButton1:
	cmp [mouseX], 3
	JL LeftClickret
	cmp [mouseX], 34
	JG LeftClickret
	mov dh, [mouseY]
	mov dl, [mouseX]
	call LOCATE
	call READATTR
	cmp [radioButtonToggle], 1
	JNE HandleColorButton2
	shl ah, 4
	and [CrapColor], 00001111b
	jmp HandleColorButton3
HandleColorButton2:
	shr ah, 4
	and [CrapColor], 11110000b
HandleColorButton3:
	or [CrapColor], ah
	mov mouseFlag, 1
LeftClickret:
	ret
LeftClick endP
; ****************************************************************
; ****************************************************************

; ****************************************************************
; ****************************************************************
MouseEvent  Proc  FAR        
Comment  !   
This function is called by the mouse Interrupt Service Routine (driver).
Make sure that you don't take up too much CPU time in here.

Input parameters:

Note that the actual mouse driver preserves the following registers for us,
so they will not be changed back in the main program.

	AX = events that occurred, depending on mask:   
	   bit 0 = mouse pointer moved
	   bit 1 = left button pressed
	   bit 2 = left button released
	   bit 3 = right button pressed
	   bit 4 = right button released
	   bit 5 = center button pressed
	   bit 6 = center button released

                                      
	BX = Current button state:
	   bit 0 = Left button (0 = up, 1 = pressed down)
	   bit 1 = Right button (0 = up, 1 = pressed down)
	   bit 2 = Center button (0 = up, 1 = pressed down)

	CX = Horizontal  coordinate of mouse
	DX = Vertical  coordinate

        These are used to check how far mouse moved since we were last
        in MouseEvent.
	SI = Last vertical mickey count
	DI = Last horizontal mickey count

	DS = Data seg of the mouse driver. I will reset it to your data seg.

	USE only BIOS interrupts.  NO NOT use any DOS interrupts like getChar and putChar.
  !

	push ds
	push ax
	push dx
	push cx

       ; data for this driver will be in our code segment.
	push cs
    pop  ds   ; ds now points to our code segment       
	cmp ax, 1b
	jne MELeftClick
       ; test for events in the order you want priority 
       ; this is basically like a switch-case statement
	shr  cx, 3       ; 8 pixels per char position 
	shr  dx, 3
    mov  [mouseX], cl ; save the new position
	mov  [mouseY], dl
	mov mouseFlag, 1
	cmp BX, 1b
	JNE MEret
	call LeftClick
	jmp MEret
MELeftClick:
	cmp ax, 10b
	jne MERightClick
	call LeftClick
	jmp MEret
MERightClick:
	cmp ax, 1000b ;Comparing to right click
	jne MEret
	ROL [CrapColor], 4 ;Rolling to switch the colors
	mov mouseFlag, 1 ;Setting mouseflag to 1 to update screen
	jmp MEret
MEret:
	pop cx
	pop dx
	pop ax
	pop ds
	ret          ; back to the mouse driver (ISR)
MouseEvent endP
;*****************************************************************
;**************************************************************
CSEG    ENDS            ; End of code segment.

END     MAIN            ; End of program. Start execution at MAIN