title "Proyecto: Tetris"
  .model small
  .386        ; Versión del procesador
  .stack 512  ; Tamaño del segmento de "stack"
  .data       ; Inicio del segmento de datos


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Definición de tipos de dato
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BLOQUE struc
  x     db  ?
  y     db  ?
ends

PIEZA struc
  x     db  ?
  y     db  ?
  color db  ?
  bloques BLOQUE 4 dup(?)
ends

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Definición de constantes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Valores auxiliares para generar números pseudo-aleatorios
max_rand_index    equ   5d

; Valor ASCII de caracteres para el marco del programa
marcoEsqInfIzq    equ   200d  ;'╚'
marcoEsqInfDer    equ   188d  ;'╝'
marcoEsqSupDer    equ   187d  ;'╗'
marcoEsqSupIzq    equ   201d  ;'╔'
marcoCruceVerSup  equ   203d  ;'╦'
marcoCruceHorDer  equ   185d  ;'╣'
marcoCruceVerInf  equ   202d  ;'╩'
marcoCruceHorIzq  equ   204d  ;'╠'
marcoCruce        equ   206d  ;'╬'
marcoHor          equ   205d  ;'═'
marcoVer          equ   186d  ;'║'

; Atributos de color de BIOS
; Valores de color para carácter
cNegro            equ   00h
cAzul             equ   01h
cVerde            equ   02h
cCyan             equ   03h
cRojo             equ   04h
cMagenta          equ   05h
cCafe             equ   06h
cGrisClaro        equ   07h
cGrisOscuro       equ   08h
cAzulClaro        equ   09h
cVerdeClaro       equ   0Ah
cCyanClaro        equ   0Bh
cRojoClaro        equ   0Ch
cMagentaClaro     equ   0Dh
cAmarillo         equ   0Eh
cBlanco           equ   0Fh

; Valores de color para fondo de carácter
bgNegro           equ   00h
bgAzul            equ   10h
bgVerde           equ   20h
bgCyan            equ   30h
bgRojo            equ   40h
bgMagenta         equ   50h
bgCafe            equ   60h
bgGrisClaro       equ   70h
bgGrisOscuro      equ   80h
bgAzulClaro       equ   90h
bgVerdeClaro      equ   0A0h
bgCyanClaro       equ   0B0h
bgRojoClaro       equ   0C0h
bgMagentaClaro    equ   0D0h
bgAmarillo        equ   0E0h
bgBlanco          equ   0F0h

;Valores para delimitar el área de juego
lim_superior      equ    1
lim_inferior      equ    23
lim_izquierdo     equ    1
lim_derecho       equ    15

;Valores de referencia para la posición inicial de la primera pieza
ini_columna       equ   lim_derecho/2
ini_renglon       equ   -1

;Valores para la posición de los controles e indicadores dentro del juego
;Next
next_col          equ    lim_derecho+7
next_ren          equ    4

;Data
hiscore_ren       equ   10
hiscore_col       equ   lim_derecho+7
level_ren         equ   12
level_col         equ   lim_derecho+7
lines_ren         equ   14
lines_col         equ   lim_derecho+7
update_rate       equ   3

;Botón STOP
stop_col          equ   lim_derecho+15
stop_ren          equ   lim_inferior-4
stop_izq          equ   stop_col
stop_der          equ   stop_col+2
stop_sup          equ   stop_ren
stop_inf          equ   stop_ren+2

;Botón PAUSE
pause_col         equ   lim_derecho+25
pause_ren         equ   lim_inferior-4
pause_izq         equ   pause_col
pause_der         equ   pause_col+2
pause_sup         equ   pause_ren
pause_inf         equ   pause_ren+2

;Botón PLAY
play_col          equ   lim_derecho+35
play_ren          equ   lim_inferior-4
play_izq          equ   play_col
play_der          equ   play_col+2
play_sup          equ   play_ren
play_inf          equ   play_ren+2

;Piezas
linea             equ   0
cuadro            equ   1
lnormal           equ   2
linvertida        equ   3
tnormal           equ   4
snormal           equ   5
sinvertida        equ   6

;Status
paro              equ   0
activo            equ   1
pausa             equ   2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;////////////////////////////////////////////////////
; Definición de variables
;////////////////////////////////////////////////////
titulo            db    "TETRIS"
finTitulo         db    ""
levelStr          db    "LEVEL"
finLevelStr       db    ""
linesStr          db    "LINES"
finLinesStr       db    ""
hiscoreStr        db    "HI-SCORE"
finHiscoreStr     db    ""
nextStr           db    "NEXT"
finNextStr        db    ""
blank             db    "     "
lines_score       dw    0
hiscore           dw    0
speed             dw    4
update_aux        dw    update_rate

; Variable para representar el área de juego
tablero           db    lim_derecho*lim_inferior dup(-1)
tab_aux           db    0

; Variables auxiliares para generar números pseudo-aleatorios
rand_seq          db    max_rand_index dup(?)
rand_index        dw    0

; Almacenamiento de información de las piezas
pieza_curr        pieza  ? ; Pieza actual
pieza_next        pieza  ? ; Pieza siguiente
pieza_sombra      pieza  ? ; Pieza que indica dónde caerá "pieza_curr"
pieza_aux         pieza  ? ; Pieza que se usa para operaciones auxiliares

; Definición de la estructura de cada una de las piezas (y1,x1),(y2,x2)...(yn,xn)
i_shape      db    0, 0,-1, 0, 1, 0, 2, 0
j_shape      db    0, 0,-1, 0, 1, 0, 1, 1
l_shape      db    0, 0,-1, 0, 1, 0, 1,-1
o_shape      db    0, 0,-1, 0,-1, 1, 0, 1
s_shape      db    0, 0, 0, 1,-1, 0,-1,-1
t_shape      db    0, 0, 0, 1, 0,-1, 1, 0
z_shape      db    0, 0, 0, 1, 1, 0, 1,-1

; Variables auxiliares para el manejo de posiciones
col_aux           db     0
ren_aux           db     0

; Variables para manejo del reloj del sistema
ticks             dw    0      ;contador de ticks
tick_ms           dw    55     ;55 ms por cada tick del sistema, esta variable se usa para operación de MUL convertir ticks a segundos
mil               dw    1000   ;dato de valor decimal 1000 para operación DIV entre 1000
diez              dw    10

