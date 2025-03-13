[BITS 16]
[ORG 0]                ; Bootloader ya cargo este sector en 0x7E00

;--------------------------------------------------
; Programa Principal
;--------------------------------------------------
Inicio:
    call ConfigurarEntorno    ; Configura DS, puntaje global y semilla
    jmp BuclePrincipal        ; Salta al bucle principal del juego

;--------------------------------------------------
; ConfigurarEntorno: Configura DS e inicializa las variables globales (puntaje y semilla)
;--------------------------------------------------
ConfigurarEntorno:
    mov ax, cs
    mov ds, ax

    xor ax, ax
    mov [PuntajeGlobal], ax

    xor ah, ah
    int 1Ah
    mov ax, dx
    mov [SemillaAleatoria], ax
    ret

;--------------------------------------------------
; BuclePrincipal: Bucle principal que ejecuta cada ronda del juego
;--------------------------------------------------
BuclePrincipal:
    ; Reiniciar puntaje de la ronda
    xor ax, ax
    mov [PuntajeRonda], ax

    ; Generar letras aleatorias
    call GenerarLetras

    ; Mostrar mensaje de cabecera y las letras generadas
    call MostrarLetras

    ; Procesar entrada para cada letra generada
    call ProcesarTodasLetras

    ; Mostrar puntajes de la ronda y global
    call MostrarPuntajes

    ; Esperar a que se presione una tecla para continuar
    call EsperarTecla

    jmp BuclePrincipal

;--------------------------------------------------
; GenerarLetras: Genera 4 letras aleatorias y las almacena en LetraAleatoria1..LetraAleatoria4
;--------------------------------------------------
GenerarLetras:
    call GenerarLetraAleatoria
    mov [LetraAleatoria1], al

    call GenerarLetraAleatoria
    mov [LetraAleatoria2], al

    call GenerarLetraAleatoria
    mov [LetraAleatoria3], al

    call GenerarLetraAleatoria
    mov [LetraAleatoria4], al
    ret

;--------------------------------------------------
; GenerarLetraAleatoria: Calcula una letra aleatoria (A..Z)
;--------------------------------------------------
GenerarLetraAleatoria:
    mov ax, [SemillaAleatoria]
    mov bx, 25173
    mul bx                   ; DX:AX = SemillaAleatoria * 25173
    add ax, 13849
    mov [SemillaAleatoria], ax
    xor dx, dx
    mov bx, 26
    div bx                   ; DX = residuo (0..25)
    add dl, 'A'
    mov al, dl
    ret

;--------------------------------------------------
; MostrarLetras: Muestra el mensaje y las 4 letras generadas.
;--------------------------------------------------
MostrarLetras:
    lea si, [MensajeCabecera]
    call ImprimirCadena

    mov al, [LetraAleatoria1]
    call ImprimirCaracter
    mov al, [LetraAleatoria2]
    call ImprimirCaracter
    mov al, [LetraAleatoria3]
    call ImprimirCaracter
    mov al, [LetraAleatoria4]
    call ImprimirCaracter

    lea si, [NuevaLinea]
    call ImprimirCadena
    ret

;--------------------------------------------------
; ProcesarTodasLetras: Procesa la entrada del usuario para cada una de las 4 letras.
;--------------------------------------------------
ProcesarTodasLetras:
    mov al, [LetraAleatoria1]
    mov [LetraActual], al
    call ProcesarEntradaFonetica

    mov al, [LetraAleatoria2]
    mov [LetraActual], al
    call ProcesarEntradaFonetica

    mov al, [LetraAleatoria3]
    mov [LetraActual], al
    call ProcesarEntradaFonetica

    mov al, [LetraAleatoria4]
    mov [LetraActual], al
    call ProcesarEntradaFonetica
    ret

