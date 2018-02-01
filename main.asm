[bits 32]
[org 0x7e00]

main_entry:
  ;mov ecx, boot_message_len
  ;mov esi, boot_message
  ;call print_str

disable_keyboard_int:
  mov al, 0x20 ; request control byte (controller cmd 0x20)
  out 0x64, al

  call wait_keyboard_in
  in al, 0x60  ; read control byte
  and al, 0xfe ; clear the lowest bit (interrupts)
  push eax     ; save the modified byte

  call wait_keyboard_out
  mov al, 0x60 ; write next byte to control (controller cmd 0x60)
  out 0x64, al

  call wait_keyboard_out
  pop eax      ; restore the modified byte
  out 0x60, al ; send it

  nop

read_keyboard:
  call wait_keyboard_in
  in al, 0x60
  jmp read_keyboard

%define kb_status_flags 0x64
%define kb_input_buffer_full_mask 0b10
%define kb_output_buffer_full_mask 0b1

wait_keyboard_out:
  in al, kb_status_flags
  test al, kb_input_buffer_full_mask 
  jnz wait_keyboard_out
  ret

wait_keyboard_in:
  in al, kb_status_flags
  test al, kb_output_buffer_full_mask
  jz wait_keyboard_in
  ret

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
