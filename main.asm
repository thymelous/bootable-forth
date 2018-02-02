[bits 32]
[org 0x7e00]

main_entry:
  ;mov ecx, boot_message_len
  ;mov esi, boot_message
  ;call print_str
  call kb_setup
  call kb_wait_in
  in al, 0x60
  call kb_scancode_to_ascii
  mov [video_mem], al
  jmp main_entry

%include "keyboard.asm"

jmp $

; ecx contains length of the string,
; esi contains address of the first byte
print_str:
  push edx
  push eax
  mov edx, video_mem
  mov ah, 0x0f       ; white-on-black
print_str_loop:
  lodsb
  mov [edx], ax
  add edx, 2
  loop print_str_loop
print_str_finish:
  pop eax
  pop edx
  ret

boot_message db 'x86 Bootable Forth'
boot_message_len equ $-boot_message
video_mem equ 0xb8000
