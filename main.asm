section .data
    nl db 10, 0
    sep db ' ', 0
    arr dd 6, 5, 12, 10, 9, 1
    len equ ($ - arr) / 4

section .bss
    buf resb 12
    left_arr resd len
    right_arr resd len

section .text
    global _start

; void merge(int left, int mid, int right)
; parameters:
;    [ebp + 8]  -> left
;    [ebp + 12] -> mid
;    [ebp + 16] -> right
merge:
    push ebp
    mov ebp, esp

    push ebx
    push esi
    push edi

    ; n1 = mid - left + 1
    mov ebx, [ebp + 12] ; mid
    mov edx, [ebp + 8]  ; left
    sub ebx, edx
    inc ebx
    push ebx

    ; n2 = right - mid
    mov ebx, [ebp + 16] ; right
    mov edx, [ebp + 12] ; mid
    sub ebx, edx
    push ebx
    xor eax, eax ; i = 0

.copy_left:
    ; i >= n1
    mov ebx, [esp + 4] ; n1
    cmp eax, ebx
    jge .copy_left_done

    ; left_arr[i] = arr[left + i]
    mov edx, [ebp + 8] ; left
    add edx, eax       ; left + i
    mov edx, [arr + edx * 4]
    mov [left_arr + eax * 4], edx

    inc eax ; i++
    jmp .copy_left

.copy_left_done:
    xor eax, eax ; i = 0

.copy_right:
    ; i >= n2
    mov ebx, [esp] ; n2
    cmp eax, ebx
    jge .copy_right_done

    ; right_arr[i] = arr[mid + i + 1]
    mov edx, [ebp + 12] ; mid
    add edx, eax
    inc edx
    mov ebx, [arr + edx * 4]
    mov [right_arr + eax * 4], ebx

    inc eax ; i++
    jmp .copy_right

.copy_right_done:
    xor eax, eax       ; i = 0
    xor ecx, ecx       ; j = 0
    mov edx, [ebp + 8] ; k = left 

.merge_loop:
    ; i >= n1
    mov ebx, [esp + 4] ; n1
    cmp eax, ebx
    jge .copy_left_remaining

    ; j >= n2
    mov ebx, [esp] ; n2
    cmp ecx, ebx
    jge .copy_left_remaining

    ; left_arr[i] <= right_arr[j]
    mov edi, [left_arr + eax * 4]  ; left_arr[i]
    mov esi, [right_arr + ecx * 4] ; right_arr[j]
    cmp edi, esi
    jle .shift_left
    jmp .shift_right

.shift_left:
    ; arr[k] = left_arr[i]
    mov [arr + edx * 4], edi    
    inc eax ; i++
    jmp .shift_done

.shift_right:
    mov [arr + edx * 4], esi
    inc ecx ; j++
    jmp .shift_done

.shift_done:
    inc edx ; k++
    jmp .merge_loop

.copy_left_remaining:
    ; i >= n1
    mov ebx, [esp + 4] ; n1
    cmp eax, ebx
    jge .copy_right_remaining

    ; arr[k] = left_arr[i]
    mov ebx, [left_arr + eax * 4]
    mov [arr + edx * 4], ebx

    inc eax ; i++
    inc edx ; k++
    jmp .copy_left_remaining

.copy_right_remaining:
    ; j >= n2
    mov ebx, [esp] ; n2
    cmp ecx, ebx
    jge .merge_done

    ; arr[k] = right_arr[j]
    mov ebx, [right_arr + ecx * 4]
    mov [arr + edx * 4], ebx

    inc ecx ; j++
    inc edx ; k++
    jmp .copy_right_remaining

.merge_done:
    add esp, 8
    pop edi
    pop esi
    pop ebx

    mov esp, ebp
    pop ebp
    ret

; void mergesort(int left, int right)
; parameters:
;    [ebp + 8]  -> left
;    [ebp + 12] -> right
mergesort:
    push ebp
    mov ebp, esp
    sub esp, 8

    push ebx
    push esi
    push edi

    mov ebx, [ebp + 8]  ; left
    mov edx, [ebp + 12] ; right
    cmp ebx, edx
    jge .mergesort_done

    ; mid = left + (right - left) / 2
    mov eax, edx ; right
    sub eax, ebx ; right - left
    shr eax, 1   ; (right - left) / 2
    add eax, ebx ; left + (right - left) / 2

    ; mergesort(left, mid)
    mov [ebp - 4], eax
    mov [ebp - 8], edx
    push eax ; mid
    push ebx ; left
    call mergesort
    add esp, 8

    ; mergesort(mid + 1, right)
    mov ecx, [ebp - 4]
    inc ecx
    mov edx, [ebp - 8]
    push edx
    push ecx
    call mergesort
    add esp, 8

    ; merge(left, mid, right)
    mov edx, [ebp - 8]
    mov eax, [ebp - 4]
    push edx ; right
    push eax ; mid
    push ebx ; left
    call merge
    add esp, 12

.mergesort_done:
    pop edi
    pop esi
    pop ebx

    mov esp, ebp
    pop ebp
    ret

print:
    push eax
    push ecx
    push edx
    push esi

    mov eax, [esp + 20]
    lea esi, [buf + 11]
    mov byte [esi], 0
    dec esi

    test eax, eax
    jne .conv_loop

    mov byte [esi], '0'
    jmp .conv_done

.conv_loop:
    xor edx, edx
    mov ecx, 10
    div ecx
    add dl, '0'
    mov [esi], dl
    dec esi
    test eax, eax
    jne .conv_loop

.conv_done:
    inc esi
    mov edx, buf + 12
    sub edx, esi
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    int 80h

    mov eax, 4
    mov ebx, 1
    mov ecx, sep
    mov edx, 1
    int 0x80

    pop esi
    pop edx
    pop ecx
    pop eax
    ret

_start:
    mov eax, len
    dec eax

    push eax     ; right
    push dword 0 ; left
    call mergesort
    add esp, 8
    xor ecx, ecx

.print_loop:
    cmp ecx, len
    jge .exit

    mov eax, [arr + ecx * 4]
    push eax
    call print
    add esp, 4

    inc ecx
    jmp .print_loop

.exit:
    mov eax, 4
    mov ebx, 1
    mov ecx, nl
    mov edx, 1
    int 80h

    mov eax, 1
    xor ebx, ebx
    int 80h
