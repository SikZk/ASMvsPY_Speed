global _start                                       ; declaring _start as global, so that linker can find it and recognize as entry point

section .data                                       ; declaring section .data where we will store data
    file_path db './test.txt', 0x00                 ; specifying file path

section .bss                                        ; declaring section .bss (Block started by symbol), where we will store uninitialized data
    file_size resq 0x01                             ; reserving quadword (8 bytes = 64 bits) for file size, resq stands for reserving quadword
    file_pointer resq 0x01                          ; reserving quadword (8 bytes = 64 bits) for file pointer
    file_stat_struct resb 0x90                      ; reserving 144 bytes for file stat structure - this is recommended size for this structure

    heap_size resq 0x01                             ; reserving quadword (8 bytes = 64 bits) for heap size
    heap_capacity resq 0x01                         ; reserving quadword (8 bytes = 64 bits) for heap capacity
    heap_pointer resq 0x01                          ; reserving quadword (8 bytes = 64 bits) for heap pointer

    current_value_pointer resb 0x20                 ; reserving 32 bytes (as sequence of 1 byte chunks) for current value pointer, resb stands for reserving byte

section .text                                       ; declaring section .text where we will store our code
    _start:                                         ; entry point of our program - from there all instructions will be executed
        ;OPEN FILE
        mov rax, 0x02                               ; setting syscall to: open
        lea rdi, [file_path]                        ; loading pointer to file path to rdi register
; IMPORTANT NOTE: mov rdi, file_path is not working, as it tries to move value of test_data to rdi, but to read_file SYSCALL,
;we need to pass pointer to file path in rdi, so we use lea (load effective address) to get the pointer to file path
        xor rsi, rsi                                ; setting rsi to 0 (flag O_RDONLY)
