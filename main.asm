; Estructura y Programación de Computadoras
; Proyecto Final
; Equipo 1
; * García Lemus, Rocío
; * Ríos Lira, Gamaliel
; * Vélez Grande, Cinthya

title "Proyecto: Tetris"
  .model small
  .386        ; Versión del procesador
  .stack 512  ; Tamaño del segmento de "stack"
  .data       ; Inicio del segmento de datos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Definición de tipos de dato
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Cada uno de los bloques individuales de una pieza
BLOQUE struc
  x     db  ? ; Posición 'x' relativa al origen
  y     db  ? ; Posición 'y' relativa al origen
ends

; Describe una pieza con sus respectivos bloques
PIEZA struc
  x     db  ? ; Posición 'x' con respecto al tablero
  y     db  ? ; Posición 'y' con respecto al tablero
  color db  ? ; Color de la pieza
  bloques BLOQUE 4 dup(?) ; Los cuatro bloques de la pieza
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

; Valores para delimitar el área de juego
lim_superior      equ    1
lim_inferior      equ    23
lim_izquierdo     equ    1
lim_derecho       equ    10

; Indica cuántas veces se lee el teclado mientras la pieza avanza un cuadro
update_rate       equ   5

; Indica el número de líneas que se tienen que completar para subir un nivel
lines_per_level   equ   4

; Valores de referencia para la posición inicial de la primera pieza
ini_columna       equ   lim_derecho/2
ini_renglon       equ   -1

; Valores para la posición de los controles e indicadores dentro del juego
; Next
next_col          equ    lim_derecho+7
next_ren          equ    6

; Data
hiscore_ren       equ   10
hiscore_col       equ   lim_derecho+7
level_ren         equ   12
level_col         equ   lim_derecho+7
lines_ren         equ   14
lines_col         equ   lim_derecho+7

; Mensaje de fin de juego
perdiste_ren      equ   14
perdiste_col      equ   (lim_derecho+lim_izquierdo)/2-(finPerdisteStr-perdisteStr)/2+1

; Botón STOP
stop_col          equ   lim_derecho+15
stop_ren          equ   lim_inferior-4
stop_izq          equ   stop_col
stop_der          equ   stop_col+2
stop_sup          equ   stop_ren
stop_inf          equ   stop_ren+2

; Botón PAUSE
pause_col         equ   lim_derecho+25
pause_ren         equ   lim_inferior-4
pause_izq         equ   pause_col
pause_der         equ   pause_col+2
pause_sup         equ   pause_ren
pause_inf         equ   pause_ren+2

; Botón PLAY
play_col          equ   lim_derecho+35
play_ren          equ   lim_inferior-4
play_izq          equ   play_col
play_der          equ   play_col+2
play_sup          equ   play_ren
play_inf          equ   play_ren+2

; Piezas
linea             equ   0
cuadro            equ   1
lnormal           equ   2
linvertida        equ   3
tnormal           equ   4
snormal           equ   5
sinvertida        equ   6

; Status
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
perdisteStr       db    "PERDISTE"
finPerdisteStr    db    ""
blank             db    "     "
lines_score       dw    0
hiscore           dw    0
wait_time         dw    ?
level             dw    1
update_aux        dw    ?

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

; Variable auxiliar para convertir números a cadena
diez              dw    10

; Mensaje para cuando el driver del mouse no esté disponible
no_mouse          db     'No se encuentra driver de mouse. Presione [enter] para salir$'

; Nombre del archivo de puntajes
scores_filename   db     'scores.txt', 0
scores_handle     dw     0
score_read        dw     ?

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
  mov   ax,1  ;opcion 0001h
  int   33h   ;int 33h para manejo del mouse. Opcion AX=0001h
              ;Habilita la visibilidad del cursor del mouse en el programa
endm

; posiciona_cursor_mouse - Establece la posición inicial del cursor del mouse
posiciona_cursor_mouse  macro columna,renglon
  mov   dx, renglon
  mov   cx, columna
  mov   ax, 4    ;opcion 0004h
  int   33h      ;int 33h para manejo del mouse. Opcion AX=0001h
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
  mov ax, 1003h     ;Opción 1003h
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

