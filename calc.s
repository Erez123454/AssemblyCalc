section	.rodata	
	format_newLine: db "%o", 10, 0	; format string
	format_string: dd "%s", 0	; format string
	format_Octal: db "%o" , 0

section .bss
    inputBuff: resb 82
    buffSize: resb 82
    startNode: resd 1 
    myStack: resd 63  ;;--------------------------
    tmp: resd 1 
    start_node: resd 1
    an: resb 82		
	an_final: resb 82

section .data
    calcString:  db 'calc: ',0 
	DFlag: dd 0
    is_plus_or_and: dd 0 ;0 stand for default and plus, 1 for and
    isZeroLeadingFlag: dd 0
    index_size_of_stack: dd 4
    size_of_stack: dd 5
    amount: dd 0
	popCounter: dd 0  
	counter: dd 0                                                       ; counter for argument parsing    
    number_of_ops: dd 0                                                 ; op counter !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
    ESO: db 'Error: Operand Stack Overflow' , 10 , 0
    EIN: db 'Error: Insufficient Number of Arguments on Stack' , 10 , 0
    empty: dd 1
    counter2: dd 0
	result: dd 0
    carry: dd 0
    

    operand1Flag: dd 0
	operand2Flag: dd 0
	bothFlag: dd 0
	curry: dd 0


%macro stackOverFlow 0
	push ESO
    push format_string
    call printf
    add esp , 8
    jmp input
%endmacro

%macro mallocNode 0
    push 5                                          ; create a node for copy
    call malloc
    add esp, 4
%endmacro

%macro printOctal 0
    push format_newLine
    call printf
    add esp, 8
%endmacro

%macro infficientOperandNumber 0
	push EIN
    push format_string
    call printf
    add esp , 8
    jmp input
%endmacro

%macro freeList 1                ; arguments: a pointer to HEAD of the list we want to delete 
    
    mov edi, %1
    %%loop:
        cmp byte [edi+1] , 0                     ; if we are at the last node
        je %%remove_last_node
        mov ebx, edi
		mov edi, [edi+1]
        push edi
		push ebx
		call free
		add esp, 4
        pop edi
        jmp %%loop
        
    %%remove_last_node:
        push edi
		call free
		add esp, 4

%endmacro

%macro debugPrint 1                ; arguments: a pointer to HEAD of the list we want to delete 
    
    mov eax, %1
    mov dword[isZeroLeadingFlag] , 1
        %%print_loop:
            mov bl, [eax]                     ;take the value from the current node
            movzx ebx , bl                    ;deleting the leading zero's
            push ebx
            inc byte[popCounter]

            cmp ebx, 0xF                      ; check if there is only one digit
            jle %%one_char_print

            cmp dword[eax+1], 0               ;check if the last node
            je %%finish_print

            mov eax, [eax+1]            ; move forword the pointer
            jmp %%print_loop

        %%one_char_print:
            cmp dword[eax+1], 0              ;check if the last node
            je %%finish_print
            push dword 0
            inc byte[popCounter]
            mov eax, [eax+1]            ; move forword the pointer
            jmp %%print_loop

        %%finish_print:
            cmp dword[popCounter] , 1
            je %%finish_print_last_node
            mov dl, [esp]
            cmp dl, 0
            je %%double_zero_node
            mov dword[isZeroLeadingFlag] , 0

            %%continue_print:
            push format_Octal
            call printf
            add esp, 8
            dec byte[popCounter]
            jmp %%finish_print
        
        %%double_zero_node:
            cmp dword[isZeroLeadingFlag] , 0
            je %%continue_print
            add esp, 4
            dec byte[popCounter]
            jmp %%finish_print

        %%finish_print_last_node:
            dec byte[popCounter]
            push format_newLine
            call printf
            add esp, 8
%endmacro

%macro getOperandsFromStack 0
    mov byte[operand1Flag] , 1              ;nullity the flag
    mov byte[operand2Flag] , 1              ;nullity the flag
    mov byte[bothFlag] , 2                  ;nullity the flag

    mov edx, [amount]
    dec edx
    mov esi , [myStack+edx*4]                    ;the first operand
    dec edx
    mov ebx , [myStack+edx*4]                    ;the second operand
    mov byte [carry] , 0                         ;nullity the carry
    mov byte [empty] , 1                         ;nullity the newNumber 
