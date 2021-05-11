stksz equ 8160

section	.rodata	
	format_int_newline: db "%X", 10, 0	; format string
	format_string: dd "%s", 0	; format string
	format_int: db "%X" , 0

section .bss
    buffer: resb 82
    lengthOfBuffer: resb 82
    FirstList: resd 1 
    tmp: resd 1 
    Head: resd 1
    stack: resd 255
    an: resb 82		
	an_final: resb 82

section .data
    calcString:  db 'calc: ',0 
	DFlag: dd 0
    isZeroLeadingFlag: dd 0
    index_size_of_stack: dd 4
    size_of_stack: dd 5
    amount: dd 0
	counter_for_pop: dd 0  
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


; change a char to the hexa value of it
%macro convertChar 0
	cmp eax , 57       
	jg %%Lett
	sub eax, 48       
	jmp %%end

	%%Lett:
		sub eax, 55       
	%%end:
%endmacro

%macro error_stack_overflow 0
	push ESO
    push format_string
    call printf
    add esp , 8
    jmp input
%endmacro

%macro error_insufficient_number 0
	push EIN
    push format_string
    call printf
    add esp , 8
    jmp input
%endmacro

%macro delete_linked_list 1                ; arguments: a pointer to HEAD of the list we want to delete 
    
    mov edi, %1
    %%delete_loop:
        cmp byte [edi+1] , 0                     ; if we are at the last node
        je %%delete_last_node
        mov ebx, edi
		mov edi, [edi+1]
        push edi
		push ebx
		call free
		add esp, 4
        pop edi
        jmp %%delete_loop
        
    %%delete_last_node:
        push edi
		call free
		add esp, 4

%endmacro

%macro print_if_debug_mode 1                ; arguments: a pointer to HEAD of the list we want to delete 
    
    mov eax, %1
    mov dword[isZeroLeadingFlag] , 1
        %%print_loop:
            mov bl, [eax]                     ;take the value from the current node
            movzx ebx , bl                    ;deleting the leading zero's
            push ebx
            inc byte[counter_for_pop]

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
            inc byte[counter_for_pop]
            mov eax, [eax+1]            ; move forword the pointer
            jmp %%print_loop

        %%finish_print:
            cmp dword[counter_for_pop] , 1
            je %%finish_print_last_node
            mov dl, [esp]
            cmp dl, 0
            je %%double_zero_node
            mov dword[isZeroLeadingFlag] , 0

            %%continue_print:
            push format_int
            call printf
            add esp, 8
            dec byte[counter_for_pop]
            jmp %%finish_print
        
        %%double_zero_node:
            cmp dword[isZeroLeadingFlag] , 0
            je %%continue_print
            add esp, 4
            dec byte[counter_for_pop]
            jmp %%finish_print

        %%finish_print_last_node:
            dec byte[counter_for_pop]
            push format_int_newline
            call printf
            add esp, 8
%endmacro


section .text
    align 16
    global main
    extern printf
    extern fprintf 
    extern fflush
    extern malloc 
    extern calloc 
    extern free 
    extern gets 
    extern getchar 
    extern fgets
    extern stdin 





main:
    push    ebp
    mov     ebp , esp
    pushad

    mov eax, [ebp+8]                        ; argc
    cmp eax , 3                             ; if argc==2
    je check_debug

    cmp eax , 1                             ; check if there is an argument
    jle end_initiate_stack                   ; if not skip
    
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
        cmp byte [ecx] , 0
        je toHex
        inc ecx
        inc byte [counter]
        jmp toLast
    
    toHex:
        dec ecx
        movzx eax , byte [ecx]
        convertChar
        mov [size_of_stack], eax
        dec byte [counter]
        cmp byte [counter] , 0
        je end_initiate_stack
        
        dec ecx
        movzx eax , byte [ecx]
        convertChar
        mov ebx, 16
        mul ebx

        mov ebx,[size_of_stack]
        add ebx, eax
        
        mov dword [size_of_stack] , ebx
        jmp end_initiate_stack

