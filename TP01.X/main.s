; Estudante - J�lio C�sar S. Carvalhaes
; Matr�cula - 19/0090332

#include <xc.inc>

global v1
PSECT udata_shr
   v1:
	DS 1
	
global v2
PSECT udata_shr
    v2:
	DS 1
psect resetVec,class=CODE,delta=2   ; Vetor de Reset definido em xc.inc para os PIC10/12/16
resetVec:
    PAGESEL start		    ; Seleciona p�gina de c�digo de programa onde est� start
    goto start 

psect code,class=CODE,delta=2	    ; Define uma sec��o o de c�digo de programa 
start:
    BANKSEL PORTA		    ; Selecionei o reg "PORTA" do Banco 0
    clrf    PORTA		    ; Por boas pr�ticas -> zerar os regs PORTA, PORTB e PORTC
    clrf    PORTB
    clrf    PORTC 
    
    BANKSEL ANSEL                  ; Sele��o do banco de mem�ria do registrador ANSEL
    clrf    ANSEL                  ; Zera ANSEL, para usar todas as portas como digitais
    clrf    ANSELH		   ; Zera ANSELH, para usar todas as portas como digitais
    
    BANKSEL TRISA		   ; Seleciona o banco TRISA respons�vel pela defini��o de entradas e sa�das
    clrf    TRISA		   ; Por boas pr�ticas -> zerar os regs TRISA, TRISB, TRISC
    clrf    TRISB
    clrf    TRISC
    movlw   00100000B		   ; Reconfigurando o RA5 como entrada;
    movwf   TRISA                  ; RA5 = W
    movlw   11111111B		   ; Reconfigurando TODOS os bits de TRISB e TRISC como entradas.
    movwf   TRISB
    movwf   TRISC
    
    BANKSEL WPUB		   ; Seleciona o banco de regs onde est� localizado o registrador WPUB
    movwf   WPUB		   ; W para o registrador WPUB.
    BANKSEL PORTA		   ; 
    
define_operacao:
    clrwdt
    clrw			    ; Zerar o W
    btfsc   PORTA, 5		    ; Checando se o bit 5 (RA05) � igual a um.
    goto    adicao
    goto    subtracao

adicao:    
    
    movf    PORTB, W		    ; M�scara
    andlw   00001111B           ; O valor fica armazenado no W
    movwf   v1			    ; Movendo o valor de W para a vari�vel "nibbleB"
    movlw   00001111B		    ; M�scara
    andwf   PORTC, 0
    movwf   v2			    ; movendo o valor de W para o nibbleC (v2)
    movf    v2, W		    ; movendo o valor do nibbleC (v2) para W
    addwf   v1, 0		    ; nibbleB (v1) + nibbleC(v2)
    goto    define_operacao	    ; Voltando para o loop "Define Operacao"
    
subtracao:
    
    movlw   00001111B		    ; M�scara
    andwf   PORTB, 0		    ; O valor fica armazenado no W
    movwf   v1			    ; Movendo o valor de W para a vari�vel "nibbleB"
    movlw   00001111B		    ; M�scara
    andwf   PORTC, 0
    movwf   v2			    ; movendo o valor de W para o nibbleC (v2)
    movf    v2, W
    subwf   v1, 0
    goto    define_operacao
    