%endmacro

%macro moveCarryToal 0
    mov dword[carry] , 0
    add al , 1
    adc dword[carry] , 0
%endmacro

section .text
    align 16
    global main
    extern printf
    extern malloc 
    extern calloc 
    extern free 
    extern getchar 
    extern fgets
    extern stdin
    extern stdout 
    extern stderr 


main:
    push    ebp
    mov     ebp , esp
    pushad

    mov eax, [ebp+8]                        ; argc
    cmp eax , 3                             ; if argc==2
    je check_debug

    cmp eax , 1                             ; check if there is an argument
    jle start                   ; if not skip
    
    mov esi, [ebp + 12]                     ; argv pointer
    mov ecx, [esi + 4]                      ; take the pointer to the first argument

    cmp word [ecx], "-d"                    ; take the pointer to a string that represnt the list size argument
    je end_initiate_debug                   ; case: only "-d" appears then jump to end and update d flag 

    jmp continue_initiate_stack             ; case: only "number" is given by the user                  
                               



; if and only if debuger is needed
check_debug:
    mov esi, [ebp +12]                       ; get the argv pointer
    mov ecx, [esi + 4]
    cmp word [ecx] , "-d"                    ; if argv[1] == -D
    je  change_debug_flag1

    mov ecx, [esi + 8]
    cmp word [ecx] , "-d"                    ; if argv[2] == -D
    je  change_debug_flag2


; if the list size argument is second
change_debug_flag1:
    mov dword [DFlag], 1                    ; debug mode
    mov ecx, [esi + 8]                      ; take the pointer to a string that represnt the list size argument
    je continue_initiate_stack

; if the list size argument is first
change_debug_flag2:
    mov word [DFlag], 1                    ; debug mode
    mov ecx,[esi + 4]                  ; take the pointer to a string that represnt the list size argument
    je continue_initiate_stack



continue_initiate_stack:
        mov ebx, 0
        mov edx, 0

    toLast:
        cmp byte [ecx] , 0  ;ecx= argv[1]
        je findStackSize
        inc ecx
        inc byte [counter]
        jmp toLast
    
    findStackSize:
        dec ecx
        movzx eax , byte [ecx]
        sub eax, 48 
        mov [size_of_stack], eax
        dec byte [counter]
        cmp byte [counter] , 0
        je start
        
        dec ecx
        movzx eax , byte [ecx]
        sub eax, 48 
        mov ebx, 8
        mul ebx

        mov ebx,[size_of_stack]
        add ebx, eax
        
        mov dword [size_of_stack] , ebx
        jmp start

end_initiate_debug:
    mov dword [DFlag], 1



start:

input:
    push calcString
    push format_string    ;;printing "calc: " to the screen
    call printf
    add esp, 8 

    
    push dword[stdin]
    push 82
    push inputBuff
    call fgets                              ;arguments of the function
    add esp, 12

    cmp byte[inputBuff] , 10
	je input
    cmp byte[inputBuff], 'q'
	je quit	

    inc byte [number_of_ops]                ; update counter
	cmp byte[inputBuff], '+'
	je plus
	cmp byte[inputBuff], 'p'
	je pop_duplicate_stackCheck
	cmp byte[inputBuff], 'd'
	je pop_duplicate_stackCheck
	cmp byte[inputBuff], '&'
	je andBit
	cmp byte[inputBuff], 'n'
	je numOfDigits
    dec byte [number_of_ops]                ; update counter
    
    mov eax, [amount]
    mov ebx, [size_of_stack]
    cmp eax, ebx                ;check if there is free space for a new number
    jge stack_overflow


input_1:
    cmp dword[DFlag] , 0
    je input_2
    push inputBuff
    push format_string
    call printf
    add esp, 8

