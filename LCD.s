; SSR.s
; Runs on TM4C1294
; Provide functions that initialize a GPIO pin and turn it on and off.
; Use bit-banded I/O.
; Daniel Valvano
; April 30, 2014

;  This example accompanies the book
;  "Embedded Systems: Introduction to ARM Cortex M Microcontrollers"
;  ISBN: 978-1469998749, Jonathan Valvano, copyright (c) 2014
;  Volume 1 Program 4.3, Figure 4.14

;Copyright 2014 by Jonathan W. Valvano, valvano@mail.utexas.edu
;   You may use, edit, run or distribute this file
;   as long as the above copyright notice remains
;THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
;OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
;MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
;VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
;OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
;For more information about my classes, my research, and my books, see
;http://users.ece.utexas.edu/~valvano/

; solid state relay connected to PN1

GPIO_PORTD1                   EQU 0x4005B3FC	;GPIO Port D (AHB) 0x4005B000 base de datos
GPIO_PORTD_DIR_R              EQU 0x4005B400	;Offset 0x400=>  0 es entrada, 1 salida
GPIO_PORTD_AFSEL_R            EQU 0x4005B420	;Offset 0x420=>  0 funcion como GPIO, 1 funciona como periferico
GPIO_PORTD_DEN_R              EQU 0x4005B51C	;Offset 0x51C=>  0 funcina como NO digital, 1 funcion digital
GPIO_PORTD_AMSEL_R            EQU 0x4005B528	;Offset 0x528=>  0 Deshabilita funcion analogica, 1 activa analogica
GPIO_PORTD_PCTL_R             EQU 0x4005B52C	;Offset 0x52C=>  0 Selecciona funcion alternativa

SYSCTL_RCGCGPIO_R             EQU 0x400FE608	;Base 0x400F.E000, Offset 0x608=> 1 activa puerto, 0 desactiva puerto
SYSCTL_RCGCGPIO_R12           EQU 0x00000008  	; 1 Enable and provide a clock to GPIO Port D in Run mode
SYSCTL_PRGPIO_R               EQU 0x400FEA08	;Base 0x400F.E000, Offset 0xA08 indica puerto listo
SYSCTL_PRGPIO_R12             EQU 0x00000008  ; Bandera puerto listo D
	
;*******************Direcciones del puerto A**********************************************
GPIO_PORTJ0                   EQU 0x400580FC
GPIO_PORTJ_DIR_R              EQU 0x40058400
GPIO_PORTJ_AFSEL_R            EQU 0x40058420
GPIO_PORTJ_PUR_R              EQU 0x40058510
GPIO_PORTJ_DEN_R              EQU 0x4005851C
GPIO_PORTJ_AMSEL_R            EQU 0x40058528
GPIO_PORTJ_PCTL_R             EQU 0x4005852C

SYSCTL_RCGCGPIO_R8            EQU 0x00000001  ; GPIO activa puerto A
SYSCTL_PRGPIO_R8              EQU 0x00000001  ; GPIO Port J Peripheral ReadyVALOR_INICIAL	


        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        
        EXPORT SSR_Toggle
		IMPORT Start
		
;-------------------------------------------------------------------------------------------
;Rutinas para el manejo del LCD
;---------------------------------------------------------------------------------------------
;UP_LCD: Configuracion el puerto D como salida, bus de datos del LCD.
		EXPORT UP_LCD
			
;------------configura puerta D como Salida------------------------
UP_LCD
    ; activa reloj para el puerto D
    LDR R1, =SYSCTL_RCGCGPIO_R      ; R1 = SYSCTL_RCGCGPIO_R direccion que  1 activa puerto
    LDR R0, [R1]                    ; R0 = [R1] lee valor
    ORR R0, R0, #SYSCTL_RCGCGPIO_R12; R0 = R0|SYSCTL_RCGCGPIO_R12, activa reloj de puerto
    STR R0, [R1]                    ; [R1] = R0  se guarda
	
    ;Verifica si el reloj es estable
    LDR R1, =SYSCTL_PRGPIO_R        ; R1 = SYSCTL_PRGPIO_R (pointer)