end_initiate_debug:
    mov dword [DFlag], 1


end_initiate_stack:
    jmp myCalc



myCalc:

input:
    push calcString
    push format_string    ;;printing "calc: " to the screen
    call printf
    add esp, 8 

    
    push dword[stdin]
    push 82
    push buffer
    call fgets                              ;arguments of the function
    add esp, 12

    cmp byte[buffer] , 10
	je input
    cmp byte[buffer], 'q'
	je quit	
    inc byte [number_of_ops]                ; update counter
	cmp byte[buffer], '+'
	je plus
	cmp byte[buffer], 'p'
	je pop
	cmp byte[buffer], 'd'
	je duplicate
	cmp byte[buffer], '&'
	je andBit
	cmp byte[buffer], '|'
	je orBit 
	cmp byte[buffer], 'n'
	je numOfDigits
    dec byte [number_of_ops]                ; update counter
    
    mov eax, [amount]
    mov ebx, [size_of_stack]
    cmp eax, ebx                ;check if there is free space for a new number
    jge stack_overflow

input_1:
    cmp dword[DFlag] , 0
    je input_2
    push buffer
    push format_string
    call printf
    add esp, 8

input_2:
    mov byte[empty], 1
    length_Of_Buffer:
        
        mov dword[lengthOfBuffer], 0        ;initiate length
        mov eax, 0                          ;initiate counter 
        .loop:                              ;count the number of digits
            cmp byte[buffer + eax], 10
            je initiate_length
            inc eax
            jmp .loop
        initiate_length:
            mov dword[lengthOfBuffer], eax 

    read_buffer:
        cmp dword[lengthOfBuffer], 0       ;end of digits
        je insert_to_stack                  ;finish to read the number                     

        movzx  ecx, byte [lengthOfBuffer]
        mov byte al, [buffer + ecx -1]
        movzx eax , al
        dec byte[lengthOfBuffer]
        convertChar                         ;convert the first char
        mov ebx, eax                        ;save the first charcter
        mov eax, 0

        cmp dword[lengthOfBuffer] , 0       ;end of digits
        je one_char_node  

        movzx  ecx, byte [lengthOfBuffer]
        mov al, [buffer + ecx -1]
        movzx eax , al
        dec byte[lengthOfBuffer]
        convertChar                         ;convert the second char
        mov dl, 16
        mul dl                              ;expand the first char
        add ebx, eax                        ;create one number and store in ebx


                                            ;create new node
        push 5
        call malloc
        add esp, 4
        mov [eax], bl

        cmp byte[empty], 1                  ; check if it is the first node
        je new_number
        mov dword[edi+1], eax               ; To concatenate rhe new node 
        mov edi, eax                        ; edi pointing to last node 
        jmp read_buffer

        new_number:
        mov byte[empty], 0
        mov edi, eax                        ;create pointer to the last node in the list
        mov dword[FirstList], eax           ;update the pointer to the first node in the list
        jmp read_buffer

        
        one_char_node:
            push 5
            call malloc
            add esp, 4
            mov [eax], bl

            cmp byte[empty], 1
            je new_number_one_bit
            mov dword[edi+1], eax               ;To concatenate the new node
            mov edi,eax                         ;edi point to the last node
            jmp insert_to_stack

            new_number_one_bit:
                mov byte[empty], 0
                mov dword[FirstList], eax
                mov edi, eax                    ;edi point to the last node

        insert_to_stack:
            mov byte[empty] , 1
            mov dword [edi+1] , 0
            mov dword eax, [FirstList]
            mov ebx, [amount]
            mov dword [stack + ebx*4] , eax
            inc byte[amount]
            jmp input