;--------------------------------------------------
; ProcesarEntradaFonetica: Solicita al usuario la palabra correspondiente a la letra actual,
; muestra si es correcta ("Correcto!") y actualiza puntajes.
;--------------------------------------------------
ProcesarEntradaFonetica:
    lea si, [MensajeSolicitud]
    call ImprimirCadena

    mov ah, 0x0E
    mov al, [LetraActual]
    int 0x10                ; Imprime la letra actual

    lea si, [MensajeDosPuntos]
    call ImprimirCadena

    call LimpiarBufferEntrada
    call LeerLineaEntrada

    ; Calcular indice para la tabla fonetica: (LetraActual - 'A') * 2
    mov al, [LetraActual]
    sub al, 'A'
    mov bl, al
    xor bh, bh
    shl bx, 1              ; BX = (LetraActual - 'A') * 2

    mov si, [TablaFonetica + bx]   ; SI apunta a la cadena correcta

    ; Comparar la cadena ingresada (BufferEntrada) con la esperada
    push si                ; Guardar puntero a la cadena esperada
    lea si, [BufferEntrada]
    pop di                 ; DI contiene la cadena esperada
    call CompararCadenas
    cmp ax, 0
    je EntradaCorrecta

    lea si, [MensajeIncorrecto]
    call ImprimirCadena
    jmp FinEntrada

EntradaCorrecta:
    lea si, [MensajeCorrecto]
    call ImprimirCadena
    inc word [PuntajeGlobal]
    inc word [PuntajeRonda]

FinEntrada:
    lea si, [NuevaLinea]
    call ImprimirCadena
    ret

;--------------------------------------------------
; MostrarPuntajes: Muestra los puntajes con barra de resultados.
;--------------------------------------------------
MostrarPuntajes:
    lea si, [NuevaLinea]
    call ImprimirCadena

    lea si, [BarraSuperior]
    call ImprimirCadena

    lea si, [MensajePuntajeRonda]
    call ImprimirCadena
    mov ax, [PuntajeRonda]
    call ImprimirNumero
    lea si, [NuevaLinea]
    call ImprimirCadena

    lea si, [MensajePuntajeGlobal]
    call ImprimirCadena
    mov ax, [PuntajeGlobal]
    call ImprimirNumero
    lea si, [NuevaLinea]
    call ImprimirCadena

    lea si, [BarraInferior]
    call ImprimirCadena

    lea si, [NuevaLinea]
    call ImprimirCadena

    ret

;--------------------------------------------------
; EsperarTecla: Espera a que el usuario presione una tecla.
;--------------------------------------------------
EsperarTecla:
    mov ah, 0
    int 16h
    ret

;--------------------------------------------------
; ImprimirCadena:
; Imprime la cadena terminada en 0 apuntada por DS:SI.
;--------------------------------------------------
ImprimirCadena:
.BucleImprimir:
    lodsb
    cmp al, 0
    je FinImprimir
    mov ah, 0x0E
    int 0x10
    jmp .BucleImprimir
FinImprimir:
    ret

;--------------------------------------------------
; ImprimirCaracter: Imprime el caracter en AL.
;--------------------------------------------------
ImprimirCaracter:
    mov ah, 0x0E
    int 0x10
    ret

;--------------------------------------------------
; LimpiarBufferEntrada: Limpia 16 bytes del buffer de entrada.
;--------------------------------------------------
LimpiarBufferEntrada:
    lea di, [BufferEntrada]
    mov cx, 16
    mov al, 0
    rep stosb
    ret

;--------------------------------------------------
; LeerLineaEntrada: Lee caracteres del teclado hasta que se presione ENTER y almacena la cadena en BufferEntrada.
;--------------------------------------------------
LeerLineaEntrada:
    lea di, [BufferEntrada]
.BucleLeer:
    mov ah, 0
    int 16h              ; Espera por tecla
    cmp al, 13           ; ¿Tecla ENTER?
    je FinLeer
    mov ah, 0x0E
    int 0x10             ; Eco del caracter
    stosb
    jmp .BucleLeer
FinLeer:
    mov byte [di], 0
    ret

;--------------------------------------------------
; CompararCadenas: Compara dos cadenas, retorna 0 si son iguales o 1 si no.
;--------------------------------------------------
CompararCadenas:
    cld                     ; Asegura el modo de incremento
