; Firm Ware Julian Santos for GY-521 Module
            INCLUDE 'derivative.inc'
LED EQU 2   
SDA EQU 1
SCL EQU 0        

            XDEF _Startup
            ABSENTRY _Startup

            ORG    Z_RAMStart         ; Insert your data definition here
var_delay: DS.B   1
VAL:	   DS.B 1

            ORG    ROMStart
            

_Startup:
			CLRA 
           	STA SOPT1 ; disenable watchdog
            LDHX   #RAMEnd+1        ; initialize the stack pointer
            TXS	

mainLoop:
			JSR initial_config ; Subroutine for initial configuration of parallel input ports
			JSR initial_states ; Subroutine for set initial states
			JSR init_I2C ; Subroutine for initilaze I2C module     
			CLI  
			MOV #15D,var_delay
  			JSR delayAx5ms
			LDA VAL
  			STA IICD
			JMP *  
            BRA    mainLoop

initial_config:
	BSET LED,PTCDD ; Data direction Output
	BCLR SDA,PTCDD
	BCLR SCL,PTCDD
	RTS
initial_states:
	BSET LED,PTCD	; LED ON
	CLRA 
	LDA #$CE
	INCA 
	STA VAL
	RTS
	
init_I2C:
		  MOV #$47,IICF  ; setting the desired baud rate I2C
		  MOV #%00010000,IICC1 ; Not enable IIC, No IIC interrupt enable, Master mode off, transmit mode ON, no sent and ack,rs 0,    
		  BSET IICC1_IICEN,IICC1  ; Enabling IIC module IIC
		  BSET IICC1_IICIE,IICC1 ; IICIE =1 	
		  BSET IICC1_TX,IICC1 ; Enabling transmit
		  BSET IICC1_MST,IICC1 ; Enabling master mode, and send a start signal		
		  RTS
  
    
    
Viic_ISR:
		  BSET IICS_IICIF,IICS ; Clearing flag
		  
		  BRSET IICS_RXAK,IICS,next
		  BCLR LED,PTCD
		  JMP *
next:  
		  BCLR LED,PTCD
		  MOV #40D,var_delay
		  JSR delayAx5ms
		  BSET LED,PTCD
		  MOV #40D,var_delay
		  JSR delayAx5ms
		  BSET IICC1_RSTA,IICC1
		  LDA VAL
		  INCA
		  STA VAL
		  STA IICD
		  RTI

  	
;******************************************Subroutine for create delays  	
delayAx5ms: ; 6 cycles the call of subroutine
			PSHH ; save context H
			PSHX ; save context X
			PSHA ; save context A
			LDA var_delay ;  cycles
delay_2:    LDHX #1387H ; 3 cycles 
delay_1:    AIX #-1 ; 2 cycles
	    	CPHX #0 ; 3 cycles  
			BNE delay_1 ; 3 cycles
			DECA ;1 cycle
			CMP #0 ; 2 cycles
			BNE delay_2  ;3 cycles
			PULA ; restore context A
			PULX ; restore context X
			PULH ; restore context H
			RTS ; 5 cycles	
			  	
;************************************************************************************VECTORS OF INTERRUPT

            ORG Vreset				; Reset
			DC.W  _Startup	
			ORG Viic
			DC.W Viic_ISR
