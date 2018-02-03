; Command-line interface routines

; =======
; read_line
;
; Reads a single line of input, providing visual feedback
; for keyboard interactions.
; =======

; Line buffer can only fit a single line; multi-line input
; is not supported (needs to broken into several lines)
%define line_buffer_size 80

; Return values:
; ebx - first char address
; ecx - number of characters
read_line:
  push eax ; used for input
  push edx ; see display_char
  push edi ; see display_cursor
  mov ebx, line_buffer       ; reset buffer
  mov [line_buffer_top], ebx
  mov ecx, line_buffer_size  ; set up iterator
read_line_loop:
  call kb_read_char
  cmp al, 0         ; ignore null chars
  je read_line_loop
  cmp al, 0x8       ; check for backspace
  je read_line_backspace
  cmp al, 0x10      ; LF ends the line
  je read_line_ret
  mov byte [ebx], al
  inc ebx
  call display_char
  loop read_line_loop
read_line_ret:
  pop edi
  pop edx
  pop eax
  mov ebx, line_buffer_size
  sub ebx, ecx              ; length = buffer_size - remaining_space
  mov ecx, ebx              ; ecx = length
  mov ebx, line_buffer      ; ebx = first char address
  ret
read_line_backspace:
  cmp ebx, line_buffer ; are we at the start of the buffer?
  je read_line_loop    ;   if so, there's nothing to erase
  dec ebx              ; move the buffer pointer one char back
  inc ecx              ; increase remaining space
  call erase_char
  jmp read_line_loop

line_buffer times (line_buffer_size) db 0
line_buffer_top equ line_buffer

video_buffer_top dd 0xb8000
video_cursor_position dw 0

; expects char in al
; may use edx and edi as scratch registers
display_char:
  mov edx, [video_buffer_top]
  mov byte [edx], al
  mov byte [edx + 1], 0x07 ; gray-on-black
  add edx, 2
  mov [video_buffer_top], edx
advance_cursor:
  mov di, [video_cursor_position]
  inc di
  mov word [video_cursor_position], di
  push eax            ; save the char
  call display_cursor
  pop eax
  ret

erase_char:
  mov edx, [video_buffer_top]
  sub edx, 2
  mov word [edx], 0x0720      ; space, gray-on-black (cursor color)
  mov [video_buffer_top], edx
move_cursor_back:
  mov di, [video_cursor_position]
  dec di
  mov word [video_cursor_position], di
  call display_cursor
  ret

; See https://wiki.osdev.org/Text_Mode_Cursor
; Uses ax, dx, di as scratch registers
display_cursor:
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
