include emu8086.inc
.MODEL SMALL
.DATA   
        SIZE EQU 10                
        HEAD DB '________________Security lock________________','$'  
        OPTION DB "A. CREATE ACCOUNT    B. LOGIN $"
        MSG1 DB 13, 10, 'Enter your ID:$'
        MSG2 DB 13, 10, 'Enter your Password:$'
        MSG3 DB 13, 10, 'ERROR ID not Found!$'
        MSG4 DB 13, 10, 'Wrong ID or Password! Access denied$'
        MSG5 DB 13, 10, 'Correct! Welcome!$'
        MSG7 DB 13, 10, 'Too many failed attempts. Access denied!$'
        MSG8 DB 13, 10, 'Attempts left: $'
        MSG9 DB 13, 10, 'Create new ID and Password OR Login (A/B): $'
        
        PROMPT1 DB 'New ID: $'            
        PROMPT2 DB 'New Password: $'              
        msg db 'Created! $'
        PROMPT3 DB 13, 10, 'Enter your ID:$'   
        PROMPT4 DB 13, 10, 'Enter your Password:$' 
       
    
        BUFFER1 DB 50                                        
                DB ?                                          
                DB 50 DUP('$')                               
        BUFFER2 DB 50                                         
                DB ?                                          
                DB 50 DUP('$')                                
        BUFFER3 DB 50                                         
                DB ?                                          
                DB 50 DUP('$')                                
        BUFFER4 DB 50                                         
                DB ?                                        
                DB 50 DUP('$')
  
        TEMP_ID DW 1 DUP(?),0
        TEMP_Pass DB 1 DUP(?)
        IDSize = $-TEMP_ID
        PassSize = $-TEMP_Pass

        ;IDs and passwords 
        ;password db 30 dup('$') ; 30 characters buffer
        ID  DW        'A1', 'B2', 'C3', 'D4', 'D111', 'E500', 'F432', 'EC12', '5321', '9876' 
        Password DB   123, 234, 31, 46, 73, 102, 112, 131, 12, 14 
        ATTEMPTS_LEFT DB 3  ; Counter for login attempts
        PASS_ATTEMPTS_LEFT DB 3 ; Password attempt counter
        prompt db "Enter password: $" 
        ;Password strong or weak check
        strong_msg db 0Dh, 0Ah, "Password is STRONG!$"
        weak_msg db 0Dh, 0Ah, "Password is WEAK!$"
        newline db 0Dh, 0Ah, '$'
        flags db 4 dup(0)
        

.CODE
MAIN        PROC
            MOV AX, @DATA  
            MOV DS, AX 
           

Title:      LEA DX, HEAD
            MOV AH, 09H
            INT 21H
START:
            mov dx, 0Ah
            mov ah,2
            int 21h
            mov dx, 0Dh
            mov ah,2
            int 21h 
            
            LEA DX, OPTION
            MOV AH,09H
            INT 21H
            LEA DX, MSG9         ; create a new ID
            MOV AH, 09H
            INT 21H
            CALL scan_char      ; Accept response

            ; If 'A', create new ID and password
            CMP AL, 'A'
          
            JE CREATE_NEW_ID_PASS

            JMP LOGIN_LOOP   ; Retry ID input
            
LOGIN_LOOP: 
            LEA DX, MSG1
            MOV AH, 09H
            INT 21H
            
ID_INPUT:   MOV BX, 0
            LEA DI, TEMP_ID
            MOV DX, IDSize
            CALL get_string
            CALL check_id_exists ; Check if ID exists

            ; If ID exists
            CMP AL, 1
            JE PASS_PROMPT

            LEA DX, MSG3         ; ID not found
            MOV AH, 09H
            INT 21H
            LEA DX, MSG9         ; Ask if they want to create a new ID
            MOV AH, 09H
            INT 21H
            CALL scan_char      ; Accept response

            ; If 'A', create new ID and password
            CMP AL, 'A'
            JE CREATE_NEW_ID_PASS

            JMP LOGIN_LOOP   ; Retry ID input 
            
