global _start                           ; declaring _start as global, so that linker can find it and recognize as entry point

section .data                           ; declaring section .data where we will store data
    test_data db '../test.txt', 0x00    ; specifying file path

section .bss                            ; declaring section .bss (Block started by symbol), where we will store uninitialized data
    data_in_program resb 0x12           ; declaring variable data_in_program with size of 0x12 bytes - resb stands for reserve bytes

; IMPORTANT NOTE: Im declaring one more byte than I'll read from file, because I need to add null terminator to the end of string

section .text                           ; declaring section .text where we will store our code
_start:                                 ; entry point of our program - from there all instructions will be executed

    ; OPEN FILE
    mov rax, 0x02                       ; setting syscall to: open
    mov rdi, test_data                  ; setting file path to rdi
    mov rsi, 0x00                       ; setting flag of open syscall to: O_RDONLY
    mov rdx, 0644o                      ; setting file permissions (octal), this is not that important as we need to read only
    SYSCALL                             ; calling open syscall, and we got file_descriptor number in rax

    ; READ FILE
    mov rdi, rax                        ; setting file_descriptor number to rax
    mov rax, 0x00                       ; setting syscall to: read
    mov rsi, data_in_program            ; assigning data from file to this variable we declared in .bss section
    mov rdx, 0x11                       ; specifying how many bytes will be read from file
    SYSCALL                             ; calling read syscall

    ; CLOSE FILE
    mov rax, 0x03                       ; setting syscall to: close
    SYSCALL                             ; calling close syscall - its closing file_descriptor with number in rdi (there is still out opened file descriptor as we didn't changed it

    ; WRITE TO STDOUT
    mov rax, 0x01                       ; setting syscall to: write
    mov rdi, 0x01                       ; setting file_descriptor to 1 (stdout)
    mov rsi, data_in_program            ; setting data to be written to stdout
    mov rdx, 0x11                       ; specifying how many bytes will be written to stdout
    SYSCALL                             ; calling write syscall - we are writing data from file to stdout

    ; EXIT PROGRAM
    mov rax, 0x3c                       ; setting syscall to: exit
    mov rdi, 0x00                       ; setting exit code to 0
    SYSCALL                             ; calling exit syscall with code 0 - everything is ok