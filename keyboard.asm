; =======
; Initial setup
; =======

; Use set 1 scan codes (6), disable mouse (5), interrupts = 0 (0)
%define kb_controller_settings 0b01100000

kb_setup:
  call kb_wait_out
  mov al, 0x60 ; write next byte to control (controller cmd 0x60)
  out 0x64, al

  call kb_wait_out
  mov al, kb_controller_settings
  out 0x60, al

  ret

; =======
; Polling routines
; ======

%define kb_status_flags 0x64
%define kb_input_buffer_full_mask 0b10
%define kb_output_buffer_full_mask 0b1

kb_wait_out:
  in al, kb_status_flags
  test al, kb_input_buffer_full_mask
  jnz kb_wait_out
  ret

kb_wait_in:
  in al, kb_status_flags
  test al, kb_output_buffer_full_mask
  jz kb_wait_in
  ret

; =======
; Scan code translation
; =======

; input: [eax (al)] - scancode
; output: [eax (al)] - ascii code
kb_scancode_to_ascii:
  push ebx                     ; ebx is used for addressing
  cmp al, 0x2a                 ; left shift pressed
  je kb_shift_pressed
  cmp al, 0x36                 ; right shift pressed
  je kb_shift_pressed
  cmp al, (0x80 | 0x2a)        ; left shift released
  je kb_shift_released
  cmp al, (0x80 | 0x36)        ; right shift released
  je kb_shift_released
  cmp al, 0x39                 ; unknown characters and release codes
  ja kb_unhandled_char
  mov ebx, [kb_shift_state]    ; check shift state (1 = held)
  test ebx, ebx
  jz kb_lookup_lower
kb_lookup_higher:              ; shift = 1
  mov ebx, kb_codemap_shift
  jmp kb_lookup
kb_lookup_lower:               ; shift = 0
  mov ebx, kb_codemap
kb_lookup:                     ; codemap lookup
  mov al, [eax + ebx]
  pop ebx
  ret                          ; return char
kb_shift_pressed:
  mov dword [kb_shift_state], 1
  jmp kb_unhandled_char
kb_shift_released:
  mov dword [kb_shift_state], 0
kb_unhandled_char:
  mov al, 0
  pop ebx
  ret                          ; return null (unrecognized/special)

kb_shift_state dd 0

; https://wiki.osdev.org/Keyboard#Scan_Code_Set_1
kb_codemap:
  ; 0x00 is undefined, 0x01 is Esc, skip them
  db 0,0
  ; 0x02 ... 0x0d
  db '1234567890-='
  ; 0x0e is backspace, ASCII 0x08
  db 0x08
  ; 0x0f is tab, ASCII 0x09
  db 0x09
  ; 0x10..0x1b
  db 'qwertyuiop[]'
  ; 0x1c is enter, assume it's LF (0x10)
  db 0x10
  ; 0x1d is control, skip it
  db 0
  ; 0x1e ...  0x29
  db "asdfghjkl;'`"
  ; 0x2a is shift (handled separately)
  db 0
  ; 0x2b ... 0x35
  db '\zxcvbnm,./'
  ; 0x36 is shift (handled separately)
  ; 0x37 ... 0x38 are ignored
  db 0,0,0
  ; 0x39 is space
  db ' '
kb_codemap_shift:
  ; 0x00 is undefined, 0x01 is Esc, skip them
  db 0,0
  ; 0x02 ... 0x0d
  db '!@#$%^&*()_+'
  ; 0x0e is backspace, ASCII 0x08
  db 0x08
  ; 0x0f is tab, ASCII 0x09
  db 0x09
  ; 0x10..0x1b
  db 'QWERTYUIOP{}'
  ; 0x1c is enter, assume it's LF (0x10)
  db 0x10
  ; 0x1d is control, skip it
  db 0
  ; 0x1e ...  0x29
  db 'ASDFGHJKL:"~'
  ; 0x2a is shift (handled separately)
  db 0
  ; 0x2b ... 0x35
  db '|ZXCVBNM<>?'
  ; 0x36 is shift (handled separately)
  ; 0x37 ... 0x38 are ignored
  db 0,0,0
  ; 0x39 is space
  db ' '
