ASSUME CS:CODE,DS:DATA,SS:STACK

STACK   SEGMENT
STK     DB      20 DUP(?)
STACK   ENDS

DATA    SEGMENT
SCREEN_WIDTH    DB      17
GAME_WIDTH      DB      15
SLENGTH DB      ?
MARK    DB      ?
FOODX   DB      ?
FOODY   DB      ?
DIRECTION       DB      0
NOWX    DB      ?
NOWY    DB      ?
SNAKEX  DB      255 DUP(?)
SNAKEY  DB      255 DUP(?)
HTAB    DB      '0123456789ABCDEF'
DATA    ENDS

CODE    SEGMENT
START:  CALL    INIT
GAME:
        CALL    INPUT 
        CALL    CLEAN
        CALL    UPDATE
        CALL    DRAW
        CALL    DRAWWORD
        MOV     BL,100
        SUB     BL,SLENGTH
        CALL    SOFTDLY
        JMP     GAME

; CHECKSNAKE
; AL ->0 NO ->1 YES
; DL ->X DH ->Y
CHECKSNAKE      PROC
        
        MOV     CL,SLENGTH
        XOR     CH,CH
        LEA     DI,SNAKEX
        LEA     SI,SNAKEY
EVERYSNAKE:
        MOV     BL,CL
        DEC     BL
        MOV     BH,0
        MOV     AL,[DI+BX]
        CMP     AL,DL
        JNE     NO_SNAKE
        MOV     AL,[SI+BX]
        CMP     AL,DH
        JNE     NO_SNAKE
        MOV     AL,1
        RET
NO_SNAKE:
        MOV     AL,0
        LOOP    EVERYSNAKE
        RET
CHECKSNAKE      ENDP


; DRAW WORD
DRAWWORD        PROC
        CMP     SLENGTH,00H
        JNE     NODEBUG
        INT     3
NODEBUG:
        MOV     AH,2
        MOV     BH,0
        MOV     DH,SCREEN_WIDTH
        INC     DH
        MOV     DL,4
        INT     10H

        MOV     AL,SLENGTH
        MOV     CL,04H
        SHR     AL,CL
        LEA     BX,HTAB
        XLAT

        MOV     AH,9
        MOV     BH,0
        MOV     BL,01
        MOV     CX,1
        INT     10H
       
        MOV     AH,2
        MOV     BH,0
        MOV     DH,SCREEN_WIDTH
        INC     DH
        MOV     DL,5
        INT     10H

        MOV     AL,SLENGTH
        AND     AL,0FH
        LEA     BX,HTAB
        XLAT

        MOV     AH,9
        MOV     BH,0
        MOV     BL,01
        MOV     CX,1
        INT     10H

        RET
DRAWWORD        ENDP

; RANDOM
; AL->RANDOM (1,15)
RANDOM  PROC
RAND:   MOV     AL,GAME_WIDTH
        SUB     AL,1
        XOR     AH,AH
        MOV     DX,41H
        OUT     DX,AX

        IN      AL,DX
        CMP     AL,0
        JE      RAND
        CMP     AL,14
        JA      RAND
        RET
RANDOM  ENDP

; UPDATE FOOD
UPDATEFOOD      PROC
RETRY:
        CALL    RANDOM
        MOV     FOODX,AL
        CALL    RANDOM
        MOV     FOODY,AL
        MOV     CL,SLENGTH
        XOR     CH,CH
        LEA     DI,SNAKEX
        LEA     SI,SNAKEY
        MOV     DL,FOODX
        MOV     DH,FOODY
        CALL    CHECKSNAKE
        CMP     AL,1
        JE      RETRY
        RET
UPDATEFOOD      ENDP

; INIT DATA
INIT    PROC
MOV     AX,DATA
MOV     DS,AX
MOV     AX,STACK
MOV     SS,AX
MOV     SNAKEX,5
MOV     SNAKEY,5

MOV     SLENGTH,1
CALL    UPDATEFOOD
RET
INIT    ENDP

; UPDATE SNKAE 
UPDATE  PROC

        MOV     CL,SLENGTH
        CMP     CL,1
        JE      HEAD
        MOV     CH,0
        
BODY:   MOV     BL,CL
        DEC     BL
        MOV     BH,0
        LEA     SI,SNAKEX
        ADD     SI,BX
        MOV     AH,[SI]
        INC     SI
        MOV     [SI],AH      ;UPDATE X
   
        SUB     BL,1
        LEA     SI,SNAKEY
        ADD     SI,BX
        MOV     AH,[SI]
        INC     SI
        MOV     [SI],AH      ;UPDATE Y                            
        LOOP    BODY

