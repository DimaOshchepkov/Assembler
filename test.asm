.MODEL SMALL
.STACK 100h

.DATA
    prompt_message DB 'Enter a string: $'
    enter_sumbol DB 'Enter a sumbol: $'
    char DB '$'
    input_buffer DB 255 DUP ('$') ; буфер для хранения введенной строки
    line DB 0DH, 0AH, '$'    ; перенос строки для вывода

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
    MOV AH, 09h           
    LEA DX, line 
    INT 21h               
    RET
NewLine ENDP

; в DL находится число
PrintSmallNumber PROC

    ADD DL, '0'    ; Преобразуем число в ASCII
    MOV AH, 02h    ; Функция вывода символа
    INT 21h

    RET
PrintSmallNumber ENDP

; Процедура для считывания строки
; Считывает в input_buffer
ReadString PROC
    MOV AH, 0Ah          ; функция для чтения строки
    LEA DX, input_buffer ; загрузка адреса буфера
    INT 21h              ; вызов прерывания 21h для чтения строки
    CALL NewLine
    RET
ReadString ENDP

; в SI находится указатель на начало строки
; в конце строки находится $
; в AL находится символ поиска
; на выходе в DI находится кол-во вхождений
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

START:
    MOV AX, @DATA
    MOV DS, AX

    LEA DX, prompt_message
    CALL DisplayString   ; вызов процедуры для вывода приглашения
    CALL ReadString      ; вызов процедуры для считывания строки

    LEA DX, enter_sumbol
    CALL DisplayString
    CALL ReadChar

    LEA SI, input_buffer + 1
    MOV AL, char
    CALL CountCharInString

    ; в DL нужное число
    CALL PrintSmallNumber

    MOV AH, 4Ch          ; функция завершения программы
    INT 21h              ; вызов прерывания 21h
END START