input_2:
    mov byte[empty], 1
    length_Of_Buffer:
        
        mov dword[buffSize], 0        ;initiate length
        mov eax, 0                          ;initiate counter 
        .loop:                              ;count the number of digits
            cmp byte[inputBuff + eax], 10
            je initiate_length
            inc eax
            jmp .loop
        initiate_length:
            mov dword[buffSize], eax 

    read_buffer:
        cmp dword[buffSize], 0       ;end of digits
        je insert_to_stack                  ;finish to read the number                     

        movzx  ecx, byte [buffSize]
        mov byte al, [inputBuff + ecx -1]
        movzx eax , al
        dec byte[buffSize]
        sub eax, 48                          ;convert the first char
        mov ebx, eax                        ;save the first charcter
        mov eax, 0

        cmp dword[buffSize] , 0       ;end of digits
        je one_char_node  

        movzx  ecx, byte [buffSize]
        mov al, [inputBuff + ecx -1]
        movzx eax , al
        dec byte[buffSize]
        sub eax, 48                          ;convert the second char
        mov dl, 8
        mul dl                              ;expand the first char
        add ebx, eax                        ;create one number and store in ebx


                                            ;create new node
        ; push 5
        ; call malloc
        ; add esp, 4
        mallocNode
        mov [eax], bl

        cmp byte[empty], 1                  ; check if it is the first node
        je new_number
        mov dword[edi+1], eax               ; To concatenate rhe new node 
        mov edi, eax                        ; edi pointing to last node 
        jmp read_buffer

        new_number:
        mov byte[empty], 0
        mov edi, eax                        ;create pointer to the last node in the list
        mov dword[startNode], eax           ;update the pointer to the first node in the list
        jmp read_buffer

        
        one_char_node:
            ; push 5
            ; call malloc
            ; add esp, 4
            mallocNode
            mov [eax], bl

            cmp byte[empty], 1
            je new_number_one_bit
            mov dword[edi+1], eax               ;To concatenate the new node
            mov edi,eax                         ;edi point to the last node
            jmp insert_to_stack

            new_number_one_bit:
                mov byte[empty], 0
                mov dword[startNode], eax
                mov edi, eax                    ;edi point to the last node

        insert_to_stack:
            mov byte[empty] , 1
            mov dword [edi+1] , 0
            mov dword eax, [startNode]
            mov ebx, [amount]
            mov dword [myStack + ebx*4] , eax
            inc byte[amount]
            jmp input



stack_overflow:
    stackOverFlow                        ;prints error
    ;jmp input

pop_duplicate_stackCheck:
    mov ebx, [amount]
    cmp ebx, 0
    je errorInfficientOperandNumber
    cmp byte[inputBuff], 'p'
    je pop
    cmp byte[inputBuff], 'd'
    je duplicate

errorInfficientOperandNumber:
    infficientOperandNumber



pop:
    mov  ebx , [amount]
    dec  ebx
    mov  eax, [myStack +ebx*4]           ; get the head of the number
    mov dword[isZeroLeadingFlag] , 1
    .loop:
        mov cl, [eax]                     ;take the value from the current node
        mov esi, eax
        inc esi
        inc byte[popCounter]
        movzx ebx , cl                    ;deleting the leading zero's
        mov edx, ebx
        push edx
        cmp dword[esi], 0              ;check if the last node
        je finish1
        cmp edx, 7                      ; check if there is only one digit
        jg more_than_one_char
        push dword 0
        inc byte[popCounter]
        mov ebx, [esi]
        mov eax, ebx            ; move forword the pointer
        jmp .loop

    more_than_one_char:
        mov eax, [esi]            ; move forword the pointer
        jmp loop

    finish1:
        cmp dword[popCounter] , 1
        je finish2
        cmp byte[esp], 0
        jg continue1
        cmp dword[isZeroLeadingFlag] , 0
        je continue2
        add esp, 4
        dec byte[popCounter]
        jmp finish1

    continue1:
        mov dword[isZeroLeadingFlag] , 0

    continue2:
        printOctal
        dec byte[popCounter]
        jmp finish1
        
    finish2:
        dec byte[popCounter]
        printOctal
        mov eax, [amount]
        dec eax
        freeList dword [myStack +eax*4] ; free the list memory
        dec byte[amount]                        ; update the amount of the stack
        jmp input




