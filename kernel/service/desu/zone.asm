;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;-------------------------------------------------------------------------------

;===============================================================================
; wejście:
;	rsi - wskaźnik do obiektu
service_desu_zone_insert_by_object:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi
	push	rsi

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	service_desu_zone_semaphore,	0

	; lista stref jest pełna?
	cmp	qword [service_desu_zone_list_records],	SERVICE_DESU_ZONE_LIST_limit
	jb	.insert	; nie

	xchg	bx,bx
	jmp	$

.insert:
	; wskaźnik pośredni na koniec listy stref
	mov	eax,	SERVICE_DESU_STRUCTURE_ZONE.SIZE
	mul	qword [service_desu_zone_list_records]	; pozycja za ostatnią strefą listy

	; wskaźnik bezpośredni końca listy stref
	mov	rdi,	qword [service_desu_zone_list_address]
	add	rdi,	rax

	; wstaw właściwości strefy
	movsq	; pozycja na osi X
	movsq	; pozycja na osi Y
	movsq	; szerokość
	movsq	; wysokość

	; oraz informacje o obiekcie zależnym
	mov	rax,	qword [rsp]
	mov	qword [rdi],	rax

	; ilość stref na liście
	inc	qword [service_desu_zone_list_records]

	; odblokuj listę stref do modyfikacji
	mov	byte [service_desu_zone_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_desu_zone_insert_by_object"

;===============================================================================
; wejście:
;	rdi - wskaźnik do strefy
;	r8 - pozycja na osi X
;	r9 - pozycja na osi Y
;	r10 - szerokość strefy
;	r11 - wysokość strefy
; wyjście:
;	rdi - nowa pozycja, jeśli zoptymalizowano listę stref
service_desu_zone_insert_by_register:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rsi
	push	rdi

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	service_desu_zone_semaphore,	0

	; lista stref jest pełna?
	cmp	qword [service_desu_zone_list_records],	SERVICE_DESU_ZONE_LIST_limit
	jb	.insert	; nie

	xchg	bx,bx
	jmp	$

.insert:
	; wskaźnik pośredni na koniec listy stref
	mov	eax,	SERVICE_DESU_STRUCTURE_ZONE.SIZE
	mul	qword [service_desu_zone_list_records]	; pozycja za ostatnią strefą listy

	; wskaźnik bezpośredni końca listy stref
	mov	rsi,	qword [service_desu_zone_list_address]
	add	rsi,	rax

	; dodaj do listy nową strefę
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.x],	r8
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.y],	r9
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.width],	r10
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.height],	r11

	; oraz jej obiekt zależny
	mov	rax,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object]
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.object],	rax

	; ilość stref na liście
	inc	qword [service_desu_zone_list_records]

	; odblokuj listę stref do modyfikacji
	mov	byte [service_desu_zone_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_desu_zone_insert_by_register"

;===============================================================================
service_desu_zone:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	service_desu_object_semaphore,	0

	; ustaw wskaźnik na pierwszą opisaną strefę na liście
	mov	rdi,	qword [service_desu_zone_list_address]

	; rozpocznij przetwarzanie
	jmp	.entry

.loop:
	; zwolnij strefę z listy
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object],	STATIC_EMPTY

	; przesuń wskaźnik na pierwszą/następną strefę do przetworzenia
	add	rdi,	SERVICE_DESU_STRUCTURE_ZONE.SIZE

.entry:
	; brak strefy do przetworzenia?
	cmp	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object],	STATIC_EMPTY
	je	.end	; tak

	;-----------------------------------------------------------------------
	; pobierz właściwości strefy
	;-----------------------------------------------------------------------

	; lewa krawędź na oxi X
	mov	r8,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	; górna krawędź na osi Y
	mov	r9,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	; prawa krawędź na osi X
	mov	r10,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.width]
	add	r10,	r8
	; dolna krawędź na osi Y
	mov	r11,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.height]
	add	r11,	r9

	; opisana strefa znajduje się w przestrzeni "ekranu"?
	cmp	r8,	qword [kernel_video_width_pixel]
	jge	.loop	; nie
	cmp	r9,	qword [kernel_video_height_pixel]
	jge	.loop	; nie
	cmp	r10,	STATIC_EMPTY
	jle	.loop	; nie
	cmp	r11,	STATIC_EMPTY
	jle	.loop	; nie

	;-----------------------------------------------------------------------
	; interferencja
	;-----------------------------------------------------------------------

	; wskaźnik pośredni na koniec listy obiektów
	mov	eax,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
	mul	qword [service_desu_object_list_records]	; pozycja za ostatnim obiektem listy

	; wskaźnik bezpośredni końca listy obiektów
	mov	rsi,	qword [service_desu_object_list_address]
	add	rsi,	rax

