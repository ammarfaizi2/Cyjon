;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
tm_static:
	; pobierz informacje o strumieniu wyjścia
	call	tm_stream_info

	; wyświetl uptime systemu
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_uptime_days_end - tm_string_uptime
	mov	rsi,	tm_string_uptime
	int	KERNEL_SERVICE

	; wyświetl ilość procesów
	mov	ecx,	tm_string_tasks_sleeping_end - tm_string_tasks
	mov	rsi,	tm_string_tasks
	int	KERNEL_SERVICE

	; wyświetl wykorzystanie pamięci RAM
	mov	ecx,	tm_string_memory_end - tm_string_memory
	mov	rsi,	tm_string_memory
	int	KERNEL_SERVICE

	; wyświetl nagłówek tablicy procesów
	mov	ecx,	tm_string_header_end - tm_string_header_position_and_color
	mov	rsi,	tm_string_header_position_and_color
	int	KERNEL_SERVICE
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	movzx	ecx,	word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
	sub	ecx,	tm_string_header_end - tm_string_header
	mov	dl,	STATIC_ASCII_SPACE
	int	KERNEL_SERVICE

	; powrót z procedury
	ret