GPIONinitloop
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ANDS R0, R0, #SYSCTL_PRGPIO_R12 ; R0 = R0&SYSCTL_PRGPIO_R12
    BEQ GPIONinitloop               ; if(R0 == 0), keep polling
	
    ; Direccion de salida
    LDR R1, =GPIO_PORTD_DIR_R       ; R1 = GPIO_PORTD_DIR_R 
    LDR R0, [R1]                    ; R0 = [R1] 
    ORR R0, R0, #0xFF               ; R0 = R0|0xFF (todos los pines del puerto D salida)
    STR R0, [R1]                    ; [R1] = R0
	
	
    ; Registro de funcion alternativa
    LDR R1, =GPIO_PORTD_AFSEL_R     ; R1 = GPIO_PORTD_AFSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0xFF               ; R0 = R0&~0x02 (disable alt funct on PN1)
    STR R0, [R1]                    ; [R1] = R0
	
    ; set digital enable register
    LDR R1, =GPIO_PORTD_DEN_R       ; R1 = GPIO_PORTD_DEN_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0xFF               ; R0 = R0|0xFF (activa digital I/O  PD0-PD7)
    STR R0, [R1]                    ; [R1] = R0
	
    ; set port control register
    LDR R1, =GPIO_PORTD_PCTL_R      ; R1 = GPIO_PORTD_PCTL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0xFFFFFFFF         ; R0 = R0&0xFFFFFFFF (clear bit1 field)
    ADD R0, R0, #0x00000000         ; R0 = R0+0x00000000 (configure PN1 as GPIO)
    STR R0, [R1]                    ; [R1] = R0
	
	
    ; set analog mode select register
    LDR R1, =GPIO_PORTD_AMSEL_R     ; R1 = GPIO_PORTD_AMSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0xFF               ; R0 = R0&~0xFF (disable analog functionality on PD0-PD7)
    STR R0, [R1]                    ; [R1] = R0
    
	
;------------Configura puerto A como salida--------------------------
   
    ; activate clock for Port J
    LDR R1, =SYSCTL_RCGCGPIO_R      ; R1 = SYSCTL_RCGCGPIO_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #SYSCTL_RCGCGPIO_R8 ; R0 = R0|SYSCTL_RCGCGPIO_R8
    STR R0, [R1]                    ; [R1] = R0
	
    ; allow time for clock to stabilize
    LDR R1, =SYSCTL_PRGPIO_R        ; R1 = SYSCTL_PRGPIO_R (pointer)
	
GPIOJinitloop
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ANDS R0, R0, #SYSCTL_PRGPIO_R8  ; R0 = R0&SYSCTL_PRGPIO_R8
    BEQ GPIOJinitloop               ; if(R0 == 0), keep polling
	
    ; set direction register
    LDR R1, =GPIO_PORTJ_DIR_R       ; R1 = GPIO_PORTJ_DIR_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0xFF               ; R0 = R0&~0x01 (make PJ0 in (PJ0 built-in SW1))
    STR R0, [R1]                    ; [R1] = R0
	
    ; set alternate function register
    LDR R1, =GPIO_PORTJ_AFSEL_R     ; R1 = GPIO_PORTJ_AFSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0xFF               ; R0 = R0&~0x01 (disable alt funct on PJ0)
    STR R0, [R1]                    ; [R1] = R0
			
    ; set digital enable register
    LDR R1, =GPIO_PORTJ_DEN_R       ; R1 = GPIO_PORTJ_DEN_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0xFF               ; R0 = R0|0x01 (enable digital I/O on PJ0)
    STR R0, [R1]                    ; [R1] = R0

    ; set port control register
    LDR R1, =GPIO_PORTJ_PCTL_R      ; R1 = GPIO_PORTJ_PCTL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0xFFFFFFFF         ; R0 = R0&0xFFFFFFF0 (clear bit0 field)
    ADD R0, R0, #0x00000000         ; R0 = R0+0x00000000 (configure PJ0 as GPIO)
    STR R0, [R1]                    ; [R1] = R0
	
    ; set analog mode select register
    LDR R1, =GPIO_PORTJ_AMSEL_R     ; R1 = GPIO_PORTJ_AMSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0xFF               ; R0 = R0&~0x01 (disable analog functionality on PJ0)
    STR R0, [R1]                    ; [R1] = R0
	
;-----------------------Activa RS=1  (modo dato)---------
	LDR R0, =GPIO_PORTJ0
	MOV R1, #0x01
	STR R1, [R0]       ;RS=A0=1, RD/WR =A1=0, E=A2=0
	BX  LR

;******************************RETARDO DE 15 ms*************************************
;RUTINA LCD_DELAY: Se trata de un rutina que implementa un retardo 
;o temporizaci¢n de 5 ms. Utiliza dos variables llamadas LCD_TEMP_1 
;y LCD_TEMP_2, que se van decrementando hasta alcanzar dicho tiempo.
;***********************************************************************************
		EXPORT LCD_DELAY
LCD_DELAY
	nop
	BX  LR

;-----------------------PORTA0=> RS=1, PORTA1=> RD/WR,  PORTA2 =>E-----------------
		EXPORT LCD_E
LCD_E
	LDR R0, =GPIO_PORTJ0
	MOV R1, #0x04
	STR R1, [R0]
	NOP
	NOP
	MOV R1, #0x00
	STR R1, [R0]
	NOP
	BX  LR
;------------SSR_Toggle------------
; Toggle PN1.
; Input: none
; Output: none
; Modifies: R0, R1
SSR_Toggle
    LDR R1, =GPIO_PORTD1            ; R1 = GPIO_PORTD1 (pointer)
    STR R6, [R1]                    ; R0 = [R1] (previous value)
    BX  LR

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