; lee_teclado - Lee la tecla presionada
;;Z=0 si se presiona una tecla
;;AL retorna con el valor ASCII de la tecla presionada
lee_teclado macro
  mov ah, 01h
  int 16h
endm

; limpia_teclado - Limpia la tecla presionada del buffer
;;AL retorna con el valor ASCII de la tecla en el buffer
limpia_teclado macro
  mov ah, 00h
  int 16h
endm

; comprueba_mouse - Revisa si el driver del mouse existe
comprueba_mouse   macro
  mov ax,0    ; opcion 0
  int 33h     ; llama interrupcion 33h para manejo del mouse, devuelve un valor en AX
              ; Si AX = 0000h, no existe el driver. Si AX = FFFFh, existe driver
endm

; delimita_mouse_h - Delimita la posición del mouse horizontalmente dependiendo los valores 'minimo' y 'maximo'
delimita_mouse_h   macro minimo,maximo
  mov cx,minimo    ;establece el valor mínimo horizontal en CX
  mov dx,maximo    ;establece el valor máximo horizontal en CX
  mov ax,7    ;opcion 7
  int 33h      ;llama interrupcion 33h para manejo del mouse
endm

; generar_aleatorio - Genera un número aleatorio entre 0 y 'max'-1
;; El número generado se almacena en DX
generar_aleatorio macro max
  local fin_generar_aleatorio
  
  ; Se lee el tiempo actual
  mov ah, 00h
  int 1Ah

  ; Obtención del siguiente elemento del arreglo
  lea bx, [rand_seq]
  mov di, [rand_index]
  mov al, [bx + di]
  
  ; Se aplica XOR para dar pseudo-aleatoridad
  xor dl, al

  ; Se calcula el módulo y se almacena en DX
  mov  ax, dx
  xor  dx, dx
  mov  cx, max
  div  cx

  ; Se calcula la siguiente posición del arreglo
  inc rand_index
  mov ax, rand_index
  cmp ax, max_rand_index
  je  fin_generar_aleatorio
  mov rand_index, 0h

  ; Se almacena el valor obtenido en la siguiente posición
  mov di, [rand_index]
  mov [bx + di], dl
fin_generar_aleatorio:
endm

; crear_pieza - Genera nuevos valores para los campos de la 'pieza' proporcionada
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

  ; Se escoge el tipo de pieza
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

  ; Se copia la estructura de las platillas para cada pieza
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

  ; Se genera un color aleatorio (no Gris Oscuro ni Negro)
loop_elegir_color:
  generar_aleatorio 0Fh

  ; Validación de colores
  cmp dl, cGrisOscuro
  je loop_elegir_color

  cmp dl, cNegro
  je loop_elegir_color
  mov [pieza.color], dl

  ; Se asigna una rotación a la pieza
  generar_aleatorio 4h
  
  ; Se gira el número de veces especificadas (0, 1, 2 ó 3)
  lea bx, [pieza]

  mov cx, dx
loop_girar_generada:
  push cx
  push bx ; Paso de parámetro al procedimiento
  call giro_der
  pop bx
  pop  cx
  loop loop_girar_generada

endm

; pausar_programa - Pausa un número específicado de microsegundos el programa
;; t1 - parte alta del tiempo a pausar
;; t2 - parte baja del tiempo a pausar
pausar_programa macro t1, t2
  mov   cx, t1
  mov   dx, t2
  mov   ah, 86h
  int   15h
endm

; obtener_tab_pos - Obtiene el valor de la matriz TAB del renglón 'ren' y la columna 'col'
;; ren - El renglón a buscar
;; col - La columna a buscar
; El valor se retorna en el registro AL
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

  mov al, [bx+di] ; Deplazamiento = (ren*lim_derecho - 1) + col - 1

  pop di
  pop bx
endm

; establecer_tab_pos - Sobreescribe el 'valor' de la matriz TAB en el renglón 'ren' y la columna 'col'
;; ren - El renglón a modificar
;; col - La columna a modificar
;; valor - El valor a sobreescribir
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
  mov [bx+di], dl ; Deplazamiento = (ren*lim_derecho - 1) + col - 1

  pop dx
  pop di
  pop bx
  pop ax
endm