CREATE_NEW_ID_PASS:
    MOV DX, 0Ah
    MOV AH, 2
    INT 21h
    MOV DX, 0Dh
    MOV AH, 2
    INT 21h
    LEA DX, PROMPT1
    MOV AH, 09H             
    INT 21H

    ; Read the first string
    LEA DX, BUFFER1
    MOV AH, 0AH             
    INT 21H  
    
    MOV DX, 0Ah
    MOV AH, 2
    INT 21h
    MOV DX, 0Dh
    MOV AH, 2
    INT 21h 
    
    ; Second string input
    LEA DX, PROMPT2
    MOV AH, 09H             
    INT 21H

    ; Read the second string
    LEA DX, BUFFER2
    MOV AH, 0AH             
    INT 21H 
    
    JMP STRONG_WEAK_CHECK

CHECK:
    MOV DX, 0Ah
    MOV AH, 2
    INT 21h
    MOV DX, 0Dh
    MOV AH, 2
    INT 21h    
    LEA DX, MSG
    MOV AH, 09H
    INT 21h

    ;  re-entry first string 
    LEA DX, PROMPT3
    MOV AH, 09H             
    INT 21H

    
    LEA DX, BUFFER3
    MOV AH, 0AH             
    INT 21H
    
    ; re-entry second string
    LEA DX, PROMPT4
    MOV AH, 09H             
    INT 21H

    
    MOV CX, 0              
    LEA DI, BUFFER4 + 2 
        
INPUT_PASSWORD:
    MOV AH, 07H             
    INT 21H
    CMP AL, 0Dh            
    JE END_PASSWORD_INPUT   

    
    MOV [DI], AL
    INC DI                  
    INC CX                  

    
    MOV DL, 'x'             
    MOV AH, 02H             
    INT 21H

    JMP INPUT_PASSWORD      ; Loop to get the next character

END_PASSWORD_INPUT:
    MOV [BUFFER4 + 1], CL   
    MOV [DI], 24h  
    
  
    MOV AL, [BUFFER1 + 1]  
    MOV BL, [BUFFER3 + 1]   
    CMP AL, BL              
    JNE STRINGS_NOT_MATCH   

    
    LEA SI, BUFFER1 + 2     
    LEA DI, BUFFER3 + 2    
COMPARE_LOOP1:
    MOV AL, [SI]           
    MOV BL, [DI]            
    CMP AL, BL              
    JNE STRINGS_NOT_MATCH 
  
    
    MOV AL, [BUFFER2 + 1]  
    MOV BL, [BUFFER4 + 1]   
    CMP AL, BL             
    JNE STRINGS_NOT_MATCH   

    
    LEA SI, BUFFER2 + 2    
    LEA DI, BUFFER4 + 2    
COMPARE_LOOP2:
    MOV AL, [SI]            
    MOV BL, [DI]            
    CMP AL, BL              
    JNE STRINGS_NOT_MATCH  
    
  
    JMP CORRECT_NEW
    
STRINGS_NOT_MATCH:
            
            DEC PASS_ATTEMPTS_LEFT
            MOV AL, PASS_ATTEMPTS_LEFT
            CMP AL, 0
            JE EXIT_DENIED       ; If no attempts left, deny access

            ; Display remaining attempts
            LEA DX, MSG4
            MOV AH, 09H
            INT 21H

            LEA DX, MSG8         
            MOV AH, 09H
            INT 21H

            MOV AL, PASS_ATTEMPTS_LEFT
            ADD AL, '0'          ; Convert number to ASCII
            MOV DL, AL           
            MOV AH, 02H         
            INT 21H

            JMP CHECK     

PASS_PROMPT:
            MOV AL, 3         ; Reset password attempts to 3
            MOV PASS_ATTEMPTS_LEFT, AL  