duplicate:
    mov eax, [size_of_stack]
    cmp dword[amount], eax
    je .errorStackOverFlow
    jmp .keepGoing
    .errorStackOverFlow:
        stackOverFlow


    .keepGoing:
        mov ebx, 0
        mov ecx, 0
        mov edx, 0
        mov ebx, [amount]
        dec ebx
        mov eax, [myStack +ebx*4]                             ; pointer to the head of the list we want to deep copy
        mov  bl, [eax]                                      ; store the number of the first node             
        mallocNode
        mov [eax], bl                                   ; copy the value to the node
        mov dword [start_node], eax                           ; save a pointer to the head for later on
        mov ebx, [amount]
        dec ebx
        mov edx, [myStack +ebx*4]                         ; pointer to the head of the list we want to deep copy

        .loop:
            inc edx
            cmp dword [edx] , 0                           ; chek if it is the last node
            je .last
            mov ecx, eax                                    ; save the last new node pointer
            mov esi, [edx]                                ; save the next node needed to be copied
            mov eax, esi
            mov ebx, [eax]                             ; move ebx the next node value
            mallocNode
            mov [eax], ebx                              ; copy the value to the node
            inc ecx
            mov edx, esi                                ; point with ecx to the next node
            mov[ecx], eax                               ; move next node adress
            jmp .loop

        .last:
            inc eax
            mov dword [eax] , 0
            mov ecx, [start_node]
            mov ebx, [amount]
            mov edx, ecx
            mov dword[myStack + ebx*4],edx  
            cmp dword[DFlag] , 1
            jne .noD
            debugPrint edx
            .noD:
            inc byte [amount]                  ; update the stack
            jmp input




numOfDigits:
    cmp byte[amount],0
    je .error1
    jmp .continue

    .error1:
        infficientOperandNumber
    .continue:
        mov  ecx , [amount]
        sub  ecx, 1
        mov  ebx, [myStack +ecx*4]           ; get the head of the number

        mov dword[buffSize], 0        ;initiate length
        mov eax, 0                          ;initiate counter 
        mov edx, 0                          ;initiate counter zero leading
        mov edi, ebx                        ; curr

        loop:                              ;count the number of digits
            cmp byte[edi+1], 0
            je check_last_node_NOD

            cmp byte[edi], 0
            je zeroNode
            mov edx, 0

            mov bl, [edi]                     ;take the value from the current node
            movzx ebx , bl
            mov [tmp] , ebx

            continue_counting:
            inc eax
            ;inc eax
            mov edi, [edi+1]
            jmp loop
        
        check_last_node_NOD:
            mov bl, [edi]                     ;take the value from the current node
            movzx ebx , bl
            cmp ebx , 0
            je check_tmp
            mov edx , 0 
            cmp ebx, 0xF                      ; check if there is only one digit
            jle add_one
            inc eax
            inc eax
            jmp print_continue
        

        zeroNode:
            inc edx
            inc edx
            jmp continue_counting


        add_one:
            inc eax
            jmp print_continue

        check_tmp:
            cmp byte[tmp], 0xF
            jle update_counter
            jmp print_continue


        update_counter:
            inc edx
            jmp print_continue

    
            
        print_continue:

            mov esi, an
	        mov edi, inputBuff

            sub eax , edx
            mov dword [result] , eax

            .toOctal:
                cmp byte [result] , 0				; check if we ended the division
                je flip_NOD								; if so jump to the end

                inc byte [counter2]					; counter the number of digits in order to flip it in the future
                mov eax, [result]					; divide the number by 16
                mov ebx, 8
                cdq
                div ebx

                mov ecx, 48						;convert to an ascii number
                add edx, ecx
                mov [esi] ,edx 					; insert to ans the new hex letter	; maybe reorder
                inc  esi

                mov [result] , eax
                jmp .toOctal



            flip_NOD:
                dec  esi
                cmp byte [counter2],0
                je end_NOD

                movzx edx, byte [esi]
                mov [edi], edx
                
                inc edi
                
                dec byte [counter2]
                jmp flip_NOD

            end_NOD:
                mov byte[edi], 10

            pop_void_NOD:
                dec byte [amount]
                mov eax, [amount]
                freeList dword [myStack +eax*4]
                jmp input_1