.BucleComparar:
    mov al, [si]            ; Cargar caracter de la primera cadena
    mov bl, [di]            ; Cargar caracter de la segunda cadena
    cmp al, bl              ; Comparar los dos caracteres
    jne .NoIguales         ; Si son diferentes, salir
    test al, al             ; ¿Es fin de cadena? (al == 0)
    jz .Iguales
    inc si                ; Avanzar en la primera cadena
    inc di                ; Avanzar en la segunda cadena
    jmp .BucleComparar
.NoIguales:
    mov ax, 1               ; Cadenas diferentes
    ret
.Iguales:
    xor ax, ax              ; Cadenas iguales (AX = 0)
    ret

;--------------------------------------------------
; ImprimirNumero: Imprime el numero en AX en formato decimal.
;--------------------------------------------------
ImprimirNumero:
    mov bx, 10
    xor cx, cx
.BucleNumero:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    cmp ax, 0
    jne .BucleNumero
.BucleImprimirNum:
    pop ax
    mov ah, 0x0E
    int 0x10
    loop .BucleImprimirNum
    ret

;--------------------------------------------------
; Datos
;--------------------------------------------------
PuntajeGlobal       dw 0
PuntajeRonda        dw 0
SemillaAleatoria    dw 0

MensajeCabecera     db "Letras aleatorias generadas: ", 0
MensajeSolicitud    db "Escribe la palabra para la letra ", 0
MensajeDosPuntos    db ": ", 0
MensajeCorrecto     db " Correcto!", 0
MensajeIncorrecto   db " Incorrecto!", 0
MensajePuntajeRonda db "Puntaje obtenido en la ronda: ", 0
MensajePuntajeGlobal db "Puntaje global: ", 0
NuevaLinea          db 0x0D,0x0A,0
BarraSuperior       db "-------- RESULTADOS --------", 0x0D,0x0A, 0
BarraInferior       db "----------------------------", 0x0D,0x0A, 0

LetraActual         db 0
BufferEntrada       times 16 db 0

LetraAleatoria1     db 0
LetraAleatoria2     db 0
LetraAleatoria3     db 0
LetraAleatoria4     db 0

TablaFonetica     dw Fonetica_A, Fonetica_B, Fonetica_C, Fonetica_D, Fonetica_E, Fonetica_F, Fonetica_G, Fonetica_H, Fonetica_I, Fonetica_J, \
                   Fonetica_K, Fonetica_L, Fonetica_M, Fonetica_N, Fonetica_O, Fonetica_P, Fonetica_Q, Fonetica_R, Fonetica_S, Fonetica_T, \
                   Fonetica_U, Fonetica_V, Fonetica_W, Fonetica_X, Fonetica_Y, Fonetica_Z

Fonetica_A   db "Alfa", 0
Fonetica_B   db "Bravo", 0
Fonetica_C   db "Charlie", 0
Fonetica_D   db "Delta", 0
Fonetica_E   db "Echo", 0
Fonetica_F   db "Foxtrot", 0
Fonetica_G   db "Golf", 0
Fonetica_H   db "Hotel", 0
Fonetica_I   db "India", 0
Fonetica_J   db "Juliett", 0
Fonetica_K   db "Kilo", 0
Fonetica_L   db "Lima", 0
Fonetica_M   db "Mike", 0
Fonetica_N   db "November", 0
Fonetica_O   db "Oscar", 0
Fonetica_P   db "Papa", 0
Fonetica_Q   db "Quebec", 0
Fonetica_R   db "Romeo", 0
Fonetica_S   db "Sierra", 0
Fonetica_T   db "Tango", 0
Fonetica_U   db "Uniform", 0
Fonetica_V   db "Victor", 0
Fonetica_W   db "Whiskey", 0
Fonetica_X   db "Xray", 0
Fonetica_Y   db "Yankee", 0
Fonetica_Z   db "Zulu", 0

times 2048 - ($-$$) db 0
