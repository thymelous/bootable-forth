%define boot_sector 0x7c00
%define main_sector 0x7e00

[bits 16]
[org boot_sector]

reset_drive:
  mov ah, 0
  int 0x13
  jc reset_drive ; carry flag is set on error

load_from_disk:
  mov ah, 0x2
  mov ch, 0           ; cylinder
  mov dh, 0           ; head
  mov cl, 2           ; sector (counting from 1)
  mov bx, main_sector ; destination address
  mov al, 1           ; sectors to be read
  int 0x13
  jc reset_drive      ; we may need to retry the whole routine

switch_to_vga_text_mode:
  xor ah, ah
  mov al, 0x3
  int 0x10

; Since interrupts are handled differently in protected mode,
; we must first disable them, then load GDT, and toggle the control bit.
; A far jump (segment:address) is required to flush the pipeline.
switch_to_protected:
  cli
  lgdt [gdt_descriptor]
  mov eax, cr0
  or eax, 0x1             ; bit 0 is Protection Enable
  mov cr0, eax
  jmp 0x8:setup_protected ; 0x8 is the second entry in GDT (code segment)

[bits 32]
setup_protected:
  mov ax, 0x10  ; 0x10 is the third entry in GDT (data segment)
  mov ds, ax    ; set 32-bit data segments
  mov ss, ax

setup_stack:
  mov esp, 0x90000 ; set the stack pointer to a high address

jmp main_sector

; Use a flat memory model with code and data segments overlapping
; See https://wiki.osdev.org/Global_Descriptor_Table
gdt:
  ; Null descriptor (this entry is not used by the processor)
  gdt_null:
    dd 0
    dd 0

  ; Code segment
  gdt_code:
    dw 0xffff     ; limit (0-15)
    db 0x0        ; base (0-23)
    db 0x0
    db 0x0
    ; present in memory? = 1, ring = 00, code/data = 1,
    ; executable = 1, conforming (executed by lower priv)? = 0,
    ; readable? = 1, accessed (set by cpu)? = 0
    db 0b10011010
    ; granular (multiply limit by 4k to access 4gb)? = 1, 32-bit? = 1,
    ; other = 00, limit (16-19) = ff
    db 0b11001111
    db 0x0        ; base (24-31)

  ; Data segment
  gdt_data:
    dw 0xffff     ; limit (0-15)
    db 0x0        ; base (0-23)
    db 0x0
    db 0x0
    ; present in memory? = 1, ring = 00, code/data = 1,
    ; executable = 0, direction (grows down)? = 0,
    ; writable? = 1, accessed (set by cpu)? = 0
    db 0b10010010
    ; granular (multiply limit by 4k to access 4gb)? = 1, 32-bit? = 1,
    ; other = 00, limit (16-19) = ff
    db 0b11001111
    db 0x0        ; base (24-31)

  gdt_end:

  gdt_descriptor:
    dw gdt_end - gdt - 1 ; GDT size - 1
    dd gdt               ; GDT start address

; 512 byte padding - 2 magic bytes
times 510 -( $ - $$ ) db 0
; Magic bytes
db 0x55
db 0xaa
