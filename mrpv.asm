[BITS 16]
[ORG 0]                             ; Bootloader ya cargo este sector en 0x7E00

;--------------------------------------------------
; Programa Principal
;--------------------------------------------------
Inicio:
    call ConfigurarEntorno          ; Configura DS, puntaje global y semilla
    jmp BuclePrincipal              ; Salta al bucle principal del juego

;--------------------------------------------------
; ConfigurarEntorno: Configura DS e inicializa las variables globales (puntaje y semilla)
;--------------------------------------------------
ConfigurarEntorno:
    mov ax, cs
    mov ds, ax

    xor ax, ax
    mov [PuntajeGlobal], ax         ; Inicializa el puntaje global a 0

    xor ah, ah                      ; Limpia ah para la llamada para obtener un valor del reloj del BIOS
    int 1Ah                         ; Llama al BIOS para obtener un valor variable
    mov ax, dx                      ; Usa DX (parte baja del contador) como semilla
    mov [SemillaAleatoria], ax
    ret

;--------------------------------------------------
; BuclePrincipal: Bucle principal que ejecuta cada ronda del juego.
; Reinicia el puntaje de la ronda, genera letras, solicita entrada y muestra resultados.
;--------------------------------------------------
BuclePrincipal:
    xor ax, ax
    mov [PuntajeRonda], ax          ; Reinicia el puntaje de esta ronda

    call GenerarLetras

    call MostrarLetras

    call ProcesarTodasLetras        ; Pide al usuario que responda por cada letra

    call MostrarPuntajes

    call EsperarTecla               ; Esperar a que se presione una tecla para continuar

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
    mov ax, [SemillaAleatoria]      ; Carga la semilla actual en AX
    mov bx, 25173                   ; Multiplicador para el generador aleatorio
    mul bx                          ; Multiplica: AX * BX => DX:AX
    add ax, 13849                   ; Suma un valor fijo para cambiar el resultado
    mov [SemillaAleatoria], ax      ; Actualiza la semilla con el nuevo valor
    xor dx, dx                      ; Limpia DX para la división
    mov bx, 26                      ; Numero total de letras (A-Z)
    div bx                          ; Divide AX entre 26; DX tendra el residuo (0..25)
    add dl, 'A'                     ; Convierte el residuo en un carácter ASCII (A = 65)
    mov al, dl                      ; Coloca la letra generada en AL
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
; Actualiza LetraActual y llama a ProcesarEntradaFonetica para solicitar la entrada del usuario.
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
; ProcesarEntradaFonetica: Solicita al usuario la palabra correspondiente a la letra actual. 
; Muestra la letra, solicita la entrada, la compara con la palabra esperada y actualiza puntajes.
;--------------------------------------------------
ProcesarEntradaFonetica:
    lea si, [MensajeSolicitud]
    call ImprimirCadena

    mov ah, 0x0E                    ; Funcion BIOS para imprimir un caracter
    mov al, [LetraActual]           ; Carga la letra actual en AL
    int 0x10                        ; Imprime la letra actual

    lea si, [MensajeDosPuntos]
    call ImprimirCadena

    call LimpiarBufferEntrada
    call LeerLineaEntrada

    ; Calcular indice para la tabla fonetica: (LetraActual - 'A') * 2
    ; (LetraActual - 'A') produce un número entre 0 y 25,
    ; que se multiplica por 2 (por el tamaño de cada entrada en la tabla) para obtener la dirección.
    mov al, [LetraActual]
    sub al, 'A'                     ; Convierte la letra en un índice (0 = A, 1 = B, ...) 
    mov bl, al
    xor bh, bh
    shl bx, 1                       ; BX = (LetraActual - 'A') * 2

    mov si, [TablaFonetica + bx]    ; SI apunta a la cadena correcta

    ; Comparar la cadena ingresada (BufferEntrada) con la esperada
    push si                         ; Guarda el puntero a la cadena esperada en la pila
    lea si, [BufferEntrada]         ; SI apunta al buffer de entrada del usuario
    pop di                          ; DI recibe el puntero a la cadena esperada
    call CompararCadenas            ; Compara ambas cadenas
    cmp ax, 0                       ; Si AX es 0, las cadenas son iguales
    je EntradaCorrecta              ; Si son iguales, la entrada es correcta

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
; MostrarPuntajes: Muestra el puntaje obtenido en la ronda y el puntaje global.
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
    mov ah, 0                       ; Funcion BIOS para leer una tecla
    int 16h                         ; Llama al BIOS (espera la entrada)
    ret

