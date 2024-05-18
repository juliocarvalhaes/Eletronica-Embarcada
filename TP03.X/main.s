#include <xc.inc>
#define	 LED PORTE, 1		    ;Estou chamando o pino RE1 de "Led"
CONFIG FOSC = INTRC_NOCLKOUT ;

global  d			    
global	n
global  q
global	r
global  i
global	LSB_q
global	LSB_r
global	MSB_q
global	MSB_r
PSECT udata_shr
d:
    DS  1
n:
    DS	1
q:  
    DS	1 
r:
    DS	1
i:  
    DS	1
LSB_q:
    DS 1
LSB_r:
    DS 1
MSB_q:
    DS 1
MSB_r:
    DS 1
psect resetVec,class=CODE,abs, delta=2   ; Vetor de Reset definido em xc.inc para os PIC10/12/16
resetVec:
    PAGESEL start		    ; Seleciona página de código de programa onde está start
    goto start
psect code,class=CODE,delta=2	    ; Define uma secção o de código de programa     

start:
;Definindo se a entrada é analógica ou digital com o ANSEL
    BANKSEL ANSEL		    
    clrf    ANSEL
    clrf    ANSELH
;Configurando as portas relacionadas as variáveis n e d			    
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
    BANKSEL WPUB
    movwf   WPUB
    
    BANKSEL PORTA
configuracao: 
;Definindo as variáveis
    clrwdt 
    clrf    n		     ;Variável de numerador
    clrf    d		     ;Variável de denominador
    clrf    q		     ;Variável de quociente
    movf    PORTB, W	     ;PortB = W
    movwf   n		     ; n = W
    movf    PORTD, W	     ; PortD = W
    movwf   d		     ; d = W
; Verifico se o valor d = 0
    movf    d, W	     ; faço W = PORTD
    btfss   STATUS, 2	     ; Verifico se a flag ZERO do reg STATUS está setado, ou seja, se d = 0.
    goto    $+6	             ; Direcionando para a escolha do algoritmo
    clrf    q		     ; Limpando o valor de "q" com q = 0
    movf    n, W	     ; Deixando n = W
    movwf   r		     ; deixando r = W
    bsf	    LED		     ; Estou ligando o LED do RE1 para indicar o erro
    goto    configuracao     ; Como deu erro eu volto ao loop/label "config"
;Escolha do Algoritmo:
    btfsc   RE0		     ; Se RE0 estiver setado em 0, pulo a linha e vou para a label "div_simples"
    call    div_deslocamentos 
    btfss   RE0		     ; Como ele está setado em 0, vai ser direcionado ao chamado de "div_simples"
    call    div_simples
resultado:
    movf    q, W
    movwf   PORTA
    movf    r, W
    movwf   PORTC
    call    registro
    goto    configuracao    ; Faço isso para não invadir a label "div_simples" e evitando um loop eterno
    
div_simples:
    movf    n, W	     ; Deixando n = W
    movwf   r		     ; Deixando r = W
    clrf    q		     ; Deixando	q = 0
;Fazendo o While R >= D:
    movf    d, W	     ; W = d
    subwf   r, W             ; r - W(d)
    btfss   STATUS, 0	     ; Tô checando se c = 1 (W <= f)
    return  		     ; Volta para a primeira linha  de div_simples
    movwf   r		     ; Estou fazendo R = R - D aqui para evitar que R seja n/ negativo
    incf    q, f	     ; Significa que não deu n° negativo e faço Q+= 1
    goto    $-6		     ; Estou voltando para a linha de "movf d, W"
    
div_deslocamentos:   
    clrf    q		     ; Inicializar q e r com zero,
    clrf    r
    movlw   0x08	     ; Mover 0 valor de 08 para W
    movwf   i		     ; i = m, visto que, m é o tamanho/comprimento de n (8 bits)
    
    bcf	    STATUS, 0        ; Procedimento para garantir rotação com 0 em n e com C em r
    rlf	    n		     ; Rotacionando n para a esquerda
    rlf	    r		     ; Rotacionando r para a esquerda
    
    movf    d, W	     ; W = d
    subwf   r, W	     ; r - W(d)
    
    btfsc   STATUS, 0	     ; Verificando se o bit 0 (bit de Carry) é igual a 0
    movwf   r		     ; Se C=1, significa que r>=d e guarda resultado parcial em r (r=W)
    rlf	    q		     ; Rotacionando q para a esquerda
    decfsz  i, f	     ; Decrementa e se for zero, pula.
    goto    $-9		     ; Volto para a linha onde garanto a rotação com C = 0  
    return		     ; Ele volta para a linha após a chamada da função (linha do btfss   RE0)