; Variables para el status del juego
status            db    0     ;Status de juegos: 0 stop, 1 active, 2 pause
conta             db    0     ;Contador auxiliar para algunas operaciones

; Variables que sirven de parámetros de entrada para el procedimiento IMPRIME_BOTON
boton_caracter    db    0
boton_renglon     db    0
boton_columna     db    0
boton_color       db    0

; Auxiliar para cálculo de coordenadas del mouse
ocho              db     8

; Mensaje para cuando el driver del mouse no esté disponible
no_mouse          db     'No se encuentra driver de mouse. Presione [enter] para salir$'

;////////////////////////////////////////////////////

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;Macros;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;clear - Limpia pantalla
clear macro
  mov   ax,0003h  ;ah = 00h, selecciona modo video
                  ;al = 03h. Modo texto, 16 colores
  int   10h       ;llama interrupcion 10h con opcion 00h.
                  ;Establece modo de video limpiando pantalla
endm

; posiciona_cursor - Cambia la posición del cursor a la especificada con 'renglon' y 'columna'
posiciona_cursor macro renglon, columna
  mov   dh, renglon  ;dh = renglon
  mov   dl, columna  ;dl = columna
  mov   bx, 0
  mov   ax, 0200h    ;preparar ax para interrupcion, opcion 02h
  int   10h         ;interrupcion 10h y opcion 02h. Cambia posicion del cursor
endm

; inicializa_ds_es - Inicializa el valor del registro DS y ES
inicializa_ds_es   macro
  mov   ax, @data
  mov   ds, ax
  mov   es, ax     ;Este registro se va a usar, junto con BP, para imprimir cadenas utilizando interrupción 10h
endm

; muestra_cursor_mouse - Establece la visibilidad del cursor del mouser
muestra_cursor_mouse  macro
  mov   ax,1    ;opcion 0001h
  int   33h      ;int 33h para manejo del mouse. Opcion AX=0001h
          ;Habilita la visibilidad del cursor del mouse en el programa
endm

; posiciona_cursor_mouse - Establece la posición inicial del cursor del mouse
posiciona_cursor_mouse  macro columna,renglon
  mov   dx, renglon
  mov   cx, columna
  mov   ax, 4    ;opcion 0004h
  int   33h     ;int 33h para manejo del mouse. Opcion AX=0001h
                ;Habilita la visibilidad del cursor del mouse en el programa
endm

; oculta_cursor_teclado - Oculta la visibilidad del cursor del teclado
oculta_cursor_teclado  macro
  mov   ah, 01h     ;Opcion 01h
  mov   cx, 2607h   ;Parametro necesario para ocultar cursor
  int   10h     ;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

; apaga_cursor_parpadeo - Deshabilita el parpadeo del cursor cuando se imprimen caracteres con fondo de color
; Habilita 16 colores de fondo
apaga_cursor_parpadeo  macro
  mov ax, 1003h     ;Opcion 1003h
  xor bl ,bl        ;BL = 0, parámetro para int 10h opción 1003h
  int 10h           ;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

; imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'.
;  Los colores disponibles están en la lista a continuacion;
;  Colores:
;  0h: Negro
;  1h: Azul
;  2h: Verde
;  3h: Cyan
;  4h: Rojo
;  5h: Magenta
;  6h: Cafe
;  7h: Gris Claro
;  8h: Gris Oscuro
;  9h: Azul Claro
;  Ah: Verde Claro
;  Bh: Cyan Claro
;  Ch: Rojo Claro
;  Dh: Magenta Claro
;  Eh: Amarillo
;  Fh: Blanco
;  utiliza int 10h opcion 09h
;  'caracter' - caracter que se va a imprimir
;  'color' - color que tomará el caracter
;  'bg_color' - color de fondo para el carácter en la celda
;  Cuando se define el color del carácter, éste se hace en el registro BL:
;  La parte baja de BL (los 4 bits menos significativos) define el color del carácter
;  La parte alta de BL (los 4 bits más significativos) define el color de fondo "background" del carácter
imprime_caracter_color macro caracter,color,bg_color
  mov ah, 09h        ;preparar AH para interrupcion, opcion 09h
  mov al, caracter     ;AL = caracter a imprimir
  mov bh, 0        ;BH = numero de pagina
  mov bl, color
  or  bl, bg_color       ;BL = color del caracter
              ;'color' define los 4 bits menos significativos
              ;'bg_color' define los 4 bits más significativos
  mov cx,1        ;CX = numero de veces que se imprime el caracter
              ;CX es un argumento necesario para opcion 09h de int 10h
  int 10h         ;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

; imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'.
;  utiliza int 10h opcion 09h
;  'cadena' - nombre de la cadena en memoria que se va a imprimir
;  'long_cadena' - longitud (en caracteres) de la cadena a imprimir
;  'color' - color que tomarán los caracteres de la cadena
;  'bg_color' - color de fondo para los caracteres en la cadena
imprime_cadena_color macro cadena,long_cadena,color,bg_color
  mov ah,13h          ;preparar AH para interrupcion, opcion 13h
  lea bp,cadena       ;BP como apuntador a la cadena a imprimir
  mov bh,0            ;BH = numero de pagina
  mov bl,color
  or bl,bg_color      ;BL = color del caracter
                      ;'color' define los 4 bits menos significativos
                      ;'bg_color' define los 4 bits más significativos
  mov cx,long_cadena  ;CX = longitud de la cadena, se tomarán este número de localidades a partir del apuntador a la cadena
  int 10h             ;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

; lee_mouse - Revisa el estado del mouse
; Devuelve:
;;BX - estado de los botones
;;;Si BX = 0000h, ningun boton presionado
;;;Si BX = 0001h, boton izquierdo presionado
;;;Si BX = 0002h, boton derecho presionado
;;;Si BX = 0003h, boton izquierdo y derecho presionados
;;CX - columna en la que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
;;DX - renglon en el que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
;Ejemplo: Si la int 33h devuelve la posición (400,120)
;Al convertir a resolución => 80x25 =>Columna: 400 x 80 / 640 = 50; Renglon: (120 x 25 / 200) = 15 => (50,15)
lee_mouse  macro
  mov ax,0003h
  int 33h
endm

lee_teclado macro
  mov ah, 01h
  int 16h
endm

limpia_teclado macro
  mov ah, 00h
  int 16h
endm