;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;Fin Macros;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;

  .code
inicio:             ; etiqueta inicio
  inicializa_ds_es

  comprueba_mouse   ; macro para revisar driver de mouse
  xor ax, 0FFFFh    ; compara el valor de AX con FFFFh, si el resultado es zero, entonces existe el driver de mouse
  jz imprime_ui     ; Si existe el driver del mouse, entonces salta a 'imprime_ui'
  ; Si no existe el driver del mouse entonces se muestra un mensaje
  lea dx, [no_mouse]
  mov ax, 0900h    ; opcion 9 para interrupcion 21h
  int 21h          ; interrupcion 21h. Imprime cadena.
  jmp salir_enter  ; salta a 'salir_enter'

imprime_ui:
  clear                 ;limpia pantalla
  oculta_cursor_teclado ;oculta cursor del mouse
  apaga_cursor_parpadeo ;Deshabilita parpadeo del cursor
  call DIBUJA_UI        ;procedimiento que dibuja marco de la interfaz de usuario
  muestra_cursor_mouse  ;hace visible el cursor del mouse
  posiciona_cursor_mouse 320d,16d  ;establece la posición del mouse

;Revisar que el boton izquierdo del mouse no esté presionado
;Si el botón está suelto, continúa a la sección "mouse"
;si no, se mantiene indefinidamente en "mouse_no_clic" hasta que se suelte
ciclo_juego: ; Ciclo principal del juego
  cmp [status], paro  ; No hacer nada si está el estado de paro
  je mouse            ; Leer mouse
  cmp [status], pausa ; No hacer nada si está el estado de pausa
  je mouse            ; Leer mouse

  ; Marcar líneas a eliminar (si hay)
  push 0h
  call marcar_lineas
  pop ax

  cmp ax, 0h
  je no_eliminar_lineas   ; Si no se eliminan líneas omitir las siguientes instrucciones
  call imprime_lines      ; Actualizar el marcador de líneas
  call dibujar_lineas_marcadas  ; Dibujar las líneas a eliminar (blancas)
  call limpiar_lineas     ; Eliminar las líneas marcadas de la matriz
  pausar_programa 1h, 0000h ; Animar el tablero
  call dibujar_tab        ; Volver a dibujar el tablero
  call actualizar_level   ; Recaulcular el nuevo nivel

no_eliminar_lineas:
  call calcular_sombra ; Recalcular la sombra de la pieza
  call dibuja_sombra   ; Dibujar la sombra de la pieza
  call dibuja_actual   ; Dibujar la pieza actual

  pausar_programa 0h, [wait_time] ; Pausar el programa un número determinado de microsegundos (aumenta/disminuye velocidad del juego)
  call  borra_actual  ; Borra la  pieza actual
  call  borra_sombra  ; Borra la sombra de la pieza

  cmp [update_aux], 0 ; Cantidad de teclas por iteración
  jg continuar_juego

  ; Desplaza la pieza hacia abajo
  inc [pieza_curr.y]

  lea ax, [pieza_curr]
  push ax ; Parámetro para el procedimiento
  call validar_lim_v ; Valida que no haya llegado hasta abajo
  pop ax

  cmp ax, 0h
  je revertir_avance_v ; Si hay choque

  lea ax, [pieza_curr]
  push ax ; Parámetro para el procedimiento
  call validar_tab_v ; Valida que no haya chocado con ninguna pieza
  pop ax
  mov [update_aux], update_rate+1

  cmp ax, 0h
  jne continuar_juego ; Si no hay choque

; Si se detectó una colisión vertical
revertir_avance_v:
  call detectar_final ; Se verifica si se ha perdido

  cmp ax, 1
  jne continuar_revertir_avance_v ; Si no se ha perdido
  mov [status], paro
  call imprime_perdiste

; Retroceder si hay colisión
continuar_revertir_avance_v:
  dec [pieza_curr.y]
  call dibuja_actual

  lea ax, [pieza_curr]
  push ax
  call agregar_pieza_tab
  pop ax
  
; Asignar nueva pieza
asignar_nueva_pieza:
  lea ax, [pieza_curr]
  push ax
  lea ax, [pieza_next]
  push ax
  call copiar_piezas ; Actual = Next
  pop ax
  pop ax

  ; Creación de nueva pieza
  call borra_next
  crear_pieza pieza_next
  call  dibuja_next