registro:
;Processo de Máscara
    movf    q, W	     ; Mascara
    andlw   00001111B	     
    movwf   LSB_q
    movf    q, W	     ; Mascara
    andlw   11110000B	     
    movwf   MSB_q
    
    movf    r, W	     ; Mascara
    andlw   00001111B	     
    movwf   LSB_r
    movf    r, W	     ; Mascara
    andlw   11110000B	     
    movwf   MSB_r
; PCLATH
    movlw   high(tabela)     ; Mover a parte alta lable da "tabela" para W que tem 15 bits
    movwf   PCLATH	     ; Movendo a parte mais alta de "tabela" para PCLATH
    swapf    MSB_q, W        ; Pegando a parte mais significativa de "q"
    call    tabela	     ; Chamando a "tabela" para ele pegar o valor			    
    movwf   INDF	     ; Movendo o valor de W para INDF visto que este último registrador lê o end e escreve nele mesmo
    incf    FSR		     ; Incrementando o FSR para poder trabalhar com o próximo end. de memória
    
    movlw   high(tabela)     ; Mover a parte alta lable da "tabela" para W que tem 15 bits
    movwf   PCLATH	     ; Movendo a parte mais alta de "tabela" para PCLATH
    movf    LSB_q,W	     ; Pegando a parte mais significativa de "q"
    call    tabela	     ; Chamando a "tabela" para ele pegar o valor		
    movwf   INDF	     ; Movendo o valor de W para INDF visto que este último registrador lê o end e escreve nele mesmo
    incf    FSR		     ; Incrementando o FSR para poder trabalhar com o próximo end. de memória
    
    movlw   high(tabela)     ; Mover a parte alta lable da "tabela" para W que tem 15 bits
    movwf   PCLATH	     ; Movendo a parte mais alta de "tabela" para PCLATH
    swapf   MSB_r, W         ; Pegando a parte mais significativa de "q"
    call    tabela	     ; Chamando a "tabela" para ele pegar o valor
    movwf   INDF	     ; Movendo o valor de W para INDF visto que este último registrador lê o end e escreve nele mesmo
    incf    FSR		     ; Incrementando o FSR para poder trabalhar com o próximo end. de memória

    movlw   high(tabela)     ; Mover a parte alta lable da "tabela" para W que tem 15 bits
    movwf   PCLATH	     ; Movendo a parte mais alta de "tabela" para PCLATH
    movf    LSB_r,W            ; Pegando a parte mais significativa de "q"
    call    tabela	     ; Chamando a "tabela" para ele pegar o valor
    movwf   INDF	     ; Movendo o valor de W para INDF visto que este último registrador lê o end e escreve nele mesmo
    incf    FSR		     ; Incrementando o FSR para poder trabalhar com o próximo end. de memória
; Reiniciar FSR
    movlw   0x20
    movwf   FSR
    return
    
ORG 0x400		     ; Garantindo que a label "tabela" está neste endereço de programa PC = 0100 0000 0000    
tabela:			
    andlw   0x0F
    addwf   PCL,F       ; Somar alguma coisa à PCL é igual a pular linha		    
    retlw   0x30	;0	    
    retlw   0x31	;1
    retlw   0x32	;2
    retlw   0x33	;3
    retlw   0x34	;4
    retlw   0x35	;5
    retlw   0x36	;6
    retlw   0x37	;7
    retlw   0x38	;8
    retlw   0x39	;9
    retlw   0x41	;A
    retlw   0x42	;B
    retlw   0x43	;C
    retlw   0x44	;D
    retlw   0x45        ;E
    retlw   0x46	;F
    
    END	resetVec