.object:
	; ustaw wskaźnik na rozpatrywany obiekt
	sub	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

	; rozpatrywany obiekt jest pierwszy na liście?
	cmp	rsi,	qword [service_desu_object_list_address]
	je	.fill	; tak

	; obiekt widoczny?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_visible
	jz	.object	; nie

	; wystąpiła interferencja z obiektem przetwarzanym? (samym sobą)
	cmp	rsi,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object]
	je	.fill	; tak

	; pobierz współrzędne obiektu

	; lewa krawędź na oxi X
	mov	r12,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	; górna krawędź na osi Y
	mov	r13,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	; prawa krawędź na osi X
	mov	r14,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
	add	r14,	r12
	; dolna krawędź na osi Y
	mov	r15,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height]
	add	r15,	r13

	;--------------------------------
	;      r9	       r13	X
	;    -------	     -------
	; r8 |  S  | r10 r12 |  O  | r14
	;    -------	     -------
	;      r11	       r15
	; Y

	; obiekt znajduje się poza przetwarzaną strefą?
	cmp	r12,	r10	; lewa krawędź obiektu za prawą krawędzią strefy?
	jge	.object	; tak
	cmp	r13,	r11	; górna krawędź obiektu za dolną krawędzią strefy?
	jge	.object	; tak
	cmp	r14,	r8	; prawa krawędź obiektu przed lewą krawędzią strefy?
	jle	.object	; tak
	cmp	r15,	r9	; dolna krawędź obiektu przed górną krawędzią strefy?
	jle	.object	; tak

	;-----------------------------------------------------------------------
	; przycinanie
	;-----------------------------------------------------------------------

.left: ;)
	; lewa strefa poza ekranem?
	cmp	r8,	STATIC_EMPTY
	jge	.left_positive	; nie

	; przesuń na początek ekranu
	xor	r8,	r8

.left_positive:
	; lewa krawędź strefy przed lewą krawędzią obiektu?
	cmp	r8,	r12
	jge	.up	; nie

	; wytnij wystający fragment strefy

	; zachowaj oryginalną pozycję prawej krawędzi strefy
	push	r10

	; szerokość odcinanej strefy
	mov	r10,	r12
	sub	r10,	r8

	; wysokość odcinanej strefy
	sub	r11,	r9

	; odłóż na listę stref
	call	service_desu_zone_insert_by_register

	; przywróć oryginalną pozycję prawej krawędzi strefy
	pop	r10

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r11,	r9

	; nowa pozycja lewej krawędzi strefy
	mov	r8,	r12

.up:
	; lewa strefa poza ekranem?
	cmp	r9,	STATIC_EMPTY
	jge	.up_positive	; nie

	; przesuń na początek ekranu
	xor	r9,	r9

.up_positive:
	; górna krawędź strefy przed górną krawędzią obiektu?
	cmp	r9,	r13
	jge	.right	; nie

	; wytnij wystający fragment strefy

	; szerokość odcinanej strefy
	sub	r10,	r8

	; zachowaj oryginalną pozycję dolnej krawędzi strefy
	push	r11

	; wysokość odcinanej strefy
	mov	r11,	r13
	sub	r11,	r9

	; odłóż na listę stref
	call	service_desu_zone_insert_by_register

	; przywróć oryginalną pozycję prawej krawędzi strefy
	pop	r11

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r10,	r8

	; nowa pozycja górnej krawędzi strefy
	mov	r9,	r13

.right:
	; lewa strefa poza ekranem?
	cmp	r10,	qword [kernel_video_width_pixel]
	jle	.right_positive	; nie

	; przesuń na początek ekranu
	mov	r10,	qword [kernel_video_width_pixel]

.right_positive:
	; prawa krawędź strefy za prawą krawędzią obiektu?
	cmp	r10,	r14
	jle	.down	; nie

	; wytnij wystający fragment strefy

	; szerokość odcinanej strefy
	sub	r10,	r14

	; zachowaj oryginalną pozycję lewej krawędzi strefy
	push	r8

	; pozycja lewej krawędzi odcinanej strefy
	mov	r8,	r14

	; odłóż na listę stref
	call	service_desu_zone_insert_by_register

	; przywróć oryginalną pozycję lewej krawędzi strefy
	pop	r8

	; nowa pozycja prawej krawędzi strefy
	mov	r10,	r14

.down:
	; lewa strefa poza ekranem?
	cmp	r11,	qword [kernel_video_height_pixel]
	jle	.down_positive	; nie

	; przesuń na początek ekranu
	mov	r11,	qword [kernel_video_height_pixel]

.down_positive:
	; dolna krawędź strefy za dolną krawędzią obiektu?
	cmp	r11,	r15
	jle	.cursor	; nie

	; wytnij wystający fragment strefy

	; wysokość odcinanej strefy
	sub	r11,	r15

	; zachowaj oryginalną pozycję górnej krawędzi strefy
	push	r9

	; pozycja górnej krawędzi odcinanej strefy
	mov	r9,	r15

	; odłóż na listę stref
	call	service_desu_zone_insert_by_register

	; przywróć oryginalną pozycję lewej krawędzi strefy
	pop	r9

	; nowa pozycja dolnej krawędzi strefy
	mov	r11,	r15

.cursor:
	; strefa należy do obiektu kursora?
	cmp	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object],	service_desu_object_cursor
	jne	.loop	; nie, zignoruj pozostały fragment

.fill:
	; wypełnij pozostały fragment danym obiektem
	sub	r10,	r8	; zwróć szerokość strefy
	sub	r11,	r9	; zwróć wysokość strefy
	call	service_desu_fill_insert_by_register

	; kontynuuj
	jmp	.loop

.end:
	; wszystkie strefy na liście zostały przetworzone
	mov	qword [service_desu_zone_list_records],	STATIC_EMPTY

	; odblokuj listę obiektów do modyfikacji
	mov	byte [service_desu_object_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_desu_zone"
