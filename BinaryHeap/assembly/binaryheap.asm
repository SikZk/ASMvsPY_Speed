global _start                           ; declaring _start as global, so that linker can find it and recognize as entry point

section .data                           ; declaring section .data where we will store data
    test_data db './test.txt', 0x00    ; specifying file path

section .bss                            ; declaring section .bss (Block started by symbol), where we will store uninitialized data
    ;THIS VARIABLES ARE USED IN FUNCTION read_file
    data_in_program resb 0x1000000      ; declaring variable data_in_program with size of 16,777,216 Bytes = 16MB - resb stands for reserve bytes
    test_txt_file_size resq 0x01        ; declaring variable test_txt_file_size with size of 1 quadword (8 bytes) - resq stands for reserve quadword
    stat_struct resb 48                 ; declaring variable stat_struct that will store output of fstat SYSCALL with size of 48 bytes - resb sta.nds for reserve bytes

; IMPORTANT NOTE: Im declaring one more byte than I'll read from file, because I need to add null terminator to the end of string

section .text                           ; declaring section .text where we will store our code
_start:                                 ; entry point of our program - from there all instructions will be executed

    lea rdi, [test_data]                ; loading address of test_data variable to rdi register - from now rdi is a pointer to file path
; IMPORTANT NOTE: mov rdi, test_data is not working, as it tries to move value of test_data to rdi, but to read_file SYSCALL, we need to pass pointer to file path in rdi
    call read_file

    ; WRITE TO STDOUT
    mov rax, 0x01                       ; setting syscall to: write
    mov rdi, 0x01                       ; setting file_descriptor to 1 (stdout)
    mov rdx, [test_txt_file_size]       ; specifying how many bytes will be written to stdout
; IMPORTANT NOTE: we didn't had to declare rsi as pointer to data_in_program, as we had already did it while opening file
    SYSCALL                             ; calling write syscall - we are writing data from file to stdout

    ; EXIT PROGRAM
    mov rax, 0x3c                       ; setting syscall to: exit
    mov rdi, 0x00                       ; setting exit code to 0
    SYSCALL                             ; calling exit syscall with code 0 - everything is ok


read_file:                              ; FUNCTION that reads whatever file is rdi pointing to and stores this data inside data_in_program variable

    ; OPEN FILE
    mov rax, 0x02                       ; setting syscall to: open
    mov rsi, 0x00                       ; setting flag of open syscall to: O_RDONLY
    mov rdx, 0644o                      ; setting file permissions (octal), this is not that important as we need to read only
    SYSCALL                             ; calling open syscall, and we got file_descriptor number in rax

    ; STORE FILE DESCRIPTOR
    mov rdi, rax                        ; setting file_descriptor number to rdi

    ;GET FILE SIZE
    mov rax, 0x05                       ; setting syscall to: fstat
    lea rsi, [stat_struct]              ; setting rsi as pointer to stat_struct variable
    SYSCALL                             ; calling fstat syscall since now by mov rdi, [stat_struct + 0x30] we can get file size in rdi

    ;STORE FILE SIZE IN VARIABLE
    mov rax, [stat_struct + 0x30]       ; moving file size to rax register
    mov [test_txt_file_size], rax       ; moving file size to test_txt_file_size variable

    ; READ FILE
    mov rax, 0x00                       ; setting syscall to: read
    lea rsi, [data_in_program]          ; setting rsi as pointer to data_in_program variable
    mov rdx, [test_txt_file_size]       ; specifying how many bytes will be read from file
    SYSCALL                             ; calling read syscall

    ; CLOSE FILE
    mov rax, 0x03                       ; setting syscall to: close
    SYSCALL                             ; calling close syscall - its closing file_descriptor with number in rdi (there is still out opened file descriptor as we didn't changed it
;IMPORTANT NOTE: functions always needs to have this ret at the end
    ret