continuar_juego:
  dec [update_aux]
  lee_mouse ; Leer mouse

  ; Procesar mouse
  cmp bx, 01h
  je  mouse

  lee_teclado ; Leer teclado
  
  ; Procesar teclado
  jnz teclado
  jmp ciclo_juego

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
  jz ciclo_juego       ;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Aqui va la lógica de la posicion del mouse;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Si el mouse fue presionado en el renglon 0
  ;se va a revisar si fue dentro del boton [X]
  
  ; Verificar si se presiona la tecla 'x'
  cmp dx,0
  je boton_x

  ; Verificar si se presiona algún botón (pause, stop, play)
  cmp dx,lim_inferior-4
  je boton_play
  cmp dx,lim_inferior-3
  je boton_play
  cmp dx,lim_inferior-2
  je boton_play
  jmp ciclo_juego

; Procesar botón 'x'
boton_x:
  jmp boton_x1
;Lógica para revisar si el mouse fue presionado en [X]
;[X] se encuentra en renglon 0 y entre columnas 76 y 78
boton_x1:
  cmp cx,76
  jge boton_x2
  jmp ciclo_juego
boton_x2:
  cmp cx,78
  jbe boton_x3
  jmp ciclo_juego
boton_x3:
  ;Se cumplieron todas las condiciones
  jmp salir
  jmp ciclo_juego

; Procesar botón 'PLAY'
boton_play:
  jmp boton_play1
boton_play1:
  cmp cx,play_izq
  jge boton_play2
  jmp boton_pause
boton_play2:
  cmp cx,play_der
  jle boton_play3
  jmp boton_pause
boton_play3:
  ;Se cumplieron todas las condiciones
  mov [status], activo
  jmp ciclo_juego

; Procesar botón 'PAUSE'
boton_pause:
  jmp boton_pause1
boton_pause1:
  cmp cx,pause_izq
  jge boton_pause2
  jmp boton_stop
boton_pause2:
  cmp cx,pause_der
  jle boton_pause3
  jmp boton_stop
boton_pause3:
  ;Se cumplieron todas las condiciones
  mov [status], pausa
  jmp ciclo_juego

; Procesar botón 'STOP'
boton_stop:
  jmp boton_stop1
boton_stop1:
  cmp cx,stop_izq
  jge boton_stop2
  jmp ciclo_juego
boton_stop2:
  cmp cx,stop_der
  jle boton_stop3
  jmp ciclo_juego
boton_stop3:
  ;Se cumplieron todas las condiciones
  mov [status], paro
  jmp imprime_ui
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Aqui va la lógica de las teclas presionadas
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
teclado:
  lee_teclado

  ; Detección de teclas
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
  jmp continuar_teclado

; Traslación a la izquierda
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
  jne continuar_teclado

mov_izq_inv:
  ; Si la posición es incorrecta, revertir el movimiento
  inc pieza_curr.x
  jmp continuar_teclado

; Traslación a la derecha
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
  jne continuar_teclado

mov_der_inv:
  ; Si la posición es incorrecta, revertir el movimiento
  dec pieza_curr.x
  jmp continuar_teclado

; Giro a la izquierda
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
  jne continuar_teclado

giro_izq_inv:
  ; Si la posición es incorrecta, revertir el movimiento
  lea ax, [pieza_curr]
  push ax
  call giro_der
  pop ax
  jmp continuar_teclado

; Giro a la derecha
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
  jne continuar_teclado

giro_der_inv:
  ; Si la posición es incorrecta, revertir el movimiento
  lea ax, [pieza_curr]
  push ax
  call giro_izq
  pop ax
  jmp continuar_teclado

; Cambio de 'pieza actual' con 'pieza siguiente'
procesar_cambio_pieza:
  call borra_next
  call borra_actual
  call borra_sombra
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
  jmp continuar_teclado

; Bajar la pieza rápidamente
procesar_bajar_rapido:
 call bajar_pieza
 mov [update_aux], 0

continuar_teclado:
  limpia_teclado
  jmp ciclo_juego

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

