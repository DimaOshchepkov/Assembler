.MODEL SMALL
.STACK 100h

.DATA
    prompt_message DB 'Enter a string: $'
    enter_sumbol DB 'Enter a symbol: $'
    char DB '$'
    input_buffer DB 255 DUP ('$') ; буфер для хранения введенной строки
    buffer_size equ 255 ; новый размер буфера
    line DB 0DH, 0AH, '$'    ; перенос строки для вывода
    output_buffer DB 5 DUP ('$')

.CODE

; Процедура для вывода строки
; в dx должен быть адрес выводимой строки!!!
DisplayString PROC
    MOV AH, 09h           ; функция вывода строки
    ;LEA DX, prompt_message ; загрузка адреса строки в DX
    INT 21h               ; вызов прерывания 21h для вывода строки
    RET
DisplayString ENDP

; Считывает в переменню char
ReadChar PROC
    MOV AH, 01h           ; функция для чтения символа с клавиатуры
    INT 21h               ; вызов прерывания 21h для ввода символа
    MOV char, AL
    CALL NewLine
    RET
ReadChar ENDP

NewLine PROC
    PUSH AX  
    MOV AH, 09h           
    LEA DX, line 
    INT 21h
    POP AX      
    RET
NewLine ENDP

; в DL находится число
PrintSmallNumber PROC

    ADD DL, '0'    ; Преобразуем число в ASCII
    MOV AH, 02h    ; Функция вывода символа
    INT 21h

    RET
PrintSmallNumber ENDP


ReadLetter PROC
read_loopL:
    mov  ah, 0h              ; AH = 0 (функция BIOS для считывания символа без эха)
    int  16h                 ; Прерывание для ввода символа

    cmp al, 0dh
    je input_enter           ; Если ввод завершен (Enter), переходим к input_enter

    cmp al, ' '
    je prints

    cmp al, 08h
    je read_loopL

    cmp  al, 'A'             
    jl   check_didits          ; Если меньше 'A', переходим к read_loopL  
    cmp  al, 'Z'             
    jg   check_lower_case    ; Если больше 'Z', проверяем нижний регистр
    jmp prints               ; Если в пределах 'A-Z', выводим символ и переходим к концу


check_didits:
    cmp al, '0'
    jl read_loopL             ; Если меньше '0', переходим к read_loopL
    cmp al, '9'
    jg read_loopL             ; Если больше '9', переходим к read_loopL
    jmp prints                ; Если в пределах '0-9', выводим символ и переходим к концу

check_lower_case:
    cmp al, 'a'
    jl read_loopL             ; Если меньше 'a', переходим к read_loopL
    cmp al, 'z'
    jg read_loopL             ; Если больше 'z', переходим к read_loopL
    jmp prints                ; Если в пределах 'a-z', выводим символ и переходим к концу

input_enter:
    call NewLine
    jmp endL

prints:
    mov  ah, 2h              ; AH = 2 (функция BIOS для вывода символа)
    mov  dl, al              ; Загрузка символа для вывода
    int  21h                 ; Вызов прерывания для вывода символа
    jmp endL

endL:
    RET
ReadLetter ENDP

; Процедура для считывания строки
; Использует si, cx, ax, dx
; Считывает в input_buffer
ReadString PROC
    lea si, input_buffer ; указатель на начало буфера
    mov cx, buffer_size ; счетчик для ограничения ввода

read_loop:
    CALL ReadLetter

    cmp al, 0dh
    je end_input

    mov [si], al ; сохраняем символ в буфере
    inc si ; увеличиваем указатель на следующий символ

    cmp si, cx
    je end_overflow_buffer

    loop read_loop ; продолжаем цикл ввода
  

end_overflow_buffer:
    CALL NewLine
    jmp end_input

end_input:
    RET

ReadString ENDP

; в SI находится указатель на начало строки
; в конце строки находится $
; в AL находится символ поиска
; на выходе в DL находится кол-во вхождений
CountCharInString PROC
    XOR DL, DL ; Сброс счетчика

count_loop:
    CMP BYTE PTR [SI], '$' ; Проверка на конец строки
    JE exit_loop ; Если достигнут конец строки, выходим из цикла

    CMP BYTE PTR [SI], AL ; Сравнение текущего символа с символом для подсчета
    JE found_char ; Если символы совпадают, увеличиваем счетчик

    INC SI ; Переход к следующему символу
    LOOP count_loop ; Продолжаем цикл

found_char:
    INC DL ; Увеличение счетчика вхождений
    INC SI ; Переход к следующему символу
    LOOP count_loop ; Продолжаем цикл, если не достигли конца строки

exit_loop:
    RET

CountCharInString ENDP

CONVERT_TOSTRING_LARGE_NUMBER PROC
;Процедура преобразования слова в строку в десятичном виде (без знака)
; AX - слово
; DI - буфер для строки (5 символов). Значение регистра не сохраняется.
word_to_udec_str:
    push ax
    push cx
    push dx
    push bx
    xor cx,cx               ;Обнуление CX
    mov bx,10               ;В BX делитель (10 для десятичной системы)
 
wtuds_lp1:                  ;Цикл получения остатков от деления
    xor dx,dx               ;Обнуление старшей части двойного слова
    div bx                  ;Деление AX=(DX:AX)/BX, остаток в DX
    add dl,'0'              ;Преобразование остатка в код символа
    push dx                 ;Сохранение в стеке
    inc cx                  ;Увеличение счетчика символов
    test ax,ax              ;Проверка AX
    jnz wtuds_lp1           ;Переход к началу цикла, если частное не 0.
 
wtuds_lp2:                  ;Цикл извлечения символов из стека
    pop dx                  ;Восстановление символа из стека
    mov [di],dl             ;Сохранение символа в буфере
    inc di                  ;Инкремент адреса буфера
    loop wtuds_lp2          ;Команда цикла
 
    pop bx
    pop dx
    pop cx
    pop ax
    ret

CONVERT_TOSTRING_LARGE_NUMBER ENDP

START:
    MOV AX, @DATA
    MOV DS, AX

    LEA DX, prompt_message
    CALL DisplayString   ; вызов процедуры для вывода приглашения
    CALL ReadString      ; вызов процедуры для считывания строки

    LEA DX, enter_sumbol
    CALL DisplayString

    CALL ReadLetter
    CALL NewLine
    LEA SI, input_buffer
    CALL CountCharInString


    XOR AX, AX
    MOV AL, DL
    LEA DI, output_buffer
    CALL CONVERT_TOSTRING_LARGE_NUMBER

    LEA DX, output_buffer
    CALL DisplayString

    MOV AH, 4Ch          ; функция завершения программы
    INT 21h              ; вызов прерывания 21h
END START