pop:
    mov eax, [amount]
    cmp eax, 1                         ; check there is two operands in the stack  
    jl .error
    jmp .continue                           ; if all conditions are set then continue

    .error:
        error_insufficient_number

    .continue:
        mov  ecx , [amount]
        sub  ecx, 1
        mov  eax, [stack +ecx*4]           ; get the head of the number
        mov dword[isZeroLeadingFlag] , 1
        print_loop:
            mov bl, [eax]                     ;take the value from the current node
            movzx ebx , bl                    ;deleting the leading zero's
            push ebx
            inc byte[counter_for_pop]

            cmp ebx, 0xF                      ; check if there is only one digit
            jle one_char_print

            cmp dword[eax+1], 0               ;check if the last node
            je finish_print

            mov eax, [eax+1]            ; move forword the pointer
            jmp print_loop

        one_char_print:
            cmp dword[eax+1], 0              ;check if the last node
            je finish_print
            push dword 0
            inc byte[counter_for_pop]
            mov eax, [eax+1]            ; move forword the pointer
            jmp print_loop

        finish_print:
            cmp dword[counter_for_pop] , 1
            je finish_print_last_node
            mov dl, [esp]
            cmp dl, 0
            je double_zero_node
            mov dword[isZeroLeadingFlag] , 0

            continue_print:
            push format_int
            call printf
            add esp, 8
            dec byte[counter_for_pop]
            jmp finish_print
        
        double_zero_node:
            cmp dword[isZeroLeadingFlag] , 0
            je continue_print
            add esp, 4
            dec byte[counter_for_pop]
            jmp finish_print

        finish_print_last_node:
            dec byte[counter_for_pop]
            push format_int_newline
            call printf
            add esp, 8

        free_list:
            mov eax, [amount]
            dec eax
            delete_linked_list dword [stack +eax*4] ; free the list memory
            dec byte[amount]                        ; update the amount of the stack
            jmp input

numOfDigits:
    cmp byte[amount],0
    je .error1
    jmp .continue

    .error1:
        error_insufficient_number
    .continue:
        mov  ecx , [amount]
        sub  ecx, 1
        mov  ebx, [stack +ecx*4]           ; get the head of the number

        mov dword[lengthOfBuffer], 0        ;initiate length
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
            inc eax
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
	        mov edi, buffer

            sub eax , edx
            mov dword [result] , eax

            .toHexa:
                cmp byte [result] , 0				; check if we ended the division
                je flip_NOD								; if so jump to the end

                inc byte [counter2]					; counter the number of digits in order to flip it in the future
                mov eax, [result]					; divide the number by 16
                mov ebx, 16
                cdq
                div ebx

                cmp edx, 10
                jge .toLetter
                jmp .toNumber


            .toNumber:
                mov ecx, 48						;convert to an ascii number
                add edx, ecx
                mov [esi] ,edx 					; insert to ans the new hex letter	; maybe reorder
                inc  esi

                mov [result] , eax
                jmp .toHexa


            .toLetter:
                mov ecx, 55						;convert to an ascii letter
                add edx, ecx
                mov [esi] ,edx 					; insert to ans the new hex letter	; maybe reorder
                inc  esi

                mov [result] , eax
                jmp .toHexa


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
                delete_linked_list dword [stack +eax*4]
                jmp input_1


stack_overflow:
    error_stack_overflow                        ;prints error
    jmp input



