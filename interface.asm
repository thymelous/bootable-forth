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
  push edi ; used in display_char
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

; expects char in al
; may use edi as a scratch register
display_char:
  mov edi, [video_buffer_top]
  mov byte [edi], al
  mov byte [edi + 1], 0x0f ; white-on-black
  add edi, 2
  mov [video_buffer_top], edi
  ret
erase_char:
  mov edi, [video_buffer_top]
  sub edi, 2
  mov word [edi], 0x0000
  mov [video_buffer_top], edi
  ret