;comprueba_mouse - Revisa si el driver del mouse existe
comprueba_mouse   macro
  mov ax,0    ;opcion 0
  int 33h      ;llama interrupcion 33h para manejo del mouse, devuelve un valor en AX
          ;Si AX = 0000h, no existe el driver. Si AX = FFFFh, existe driver
endm

;delimita_mouse_h - Delimita la posición del mouse horizontalmente dependiendo los valores 'minimo' y 'maximo'
delimita_mouse_h   macro minimo,maximo
  mov cx,minimo    ;establece el valor mínimo horizontal en CX
  mov dx,maximo    ;establece el valor máximo horizontal en CX
  mov ax,7    ;opcion 7
  int 33h      ;llama interrupcion 33h para manejo del mouse
endm

generar_aleatorio macro max
  local fin_generar_aleatorio
  mov ah, 00h
  int 1Ah

  lea bx, [rand_seq]
  mov di, [rand_index]

  mov al, [bx + di]
  xor dl, al

  mov  ax, dx
  xor  dx, dx
  mov  cx, max
  div  cx

  inc rand_index
  mov ax, rand_index
  test ax, max_rand_index
  jz  fin_generar_aleatorio
  mov rand_index, 0h
  mov di, [rand_index]
  mov [bx + di], dl
fin_generar_aleatorio:
endm

crear_pieza   macro pieza
  local loop_crear_bloques
  local escoger_pieza_i
  local escoger_pieza_j
  local escoger_pieza_l
  local escoger_pieza_o
  local escoger_pieza_s
  local escoger_pieza_t
  local escoger_pieza_z
  local escoger_pieza_fin
  local loop_girar_generada
  local loop_elegir_color

generar_aleatorio 7h

cmp dl, 0h
je escoger_pieza_i
cmp dl, 1h
je escoger_pieza_j
cmp dl, 2h
je escoger_pieza_l
cmp dl, 3h
je escoger_pieza_o
cmp dl, 4h
je escoger_pieza_s
cmp dl, 5h
je escoger_pieza_t
cmp dl, 6h
je escoger_pieza_z

escoger_pieza_i:
  lea bx, [i_shape]
  jmp escoger_pieza_fin;
escoger_pieza_j:
  lea bx, [j_shape]
  jmp escoger_pieza_fin;
escoger_pieza_l:
  lea bx, [l_shape]
  jmp escoger_pieza_fin;
escoger_pieza_o:
  lea bx, [o_shape]
  jmp escoger_pieza_fin;
escoger_pieza_s:
  lea bx, [s_shape]
  jmp escoger_pieza_fin;
escoger_pieza_t:
  lea bx, [t_shape]
  jmp escoger_pieza_fin;
escoger_pieza_z:
  lea bx, [z_shape]
  jmp escoger_pieza_fin;
escoger_pieza_fin:

  lea di, [pieza.bloques]

  mov cx, 4
loop_crear_bloques:

  mov ah, [bx]
  mov [di.y], ah
  mov ah, [bx+1]
  mov [di.x], ah

  add bx, 2
  add di, size BLOQUE

  loop loop_crear_bloques

  mov [pieza.x], ini_columna
  mov [pieza.y], ini_renglon

  ; Se genera un color aleatorio
loop_elegir_color:
  generar_aleatorio 0Fh
  cmp dl, cGrisOscuro
  je loop_elegir_color
  cmp dl, cNegro
  je loop_elegir_color
  mov [pieza.color], dl

  generar_aleatorio 4h
  lea bx, [pieza]

  mov cx, dx
loop_girar_generada:
  push cx
  push bx
  call giro_der
  pop bx
  pop  cx
  loop loop_girar_generada

endm

pausar_programa macro t1, t2
  mov   cx, t1
  mov   dx, t2
  mov   ah, 86h
  int   15h
endm

obtener_tab_pos macro ren, col
  push bx
  push di

  mov al, ren
  dec al

  mov ah, lim_derecho
  mul ah 

  xor bx, bx
  mov bl, col

  add ax, bx
  dec ax
  
  lea bx, [tablero]
  mov di, ax

  mov al, [bx+di]

  pop di
  pop bx
endm

establecer_tab_pos macro ren, col, valor
  push ax
  push bx
  push di
  push dx

  mov al, ren
  dec al

  mov ah, lim_derecho
  mul ah 

  xor bx, bx
  mov bl, col

  add ax, bx
  dec ax
  
  lea bx, [tablero]
  mov di, ax

  mov dl, valor
  mov [bx+di], dl

  pop dx
  pop di
  pop bx
  pop ax
endm

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;Fin Macros;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

  .code
inicio:          ;etiqueta inicio
  inicializa_ds_es

  comprueba_mouse    ;macro para revisar driver de mouse
  xor ax, 0FFFFh    ;compara el valor de AX con FFFFh, si el resultado es zero, entonces existe el driver de mouse
  jz imprime_ui    ;Si existe el driver del mouse, entonces salta a 'imprime_ui'
  ;Si no existe el driver del mouse entonces se muestra un mensaje
  lea dx, [no_mouse]
  mov ax, 0900h    ;opcion 9 para interrupcion 21h
  int 21h        ;interrupcion 21h. Imprime cadena.
  jmp salir_enter    ;salta a 'salir_enter'

imprime_ui:
  clear           ;limpia pantalla
  oculta_cursor_teclado  ;oculta cursor del mouse
  apaga_cursor_parpadeo   ;Deshabilita parpadeo del cursor
  call DIBUJA_UI       ;procedimiento que dibuja marco de la interfaz de usuario
  muestra_cursor_mouse   ;hace visible el cursor del mouse
  posiciona_cursor_mouse 320d,16d  ;establece la posición del mouse

;Revisar que el boton izquierdo del mouse no esté presionado
;Si el botón está suelto, continúa a la sección "mouse"
;si no, se mantiene indefinidamente en "mouse_no_clic" hasta que se suelte
lectura_entrada:
  mov ax, 0h
  push ax
  call  eliminar_lineas
  pop ax

  cmp ax, 0h
  je no_eliminar_lineas
  call  dibujar_lineas_marcadas
  call  limpiar_lineas
  pausar_programa 1h, 0000h
  call  dibujar_tab

