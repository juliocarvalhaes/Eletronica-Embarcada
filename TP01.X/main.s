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
    PAGESEL start		    ; Seleciona página de código de programa onde está start
    goto start 

psect code,class=CODE,delta=2	    ; Define uma secção o de código de programa 
start:
    BANKSEL PORTA		    ; Selecionei o reg "PORTA" do Banco 0
    clrf    PORTA		    ; Por boas práticas -> zerar os regs PORTA, PORTB e PORTC
    clrf    PORTB
    clrf    PORTC 
    
    BANKSEL ANSEL                  ; Seleção do banco de memória do registrador ANSEL
    clrf    ANSEL                  ; Zera ANSEL, para usar todas as portas como digitais
    clrf    ANSELH		   ; Zera ANSELH, para usar todas as portas como digitais
    
    BANKSEL TRISA		   ; Seleciona o banco TRISA responsável pela definição de entradas e saídas
    clrf    TRISA		   ; Por boas práticas -> zerar os regs TRISA, TRISB, TRISC
    clrf    TRISB
    clrf    TRISC
    movlw   00100000B		   ; Reconfigurando o RA5 como entrada;
    movwf   TRISA                  ; RA5 = W
    movlw   11111111B		   ; Reconfigurando TODOS os bits de TRISB e TRISC como entradas.
    movwf   TRISB
    movwf   TRISC
    
    BANKSEL WPUB		   ; Seleciona o banco de regs onde está localizado o registrador WPUB
    movwf   WPUB		   ; W para o registrador WPUB.
    BANKSEL PORTA		   ; 
    
define_operacao:
    clrwdt
    clrw			    ; Zerar o W
    btfsc   PORTA, 5		    ; Checando se o bit 5 (RA05) é igual a um.
    goto    adicao
    goto    subtracao

adicao:
    movf    PORTB, W        ; Máscara
    andlw   00001111B       ; O valor fica armazenado no W
    movwf   v1              ; Movendo o valor de W para a variável "v1"
    movlw   00001111B       ; Máscara
    andwf   PORTC, 0
    movwf   v2              ; movendo o valor de W para a variável "v2"
    movf    v2, W
    addwf   v1, 0           ; v1 + v2
    movwf   PORTA           ; Armazenar o resultado na PORTA
    goto    define_operacao ; Voltando para o loop "Define Operacao"

subtracao:
    movlw   00001111B       ; Máscara
    andwf   PORTB, 0        ; O valor fica armazenado no W
    movwf   v1              ; Movendo o valor de W para a variável "v1"
    movlw   00001111B       ; Máscara
    andwf   PORTC, 0
    movwf   v2              ; movendo o valor de W para a variável "v2"
    movf    v2, W
    subwf   v1, 0           ; v1 - v2
    movwf   PORTA           ; Armazenar o resultado na PORTA
    goto    define_operacao ; Voltando para o loop "Define Operacao"
