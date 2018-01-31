[bits 16]
[org 0x7e00]

main_entry:
  mov ah, 0xe
  mov cx, boot_message_len
  mov si, boot_message
  call print_str

jmp $

; cx contains length of the string,
; si contains address of the first byte
print_str:
  lodsb
  int 0x10
  loop print_str
  ret

boot_message db 'x86 Bootable Forth'
boot_message_len equ $-boot_message