no_eliminar_lineas:
  call calcular_sombra
  call dibuja_sombra
  call  dibuja_actual

  pausar_programa 1h, 0000h
  cmp [update_aux], 0
  jg continuar_v

  call  borra_actual
  inc   [pieza_curr.y]

  lea ax, [pieza_curr]
  push ax
  call validar_lim_v
  pop ax

  cmp ax, 0h
  je revertir_avance_v ; Si hay choque

  lea ax, [pieza_curr]
  push ax
  call validar_tab_v
  pop ax
  mov [update_aux], update_rate+1

  cmp ax, 0h
  jne continuar_v ; Si no hay choque

revertir_avance_v:
  dec [pieza_curr.y]
  call  dibuja_actual

  lea ax, [pieza_curr]
  push ax
  call agregar_pieza_tab
  pop ax
  
  ; Asignación de nueva de pieza
asignar_nueva_pieza:
  lea ax, [pieza_curr]
  push ax
  lea ax, [pieza_next]
  push ax
  call copiar_piezas
  pop ax
  pop ax

  ; Creación de nueva pieza
  call borra_next
  crear_pieza pieza_next
  call  dibuja_next

continuar_v:
  dec [update_aux]
  lee_mouse
  cmp bx, 01h
  je  mouse
  lee_teclado
  jnz teclado
  jmp lectura_entrada

mouse:
  lee_mouse
conversion_mouse:
  ;Leer la posicion del mouse y hacer la conversion a resolucion
  ;80x25 (columnas x renglones) en modo texto
  mov ax,dx       ; Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
  div [ocho]      ; Division de 8 bits
            ; divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
            ; para obtener el valor correspondiente en resolucion 80x25
  xor ah,ah       ;Descartar el residuo de la division anterior
  mov dx,ax       ;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

  mov ax,cx       ;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
  div [ocho]       ;Division de 8 bits
            ;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
            ;para obtener el valor correspondiente en resolucion 80x25
  xor ah,ah       ;Descartar el residuo de la division anterior
  mov cx,ax       ;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

  ;Aquí se revisa si se hizo clic en el botón izquierdo
  test bx,0001h     ;Para revisar si el boton izquierdo del mouse fue presionado
  jz lectura_entrada       ;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Aqui va la lógica de la posicion del mouse;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Si el mouse fue presionado en el renglon 0
  ;se va a revisar si fue dentro del boton [X]
  cmp dx,0
  je boton_x
  jmp lectura_entrada
boton_x:
  jmp boton_x1
;Lógica para revisar si el mouse fue presionado en [X]
;[X] se encuentra en renglon 0 y entre columnas 76 y 78
boton_x1:
  cmp cx,76
  jge boton_x2
  jmp lectura_entrada
boton_x2:
  cmp cx,78
  jbe boton_x3
  jmp lectura_entrada
boton_x3:
  ;Se cumplieron todas las condiciones
  jmp salir

  jmp lectura_entrada
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Aqui va la lógica de las teclas presionadas
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
teclado:
  lee_teclado

  cmp al, 'h'
  je procesar_mov_izq
  cmp al, 'l'
  je procesar_mov_der
  cmp al, 'j'
  je procesar_giro_izq
  cmp al, 'k'
  je procesar_giro_der
  cmp al, 'q'
  je procesar_cambio_pieza
  cmp al, ' '
  je procesar_bajar_rapido
  jmp continuar

procesar_mov_izq:
  ; Trasladar pieza a la izquierda
  dec pieza_curr.x

  ; Validar que la nueva posición esté dentro del tablero
  lea ax, [pieza_curr]
  push ax
  call validar_lim_h
  pop ax
  cmp ax, 0h
  je mov_izq_inv

  ; Validar que la nueva posición no tenga bloques
  lea ax, [pieza_curr]
  push ax
  call validar_tab_v
  pop ax
  cmp ax, 0h
  jne continuar

mov_izq_inv:
  ; Si la posición es incorrecta, revertir el movimiento
  inc pieza_curr.x
  jmp continuar

procesar_mov_der:
  ; Trasladar pieza a la derecha
  inc pieza_curr.x

  ; Validar que la nueva posición esté dentro del tablero
  lea ax, [pieza_curr]
  push ax
  call validar_lim_h
  pop ax
  cmp ax, 0h
  je mov_der_inv

  ; Validar que la nueva posición no tenga bloques
  lea ax, [pieza_curr]
  push ax
  call validar_tab_v
  pop ax
  cmp ax, 0h
  jne continuar

mov_der_inv:
  ; Si la posición es incorrecta, revertir el movimiento
  dec pieza_curr.x
  jmp continuar

procesar_giro_izq:
  ; Girar pieza a la izquierda
  lea ax, [pieza_curr]
  push ax
  call giro_izq
  pop ax

  ; Validar que la nueva posición esté dentro del tablero
  lea ax, [pieza_curr]
  push ax
  call validar_lim_h
  pop ax
  cmp ax, 0h
  je giro_izq_inv

  ; Validar que la nueva posición no tenga bloques
  lea ax, [pieza_curr]
  push ax
  call validar_tab_v
  pop ax
  cmp ax, 0h
  jne continuar

giro_izq_inv:
  ; Si la posición es incorrecta, revertir el movimiento
  lea ax, [pieza_curr]
  push ax
  call giro_der
  pop ax
  jmp continuar

procesar_giro_der:
  ; Girar pieza a la derecha
  lea ax, [pieza_curr]
  push ax
  call giro_der
  pop ax

  ; Validar que la nueva posición esté dentro del tablero
  lea ax, [pieza_curr]
  push ax
  call validar_lim_h
  pop ax
  cmp ax, 0h
  je giro_der_inv

  ; Validar que la nueva posición no tenga bloques
  lea ax, [pieza_curr]
  push ax
  call validar_tab_v
  pop ax
  cmp ax, 0h
  jne continuar

giro_der_inv:
  ; Si la posición es incorrecta, revertir el movimiento
  lea ax, [pieza_curr]
  push ax
  call giro_izq
  pop ax
  jmp continuar

procesar_cambio_pieza:
  call borra_next
  call borra_actual
  call cambiar_next_curr

  ; Validar que la nueva posición esté dentro del tablero
  lea ax, [pieza_curr]
  push ax
  call validar_lim_h
  pop ax
  cmp ax, 0h
  je procesar_cambio_pieza_inv

  ; Validar que la nueva posición no tenga bloques
  lea ax, [pieza_curr]
  push ax
  call validar_tab_v
  pop ax
  cmp ax, 0h
  jne continuar_cambio_pieza