duplicate:
    cmp byte[amount],0
    je .error1
    mov edx, [size_of_stack]
    cmp dword[amount], edx
    je .error2
    jmp .continue

    .error1:
        error_insufficient_number
    .error2:
        error_stack_overflow


    .continue:
        mov edx, [amount]
        dec edx
        mov ecx, [stack +edx*4]                             ; pointer to the head of the list we want to deep copy
        mov  bl, [ecx]                                      ; store the number of the first node

        dup_start:               
            push 5                                          ; create a node for copy
            call malloc
            add esp, 4
            mov [eax], bl                                   ; copy the value to the node
            mov dword [Head], eax                           ; save a pointer to the head for later on

            mov edx, [amount]
            dec edx
            mov ecx, [stack +edx*4]                         ; pointer to the head of the list we want to deep copy

        dup_check:
            cmp dword [ecx+1] , 0                           ; chek if it is the last node
            je last_node

            mov edi, [ecx+1]                                ; save the next node needed to be copied
            mov esi, eax                                    ; save the last new node pointer
        
        dup_loop:
            mov ebx,  [edi]                             ; move ebx the next node value
            push 5                                      ; create the next node for copy
            call malloc
            add esp, 4
            mov [eax], ebx                              ; copy the value to the node
            mov[esi+1], eax                               ; move next node adress
            mov ecx, edi                                ; point with ecx to the next node
            jmp dup_check

        last_node:
            mov dword [eax+1] , 0
            mov ecx, [amount]
            mov eax, [Head]
            mov dword[stack + ecx*4],eax  
            inc byte [amount]                  ; update the stack
            cmp dword[DFlag] , 0
            je .continue
            print_if_debug_mode eax
            .continue:
            jmp input

andBit:
    cmp byte [amount] , 2                         ; check there is two operands in the stack  
    jl .error
    jmp .continue                           ; if all conditions are set then continue

    .error:
        error_insufficient_number

    .continue:
        mov byte[operand1Flag] , 1              ;nullity the flag
        mov byte[operand2Flag] , 1              ;nullity the flag

        mov eax, [amount]
        dec eax
        mov esi , [stack+eax*4]                      ;the first operand
        dec eax
        mov ebx , [stack+eax*4]                     ;the second operand
        mov byte [empty] , 1                             ;nullity the newNumber 


        and_loop:
            mov eax , 0
            mov edx , 0

            cmp byte [operand1Flag] ,  0             ;operand1 finish but operand2 didnt
            je skip_first_number_and
            cmp byte [operand2Flag] ,  0             ;operand2 finish but operand1 didnt
            je skip_second_number_and
            
            mov al , [esi]                      ;node from operand1
            movzx eax , al
            mov dl , [ebx]                      ;node from operand2
            movzx edx , dl
            jmp to_and

            skip_first_number_and:
                mov dl , [ebx]                      ;node from operand2
                movzx edx , dl
                jmp to_and
            
            skip_second_number_and:
                mov al , [esi]                      ;node from operand1
                movzx eax , al

            to_and:
                and al , dl


            add_to_list_and:
                mov [tmp] , eax                 ;save the value
                push 5
                call malloc
                add esp, 4
                mov edx , [tmp]
                mov [eax], dl

                cmp dword [empty] , 1
                je new_number_and
                mov dword[edi+1], eax               ; To concatenate rhe new node ???
                mov edi, eax                        ; edi pointing to last node ????
                jmp forword_the_numbers_and
                
                new_number_and:
                    mov byte[empty], 0
                    mov edi, eax                                ;create pointer to the last node in the list
                    mov dword[FirstList], eax                   ;update the pointer to the first node in the list
                    jmp forword_the_numbers_and

                forword_the_numbers_and:
                    cmp dword[esi + 1] , 0                      ;check if the last node
                    je .first_number_finish_and
                    mov esi , [esi + 1]

                    .second_number_and:
                        cmp dword[ebx + 1] , 0                  ;check if the last node
                        je .second_number_finish_and
                        mov ebx , [ebx + 1]

                    .check_both_flag_and:
                        cmp dword[operand1Flag] , 0                 ;0 if both numbers finish
                        je .check_second_and
                        jmp and_loop
                        .check_second_and:
                            cmp dword[operand2Flag] , 0                 ;0 if both numbers finish
                            je insert_to_stack_and
                        jmp and_loop

                    .first_number_finish_and:
                        mov dword[operand1Flag] ,0
                        jmp .second_number_and

                    .second_number_finish_and:
                        mov dword[operand2Flag] ,0
                        jmp .check_both_flag_and


                    insert_to_stack_and:
                        mov dword [edi+1], 0

                        mov edx, [amount]
                        dec edx	            ;sign fot finish the list
                        delete_linked_list [stack + edx*4]

                        mov edx, [amount]
                        sub edx , 2
                        delete_linked_list [stack + 4*edx]

                    	mov edx, [amount]
                        sub edx , 2	
                        mov eax, [FirstList]
                        mov [stack+4*edx] , eax
                        dec byte[amount]
                        cmp dword[DFlag] , 0
                        je .continue
                        print_if_debug_mode eax
                        .continue:
                        jmp input