; dibuja_ui - dibuja todo el tablero del juego para una nueva partida
dibuja_ui proc
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
    call imprime_textos
    call imprime_botones
    call imprime_datos_iniciales
    ret
  endp

  ; imprime_textos - Imprime las etiquetas "NEXT", "LEVEL", "LINES" y "HI-SCORE"
  imprime_textos proc
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

  ; imprime_perdiste - Imprime la leyenda "PERDISTE"
  imprime_perdiste proc
    ;Imprime cadena "PERDISTE"
    posiciona_cursor perdiste_ren,perdiste_col
    imprime_cadena_color perdisteStr,finPerdisteStr-perdisteStr,cRojo,bgBlanco
    ret
  endp

  ; imprime_botones - Dibuja los tres botones para controlar el juego (stop, pause, play)
  imprime_botones proc
    ;Botón STOP
    mov [boton_caracter],219d
    mov [boton_color],bgAmarillo
    mov [boton_renglon],stop_ren
    mov [boton_columna],stop_col
    call imprime_boton

    ;Botón PAUSE
    mov [boton_caracter],186d
    mov [boton_color],bgAmarillo
    mov [boton_renglon],pause_ren
    mov [boton_columna],pause_col
    call imprime_boton

    ;Botón PLAY
    mov [boton_caracter],16d
    mov [boton_color],bgAmarillo
    mov [boton_renglon],play_ren
    mov [boton_columna],play_col
    call imprime_boton
    ret
  endp

  ; imprime_scores - Imprime el número de líneas, hi-score y level en el tablero
  imprime_scores proc
    call imprime_lines
    call imprime_hiscore
    call imprime_level
    ret
  endp

  ; imprime_lines - Imprime el número de líneas
  imprime_lines proc
    mov [ren_aux],lines_ren
    mov [col_aux],lines_col+20
    mov bx,[lines_score]
    call imprime_bx
    ret
  endp

  ; imprime_hiscore - Imprime el hi-score
  imprime_hiscore proc
    mov [ren_aux],hiscore_ren
    mov [col_aux],hiscore_col+20
    mov bx,[hiscore]
    call imprime_bx
    ret
  endp

  ; imprime_level - Imprime el level
  imprime_level proc
    mov [ren_aux],level_ren
    mov [col_aux],level_col+20
    mov bx, [level]
    call imprime_bx
    ret
  endp

  ; imprime_bx - Imprime el valor del registro BX como entero sin signo (positivo)
  ; Se imprime con 5 dígitos (incluyendo ceros a la izquierda)
  ; Se usan divisiones entre 10 para obtener dígito por dígito en un LOOP 5 veces (una por cada dígito)
  imprime_bx proc
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

  ; imprime_datos_iniciales - Inicializa e imprime los datos iniciales del juego
  imprime_datos_iniciales proc
    call datos_iniciales     ;inicializa variables de juego
    call imprime_scores
    call dibuja_next
    call dibuja_actual
    ret
  endp

  ; datos iniciales - Inicializa variables del juego para un juego nuevo
  datos_iniciales proc
    mov [lines_score],0
    mov [update_aux], update_rate
    mov [wait_time], 0FFFFh
    mov [level], 1h
    crear_pieza pieza_curr
    crear_pieza pieza_next
    call leer_highscore
    call inicializar_tab
    ;agregar otras variables necesarias
    ret
  endp

  ; imprime_boton - Dibuja un boton que abarca 3 renglones y 5 columnas
  ; con un caracter centrado dentro del boton
  ; en la posición que se especifique (esquina superior izquierda)
  ; y de un color especificado
  ; Utiliza paso de parametros por variables globales
  ; Las variables utilizadas son:
  ; boton_caracter: debe contener el caracter que va a mostrar el boton
  ; boton_renglon: contiene la posicion del renglon en donde inicia el boton
  ; boton_columna: contiene la posicion de la columna en donde inicia el boton
  ; boton_color: contiene el color del boton
  imprime_boton proc
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
  ; Como parámetros se utilizan:
  ; col_aux y ren_aux: Toma como referencia los valores establecidos en ren_aux y en col_aux
  ; esas coordenadas son la referencia (esquina superior izquierda) de una matriz 4x4
  ; si - apuntador al arreglo de renglones en donde se van a guardar esas posiciones
  ; di - apuntador al arreglo de columnas en donde se van a guardar esas posiciones
  ; si y di están parametrizados porque se puede dibujar la pieza actual o la pieza next
  ; Se calculan las posiciones y se almacenan en los arreglos correspondientes
  ; posteriormente se llama al procedimiento DIBUJA_PIEZA que hace uso de esas posiciones para imprimir la pieza en pantalla


  ; dibuja_pieza - procedimiento para imprimir una pieza en pantalla
  ;Como parámetros recibe:
  ; si - apuntador al arreglo de renglones
  ; di - apuntador al arreglo de columnas
  dibuja_pieza PROC
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

  ; dibuja_next - se usa para imprimir la pieza siguiente en pantalla
  ; Primero se debe calcular qué pieza se va a dibujar
  ; Dentro del procedimiento se utilizan variables referentes a la pieza siguiente
  dibuja_next proc
    lea si, pieza_next
    lea di, pieza_next.bloques
    mov [col_aux], next_col+10
    mov [ren_aux], next_ren-1

    call dibuja_pieza

    ret
  endp

  ; dibuja_actual - se usa para imprimir la pieza actual en pantalla
  ; Primero se debe calcular qué pieza se va a dibujar
  ; Dentro del procedimiento se utilizan variables referentes a la pieza actual
  dibuja_actual proc
    lea si, pieza_curr
    lea di, [pieza_curr.bloques]
    mov al, [pieza_curr.x]
    mov ah, [pieza_curr.y]
    mov [col_aux], al
    mov [ren_aux], ah

    call dibuja_pieza
    ret
  endp

  ; dibuja_sombra - se usa para imprimir la sombra de la pieza actual en pantalla
  ; Primero se debe calcular qué pieza se va a dibujar
  ; Dentro del procedimiento se utilizan variables referentes a la sombra de la pieza
  dibuja_sombra proc
    lea si, pieza_sombra
    lea di, [pieza_sombra.bloques]
    mov al, [pieza_sombra.x]
    mov ah, [pieza_sombra.y]
    mov [col_aux], al
    mov [ren_aux], ah

    call dibuja_pieza
    ret
  endp

  ; borra_actual - Borra la pieza actual colocando espacios en blanco en los luegares donde se encuentran sus bloques
  borra_actual proc
    lea si, pieza_curr
    lea di, [pieza_curr.bloques]
    mov al, [pieza_curr.x]
    mov ah, [pieza_curr.y]
    mov [col_aux], al
    mov [ren_aux], ah

    call borra_pieza
    ret
  endp

  ; borra_sombra - Borra la sombra de la pieza actual colocando espacios en blanco en los luegares donde se encuentran sus bloques
  borra_sombra proc
    lea si, pieza_sombra
    lea di, [pieza_sombra.bloques]
    mov al, [pieza_sombra.x]
    mov ah, [pieza_sombra.y]
    mov [col_aux], al
    mov [ren_aux], ah

    call borra_pieza
    ret
  endp

  ; borra_next - Borra la pieza siguiente colocando espacios en blanco en los luegares donde se encuentran sus bloques
  borra_next proc
    lea si, pieza_next
    lea di, pieza_next.bloques
    mov [col_aux], next_col+10
    mov [ren_aux], next_ren-1

    call borra_pieza

    ret
  endp

  ; borra_pieza - Borra una pieza colocando espacios en el lugar de sus bloques
  ; Recibe como parámetros:
  ; si: La dirección de la pieza a dibujar
  ; di: La dirección de los bloques de la pieza a dibujar
  borra_pieza proc
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

  ; giro_der - Gira una pieza con respecto a su origen (coordenada {0,0}) aplicando una matriz de rotación para 90°
  ; Recibe como parámetros:
  ; sp+2: Un apuntador a la pieza a girar
  giro_der proc
    mov bp, sp
    mov si, [bp+2]
    lea si, [si.bloques]

    mov cx, 4
  loop_giro_derecha:

    ; x' = -y
    ; y' =  x
    mov al, [si.x]
    mov ah, [si.y]
    not ah

    mov [si.y], al
    mov [si.x], ah

    add si, size bloque
    loop loop_giro_derecha
    ret
  endp

  ; giro_der - Gira una pieza con respecto a su origen (coordenada {0,0}) aplicando una matriz de rotación para -90°
  ; Recibe como parámetros:
  ; sp+2: Un apuntador a la pieza a girar
  giro_izq proc
    mov bp, sp
    mov si, [bp+2]
    lea si, [si.bloques]

    mov cx, 4
  loop_giro_izquierda:

    ; x' =  y
    ; y' = -x
    mov al, [si.x]
    mov ah, [si.y]
    not al

    mov [si.y], al
    mov [si.x], ah

    add si, size bloque
    loop loop_giro_izquierda
    ret
  endp

  ; validar_lim_h - Valida que una pieza no sobresalga del tablero de juego horizontalmente
  ; Recibe como parámetros:
  ; sp+2: Un apuntador a la pieza a validar
  ; Retorna:
  ; sp+2: 1 si no falla, 0 si falla
  validar_lim_h proc
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

  ; validar_lim_v - Valida que una pieza no esté más abajo del tablero
  ; Recibe como parámetros:
  ; sp+2: Un apuntador a la pieza a validar
  ; Retorna:
  ; sp+2: 1 si no falla, 0 si falla
  validar_lim_v proc
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


  ; validar_tab_v - Valida que una pieza no colisione con los bloques del tablero
  ; Recibe como parámetros:
  ; sp+2: Un apuntador a la pieza a validar
  ; Retorna:
  ; sp+2: 1 si no falla, 0 si falla
  validar_tab_v proc
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

  ; agregar_pieza_tab - Agrega una pieza al tablero
  ; Recibe como parámetros:
  ; sp+2: Un apuntador a la pieza a agregar
  agregar_pieza_tab proc
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

  ; marcar_lineas - Busca renglones completos y en caso de encontrarlos, los marca con 0FEh
  ; Retorna:
  ; sp+2: El número de líneas marcadas
  marcar_lineas proc
    mov bp, sp
    mov [conta], 0h

    mov cx, lim_inferior
