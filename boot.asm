%define boot_sector 0x7c00
%define main_sector 0x7e00

[bits 16]
[org boot_sector]

reset_drive:
  mov ah, 0
  int 0x13
  test ah, ah     ; check operation status (0 = success)
  jnz reset_drive

load_from_disk:
  mov ah, 0x2
  mov ch, 0           ; cylinder
  mov dh, 0           ; head
  mov cl, 2           ; sector (counting from 1)
  mov bx, main_sector ; destination address
  mov al, 1           ; sectors to be read
  int 0x13
  test ah, ah
  jnz reset_drive     ; we may need to retry this
  jmp main_sector

jmp $

; 512 byte padding - 2 magic bytes
times 510 -( $ - $$ ) db 0
; Magic bytes
db 0x55
db 0xaa