procesar_cambio_pieza_inv:
  call cambiar_next_curr

continuar_cambio_pieza:
  call dibuja_next
  jmp continuar

procesar_bajar_rapido:
 call bajar_pieza
 mov [update_aux], 0

continuar:
  limpia_teclado
  jmp lectura_entrada

;Si no se encontró el driver del mouse, muestra un mensaje y el usuario debe salir tecleando [enter]
salir_enter:
  mov ah,08h
  int 21h       ;int 21h opción 08h: recibe entrada de teclado sin eco y guarda en AL
  cmp al,0Dh      ;compara la entrada de teclado si fue [enter]
  jnz salir_enter   ;Sale del ciclo hasta que presiona la tecla [enter]

salir:        ;inicia etiqueta salir
  clear       ;limpia pantalla
  mov ax,4C00h  ;AH = 4Ch, opción para terminar programa, AL = 0 Exit Code, código devuelto al finalizar el programa
  int 21h      ;señal 21h de interrupción, pasa el control al sistema operativo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;PROCEDIMIENTOS;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DIBUJA_UI proc
  ;imprimir esquina superior izquierda del marco
  posiciona_cursor 0,0
  imprime_caracter_color marcoEsqSupIzq,cGrisClaro,bgNegro

  ;imprimir esquina superior derecha del marco
  posiciona_cursor 0,79
  imprime_caracter_color marcoEsqSupDer,cGrisClaro,bgNegro

  ;imprimir esquina inferior izquierda del marco
  posiciona_cursor 24,0
  imprime_caracter_color marcoEsqInfIzq,cGrisClaro,bgNegro

  ;imprimir esquina inferior derecha del marco
  posiciona_cursor 24,79
  imprime_caracter_color marcoEsqInfDer,cGrisClaro,bgNegro

  ;imprimir marcos horizontales, superior e inferior
  mov cx,78     ;CX = 004Eh => CH = 00h, CL = 4Eh
  marcos_horizontales:
    mov [col_aux],cl
    ;Superior
    posiciona_cursor 0,[col_aux]
    imprime_caracter_color marcoHor,cGrisClaro,bgNegro
    ;Inferior
    posiciona_cursor 24,[col_aux]
    imprime_caracter_color marcoHor,cGrisClaro,bgNegro

    mov cl,[col_aux]
    loop marcos_horizontales

    ;imprimir marcos verticales, derecho e izquierdo
    mov cx,23     ;CX = 0017h => CH = 00h, CL = 17h
  marcos_verticales:
    mov [ren_aux],cl
    ;Izquierdo
    posiciona_cursor [ren_aux],0
    imprime_caracter_color marcoVer,cGrisClaro,bgNegro
    ;Derecho
    posiciona_cursor [ren_aux],79
    imprime_caracter_color marcoVer,cGrisClaro,bgNegro
    ;Interno
    posiciona_cursor [ren_aux],lim_derecho+1
    imprime_caracter_color marcoVer,cGrisClaro,bgNegro

    mov cl,[ren_aux]
    loop marcos_verticales

    ;imprimir marcos horizontales internos
    mov cx,79-lim_derecho-1
  marcos_horizontales_internos:
    push cx
    mov [col_aux],cl
    add [col_aux],lim_derecho
    ;Interno superior
    posiciona_cursor 8,[col_aux]
    imprime_caracter_color marcoHor,cGrisClaro,bgNegro

    ;Interno inferior
    posiciona_cursor 16,[col_aux]
    imprime_caracter_color marcoHor,cGrisClaro,bgNegro

    mov cl,[col_aux]
    pop cx
    loop marcos_horizontales_internos

    ;imprime intersecciones internas
    posiciona_cursor 0,lim_derecho+1
    imprime_caracter_color marcoCruceVerSup,cGrisClaro,bgNegro
    posiciona_cursor 24,lim_derecho+1
    imprime_caracter_color marcoCruceVerInf,cGrisClaro,bgNegro

    posiciona_cursor 8,lim_derecho+1
    imprime_caracter_color marcoCruceHorIzq,cGrisClaro,bgNegro
    posiciona_cursor 8,79
    imprime_caracter_color marcoCruceHorDer,cGrisClaro,bgNegro

    posiciona_cursor 16,lim_derecho+1
    imprime_caracter_color marcoCruceHorIzq,cGrisClaro,bgNegro
    posiciona_cursor 16,79
    imprime_caracter_color marcoCruceHorDer,cGrisClaro,bgNegro

    ;imprimir [X] para cerrar programa
    posiciona_cursor 0,76
    imprime_caracter_color '[',cGrisClaro,bgNegro
    posiciona_cursor 0,77
    imprime_caracter_color 'X',cRojoClaro,bgNegro
    posiciona_cursor 0,78
    imprime_caracter_color ']',cGrisClaro,bgNegro

    ;imprimir título
    posiciona_cursor 0,37
    imprime_cadena_color [titulo],finTitulo-titulo,cBlanco,bgNegro
    call IMPRIME_TEXTOS
    call IMPRIME_BOTONES
    call IMPRIME_DATOS_INICIALES
    ret
  endp

  IMPRIME_TEXTOS proc
    ;Imprime cadena "NEXT"
    posiciona_cursor next_ren,next_col
    imprime_cadena_color nextStr,finNextStr-nextStr,cGrisClaro,bgNegro

    ;Imprime cadena "LEVEL"
    posiciona_cursor level_ren,level_col
    imprime_cadena_color levelStr,finlevelStr-levelStr,cGrisClaro,bgNegro

    ;Imprime cadena "LINES"
    posiciona_cursor lines_ren,lines_col
    imprime_cadena_color linesStr,finLinesStr-linesStr,cGrisClaro,bgNegro

    ;Imprime cadena "HI-SCORE"
    posiciona_cursor hiscore_ren,hiscore_col
    imprime_cadena_color hiscoreStr,finHiscoreStr-hiscoreStr,cGrisClaro,bgNegro
    ret
  endp

  IMPRIME_BOTONES proc
    ;Botón STOP
    mov [boton_caracter],219d
    mov [boton_color],bgAmarillo
    mov [boton_renglon],stop_ren
    mov [boton_columna],stop_col
    call IMPRIME_BOTON
    ;Botón PAUSE
    mov [boton_caracter],186d
    mov [boton_color],bgAmarillo
    mov [boton_renglon],pause_ren
    mov [boton_columna],pause_col
    call IMPRIME_BOTON
    ;Botón PLAY
    mov [boton_caracter],16d
    mov [boton_color],bgAmarillo
    mov [boton_renglon],play_ren
    mov [boton_columna],play_col
    call IMPRIME_BOTON
    ret
  endp

  IMPRIME_SCORES proc
    call IMPRIME_LINES
    call IMPRIME_HISCORE
    call IMPRIME_LEVEL
    ret
  endp

  IMPRIME_LINES proc
    mov [ren_aux],lines_ren
    mov [col_aux],lines_col+20
    mov bx,[lines_score]
    call IMPRIME_BX
    ret
  endp

  IMPRIME_HISCORE proc
    mov [ren_aux],hiscore_ren
    mov [col_aux],hiscore_col+20
    mov bx,[hiscore]
    call IMPRIME_BX
    ret
  endp

  IMPRIME_LEVEL proc
    mov [ren_aux],level_ren
    mov [col_aux],level_col+20
    mov bx,[lines_score]
    call IMPRIME_BX
    ret
  endp

  ;BORRA_SCORES borra los marcadores numéricos de pantalla sustituyendo la cadena de números por espacios
  BORRA_SCORES proc
    call BORRA_SCORE
    call BORRA_HISCORE
    ret
  endp

  BORRA_SCORE proc
    posiciona_cursor lines_ren,lines_col+20     ;posiciona el cursor relativo a lines_ren y score_col
    imprime_cadena_color blank,5,cBlanco,bgNegro   ;imprime cadena blank (espacios) para "borrar" lo que está en pantalla
    ret
  endp

  BORRA_HISCORE proc
    posiciona_cursor hiscore_ren,hiscore_col+20   ;posiciona el cursor relativo a hiscore_ren y hiscore_col
    imprime_cadena_color blank,5,cBlanco,bgNegro   ;imprime cadena blank (espacios) para "borrar" lo que está en pantalla
    ret
  endp

  ;Imprime el valor del registro BX como entero sin signo (positivo)
  ;Se imprime con 5 dígitos (incluyendo ceros a la izquierda)
  ;Se usan divisiones entre 10 para obtener dígito por dígito en un LOOP 5 veces (una por cada dígito)
  IMPRIME_BX proc
    mov ax,bx
    mov cx,5
  div10:
    xor dx,dx
    div [diez]
    push dx
    loop div10
    mov cx,5
  imprime_digito:
    mov [conta],cl
    posiciona_cursor [ren_aux],[col_aux]
    pop dx
    or dl,30h
    imprime_caracter_color dl,cBlanco,bgNegro
    xor ch,ch
    mov cl,[conta]
    inc [col_aux]
    loop imprime_digito
    ret
  endp

  IMPRIME_DATOS_INICIALES proc
    call DATOS_INICIALES     ;inicializa variables de juego
    call IMPRIME_SCORES
    call DIBUJA_NEXT
    call DIBUJA_ACTUAL
    ;implementar
    ret
  endp

  ;Inicializa variables del juego
  DATOS_INICIALES proc
    mov [lines_score],0
    crear_pieza pieza_curr
    crear_pieza pieza_next
    ;agregar otras variables necesarias
    ret
  endp

  ;procedimiento IMPRIME_BOTON
  ;Dibuja un boton que abarca 3 renglones y 5 columnas
  ;con un caracter centrado dentro del boton
  ;en la posición que se especifique (esquina superior izquierda)
  ;y de un color especificado
  ;Utiliza paso de parametros por variables globales
  ;Las variables utilizadas son:
  ;boton_caracter: debe contener el caracter que va a mostrar el boton
  ;boton_renglon: contiene la posicion del renglon en donde inicia el boton
  ;boton_columna: contiene la posicion de la columna en donde inicia el boton
  ;boton_color: contiene el color del boton
  IMPRIME_BOTON proc
     ;background de botón
    mov ax,0600h     ;AH=06h (scroll up window) AL=00h (borrar)
    mov bh,cRojo     ;Caracteres en color amarillo
    xor bh,[boton_color]
    mov ch,[boton_renglon]
    mov cl,[boton_columna]
    mov dh,ch
    add dh,2
    mov dl,cl
    add dl,2
    int 10h
    mov [col_aux],dl
    mov [ren_aux],dh
    dec [col_aux]
    dec [ren_aux]
    posiciona_cursor [ren_aux],[col_aux]
    imprime_caracter_color [boton_caracter],cRojo,[boton_color]
     ret       ;Regreso de llamada a procedimiento
  endp         ;Indica fin de procedimiento IMPRIME_BOTON para el ensamblador

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Los siguientes procedimientos se utilizan para dibujar piezas y utilizan los mismos parámetros
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Como parámetros se utilizan:
  ;col_aux y ren_aux: Toma como referencia los valores establecidos en ren_aux y en col_aux
  ;esas coordenadas son la referencia (esquina superior izquierda) de una matriz 4x4
  ;si - apuntador al arreglo de renglones en donde se van a guardar esas posiciones
  ;di - apuntador al arreglo de columnas en donde se van a guardar esas posiciones
  ;si y di están parametrizados porque se puede dibujar la pieza actual o la pieza next
  ;Se calculan las posiciones y se almacenan en los arreglos correspondientes
  ;posteriormente se llama al procedimiento DIBUJA_PIEZA que hace uso de esas posiciones para imprimir la pieza en pantalla


  ;DIBUJA_PIEZA - procedimiento para imprimir una pieza en pantalla
  ;Como parámetros recibe:
  ;si - apuntador al arreglo de renglones
  ;di - apuntador al arreglo de columnas
  DIBUJA_PIEZA proc
    mov cx, 4
  loop_dibuja_pieza:
    push cx
    push si
    push di
    mov al, col_aux
    mov ah, ren_aux
    push ax

    mov ah, [di.x]
    add col_aux, ah
    mov ah, [di.y]
    add ren_aux, ah

    ; No dibuja los bloques fuera del marco
    cmp ren_aux, lim_superior
    jl fin_dibujar_bloque
    cmp ren_aux, lim_inferior
    jg fin_dibujar_bloque

    posiciona_cursor ren_aux, col_aux
    imprime_caracter_color 254, [si.color], bgGrisOscuro