HEAD:   MOV     CL,DIRECTION
        CMP     DIRECTION,0
        JE      SSUP
        CMP     DIRECTION,1
        JE      SSDOWN
        CMP     DIRECTION,2
        JE      SSLEFT
        CMP     DIRECTION,3
        JE      SSRIGHT

EATFOOD:
        MOV     AL,SNAKEX
        CMP     AL,FOODX
        JNE     NOEATFOOD
        MOV     AL,SNAKEY
        CMP     AL,FOODY
        JNE     NOEATFOOD
        ADD     SLENGTH,1
        
EAT:    CALL    UPDATEFOOD
        MOV     AL,SNAKEX
        CMP     AL,FOODX
        JNE     NOEATFOOD
        MOV     AL,SNAKEY
        CMP     AL,FOODY
        JNE     NOEATFOOD
        JMP     EAT

NOEATFOOD:
        RET


SSUP:   JMP     SUP
SSDOWN: JMP     SDOWN
SSLEFT: JMP     SLEFT
SSRIGHT:JMP     SRIGHT


SUP:    MOV     DL,SNAKEX
        MOV     DH,SNAKEY
        DEC     DH
        CMP     DH,0
        JA      NSUPOVER
        MOV     AL,GAME_WIDTH
        ADD     DH,AL
NSUPOVER:
        CALL    CHECKSNAKE

        CMP     AL,1
        JE      EXIT
        SUB     SNAKEY,1
        CMP     SNAKEY,0
        JBE     SUPOVER    
        JMP     EATFOOD
SUPOVER:
        MOV     AL,GAME_WIDTH
        ADD     SNAKEY,AL
        JMP     EATFOOD


SDOWN:  MOV     DL,SNAKEX
        MOV     DH,SNAKEY
        INC     DH
        MOV     AL,GAME_WIDTH
        CMP     DH,AL
        JBE     NSDOWOVER
        SUB     DH,AL
NSDOWOVER:
        CALL    CHECKSNAKE
        CMP     AL,1
        JE      EXIT
        MOV     AL,GAME_WIDTH
        ADD     SNAKEY,1
        CMP     SNAKEY,AL
        JA      SDOWNOVER
        JMP     EATFOOD
SDOWNOVER:
        MOV     AL,GAME_WIDTH
        SUB     SNAKEY,AL
        JMP     EATFOOD

EXIT:   CALL    FINAL

SLEFT:  MOV     DL,SNAKEX
        DEC     DL
        MOV     DH,SNAKEY
        CMP     DH,0
        JA      NSLEFTOVER
        MOV     AL,GAME_WIDTH
        ADD     DL,AL
NSLEFTOVER:
        CALL    CHECKSNAKE
        CMP     AL,1
        JE      EXIT
        SUB     SNAKEX,1
        CMP     SNAKEX,0
        JBE     SLEFTOVER
        JMP     EATFOOD
SLEFTOVER:
        MOV     AL,GAME_WIDTH
        ADD     SNAKEX,AL
        JMP     EATFOOD

SRIGHT: MOV     DL,SNAKEX
        INC     DL
        MOV     DH,SNAKEY
        MOV     AL,GAME_WIDTH
        CMP     DL,AL
        JBE     NSRIGHTOVER
        SUB     DL,GAME_WIDTH
NSRIGHTOVER:
        CALL    CHECKSNAKE
        CMP     AL,1
        JE      EXIT
        MOV     AL,GAME_WIDTH
        ADD     SNAKEX,1
        CMP     SNAKEX,AL
        JA      SRIGHTOVER
        JMP     EATFOOD
SRIGHTOVER:
        SUB     SNAKEX,AL
        JMP     EATFOOD
        
UPDATE  ENDP

; CLEAN ALL SCREEN
CLEAN   PROC        
        MOV     AH,0
        MOV     AL,0DH
        INT     10H
        RET
CLEAN   ENDP

; SOFTDLY
; BL:  (10MS) WANT TO SLEEP
SOFTDLY PROC
DELAY:  MOV     CX,2801
WAIT0:  LOOP    WAIT0
        DEC     BL
        JNZ     DELAY
        RET
SOFTDLY ENDP

; DRAW ALL TO SCREEN
DRAW    PROC
        MOV     NOWX,0
        MOV     NOWY,0