orBit:
    cmp byte [amount] , 2                         ; check there is two operands in the stack  
    jl .error
    jmp .continue                           ; if all conditions are set then continue

    .error:
        error_insufficient_number

    .continue:
        mov byte[operand1Flag] , 1              ;nullity the flag
        mov byte[operand2Flag] , 1              ;nullity the flag

        mov eax, [amount]
        dec eax
        mov esi , [stack+eax*4]                      ;the first operand
        dec eax
        mov ebx , [stack+eax*4]                     ;the second operand
        mov byte [empty] , 1                             ;nullity the newNumber 


        or_loop:
            mov eax , 0
            mov edx , 0

            cmp byte [operand1Flag] ,  0             ;operand1 finish but operand2 didnt
            je skip_first_number_or
            cmp byte [operand2Flag] ,  0             ;operand2 finish but operand1 didnt
            je skip_second_number_or
            
            mov al , [esi]                      ;node from operand1
            movzx eax , al
            mov dl , [ebx]                      ;node from operand2
            movzx edx , dl
            jmp to_or

            skip_first_number_or:
                mov dl , [ebx]                      ;node from operand2
                movzx edx , dl
                jmp to_or
            
            skip_second_number_or:
                mov al , [esi]                      ;node from operand1
                movzx eax , al

            to_or:
                or al , dl


            add_to_list_or:
                mov [tmp] , eax                 ;save the value
                push 5
                call malloc
                add esp, 4
                mov edx , [tmp]
                mov [eax], dl

                cmp dword [empty] , 1
                je new_number_or
                mov dword[edi+1], eax               ; To concatenate rhe new node ???
                mov edi, eax                        ; edi pointing to last node ????
                jmp forword_the_numbers_or
                
                new_number_or:
                    mov byte[empty], 0
                    mov edi, eax                                ;create pointer to the last node in the list
                    mov dword[FirstList], eax                   ;update the pointer to the first node in the list
                    jmp forword_the_numbers_or

                forword_the_numbers_or:
                    cmp dword[esi + 1] , 0                      ;check if the last node
                    je .first_number_finish_or
                    mov esi , [esi + 1]

                    .second_number_or:
                        cmp dword[ebx + 1] , 0                  ;check if the last node
                        je .second_number_finish_or
                        mov ebx , [ebx + 1]

                    .check_both_flag_or:
                        cmp dword[operand1Flag] , 0                 ;0 if both numbers finish
                        je .check_second_or
                        jmp or_loop
                        .check_second_or:
                            cmp dword[operand2Flag] , 0                 ;0 if both numbers finish
                            je insert_to_stack_or
                        jmp or_loop

                    .first_number_finish_or:
                        mov dword[operand1Flag] ,0
                        jmp .second_number_or

                    .second_number_finish_or:
                        mov dword[operand2Flag] ,0
                        jmp .check_both_flag_or


                    insert_to_stack_or:
                        mov dword [edi+1], 0

                        mov edx, [amount]
                        dec edx	            ;sign fot finish the list
                        delete_linked_list [stack + edx*4]

                        mov edx, [amount]
                        sub edx , 2
                        delete_linked_list [stack + 4*edx]

                    	mov edx, [amount]
                        sub edx , 2	
                        mov eax, [FirstList]
                        mov [stack+4*edx] , eax
                        dec byte[amount]
                        cmp dword[DFlag] , 0
                        je .continue
                        print_if_debug_mode eax
                        .continue:
                        jmp input