loop_recorrer_lineas:
    mov ren_aux, cl
    push cx

    mov cx, lim_derecho
loop_recorrer_linea:
    mov col_aux, cl

    obtener_tab_pos ren_aux, col_aux

    cmp al, 0FFh
    je recorrer_siguiente_linea ; Si hay una celda vacía, salta a la siguiente línea

    loop loop_recorrer_linea

    mov cx, lim_derecho
    inc lines_score ; Aumenta el score
    inc [conta] ; Aumenta el contador de líneas detectadas

  ; Marca la línea
loop_marcar_linea:
    mov col_aux, cl
    establecer_tab_pos ren_aux, col_aux, 0FEh
loop loop_marcar_linea

recorrer_siguiente_linea:
    pop cx
    loop loop_recorrer_lineas
    xor ah, ah
    mov al, [conta]
    mov [bp+2], ax
    ret
  endp

  ; dibujar_lineas_marcadas - Dibuja las líneas marcadas con un destello blanco
  dibujar_lineas_marcadas proc
    mov cx, lim_inferior
loop_dibujar_linea_v:
    mov ren_aux, cl
    push cx

    mov cx, lim_derecho
loop_dibujar_linea_h:
    mov col_aux, cl
    obtener_tab_pos ren_aux, col_aux

    cmp al, 0FEh
    jne dibujar_siguiente_linea ; Si no está marcada, continúa

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

  ; dibujar_tab - Redibuja todos los bloques del tablero
  dibujar_tab proc
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
    ; Imprime bloque
    mov tab_aux, al
    posiciona_cursor ren_aux, col_aux
    imprime_caracter_color 254, tab_aux, bgGrisOscuro
    jmp continuar_imprimir