PASS_INPUT_LOOP:
            LEA DX, MSG2      ; Prompt for password each time
            MOV AH, 09H
            INT 21H

            CALL scan_num
            CMP CL, 0FH
            
            MOV BH, 00H
            MOV DL, Password[BX]
            CMP CL, DL
            JE CORRECT 
             
            ; Wrong password
            DEC PASS_ATTEMPTS_LEFT
            MOV AL, PASS_ATTEMPTS_LEFT
            CMP AL, 0
            JE EXIT_DENIED       ; If no attempts left, deny access

            ; Display remaining attempts
            LEA DX, MSG4
            MOV AH, 09H
            INT 21H

            LEA DX, MSG8         ; Display remaining attempts
            MOV AH, 09H
            INT 21H

            MOV AL, PASS_ATTEMPTS_LEFT
            ADD AL, '0'          ; Convert number to ASCII
            MOV DL, AL          
            MOV AH, 02H         
            INT 21H

            JMP PASS_INPUT_LOOP  ; Retry password input
            
            
STRONG_WEAK_CHECK:            
    
    lea si, BUFFER2 + 2     
    mov cx, 0              

    
    mov flags, 0            ; Uppercase flag
    mov flags+1, 0          ; Lowercase flag
    mov flags+2, 0          ; Digit flag
    mov flags+3, 0          ; Special character flag

check_loop:
   
    mov al, [si]
    cmp al, 0               
    je evaluate

    ; Check for uppercase letters
    cmp al, 'A'
    jl check_lowercase
    cmp al, 'Z'
    jg check_lowercase
    mov flags, 1            
    jmp next_char

check_lowercase:
    ; Check for lowercase letters
    cmp al, 'a'
    jl check_digit
    cmp al, 'z'
    jg check_digit
    mov flags+1, 1         
    jmp next_char

check_digit:
    ; Check for digits
    cmp al, '0'
    jl check_special
    cmp al, '9'
    jg check_special
    mov flags+2, 1          
    jmp next_char

check_special:
    ; Check for common special characters
    cmp al, '!' 
    je set_special
    cmp al, '@'
    je set_special
    cmp al, '#'
    je set_special
    cmp al, '$'
    je set_special
    cmp al, '%'
    je set_special
    cmp al, '^'
    je set_special
    cmp al, '&'
    je set_special
    cmp al, '*'
    je set_special
    cmp al, '('
    je set_special
    cmp al, ')'
    je set_special
    jmp next_char

set_special:
    mov flags+3, 1          
    jmp next_char

next_char:
    
    inc si
    inc cx
    jmp check_loop

evaluate:
    ; Check all flags for strength
    mov al, flags     ; Check uppercase
    and al, flags+1  ; Check lowercase
    and al, flags+2   ; Check digit
    and al, flags+3  ; Check special
    cmp al, 1     ; All flags set
    jne weak_password

strong_password:
    ; Output strong password message
    lea dx, strong_msg
    mov ah, 09h
    int 21h 
    jmp CHECK

weak_password:
    ; Output weak password message
    lea dx, weak_msg
    mov ah, 09h
    int 21h
    jmp CREATE_NEW_ID_PASS   
                                 

EXIT_DENIED:
            LEA DX, MSG7
            MOV AH, 09H
            INT 21H
            JMP Terminate

CORRECT:    
            LEA DX, MSG5
            MOV AH, 09H
            INT 21H 
            
            JMP Terminate
            
CORRECT_NEW:
            LEA DX, MSG5
            MOV AH, 09H
            INT 21H 
            
            JMP Terminate



DEFINE_SCAN_NUM
DEFINE_GET_STRING

; read a single character input
scan_char PROC
    MOV AH, 01H         
    INT 21H             
    RET
scan_char ENDP

; check if ID exists
check_id_exists PROC
    MOV BX, 0
    MOV SI, 0
    MOV AL, 0

CHECK_ID_LOOP:
    MOV AX, ID[SI] 
    MOV DX, TEMP_ID
    CMP DX, AX
    JE ID_FOUND

    INC BX
    ADD SI, 4
    CMP BX, SIZE
    JB CHECK_ID_LOOP
    RET

ID_FOUND:
    MOV AL, 1  ; ID exists
    RET

check_id_exists ENDP

Terminate:        
END MAIN  

