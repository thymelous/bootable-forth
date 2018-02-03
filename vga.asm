; =======
; Printing routines
; =======

%define vga_gray_on_black 0x07
%define vga_blank_character 0x0720 ; 0x20 = ASCII space

; Input char is passed in %al (the register is not modified)
; Uses %edx and %edi as scratch registers, does not restore them!
vga_put_char:
  mov edx, [vga_buffer_top]
  mov byte [edx], al
  mov byte [edx + 1], vga_gray_on_black
  add edx, 2
  mov [vga_buffer_top], edx
vga_advance_cursor:
  mov di, [vga_cursor_position]
  inc di
  mov word [vga_cursor_position], di
  push eax
  call vga_refresh_cursor
  pop eax
  ret

; Uses %eax, %edx, %edi as scratch registers, does not restore them!
vga_erase_char:
  mov edx, [vga_buffer_top]
  sub edx, 2
  mov word [edx], vga_blank_character
  mov [vga_buffer_top], edx
vga_retreat_cursor:
  mov di, [vga_cursor_position]
  dec di
  mov word [vga_cursor_position], di
  call vga_refresh_cursor
  ret

; =======
; Low-level routines
; =======

; See https://wiki.osdev.org/Text_Mode_Cursor
; Uses %ax, %dx, %di as scratch registers
vga_refresh_cursor:
  ; cursor low port to index register
  mov al, 0xf
  mov dx, 0x3d4
  out dx, al
  ; cursor low position to data register
  mov ax, di
  mov dx, 0x3d5
  out dx, al
  ; cursor high port to index register
  mov al, 0xe
  mov dx, 0x3d4
  out dx, al
  ; cursor high position to data register
  mov ax, di
  shr ax, 8
  mov dx, 0x3d5
  out dx, al
  ret

; =======
; Data
; =======

vga_buffer_top dd 0xb8000
vga_cursor_position dw 0
