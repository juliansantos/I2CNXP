; Firm Ware Julian Santos for GY-521 Module
           INCLUDE 'MC9S08JM16.inc'
         
LED EQU 2   
SDA EQU 1
SCL EQU 0        
dirGY521 EQU 0D0H ; to write
rGY521 EQU 0D1H ; to read
    ; Name Pull-down AD0 
dirPower EQU 06BH ; Register for manage the power of sensor '=0 to turn on'
acelx EQU 3BH ;
flag_down EQU 0
  ;*******************************Pin definition section
pin_ENABLE EQU 5 ; pin ENABLE
pin_RS EQU 4 ; pin RS
pin_LED EQU 0
pin_buzzer EQU 1
  
  ;*******************************LCD  label definition Q
cmd_clear  EQU 01H ; Command to clear the display
cmd_8bitmode EQU 38H ; Command to set parallel mode at 8 bits
cmd_line1 EQU 80H ; Command to set the cursor in the line 1
cmd_line3 EQU 88H 
cmd_line2 EQU 90H ; Command to set the cursor in the line 2
cmd_line4 EQU 98H 
cmd_displayON EQU 0CH ; Command to turn on the display
cmd_displayOFF EQU 80H
cmd_home EQU 2H

    
            XDEF _Startup
            ABSENTRY _Startup

            ORG     0B0H        ; Insert your data definition here
var_delay: DS.B   1
VAL:	   DS.B 1
var_x_accel:  DS.B 2
ascci_accel   DS.B 5
repeticiones DS.B 1
flags DS.B 1
segundos DS.B 1
minutos DS.B 1
horas DS.B 1
dias DS.B 1

           ORG    0C000H
            
_Startup:
			CLRA 
           	STA SOPT1 ; disenable watchdog
            LDHX   #RAMEnd+1        ; initialize the stack pointer
            TXS	

mainLoop:
				JSR initial_config ; Subroutine for initial configuration of parallel input ports
				JSR initial_states ; Subroutine for set initial states
				JSR init_LCD
				
				LDA #cmd_line1 ; Line 1 
				ADD #3
				JSR send_command
				
				LDHX #initial_message 
				JSR write_message ; Display the initial message
				
				LDA #cmd_line3 ; Line 3 
				ADD #3
				JSR send_command
				
				LDHX #alarm
				JSR write_message ; Display the initial message
				
				JSR init_RTC
				CLI ; enabling interrupts
				JMP *
				
lectura:     	JSR init_I2C ; Subroutine for initilaze I2C module 
        		JSR read_acel_x  
				;JSR show_acel_x  
				JSR show_rept			
    			BSET LED,PTCD
		;		JMP *
	            BRA  lectura
;**********************************************************Subroutine for initial configuration
initial_config:
				BSET LED,PTCDD ; Data direction Output
				BCLR SDA,PTCDD
				BCLR SCL,PTCDD
				BSET pin_ENABLE,PTFDD ; Setting data direction (pin ENABLE)
				BSET pin_RS,PTFDD ; Setting data direction (pin RS)
				MOV #$FF,PTEDD ; Setting data direction pins of data to LCD
				RTS
;**********************************************************Subroutine for set the initial states			
initial_states:
				;BSET LED,PTCD	; LED ON
				CLRA 
				STA var_x_accel
				STA var_x_accel+1
				STA ascci_accel+4
				STA ascci_accel+3
				STA ascci_accel+2
				STA ascci_accel+1
				STA ascci_accel+0
				STA flags
				STA segundos
				STA minutos
				STA horas 
				STA dias
				LDA #30D
				STA repeticiones
				RTS
;**********************************************************Init RTC
init_RTC:
				MOV #0H,RTCMOD
				MOV #1FH,RTCSC
				RTS				