fin_dibujar_bloque:
    pop ax
    pop di
    pop si
    pop cx

    mov ren_aux, ah
    mov col_aux, al
    add di, size bloque

    loop loop_dibuja_pieza
    ret
  endp

  ;DIBUJA_NEXT - se usa para imprimir la pieza siguiente en pantalla
  ;Primero se debe calcular qué pieza se va a dibujar
  ;Dentro del procedimiento se utilizan variables referentes a la pieza siguiente
  DIBUJA_NEXT proc
    lea si, pieza_next
    lea di, pieza_next.bloques
    mov [col_aux], next_col+10
    mov [ren_aux], next_ren-1

    call DIBUJA_PIEZA

    ret
  endp

  ;DIBUJA_ACTUAL - se usa para imprimir la pieza actual en pantalla
  ;Primero se debe calcular qué pieza se va a dibujar
  ;Dentro del procedimiento se utilizan variables referentes a la pieza actual
  DIBUJA_ACTUAL proc
    lea si, pieza_curr
    lea di, [pieza_curr.bloques]
    mov al, [pieza_curr.x]
    mov ah, [pieza_curr.y]
    mov [col_aux], al
    mov [ren_aux], ah

    call DIBUJA_PIEZA
    ret
  endp

  DIBUJA_SOMBRA proc
    lea si, pieza_sombra
    lea di, [pieza_sombra.bloques]
    mov al, [pieza_sombra.x]
    mov ah, [pieza_sombra.y]
    mov [col_aux], al
    mov [ren_aux], ah

    call DIBUJA_PIEZA
    ret
  endp

  BORRA_ACTUAL proc
    lea si, pieza_curr
    lea di, [pieza_curr.bloques]
    mov al, [pieza_curr.x]
    mov ah, [pieza_curr.y]
    mov [col_aux], al
    mov [ren_aux], ah

    call BORRA_PIEZA
    ret
  endp

  BORRA_NEXT proc
    lea si, pieza_next
    lea di, pieza_next.bloques
    mov [col_aux], next_col+10
    mov [ren_aux], next_ren-1

    call BORRA_PIEZA

    ret
  endp

  BORRA_PIEZA proc
    mov cx, 4
  loop_borra_pieza:
    push cx
    push si
    push di
    mov al, col_aux
    mov ah, ren_aux
    push ax

    mov ah, [di.x]
    add col_aux, ah
    mov ah, [di.y]
    add ren_aux, ah

    ; No borra los bloques fuera del marco
    cmp ren_aux, lim_superior
    jl fin_borra_bloque
    cmp ren_aux, lim_inferior
    jg fin_borra_bloque
    posiciona_cursor ren_aux, col_aux
    imprime_caracter_color 32, cNegro, bgNegro

