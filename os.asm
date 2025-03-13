[BITS 16]
[ORG 0x7C00]   ; Direccion donde la BIOS carga el sector de arranque



;--------------------------------------------------
; Inicio: Punto de entrada del bootloader.Muestra un mensaje y carga el juego desde el disco.
;--------------------------------------------------
Inicio:
    ; Mostrar mensaje de inicio
    mov si, mensaje_arranque
    call Imprimir_cadena

    ; Cargar el juego desde el segundo sector (LBA 1) a la direccion 0x7E00
    mov ax, 0x7E0   ; Segmento donde se cargara el juego
    mov es, ax
    mov bx, 0x0000  ; Offset dentro de ES:BX

    mov ah, 0x02    ; Funcion de INT 13h para leer desde el disco
    mov al, 4       ; Leer 4 sectores (si tu juego ocupa mas, ajusta esto)
    mov ch, 0       ; Cilindro 0
    mov cl, 2       ; Sector 2 (LBA 1 en CHS)
    mov dh, 0       ; Cabeza 0
    mov dl, 0x80    ; Disco duro (0x00 si es disquete)
    int 0x13        ; Leer el sector

    jc Error_disco  ; Si hay error, mostrar mensaje y detener

    ; Saltar a ejecutar el codigo cargado en 0x7E00:0000
    jmp 0x7E0:0x0000


;--------------------------------------------------
; Error_disco: Maneja errores de lectura del disco.
;--------------------------------------------------
Error_disco:
    mov si, mensaje_error
    call Imprimir_cadena
    jmp $


;--------------------------------------------------
; Imprimir_cadena: Imprime la cadena de texto. 
;--------------------------------------------------
Imprimir_cadena:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .fin
    int 0x10
    jmp .loop
.fin:
    ret


;--------------------------------------------------
; Datos
;--------------------------------------------------
mensaje_arranque db "Bootloader iniciado. Cargando el juego...", 0
mensaje_error    db "Error al leer el juego!", 0

times 510-($-$$) db 0  ; Rellenar hasta 510 bytes
dw 0xAA55             ; Firma de sector de arranque