imprime_vacio:
    ; Imprime espacio en blanco
    posiciona_cursor ren_aux, col_aux
    imprime_caracter_color ' ', cNegro, bgNegro
continuar_imprimir:
    pop cx

    loop loop_dibujar_tab_h

    pop cx
    loop loop_dibujar_tab_v
    ret
  endp

  ; limpiar_lineas - Recorre todas las líneas blancas (a lo más 4) hasta el principio de TAB y las elimina
  limpiar_lineas proc
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

  ; copiar_piezas - Copia una pieza de un origen a un destino
  ; Recibe como parámetros:
  ; sp+2: Apuntador a la pieza origen
  ; sp+3: Apuntador a la pieza destino
  copiar_piezas proc
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

  ; calcular_sombra - Partiendo de la pieza actual, crea una copia, la cual hace descender hasta que colisiona. A esta pieza le asigna el color gris oscuro
  calcular_sombra proc
    lea ax, [pieza_sombra]; Destino
    push ax
    lea ax, [pieza_curr]; Origen
    push ax

    call copiar_piezas

    pop ax
    pop ax

    mov [pieza_sombra.color], cGrisOscuro ; Color de la pieza

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

  ; cambiar_next_curr - Intercambia las posiciones de 'pieza_next' y 'pieza_curr' si y sólo si no hay colisiones
  cambiar_next_curr proc
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

    ; bajar_pieza - Intercambia le asigna la posición de la pieza actual a la pieza sombra
    bajar_pieza proc
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

  ; actualiza_level - Vuelve a calcular el nivel del juego tomando en cuenta el número de líneas borradas
  actualizar_level proc
    mov ax, lines_score
    mov bl, lines_per_level
    div bl

    xor ah, ah
    mov [level], ax
    inc [level]

    mov ax, [level]
    cmp ax, [hiscore]
    jle continuar_actualizar_level
    mov hiscore, ax
    call escribir_highscore
    call imprime_hiscore

  continuar_actualizar_level:
    sub wait_time, 05F0h
    call imprime_level
    ret
  endp

  ; detectar_final - Detecta si el juego ha terminado o no
  ; Retorna:
  ; ax: 0 si no ha terminado, 1 si ya terminó
  detectar_final proc
    lea di, [pieza_curr.bloques]

    mov cx, 4 ; Se itera sobre los cuatro bloques de la pieza

    loop_detectar_final:

      mov al, [pieza_curr.y]
      mov bl, [di.y]
      add al, bl
      mov [ren_aux], al

      cmp [ren_aux], 0
      jg continuar_detectar_final
      mov ax, 1
      ret

      continuar_detectar_final:
      add di, size BLOQUE
    loop loop_detectar_final

    mov ax, 0
    ret
  endp

  ; leer_highscore - Carga el puntaje más alto del archivo
  leer_highscore proc
    ; Se abre el archivo
    mov ah,3Dh
		mov al,0   ; 0 - para lectura
		lea dx,[scores_filename]  ; puntero al nombre del archivo
		int 21h
		mov [scores_handle],ax

    ; Se lee contenido del archivo
    mov ah,3Fh
		mov cx,2   ; Se leen 2 [bytes]
		lea dx,[score_read]
		mov bx,[scores_handle]
		int 21h

    mov ax, [score_read]
    mov [hiscore], ax

    ; Se cierra el archivo
    mov ah,3Eh
    mov bx,[scores_handle]
		int 21h
    ret
  endp

  ; escribir_highscore - Sobreescribe el puntaje más alto del archivo
  escribir_highscore proc
    ; Se abre el archivo
    mov ah,3Dh
		mov al,1   ; 1 - para escritura
		lea dx,[scores_filename]  ; apuntador al nombre del archivo
		int 21h
		mov [scores_handle],ax

    ; Se escribe el contenido
    mov ah,40h
		mov bx,[scores_handle] ; pointer to number of bytes read from user.
		mov cx,2   ; Se escriben 2 [bytes]
		lea dx, [hiscore]
		int 21h

    ; Se cierra el archivo
    mov ah,3Eh
    mov bx,[scores_handle]
		int 21h
    ret
  endp

  ; inicializa_tab - Asigna 0FFh a todas las celdas de TAB
  inicializar_tab proc
    lea di, [tablero]

    mov al, 0FFh
    mov cx, lim_derecho * lim_inferior
    loop_inicializar_tab:
      mov [di], al
      add di, 1
    loop loop_inicializar_tab
    ret
  endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;FIN PROCEDIMIENTOS;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  end inicio      ;fin de etiqueta inicio, fin de programa