;--------------------------------------------------
; ImprimirCadena: Imprime la cadena terminada en 0 apuntada por DS:SI.
;--------------------------------------------------
ImprimirCadena:
.BucleImprimir:
    lodsb                           ; Carga el siguiente byte de la cadena en AL
    cmp al, 0                       ; Comprueba si es el fin de la cadena (carácter nulo)
    je FinImprimir
    mov ah, 0x0E                    ; Funcion BIOS para imprimir un carácter en modo teletipo
    int 0x10                        ; Imprime el caracter
    jmp .BucleImprimir
FinImprimir:
    ret

;--------------------------------------------------
; ImprimirCaracter: Imprime el carácter que se encuentra en AL.
;--------------------------------------------------
ImprimirCaracter:
    mov ah, 0x0E
    int 0x10
    ret

;--------------------------------------------------
; LimpiarBufferEntrada: Limpia 16 bytes del buffer de entrada, los llena con 0.
;--------------------------------------------------
LimpiarBufferEntrada:
    lea di, [BufferEntrada]         ; DI apunta al inicio del buffer
    mov cx, 16                      ; Numero de bytes a limpiar
    mov al, 0                       ; Valor 0 para borrar
    rep stosb                       ; Llena el buffer con 0 (repitiendo la operación)
    ret

;--------------------------------------------------
; LeerLineaEntrada: Lee caracteres del teclado hasta que se presione ENTER y almacena la cadena en BufferEntrada.
;--------------------------------------------------
LeerLineaEntrada:
    lea di, [BufferEntrada]         ; DI apunta al buffer donde se almacenará la entrada
.BucleLeer:
    mov ah, 0                       ; Funcion BIOS para esperar una tecla
    int 16h                         ; Llama al BIOS para leer el teclado
    cmp al, 13                      ; Comprueba si se presiono ENTER (código 13)
    je FinLeer                      ; Si es ENTER, finaliza la lectura
    mov ah, 0x0E                    ; Funcion BIOS para imprimir el caracter (eco)
    int 0x10                        ; Imprime el caracter en pantalla
    stosb                           ; Almacena el caracter en BufferEntrada y avanza DI
    jmp .BucleLeer                  ; Repite el proceso hasta ENTER
FinLeer:
    mov byte [di], 0                ; Termina la cadena con caracter nulo (0)
    ret

;--------------------------------------------------
; CompararCadenas: Compara dos cadenas, retorna 0 si son iguales o 1 si no.
;--------------------------------------------------
CompararCadenas:
    cld                             ; Asegura que SI y DI se incrementen
.BucleComparar:
    mov al, [si]                    ; Obtiene el caracter actual de la primera cadena
    mov bl, [di]                    ; Obtiene el caracter actual de la segunda cadena
    cmp al, bl                      ; Compara ambos caracteres
    jne .NoIguales                  ; Si son diferentes, las cadenas no coinciden
    test al, al                     ; Verifica si es el fin de la cadena (al == 0)
    jz .Iguales                     ; Si es fin, las cadenas son iguales
    inc si                          ; Avanza al siguiente caracter en la primera cadena
    inc di                          ; Avanza al siguiente caracter en la segunda cadena
    jmp .BucleComparar              ; Continua comparando
.NoIguales:
    mov ax, 1                       ; Retorna 1 en AX para indicar diferencia
    ret
.Iguales:
    xor ax, ax                      ; Retorna 0 en AX para indicar igualdad
    ret


;--------------------------------------------------
; ImprimirNumero: Imprime el numero en AX en formato decimal.
;--------------------------------------------------
ImprimirNumero:
    mov bx, 10                      ; Base decimal para la conversión
    xor cx, cx
.BucleNumero:
    xor dx, dx
    div bx                          ; Divide AX entre 10, el residuo queda en DX
    add dl, '0'                     ; Convierte el digito a carácter ASCII
    push dx                         ; Guarda el digito en la pila
    inc cx
    cmp ax, 0
    jne .BucleNumero                ; Repite hasta que AX sea 0
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