fin_borra_bloque:
    pop ax
    pop di
    pop si
    pop cx

    mov ren_aux, ah
    mov col_aux, al
    add di, size bloque

    loop loop_borra_pieza
    ret
  endp

  GIRO_DER proc
    mov bp, sp
    mov si, [bp+2]
    lea si, [si.bloques]

    mov cx, 4
  loop_giro_derecha:
    mov al, [si.x]
    mov ah, [si.y]
    not ah

    mov [si.y], al
    mov [si.x], ah

    add si, size bloque
    loop loop_giro_derecha
    ret
  endp

  GIRO_IZQ proc
    mov bp, sp
    mov si, [bp+2]
    lea si, [si.bloques]

    mov cx, 4
  loop_giro_izquierda:
    mov al, [si.x]
    mov ah, [si.y]
    not al

    mov [si.y], al
    mov [si.x], ah

    add si, size bloque
    loop loop_giro_izquierda
    ret
  endp

  VALIDAR_LIM_H proc
    mov bp, sp
    mov di, [bp+2]
    lea si, [di.bloques]

    mov cx, 4
  loop_validar_h:
    mov ah, [di.x]
    add ah, [si.x]

    cmp ah, lim_derecho
    jg fallo_validar_h

    cmp ah, lim_izquierdo
    jl fallo_validar_h

    add si, size bloque
    loop loop_validar_h

    mov ax, 1h
    mov [bp + 2], ax
    ret

  fallo_validar_h:
    mov ax, 0h
    mov [bp + 2], ax
    ret
  endp

  VALIDAR_LIM_V proc
    mov bp, sp
    mov di, [bp+2]
    lea si, [di.bloques]

    mov cx, 4
  loop_validar_v:
    mov ah, [di.y]
    add ah, [si.y]

    cmp ah, lim_inferior
    jg fallo_validar_v

    add si, size bloque
    loop loop_validar_v

    mov ax, 1h
    mov [bp + 2], ax
    ret

  fallo_validar_v:
    mov ax, 0h
    mov [bp + 2], ax
    ret
  endp


  VALIDAR_TAB_V proc
    mov bp, sp
    mov di, [bp+2]
    lea si, [di.bloques]

    mov cx, 4
  loop_validar_tab_v:
    mov al, [di.y]
    add al, [si.y]
    dec al

    cmp al, 0h
    jl continuar_validar_tab_v

    mov bl, lim_derecho
    mul bl 

    xor bx, bx
    mov bl, [di.x]
    add bl, [si.x]

    add bx, ax
    dec bx

    push di

    mov di, bx
    lea bx, [tablero]
    mov al, [bx + di]

    pop di

    cmp al, -1
    jne fallo_validar_tab_v

continuar_validar_tab_v:
    add si, size bloque
    loop loop_validar_tab_v

    mov ax, 1h
    mov [bp + 2], ax
    ret

  fallo_validar_tab_v:
    mov ax, 0h
    mov [bp + 2], ax
    ret
  endp

  AGREGAR_PIEZA_TAB proc
    mov bp, sp
    mov di, [bp+2]
    lea si, [di.bloques]

    mov cx, 4
  loop_agregar_pieza_tab:
    mov al, [di.y]
    add al, [si.y]
    dec al

    cmp al, 0h
    jl continuar_agregar_pieza_tab

    mov bl, lim_derecho
    mul bl 

    xor bx, bx
    mov bl, [di.x]
    add bl, [si.x]

    add bx, ax
    dec bx

    mov dl, [di.color]

    push di
      mov di, bx
      lea bx, [tablero]
      mov [bx + di], dl
    pop di

continuar_agregar_pieza_tab:
    add si, size bloque
    loop loop_agregar_pieza_tab

    ret
  endp

  ELIMINAR_LINEAS proc
    mov bp, sp
    mov [conta], 0

    mov cx, lim_inferior