andBit:
    mov dword [is_plus_or_and], 1
    jmp plus_and_loop

plus:
    mov dword [is_plus_or_and], 0
    jmp plus_and_loop

plus_and_loop:
    cmp byte [amount] , 2         ; check there is two operands in the stack  
    jge .continue
    jmp .error                    ;if all conditions are set then continue

    .error:
        infficientOperandNumber

    .continue:
        getOperandsFromStack        ;macro:L edx<-firstArg, ebx<-secondArg

        main_loop:
            mov eax , 0
            mov edx , 0
     
            mov al , [esi]                      ;node from operand1
            movzx eax , al
            mov dl , [ebx]                      ;node from operand2
            movzx edx , dl
            cmp dword [is_plus_or_and], 0
            je to_add
            jmp to_and

            to_and:
                and al , dl
                jmp add_to_list

            to_add:
                clc                               ;clean carry
                cmp byte [carry]  , 0             ;check carry
                je .start_with_carry_zero
                moveCarryToal                     ;macro: carry<-0, al<-1
            
                .start_with_carry_zero:
                    add al , dl
                    jnc add_to_list
                    mov dword [carry] , 1


            add_to_list:
                mov [tmp] , eax                 ;save the value
                ; push 5
                ; call malloc
                ; add esp, 4
                mallocNode
                mov edx , [tmp]
                mov [eax], dl

                cmp dword [empty] , 1
                je handle_new_number
                mov dword[edi+1], eax               ; To concatenate rhe new node ???
                mov edi, eax                        ; edi pointing to last node ????
                jmp next_number
                
                handle_new_number:
                    mov byte[empty], 0
                    mov edi, eax                     ;create pointer to the last node in the list
                    mov dword[startNode], eax        ;update the pointer to the first node in the list
                    jmp next_number

                next_number:
                    cmp dword[esi + 1] , 0                      ;check if the last node
                    je .first_number_finish
                    mov esi , [esi + 1]

                    .second_number:
                        cmp dword[ebx + 1] , 0                  ;check if the last node
                        je .second_number_finish
                        mov ebx , [ebx + 1]

                    .check_both_flag:
                        cmp dword[operand1Flag] , 0                 ;0 if both numbers finish
                        je .check_second
                        jmp main_loop
                        .check_second:
                            cmp dword[operand2Flag] , 0           ;0 if both numbers finish
                            je check_carry
                        jmp main_loop

                    .first_number_finish:
                        mov dword[operand1Flag] ,0
                        jmp .second_number

                    .second_number_finish:
                        mov dword[operand2Flag] ,0
                        jmp .check_both_flag

                    check_carry:
                        cmp dword [is_plus_or_and] ,1
                        je push_to_stack
                        cmp dword[carry] , 0
                        je push_to_stack
                        ; push 5
                        ; call malloc
                        ; add esp, 4
                        mallocNode
                        mov edx , [carry]
                        mov [eax], dl
                        mov [edi+1], eax
                        mov edi , [edi+1]

                    push_to_stack:
                        mov dword [edi+1], 0

                        mov edx, [amount]
                        dec edx	                        ;sign fot finish the list
                        freeList [myStack + edx*4]

                        mov edx, [amount]
                        sub edx , 2
                        freeList [myStack + 4*edx]

                    	mov edx, [amount]
                        sub edx , 2	
                        mov eax, [startNode]
                        mov [myStack+4*edx] , eax
                        dec byte[amount]
                        cmp dword[DFlag] , 0
                        je .continue
                        debugPrint eax
                        .continue:
                        jmp input



quit:
    mov dword eax, [number_of_ops]
    push eax
    push format_newLine
    call printf
    add esp,8

    delete_operands:
        cmp byte [amount], 0
        je end_of_program
        dec byte [amount]
        mov ecx, [amount]
        freeList dword [myStack+ecx*4]
        jmp delete_operands

end_of_program:
    popad			
	mov esp, ebp	
	pop ebp
	ret
