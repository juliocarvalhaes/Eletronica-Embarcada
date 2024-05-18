#include <xc.inc>

CONFIG FOSC = INTRC_NOCLKOUT ;

global	cnt			    ; Variável auxiliar
global	acc			    ; Variável que faz o papel de acumular    
global  var_A			    ; Variável a
global  var_B			    ; Variável b
PSECT udata_shr
acc:
    DS  2
cnt:
    DS  1
var_A:
    DS  2
var_B:
    DS  1
psect resetVec,class=CODE,delta=2   ; Vetor de Reset definido em xc.inc para os PIC10/12/16
resetVec:
    PAGESEL start		    ; Seleciona página de código de programa onde está start
    goto start
psect code,class=CODE,delta=2	    ; Define uma secção o de código de programa     

start:
;Definindo se a entrada é analógica ou digital com o ANSEL
    BANKSEL ANSEL		    
    clrf    ANSEL
    clrf    ANSELH
;Configurando as portas relacionadas as variáveis a e b			    
    BANKSEL PORTB		
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
    movlw   0x20
    movwf   FSR 
;Definindo os pinos de entrada e saída
    BANKSEL TRISB
    movlw   11111111B
    movwf   TRISB
    clrf    TRISA
    clrf    TRISC
    movlw   11111111B
    movwf   TRISD
    movlw   00000001B
    movwf   TRISE
    
    BANKSEL PORTA
    
loop:    
;PC = linha 0x7B9
    clrwdt 
    clrf    var_A
    clrf    var_B
    movf    PORTB, W
    movwf   var_A
    movf    PORTD, W
    movwf   var_B
    clrf    acc
    clrf    acc+1		     ;acc+1 é segundo Byte de acc

; Verifico se o valor de  var_A ou var_B = 0
    movf    var_A, W	             ; faço W = PORTB  
    btfsc   STATUS, 2		     ; Verifico se a flag ZERO do reg STATUS está setado.
    goto    resultado		     ; Direcionando para a Label "resultado"
    movf    var_B, W		     ; faço W = PORTD
    btfsc   STATUS, 2		     ; Verifico se a flag ZERO do reg STATUS está setado.
    goto    resultado		     ; Direcionando para a Label "resultado"
;Escolha do Algoritmo:
    btfsc   RE0			
    goto    soma_deslocamento
    
somas_sucessivas:
    movf    var_A, W		    ; Passo o valor de A para W
    addwf   acc, f		    ; 
    btfsc   STATUS, 0		    ; Verifico se houve overflow, se não tiver ocorrido o overflow pula-se a linha
    incf    acc+1, f		    ; Estou jogando o valor do overflow para a minha área de bytes mais significativos e jogo nele mesmo
    decfsz  var_B, f		    ; Estou decrementando o valor de B e verificando se já encerrou a contagem
    goto    somas_sucessivas	    
    goto    resultado
    
soma_deslocamento:
    btfss   var_B, 0		    ; bit 0 de var_b está setado?
    goto    $+7			    ; A fim de evitar a criação de mais uma label, eu utilizo este recurso pulando a acumulação
    movf    var_A, W		    ; Passando o valor de A para W
    addwf   acc, f		    ; Adiciona o valor de "a" em "acc"
    btfsc   STATUS, 0		    ; Verifico se houve overflow, se não tiver ocorrido o overflow pula-se a linha
    incf    acc+1, f		    ; Estou jogando o valor do overflow para a minha área de bytes mais significativos e jogo nele mesmo			    
    movf    var_A+1, W              ; Estou fazendo o mesmo movimento, porém para o byte mais significativo
    addwf   acc+1, f            
   
    bcf	    STATUS, 0		    ; Devo fazer isso para garantir uma rotação/rolagem com 0 lógico
    rlf	    var_A		    ; Deslocar var_a para a esquerda em 1 bit.
    rlf	    var_A+1		    ; Devo fazer a mesma coisa para minha área de bytes mais significativo
    bcf	    STATUS, 0		    ; Devo fazer isso para garantir uma rotação/rolagem com 0 lógico no carry
    rrf	    var_B
; Verificar se o byte mais significativo é zero:
    movf    var_B, f		    ; Movendo o meu reg para ele mesmo
    btfsc   STATUS, 2		    ; Verificar se a flag de Zero está setada/levantada
    goto    resultado		    ; Se for 0
    goto    soma_deslocamento	    ;
    
resultado:
    movf    acc, W		    ; W = cl
    movwf   PORTA		    ; PORTA recebe o valor de W
    movf    acc+1, W		    ; W = ch
    movwf   PORTC		    ; PORTC receb o valor de W
 ;  goto    loop
    
enderecamento_indireto:
;Trabalhando no banco 00
    bcf	    STATUS, 7		    ; Como estou trabalhando no banco 0, preciso trabalhar no bit 7 de status
    bcf	    FSR,  7		    ; Bit 7 do FSR
    movf    PORTB, W		    ; Armazenar o valor em INDF nestas próximas duas linhas
    movwf   INDF		    ; Devo mover para INDF porque ele é quem acessa o endereço de FSR
;Trabalhando no banco 01
    bcf	    STATUS, 7		    ; Como estou trabalhando no banco 1, preciso trabalhar no bit 7 de status
    bsf	    FSR,   7
    movf    PORTD, W
    movwf   INDF
; Trabalhando no banco 10
    bsf	    STATUS, 7
    bcf	    FSR,    7
    movf    acc+1,  W
    movwf   INDF
; Trabalhando no banco 11
    bsf	    STATUS, 7
    bsf	    FSR,    7
    movf    acc,    W
    movwf   INDF
; Verificar se FSR = 6Fh (Endereço)
    movlw   0x6F		    ; Devo mover este valor de endereço  p/ Wreg  
    xorwf   FSR, W		    ; Faço uma XOR bit a bit para verificar se FSR = W
    btfss   STATUS, 2		    ; Verifico no bit 02 (flag de zero)
    goto    $+4
; Vou reiniciar
    movlw   0x20		    ; Devo mover este valor de endereço  p/ Wreg  
    movwf   FSR			    ; Devo mover W -> FSR
    goto    loop		    ; Volto para o loop
;Vou incrementar
    incf    FSR
    goto    loop