loop_recorrer_lineas:
    mov ren_aux, cl
    push cx

    mov cx, lim_derecho
loop_recorrer_linea:
    mov col_aux, cl

    obtener_tab_pos ren_aux, col_aux

    cmp al, 0FFh
    je recorrer_siguiente_linea

    loop loop_recorrer_linea

    mov cx, lim_derecho
    inc lines_score
    inc [conta]
loop_marcar_linea:
    mov col_aux, cl
    establecer_tab_pos ren_aux, col_aux, 0FEh
loop loop_marcar_linea

recorrer_siguiente_linea:
    pop cx
    loop loop_recorrer_lineas
    call imprime_lines
    mov ax, 0
    mov al, [conta]
    mov [bp+2], ax
    ret
  endp

  DIBUJAR_LINEAS_MARCADAS proc
    mov cx, lim_inferior
loop_dibujar_linea_v:
    mov ren_aux, cl
    push cx

    mov cx, lim_derecho
loop_dibujar_linea_h:
    mov col_aux, cl
    obtener_tab_pos ren_aux, col_aux

    cmp al, 0FEh
    jne dibujar_siguiente_linea

    push cx
    posiciona_cursor ren_aux, col_aux
    imprime_caracter_color ' ', cNegro, bgBlanco
    pop cx

    loop loop_dibujar_linea_h

dibujar_siguiente_linea:
    pop cx
    loop loop_dibujar_linea_v
    ret
  endp

  DIBUJAR_TAB proc
    mov cx, lim_inferior
loop_dibujar_tab_v:
    mov ren_aux, cl
    push cx

    mov cx, lim_derecho
loop_dibujar_tab_h:
    mov col_aux, cl
    obtener_tab_pos ren_aux, col_aux

    push cx
    cmp al, 0FFh
    je imprime_vacio
    mov tab_aux, al
    posiciona_cursor ren_aux, col_aux
    imprime_caracter_color 254, tab_aux, bgGrisOscuro
    jmp continuar_imprimir
imprime_vacio:
    posiciona_cursor ren_aux, col_aux
    imprime_caracter_color ' ', cNegro, bgNegro
continuar_imprimir:
    pop cx

    loop loop_dibujar_tab_h

    pop cx
    loop loop_dibujar_tab_v
    ret
  endp

  LIMPIAR_LINEAS proc
    lea bx, [tablero]

    mov cx, 4h
loop_lineas_mayor:
    push cx
    mov cx, lim_derecho * lim_inferior - 1
loop_limpiar_lineas:
    cmp cx, lim_derecho
    jl continuar_limpiar_lineas
    mov di, cx
    mov al, [bx+di]
    cmp al, 0FEh
    jne continuar_limpiar_lineas
    mov ah, [bx+di-lim_derecho]
    mov [bx+di], ah
    mov [bx+di-lim_derecho], al
continuar_limpiar_lineas:
    loop loop_limpiar_lineas
    pop cx
    loop loop_lineas_mayor

    mov di, 0h    
eliminar_marcas:
    mov al, [bx+di]
    cmp al, 0FEh
    jne terminar_limpia
    mov al, 0FFh
    mov [bx+di], al
    inc di
    jmp eliminar_marcas

terminar_limpia:
    ret
  endp

  COPIAR_PIEZAS proc
    mov bp, sp
    mov di, [bp+2] ; Origen
    mov si, [bp+4] ; Destino

    ; Asignación del color
    mov al, [di.color]
    mov [si.color], al

    ; Asignación de 'x'
    mov al, [di.x]
    mov [si.x], al

    ; Asignación de 'y'
    mov al, [di.y]
    mov [si.y], al

    ; Copia de bloques
    lea di, [di.bloques]
    lea si, [si.bloques]

    mov cx, 4h

  loop_copiar_pieza:
    ; Asignación de 'x' (bloque)
    mov al, [di.x]
    mov [si.x], al

    ; Asignación de 'y' (bloque)
    mov al, [di.y]
    mov [si.y], al

    add di, size bloque
    add si, size bloque
    loop loop_copiar_pieza

    ret
  endp

  CALCULAR_SOMBRA proc
    lea ax, [pieza_sombra]; Destino
    push ax
    lea ax, [pieza_curr]; Origen
    push ax

    call copiar_piezas

    pop ax
    pop ax

    mov [pieza_sombra.color], cGrisOscuro

loop_recorrer_sombra:
    lea ax, [pieza_sombra]
    push ax
    call validar_tab_v
    pop ax
    cmp ax, 0h
    je terminar_recorrer_sombra

    lea ax, [pieza_sombra]
    push ax
    call validar_lim_v
    pop ax
    cmp ax, 0h
    je terminar_recorrer_sombra

    inc [pieza_sombra.y]
    loop loop_recorrer_sombra

terminar_recorrer_sombra:
    dec [pieza_sombra.y]
    ret
  endp

  CAMBIAR_NEXT_CURR proc
    ; aux = next
    lea ax, [pieza_aux]
    push ax
    lea ax, [pieza_next]
    push ax
    call copiar_piezas
    pop ax
    pop ax

    ; next = curr
    lea ax, [pieza_next]
    push ax
    lea ax, [pieza_curr]
    push ax
    call copiar_piezas
    pop ax
    pop ax

    ; curr = aux
    lea ax, [pieza_curr]
    push ax
    lea ax, [pieza_aux]
    push ax
    call copiar_piezas
    pop ax
    pop ax

    ; Intercambio de posiciones
    mov al, [pieza_curr.x]
    mov ah, [pieza_curr.y]

    mov bl, [pieza_next.x]
    mov bh, [pieza_next.y]

    mov [pieza_next.x], al
    mov [pieza_next.y], ah

    mov [pieza_curr.x], bl
    mov [pieza_curr.y], bh

    ret

    BAJAR_PIEZA proc
      mov al, [pieza_curr.color]
      mov tab_aux, al

      lea ax, [pieza_curr]
      push ax
      lea ax, [pieza_sombra]
      push ax
      call copiar_piezas
      pop ax
      pop ax

      mov al, tab_aux
      mov [pieza_curr.color], al
      ret
    endp
  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;FIN PROCEDIMIENTOS;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  end inicio      ;fin de etiqueta inicio, fin de programa