; IMPORTANT NOTE: mov rsi, 0x00 would give us same result as xor rsi, rsi, but xor operation is faster (smaller instruction size and less CPU cycles)
        SYSCALL                                     ; calling open syscall, we got file descriptor in rax
        push rax                                    ; pushing file descriptor to stack
        mov rdi, rax                                ; moving file descriptor to rdi register

        ;GET FILE SIZE
        mov rax, 0x05                               ; setting syscall to: fstat
        lea rsi, [file_stat_struct]                 ; setting rsi as pointer to stat_struct variable
        SYSCALL                                     ; calling fstat syscall since now by mov rdi, [stat_struct + 0x30] we can get file size in rdi
        mov rax, [file_stat_struct + 0x30]          ; moving file size to rax register
        mov [file_size], rax                        ; moving file size to file_size variable

        ;MMAP - dynamic memory allocation for file
        mov rax, 0x09                               ; setting syscall to: mmap
        xor rdi, rdi                                ; rdi in MMAP is address where we want to map file, but as we set it to 0, kernel will choose address for us
        mov rsi, [file_size]                        ; setting size of mapped memory to size of file
        mov rdx, 0x01                               ; setting memory protection to PROT_READ (it's mode for read only memory)
        mov r10, 0x01                               ; setting flag for mapping as MAP_PRIVATE (changes made to memory mapped file will not be visible to other processes)
        pop r8                                      ; popping file_descriptor number from stack
        xor r9, r9                                  ; setting offset in file to 0 (so we are reading from beginning of file)
        SYSCALL                                     ; calling mmap syscall - we are mapping file to memory and getting address of mapped memory in rax
        mov [file_pointer], rax                     ; storing address of mapped memory to file_pointer variable

        ;CLOSE FILE
        mov rax, 0x03                               ; setting syscall to: close
        mov rdi, r8                                 ; setting rdi as file_descriptor number that had been stored in r8
        SYSCALL                                     ; calling close syscall

        ;INITIALIZE BINARY HEAP WITH 64 quadword capacity
        mov qword [heap_capacity], 0x200            ; setting heap_capacity to 512 bytes (2 * 16^2 = 512)
        mov qword [heap_size], 0x00                 ; setting heap_size to 0
        mov rax, 0x09                               ; setting syscall to: mmap
        xor rdi, rdi                                ; rdi in MMAP is address where we want to map file, but as we set it to 0, kernel will choose address for us
        mov rsi, [heap_capacity]                    ; setting size of mapped memory to heap_capacity
        mov rdx, 0x03                               ; setting memory protection to PROT_READ | PROT_WRITE (it's mode for read and write memory)
        mov r10, 0x21                               ; setting flag for mapping as MAP_PRIVATE (changes made to memory mapped file will not be visible to other processes)
        xor r8, r8                                  ; setting file_descriptor to 0 (as we are not mapping file)
        xor r9, r9                                  ; setting offset in file to 0 (as we are not mapping file)
        SYSCALL                                     ; calling mmap syscall - we are mapping memory for heap and getting address of mapped memory in rax
        mov [heap_pointer], rax                     ; storing address of mapped memory to heap_pointer variable

        ;ITERATE THROUGH FILE
        xor rcx, rcx                                ; rcx = current index in our iteration (we start from 0)
        mov r15, [file_pointer]                     ; rsi = pointer to the file
        xor rax, rax                                ; rax = value of the number we are reading
        file_iteration_loop:                        ; we are iterating through every byte in the file
            cmp rcx, [file_size]                    ; if we have reached the end of the file, we exit the loop
            jge end_loop                            ; jump to the end of the loop
            mov bl, [r15 + rcx]                     ; bl is 8 lowest bytes from rbx register, and it holds the current byte we are reading
            add rcx, 0x01

            movzx rdx, bl                           ; we are moving the 8 bytes bl to 64 bytes register so we can do some operations
            cmp rdx, 0x0a                           ; if we have reached the end of the line, we jump to new_line
            je new_line                             ; jump to new_line

            sub rdx, '0'                            ; we are converting the byte to a number (we are subtracting the ASCII value of '0')
            imul rax, rax, 0x0a                     ; we are multiplying the current value by 10
            add rax, rdx                            ; we are adding the new digit to the current value


            jmp file_iteration_loop                 ; jump to the beginning of the loop

        new_line:                                   ; we have reached the end of the line
            call insert_to_heap                     ; we are inserting the value to the heap
            xor rax, rax                            ; we are resetting the value of the number we are reading


            jmp file_iteration_loop                 ; we are jumping to the beginning of the loop

        end_loop:                                   ; we have reached the end of the file

            call insert_to_heap                     ; we are inserting the last value to the heap


        call clean_and_exit                         ; we are cleaning up and exiting our program



    clean_and_exit:

        ;MUNMAP file
        mov rax, 0x0b
        mov rdi, [file_pointer]
        mov rsi, [file_size]
        SYSCALL

        ;MUNMAP heap
        mov rax, 0x0b
        mov rdi, [heap_pointer]
        mov rsi, [heap_capacity]
        SYSCALL

        ;EXIT
        mov rax, 0x3c
        mov rdi, 0x00
        SYSCALL
    ret

    resize_heap:

        mov r8, rcx
        mov r12, [heap_pointer]
        mov r13, [heap_capacity]

        ;DOUBLE CAPACITY
        mov rax, [heap_capacity]
        shl rax, 0x01
        mov [heap_capacity], rax

        ;MMAP new heap
        mov rax, 0x09
        xor rdi, rdi
        mov rsi, [heap_capacity]
        mov rdx, 0x03
        mov r10, 0x21
        xor r9, r9
        SYSCALL
        mov [heap_pointer], rax

        ;COPY previous heap to new heap
        mov rdi, rax
        mov rsi, r12
        mov rcx, r13
        shr rcx, 0x03
        rep movsq

        ;MUNMAP previous heap
        mov rax, 0x0b
        mov rdi, r12
        mov rsi, r13
        SYSCALL

        mov rcx, r8

        end_resize_heap:

    ret
    insert_to_heap:                         ;This will use rax as the value to insert
    ;we are free to use rbx, and rdx
        mov rbx, [heap_size]
        add rbx, 0x01
        mov [heap_size], rbx
        imul rbx, rbx, 0x08

        mov rdx, [heap_capacity]
        cmp rbx, rdx
        jge resize_heap_call
        jmp end_resize_heap_call

        resize_heap_call:
            call resize_heap
            jmp end_resize_heap_call
        end_resize_heap_call:
            mov rbx, [heap_size]
            sub rbx, 0x01
            imul rbx, rbx, 0x08
            mov rdx, rbx
            add rdx, [heap_pointer]
            mov qword [rdx], rax

            call move_up_the_heap

    ret

    move_up_the_heap:                       ;This needs to have rdx = index of the element we want to move up

        sub rbx, 0x08
        sar rbx, 0x01

        mov r8, [heap_size]
        and r8, 0x01
        add r8, 0x00
        je even_index
        jmp odd_index
        odd_index:
            sub rbx, 0x04
        even_index:

        start_move_up_loop:
            cmp rbx, 0x00
            jl end_move_up_loop
            mov r8, [heap_pointer]
            add r8, rbx
            mov r9, [r8]
            cmp r9, rax
            jle end_move_up_loop


            test_breakpoint:
            mov [r8], rax
            mov [rdx], r9
            mov rdx, r8

            sub rbx, 0x08
            sar rbx, 0x01

            mov r8, [heap_size]
            and r8, 0x01
            add r8, 0x00
            jne even_index_in_loop
            jmp odd_index_in_loop
            odd_index_in_loop:
                sub rbx, 0x04
            even_index_in_loop:

            jmp start_move_up_loop

        end_move_up_loop:

    ret

    move_down_the_heap:                     ;This needs to have rdx = index of the element we want to move down
        ;TO IMPLEMENT IN THE FUTURE (THIS METHOD IS NEEDED FOR DELETING ELEMENTS FROM HEAP)
    ret

    delete_min_from_heap:                   ;This will delete the minimum element from the heap
        ;TO IMPLEMENT IN THE FUTURE (THIS METHOD IS NEEDED FOR DELETING ELEMENTS FROM HEAP)
    ret

;NOTE: functions always needs to have ret at the end