global _start                           ; declaring _start as global, so that linker can find it and recognize as entry point

section .data                           ; declaring section .data where we will store data
    test_data db './test.txt', 0x00     ; specifying file path

section .bss                            ; declaring section .bss (Block started by symbol), where we will store uninitialized data
    test_txt_file_size resq 0x01        ; declaring variable test_txt_file_size with size of 1 quadword (8 bytes) - resq stands for reserve quadword
    test_txt_file resq 0x01
    stat_struct resb 48                 ; declaring variable stat_struct that will store output of fstat SYSCALL with size of 48 bytes - resb sta.nds for reserve bytes

    new_line_amount resq 0x01           ; declaring variable that will store amount of new lines in file (which is amount of elements in binary heap)
    heap_storage resq 0x01
    heap_storage_size resq 0x01

section .text                           ; declaring section .text where we will store our code
_start:                                 ; entry point of our program - from there all instructions will be executed
    ;OPEN FILE
    lea rdi, [test_data]                ; loading address of test_data variable to rdi register - from now rdi is a pointer to file path
; IMPORTANT NOTE: mov rdi, test_data is not working, as it tries to move value of test_data to rdi, but to read_file SYSCALL, we need to pass pointer to file path in rdi
    mov rax, 0x02                       ; setting syscall to: open
; IMPORTANT NOTE: mov rsi, 0x00 would give us same result as xor rsi, rsi, but xor operation is faster (smaller instruction size and less CPU cycles)
    xor rsi, rsi                        ; setting flag of open syscall to: O_RDONLY
    SYSCALL                             ; calling open syscall, and we got file_descriptor number in rax

    ; STORE FILE DESCRIPTOR
    push rax                            ; pushing file_descriptor number to stack
    mov rdi, rax                        ; setting file_descriptor number to rdi

    ;GET FILE SIZE
    mov rax, 0x05                       ; setting syscall to: fstat
    lea rsi, [stat_struct]              ; setting rsi as pointer to stat_struct variable
    SYSCALL                             ; calling fstat syscall since now by mov rdi, [stat_struct + 0x30] we can get file size in rdi

    ;STORE FILE SIZE IN VARIABLE
    mov rax, [stat_struct + 0x30]       ; moving file size to rax register
    mov [test_txt_file_size], rax       ; moving file size to test_txt_file_size variable

    ;MMAP - MAP FILE TO MEMORY
    mov rax, 0x09                       ; setting syscall to: mmap
    xor rdi, rdi                        ; rdi in MMAP is address where we want to map file, but as we set it to 0, kernel will choose address for us
    mov rsi, [test_txt_file_size]       ; setting size of mapped memory to size of file
    mov rdx, 0x01                       ; setting memory protection to PROT_READ (it's mode for read only memory)
    mov r10, 0x01                       ; setting flag for mapping as MAP_PRIVATE (changes made to memory mapped file will not be visible to other processes)
    pop r8                              ; popping file_descriptor number from stack
    xor r9, r9                          ; setting offset in file to 0 (so we are reading from beginning of file)
    SYSCALL                             ; calling mmap syscall - we are mapping file to memory and getting address of mapped memory in rax
    mov rsi, rax                        ; moving address of mapped memory to rsi register
    mov [test_txt_file], rsi            ; storing address of mapped memory in test_txt_file variable

    ; CLOSE FILE
    mov rax, 0x03                       ; setting syscall to: close
    mov rdi, r8                         ; setting rdi as file_descriptor number that had been stored in r8
    SYSCALL                             ; calling close syscall - its closing file_descriptor with number in rdi (there is still out opened file descriptor as we didn't changed it

;                    ; WRITE TO STDOUT
;                    mov rax, 0x01                       ; setting syscall to: write
;                    mov rdi, 0x01                       ; setting file_descriptor to 1 (stdout)
;                    mov rdx, [test_txt_file_size]       ; specifying how many bytes will be written to stdout
;                ; IMPORTANT NOTE: we didn't had to declare rsi as pointer to data_in_program, as we had already did it while mapping file to memory
;                    SYSCALL                             ; calling write syscall - we are writing data from file to stdout, we had pointer to data in rsi from mmap SYSCALL

    ; COUNT NEW LINES
    xor rbx, rbx                        ; setting rbx to 0 - it will be our counter for new lines
    xor rcx, rcx                        ; setting rcx to 0 - it will store current index
    mov rdx, [test_txt_file_size]       ; moving file size to rdx register
    count_lines_loop:
        cmp rcx, rdx
        jge count_lines_end
        mov al, byte [rsi + rcx]
        cmp al, 0x0a
        jne skip_new_line_increment
        inc rbx
    skip_new_line_increment:
        inc rcx
        jmp count_lines_loop
    count_lines_end:
        mov [new_line_amount], rbx

    ; CALCULATE HEAP SIZE
    mov rdi, [new_line_amount]          ; moving amount of new lines to rdi register
    add rdi, 0x01                       ; adding 1 to amount of new lines, as last line doesn't have new line character
    shl rdi, 0x03                       ; shifting to left by 3 bits is same as multiplying by 8 (size of quadword), that gives us size of heap in bytes
    mov [heap_storage_size], rdi        ; storing size of heap in heap_storage variable




    ; NEED TO CONSIDER JUST RESIZE FUNCTION THAT WOULD DOUBLE THE SIZE OF HEAP IF NEEDED AND EVERYTHING WOULD BE DONE IN ONE LOOP

    ; ALLOCATE HEAP using MMAP
    mov rax, 0x09
    xor rdi, rdi
    mov rsi, [heap_storage_size]
    mov rdx, 0x03
    mov r10, 0x01
    xor r9, r9
    SYSCALL
    mov [heap_storage], rax             ; storing address of heap in heap_storage variable

    ; STORE DATA IN HEAP
    mov rsi, rax
    xor rcx, rcx                        ; initializing current line index to 0
    ;mov rbx, [new_line_amount]         ; not necessary, as we have this in our rbx register from earlier
    store_data_loop:
        cmp rcx, rbx
        jge store_data_end


    store_data_end:

    ; MUNMAP - UNMAP FILE FROM MEMORY
    mov rax, 0x0b                       ; setting syscall to: munmap
    mov rdi, [test_txt_file]            ; setting address of mapped memory to unmap
    mov rsi, [test_txt_file_size]       ; setting size of mapped memory to size of file (we are unmapping whole file)
    SYSCALL                             ; calling munmap syscall - we are unmapping file from memory

    ; MUNMAP - UNMAP HEAP FROM MEMORY
    mov rax, 0x0b
    mov rdi, [heap_storage]
    mov rsi, [heap_storage_size]
    SYSCALL

    ; EXIT PROGRAM
    mov rax, 0x3c                       ; setting syscall to: exit
    xor rdi, rdi                        ; setting exit code to 0
    SYSCALL                             ; calling exit syscall with code 0 - everything is ok


;NOTE: functions always needs to have ret at the end
ascii_to_quadword:
    xor rax, rax
    xor rdx, rdx
    next_digit:
    ret