plus:
    cmp byte [amount] , 2                         ; check there is two operands in the stack  
    jl .error
    jmp .continue                           ; if all conditions are set then continue

    .error:
        error_insufficient_number

    .continue:
        mov byte[operand1Flag] , 1              ;nullity the flag
        mov byte[operand2Flag] , 1              ;nullity the flag
        mov byte[bothFlag] , 2                  ;nullity the flag

        mov eax, [amount]
        dec eax
        mov esi , [stack+eax*4]                      ;the first operand
        dec eax
        mov ebx , [stack+eax*4]                     ;the second operand
        mov byte [carry] , 0                         ;nullity the carry
        mov byte [empty] , 1                             ;nullity the newNumber 


        plus_loop:
            mov eax , 0
            mov edx , 0

            cmp byte [operand1Flag] ,  0             ;operand1 finish but operand2 didnt
            je skip_first_number
            cmp byte [operand2Flag] ,  0             ;operand2 finish but operand1 didnt
            je skip_second_number
            
            mov al , [esi]                      ;node from operand1
            movzx eax , al
            mov dl , [ebx]                      ;node from operand2
            movzx edx , dl
            jmp to_add

            skip_first_number:
                mov dl , [ebx]                      ;node from operand2
                movzx edx , dl
                jmp to_add
            
            skip_second_number:
                mov al , [esi]                      ;node from operand1
                movzx eax , al

            to_add:
                clc                                     ;clean carry
                
                cmp byte [carry]  , 0                    ;check carry
                je add_without_curry
                mov dword[carry] , 0
                add al , 1
                adc dword[carry] , 0

            
            add_without_curry:
                add al , dl
                jnc add_to_list
                mov dword [carry] , 1


            add_to_list:
                mov [tmp] , eax                 ;save the value
                push 5
                call malloc
                add esp, 4
                mov edx , [tmp]
                mov [eax], dl

                cmp dword [empty] , 1
                je new_number_plus
                mov dword[edi+1], eax               ; To concatenate rhe new node ???
                mov edi, eax                        ; edi pointing to last node ????
                jmp forword_the_numbers
                
                new_number_plus:
                    mov byte[empty], 0
                    mov edi, eax                                ;create pointer to the last node in the list
                    mov dword[FirstList], eax                   ;update the pointer to the first node in the list
                    jmp forword_the_numbers

                forword_the_numbers:
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
                        jmp plus_loop
                        .check_second:
                            cmp dword[operand2Flag] , 0                 ;0 if both numbers finish
                            je check_carry
                        jmp plus_loop

                    .first_number_finish:
                        mov dword[operand1Flag] ,0
                        jmp .second_number

                    .second_number_finish:
                        mov dword[operand2Flag] ,0
                        jmp .check_both_flag

                    check_carry:
                        cmp dword[carry] , 0
                        je insert_to_stack_plus
                        push 5
                        call malloc
                        add esp, 4
                        mov edx , [carry]
                        mov [eax], dl
                        mov [edi+1], eax
                        mov edi , [edi+1]

                    insert_to_stack_plus:
                        mov dword [edi+1], 0

                        mov edx, [amount]
                        dec edx	            ;sign fot finish the list
                        delete_linked_list [stack + edx*4]

                        mov edx, [amount]
                        sub edx , 2
                        delete_linked_list [stack + 4*edx]

                    	mov edx, [amount]
                        sub edx , 2	
                        mov eax, [FirstList]
                        mov [stack+4*edx] , eax
                        dec byte[amount]
                        cmp dword[DFlag] , 0
                        je .continue
                        print_if_debug_mode eax
                        .continue:
                        jmp input



quit:
    mov dword eax, [number_of_ops]
    push eax
    push format_int_newline
    call printf
    add esp,8

    delete_operands:
        cmp byte [amount], 0
        je end_of_program
        dec byte [amount]
        mov ecx, [amount]
        delete_linked_list dword [stack+ecx*4]
        jmp delete_operands

end_of_program:
    popad			
	mov esp, ebp	
	pop ebp
	ret
