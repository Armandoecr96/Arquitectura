; SSRTestMain.s
; Runs on TM4C1294
;------------------------------------------------------------------------------
GPIO_PORTJ0                   EQU 0x400580FC

;------------------------------------------------------------------------------
SYSCTL_STCURRENT			  EQU 0XE000E018
SYSCTL_STRELOAD				  EQU 0XE000E014
SYSCTL_STCTRL				  EQU 0XE000E010
SYSCTL_RSCLKCFG				  EQU 0x400FE0B0
;-------------------------------------------------------------------------------
			AREA    DATA, READWRITE, ALIGN=2
CONTA    	SPACE   4
CONTA1      SPACE   2


        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT Start
        IMPORT UP_LCD
		IMPORT LCD_DELAY
		IMPORT LCD_E
        IMPORT SSR_Toggle
		EXPORT TABLA 
		EXPORT CONTA1
			
TABLA DCB 0X40, 0XF9, 0XA4, 0XB0, 0X99, 0X92, 0X82, 0XF8, 0X80, 0X98

Start
		
;-----------------------------------------------------------------------
	LDR R0, =SYSCTL_RSCLKCFG	;0x400FE0B0
	LDR R1, [R0]
	ORR R1, #0X00000000
	STR R1, [R0]
;---------------------------------------------------------------------
    LDR R0, =SYSCTL_STCTRL
	LDR R1, [R0]
	AND R1, #0X00000000
	STR R1, [R0]
;---------------------------CUENTA------------------------------------
	LDR R0, =SYSCTL_STRELOAD
	LDR R1, =0x0003D08FF
	STR R1, [R0]
;---------------------------------------------------------------------
	LDR R0, =SYSCTL_STCURRENT
	MOV R1, #0
	STR R1, [R0]
;---------------------------------------------------------------------
    LDR R0, =SYSCTL_STCTRL
	LDR R1, [R0]
	ORR R1, #0X00000001
	STR R1, [R0]
;---------------------------------------------------------------

 BL  UP_LCD                    ; inicializa el puerto D
;------------------------------------------------------------
L2
    LDR R2, =0X00
	LDR R1, =CONTA1	
	STR R2, [R1]
L1	
;****************apaga pines puerto A*************
	LDR R0, =GPIO_PORTJ0
	mov R1, #0x00
	STR R1, [R0]
;***********Lee contador***************************

	LDR R1, =CONTA1
	LDR R2, [R1]
;*********separa unidades y decenas****************
	MOV R1, #0x0A
	UDIV R4, R2, R1		;Decenas en R4
	MUL  R7, R4, R1
	SUB  R7,R2, R7		;Unidads en R7
;***********muestra Decenas*************************
	LDR R5, =TABLA
	LDRB R6, [R5, R4]
	LDR R0, =GPIO_PORTJ0
	BL SSR_Toggle
;***************activa decenas**********************
	mov R1, #0x01
	STR R1, [R0]
;****************apaga display**********************	
	LDR R0, =GPIO_PORTJ0
	mov R1, #0x00
	STR R1, [R0]
;*************Muestra unidads*******************	
	LDR R5, =TABLA
	LDRB R6, [R5, R7]
	BL SSR_Toggle
	LDR R0, =GPIO_PORTJ0
;*********Prende unidades*************************
	mov R1, #0x02
	STR R1, [R0]
;**************Lee el registro de estado*********
	LDR R0, =SYSCTL_STCTRL
	LDR R1, [R0]
	MOV R2, #0x00010000		
	AND R1, R2			;verifica si ya se desbordo
	CBNZ R1, salta		;Salta si se desbordo
	B L1				;Salta si no se desbordo
;**********Incrementa contador********************
salta
	LDR R3,=CONTA1
	LDR R4, [R3]
	ADD R4,R4,#0x01
	STR R4,[R3]
	CMP R4, #0X64
	BEQ L2
	B   L1
    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