DRAWBEGIN:
        ;DRAW WALL
        MOV     BL,SCREEN_WIDTH 
        SUB     BL,1
        CMP     NOWY,0
        JE      WALL1
        CMP     NOWY,BL
        JE      WALL1
        CMP     NOWX,0
        JE      WALL1
        CMP     NOWX,BL
        JE      WALL1

        ;DRAW SNAKE
        MOV     CL,SLENGTH
        XOR     CH,CH
        ;DL ->NOWX DH ->NOWY
        MOV     DL,NOWX
        MOV     DH,NOWY
        ;SI ->[SNAKEX] DI->[SNAKEY]
        LEA     SI,SNAKEX
        LEA     DI,SNAKEY
        XOR     BH,BH
        JMP     SNAKEP

WALL1:  JMP     WALL

SNAKEP:
        MOV     BL,CL
        DEC     BL
        MOV     AL,[SI+BX] ;get SNAKEX
        CMP     AL,DL
        JNE     NOSNAKE
        MOV     AL,[DI+BX] ;get SNAKEY
        CMP     AL,DH
        JNE     NOSNAKE

        JMP     SNAKE
NOSNAKE:

        LOOP    SNAKEP
        
        ;DRAW FOOD
        MOV     BL,FOODX
        CMP     BL,NOWX
        JNE     NOFOOD
        MOV     BL,FOODY
        CMP     BL,NOWY
        JNE     NOFOOD
        JMP     FOOD
NOFOOD:

NEXT:   MOV     BL,SCREEN_WIDTH
        SUB     BL,1
        INC     NOWX
        CMP     NOWX,BL
        JA      ADDY
        JMP     DRAWBEGIN
ADDY:   INC     NOWY
        MOV     NOWX,0
        CMP     NOWY,BL
        JA      DRAWFINISH
        JMP     DRAWBEGIN

WALL:   MOV     AL,0
        JMP     DRAWPOINT
       
SNAKE:  MOV     AL,1
        JMP     DRAWPOINT

FOOD:   MOV     AL,2
        JMP     DRAWPOINT

DRAWPOINT:
        MOV     BL,NOWX
        MOV     BH,NOWY
        CALL    DRAWONE
        JMP     NEXT

DRAWFINISH:
        RET

DRAW    ENDP

; DRAW ONE BLOCK ON SCREEN
; AL:   THE TYPE TO DRAW 0->WALL 1->SNAKE 2->FOOD
; BL:   X
; BH:   Y
DRAWONE PROC
        MOV     AH,2
        MOV     DH,BH
        MOV     DL,BL
        MOV     BH,0
        INT     10H

        MOV     BL,AL
        ADD     BL,3      
        MOV     AH,9
        MOV     AL,219
        MOV     BH,0
        MOV     CX,1
        INT     10H
        RET
DRAWONE ENDP
                     

; IF INPUT THE KEY,THEN RETURN THE KEY VALUE
; AL:   THE KEY VALUE
; AH:   FF:TRUE 0:FALSE
INPUT PROC
        MOV     AX,0B00H
        INT     21H
        MOV     AH,0H
        CMP     AL,0FFH
        JNE     FINISH_CGI
        MOV     AH,07H
        INT     21H
        MOV     AH,0FFH
        MOV     BL,GAME_WIDTH
        MOV     BH,GAME_WIDTH
        SUB     BH,1
        CMP     AL,'W' 
        JE      UP
        CMP     AL,'w'
        JE      UP
        CMP     AL,'S'
        JE      DOWN
        CMP     AL,'s'
        JE      DOWN
        CMP     AL,'A'
        JE      LEFT
        CMP     AL,'a'
        JE      LEFT
        CMP     AL,'D'
        JE      RIGHT
        CMP     AL,'d'
        JE      RIGHT

        CMP     AL,1BH
        JE      TO_EXIT

        JMP     FINISH_CGI
TO_EXIT:
        CALL    FINAL
FINISH_CGI:
        RET        

UP:     CMP     DIRECTION,1
        JE      FINISH_CGI
        MOV     DIRECTION,0
        RET
DOWN:   CMP     DIRECTION,0
        JE      FINISH_CGI
        MOV     DIRECTION,1
        RET
LEFT:   CMP     DIRECTION,3
        JE      FINISH_CGI
        MOV     DIRECTION,2
        RET
RIGHT:  CMP     DIRECTION,2
        JE      FINISH_CGI
        MOV     DIRECTION,3
        RET
INPUT ENDP

FINAL   PROC
FINALS:
        ;MOV     AH,4CH
        ;INT     21H
        CALL    DRAW
        CALL    DRAWWORD
        MOV     AH,2
        MOV     BH,0
        MOV     DH,SCREEN_WIDTH
        ADD     DH,2
        MOV     DL,0
        INT     21H

        MOV     AH,01H
        INT     21H
        MOV     AH,4CH
        INT     21H
FINAL   ENDP

CODE    ENDS
        END     START