;**********************************************************Subroutine for initialize LCD	
init_I2C:
			  MOV #014H,IICF  ; setting the desired baud rate I2C  
			  BCLR IICC1_IICEN,IICC1
			  BSET IICC1_IICEN,IICC1  ; Enabling IIC module IIC
			  BSET IICS_IICIF,IICS  ;Clear any pending interrupt
			  BCLR IICC1_MST,IICC1 ; Master mode disenable
			  BCLR IICS_SRW,IICS;
			  BSET IICC1_TX,IICC1 ; /* Select Transmit Mode */
			  BSET IICC1_MST,IICC1 ;  Master mode enable 
			    
			  MOV #1,var_delay ; Short delay
			  JSR delayAx5ms
			  
			  BSET IICC1_TX,IICC1 ; Enabling transmit	
			  BSET IICC1_MST,IICC1 ; Enabling master mode, and send a start signal
			  BRCLR IICS_BUSY,IICS,*  ; If Bus is busy continue 
			  
	  		  LDA #0D0H ; Direction of the accelerometer and bit to write it. 
	  		  
	  		  STA IICD ; Send data
	  		  BRCLR IICS_IICIF,IICS,* ; Has finished the transfer?
			  BRSET IICS_RXAK,IICS,* ; was recived an acknowledge?
			  BSET IICS_IICIF,IICS ; Clearing the flag
			  				
			  LDA #6BH ;Sending the direction of power control register
			  STA IICD ; Send data
	  		  BRCLR IICS_IICIF,IICS,* ; Has finished the transfer?
			  BRSET IICS_RXAK,IICS,* ; was recived an acknowledge?
			  BSET IICS_IICIF,IICS ; Clearing the flag
			  	
    	      LDA #00H ; writing 0 in a power control register to wake up the sensor
    		 
	  		  STA IICD ; Send data
	  		  BRCLR IICS_IICIF,IICS,* ;Has finished the transfer?
			  BRSET IICS_RXAK,IICS,* ; was recived an acknowledge?
			  BSET IICS_IICIF,IICS ; Clearing the flag
			      		 	 			
    		  BCLR IICC1_MST,IICC1  ; Stop Signal
    		  BRSET IICS_BUSY,IICS,*  ; Busy Bus 
    		  
    		  ;///////////////////////////////////SET THE CURSOR IN A PROPERLY POSITION
    		  
    		  BSET IICC1_MST,IICC1 ; Enabling master mode, and send a start signal
    		  MOV #1,var_delay ; Short delay
			  JSR delayAx5ms
			  BRCLR IICS_BUSY,IICS,*  ; If Bus is busy continue 
    		  
    		  LDA #0D0H ; Direction of the accelerometer and bit to write it. 
	  		  
	  		  STA IICD ; Send data
	  		  BRCLR IICS_IICIF,IICS,* ; Has finished the transfer?
			  BRSET IICS_RXAK,IICS,* ; was recived an acknowledge?
			  BSET IICS_IICIF,IICS ; Clearing the flag
			  				
			  LDA #3BH ;Sending the direction of power control register
			  STA IICD ; Send data
	  		  BRCLR IICS_IICIF,IICS,* ; Has finished the transfer?
			  BRSET IICS_RXAK,IICS,* ; was recived an acknowledge?
			  BSET IICS_IICIF,IICS ; Clearing the flag
			  
			  BCLR IICC1_MST,IICC1  ; Stop Signal
    		  BRSET IICS_BUSY,IICS,*  ; Busy Bus 
    		  
			  
			  ;/////////////////////////////////////////Setting for reading
			  
			  BSET IICC1_MST,IICC1 ; Enabling master mode, and send a start signal
    		  MOV #1,var_delay ; Short delay
			  JSR delayAx5ms
			  BRCLR IICS_BUSY,IICS,*  ; If Bus is busy continue 
			  			  
			  LDA #0D1H ; Direction of the accelerometer and bit to write it.  
	  		  STA IICD ; Send data
	  		  BRCLR IICS_IICIF,IICS,* ; Has finished the transfer?
			  BRSET IICS_RXAK,IICS,* ; was recived an acknowledge?
			  BSET IICS_IICIF,IICS ; Clearing the flag
			  
		  *TICK(
				;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;READING THE FIRST BYTE
    		  BCLR IICC1_TX,IICC1 ; Enabling reciving mode 
    		  LDA IICD ; Dummy read
    		  BCLR IICC_TXAK,IICC ; Transmit and acknowledge (YES) 
			  BRCLR IICS_IICIF,IICS,* ; Has finished the transfer?
			  BSET IICS_IICIF,IICS ; Clearing the flag
			  LDA IICD ; Reading real value
			  STA var_x_accel+0
			  
			    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;READING THE SECOND BYTE
			  BSET IICC_TXAK,IICC ; Transmit and acknowledge (NO)
			  BRCLR IICS_IICIF,IICS,* ; Has finished the transfer?
			  BSET IICS_IICIF,IICS
			  LDA IICD
			  STA var_x_accel+1 
			  
			  BCLR IICC1_MST,IICC1  ; Stop Signal
    		  ;BRSET IICS_BUSY,IICS,*  ; Busy Bus 
    		  
    		  ;BSET LED,PTCD
			  ;JMP *	
	
			  
			  RTS ; Return from subroutine
;*********************************************************Subroutine for show repetitions			  
show_rept:
			  LDA var_x_accel
			  NSA
			  AND #0FH
			  CBEQA #0FH,down
			  CBEQA #03H,up
			  BRA fin_rep
down:		
			  BSET flag_down,flags
			  BRA fin_rep	  
up:			  BRCLR flag_down,flags,fin_rep
			  BCLR flag_down,flags
			  LDA repeticiones
			  DECA
			  STA repeticiones
			  CBEQA #0H,*
			  MOV #100D,var_delay
			  JSR delayAx5ms
			  	  
fin_rep:      LDA #cmd_line3
			  ADD #3
		      JSR send_command
			  LDA repeticiones
			  LDHX #0000H
			  LDX #10D
			  DIV
			  ORA #30H
			  JSR send_data
			  PSHH
			  PULA
			  ORA #30H
			  JSR send_data
			  RTS			  
;*********************************************************Subroutine for send data to IIC bus  
;send_I2C:
;				STA IICD
;				BRCLR IICS_IICIF,IICS,*
;				BRSET IICS_RXAK,IICS,* ; ack?
;				BSET IICS_IICIF,IICS ; Clearing flag
;			 	RTS    
		 	
;************************************************Subroutine for reading aceleration
read_acel_x:
				
    			RTS
;********************************************************SUBROUTINE TO SHOW THE DATA   			
show_acel_x:	
				LDA #cmd_line3
				ADD #3
				JSR send_command	
				JSR conversion
				JSR conversion1
				RTS
				
conversion:
				LDA var_x_accel; High nibble
				NSA 
				AND #0FH
				CMP #9
				BHI ascii_letter
				ORA #30H ; to ascii 
				JSR send_data
				BRA low_nibble
ascii_letter:
				SUB #9
				ORA #60H
				JSR send_data
low_nibble:
				LDA var_x_accel ; Low nibble
				AND #0FH
				CMP #9
				BHI ascii_letter1
				ORA #30H ; to ascii 
				JSR send_data
				RTS
ascii_letter1:
				SUB #9
				ORA #60H
				JSR send_data
				RTS
conversion1:
				LDA var_x_accel+1; High nibble
				NSA 
				AND #0FH
				CMP #9
				BHI ascii_letter0
				ORA #30H
				JSR send_data
				BRA low_nibble1
ascii_letter0:
				SUB #9
				ORA #60H
				JSR send_data
low_nibble1:
				LDA var_x_accel+1 ; Low nibble
				AND #0FH
				CMP #9
				BHI ascii_letter11
				ORA #30H ; to ascii 
				JSR send_data
				RTS
ascii_letter11:
				SUB #9
				ORA #60H
				JSR send_data				
				RTS
				
;******************************************Subroutine for initilize the LCD
init_LCD:
		 	MOV #8,var_delay
			JSR delayAx5ms ; delay for 20ms (level voltage desired to LCD)
			LDHX #config_LCD ;	Load initial direction LCD		
bucle_initLCD:	LDA ,X ; Deferencing pointer
			CBEQA #0H,fin_initLCD			
			JSR send_command             
			AIX #1 ; Incrementing pointer
			BRA bucle_initLCD ; Repet until end
fin_initLCD:	RTS

;********************************************************************Subroutines neccesaries to send data to LCD
enable_pulse: BSET pin_ENABLE,PTFD 
 			MOV #4,var_delay
			JSR delayAx5ms
            BCLR pin_ENABLE,PTFD
			RTS
	
send_command: STA PTED ; Send command to LCD terminals
			BCLR pin_RS,PTFD ; command mode
			JSR enable_pulse
			MOV #4,var_delay
			JSR delayAx5ms
			RTS
	
send_data: 	STA PTED ; Send data to LCD terminal
			BSET pin_RS,PTFD ; data mode
			JSR enable_pulse
			MOV #4,var_delay
			JSR delayAx5ms
			RTS
			
write_message: LDA ,X ; Deferencing pointer
			CBEQA #0H,fin_messageLCD			
			JSR send_data            
			AIX #1 ; Incrementing pointer
			BRA write_message ; Repet until end
fin_messageLCD:	RTS	


					
				;LDA #$0  
			;	STA var_x_acceleration
				;STA var_x_acceleration+1
				
   			
    						     	
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
			  	
;**********************************************Interrupt Service routine RTC
Vrtc_ISR:
		   BSET RTCSC_RTIF,RTCSC ;  BLINK LED
		   BSET LED,PTCD
		   
		   LDA segundos
		   INC segundos
		   LDA #60D
		   CBEQ segundos,inc_minutes
		   BRA show_time			  	
inc_minutes:
		   CLR segundos
		   INC minutos
		   LDA #60D
		   CBEQ minutos,inc_hour
		   BRA show_time
inc_hour:
		   CLR minutos
		   INC horas		   
		   LDA #13D
		   CBEQ minutos,inc_dias
		   BRA show_time		
inc_dias:
		   CLR horas 
		   INC dias

show_time:    LDA #cmd_line2
			  ADD #2
		      JSR send_command
			  LDA horas
			  JSR separate_time
			  LDA #':'
			  JSR send_data
			  LDA minutos
			  JSR separate_time
			  LDA #':'
			  JSR send_data
			  LDA segundos
			  JSR separate_time
			  ;MOV #30D,var_delay
		      ;JSR delayAx5ms
		      BCLR LED,PTCD
			  RTI
			  
separate_time:			  
			  LDHX #0000H
			  LDX #10D
			  DIV
			  ORA #30H
			  JSR send_data
			  PSHH
			  PULA
			  ORA #30H
			  JSR send_data 		   		      
		   	  RTS
		   	  		   
;************************************************************************************VECTORS OF INTERRUPT
config_LCD:	DC.B cmd_8bitmode,cmd_displayON,cmd_clear,cmd_line2,0  ; 90 second line
initial_message: DC.B 'CLOCK',0
alarm: DC.B 'ALARM: ',0
i2c_config: DC.B 0D0H,6BH,0H

            ORG Vreset				; Reset
			DC.W  _Startup	
			;ORG Viic
			;DC.W Viic_ISR
			ORG Vrtc
			DC.W Vrtc_ISR



