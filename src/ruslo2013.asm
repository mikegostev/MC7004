.EQU P1STAT    #021H
.EQU LASTKEY   #022H
.EQU REPDLYCNT #023H
.EQU REPPSECNT #024H
.EQU REPDELAY  #025H
.EQU REPPAUSE  #026H
.EQU FLAGS     #027H ; b0 - передача разрешена
.EQU PULSE     #028H

.EQU CLCKDLY   2

.EQU KEYTBL    #030H

.org 0

dis i
jmp Entry

.org 3

dis i
jmp ExtInterrupt

.org 7
dis i
jmp TimerInterrupt

Entry:
sel	rb0
ent0	clk
en	tcnti

orl	p1,#010H ; trigger reset
anl	p1,#0EFH  

orl	p2,#0F0H ; LEDS on
orl	p1,#020H ; R/L on

call	Beep
call	Beep

anl	p2,#00FH ; LEDS off
anl	p1,#0DFH ; R/L off

call	Clear

mov	r2,#000H

main_loop:

mov	a,r2
rl	a
swap	a
andl	a,#0FH ; вычисляем номер байта. Т.е. a=r2/8
add     a,KEYTBL
mov 	r0,a
mov	a,@r0
mov	r7,a ;в r7 байт состояния клавиш

mov	a,r2
andl	a,#07H

jb0	oddbit ; делаем в r6 маску бита в байте по младшим разрядам счётчика
jb1	bits6n2
jb2	bit4
mov	r6,#01H
jmp 	checkKey

bit4:
mov	r6,#010H
jmp 	checkKey

oddbit:
jb1	bits7n3
jb2	bit5
mov	r6,#02H
jmp 	checkKey

bits6n2:
jb2	bit6
mov	r6,#04H
jmp 	checkKey

bits7n3:
jb2	bit7
mov	r6,#08H
jmp 	checkKey

bit5:
mov	r6,#020H
jmp 	checkKey

bit6:
mov	r6,#040H
jmp 	checkKey

bit7:
mov	r6,#080H

checkKey:

call	SelectRow
call	SelectCol

jnt1    key_not_pressed

orl     p1,#010H ; trigger reset
anl     p1,#0EFH

mov     r4,#045H
mov     r5,#002H
call    Delay

call    SelectCol ; try to read one more time
jnt1    key_not_pressed

orl     p1,#010H ; trigger reset
anl     p1,#0EFH

mov	a,r7
andl	a,r6
jz	new_key_pressed ; эта клавиша не была нажата

mov	r0,LASTKEY
mov	a,@r0
xrl	a,r2 ; проверяем, была ли эта клавиша нажата последней
jnz	update_counter ; если это не последняя клавиша, то ничего не делаем

inc	r0  ; теперь r0 == REPDLYCNT
mov	a,@r0
jz	do_repeat
dec	a
mov	@r0,a
jmp	update_counter ; просто уменьшаем счётчик задержки и сваливаем

do_repeat:

inc	r0  ; теперь r0 == REPPSECNT
mov	a,@r0
jz	send_repeat
dec	a
mov	@r0,a
jmp	update_counter ; просто уменьшаем счётчик интервала и сваливаем

send_repeat:
mov	a,REPPAUSE
mov	@r0,a ; инициализируем счётчик интервала репитера
jmp	send_key

new_key_pressed:

mov	a,r7
orl	a,r6
mov	@r0,a

mov	r0,LASTKEY ; сохраняем последнюю нажатую клавишу. Нужно для репитера
mov	a,r2
mov	@r0,a

inc	r0 ; теперь r0 == REPDLYCNT
mov	a,REPDELAY
mov	@r0,a ; инициализируем счётчик задержки репитера

inc	r0 ; теперь r0 == REPPSECNT
mov	a,REPPAUSE
mov	@r0,a ; инициализируем счётчик интервала репитера


send_key:

mov	r6,r2
call	send_r6
jmp	update_counter

key_not_pressed:

mov	a,r7
andl	a,r6
jz	update_counter ; клавиша не была нажата

mov	a,r7
xrl	a,r6 ; клавиша была нажата и теперь отпущена
mov	@r0,a

mov	a,r2
orl	a,#080H
mov	r6,a
call	send_r6
jmp	update_counter

update_counter:

inc	r2
mov	a,r2
jb7	reset_ctn

end_of_loop:
jmp	main_loop

reset_cnt:
mov	r2,0H
jmp	main_loop

;-----------------------------------

SelectCol:


mov	a,r2
jb2	odd_port

jb3	sel_port6

movd	p4,a
retr

sel_port6:
movd	p6,a
retr

odd_port:
jb3	sel_port7

movd	p5,a
retr

sel_port7:
movd	p7,a
retr

;-----------------------------------

SelectRow:

mov	a,r2
swap	a
anl	a,#007H ; select lower 3 bits for row number
mov	r1,a

mov	r0,P1STAT
mov	a,@r0
anl	a,#0F8H ; mask muliplexor lines
add     a,r1
mov     @r0,a

outl    p1,a  ; select row

retr

;-----------------------------------
Beep:
mov     r6,#0FEH
mov     r1,P1STAT

beep_loop:
mov     a,@r1
xrl     a,#008H
outl    p1,a
mov     r4,#01EH
mov     r5,#001H
call    Delay
mov     @r1,a
djnz    r6,beep_loop

retr

;------------------------------------

send_r6:
mov	r0,FLAGS
mov	a,@r0
jb0	end_of_send ; передача не разрешена

mov	r0,PUSLE
mov	a,@r0
mov	r4,a
mov	r5,#001H

mov	r1,P1STAT
mov	a,@r1

anl	a,#07FH
mov	@r1,a
outl	p1,a     ; start bit

mov	r3,0 ; счётчик чётности

anl	a,#03FH  ; clock pulse
outl	p1,a

mov	r7,#008H

send_loop:

call	Delay
orl	p1,#040H

mov	a,r6
anl	a,#001H
add	a,r3
mov	r3,a

mov	a,r6
rr	a
mov	r6,a
anl	a,#080H
add	a,@r1
outl	p1,a

call	Delay
anl	p1,#040H

djnz	r7,send_loop

call	Delay
orl	p1,#040H

mov	a,r3 ; посылаем бит чётности
rr	a
anl	a,#080H
add	a,@r1
outl	p1,a

call	Delay
anl	p1,#040H

call	Delay
orl	p1,#040H

anl	p1,#080H ; стоповый бит

call	Delay
anl	p1,#040H

call	Delay
orl	p1,#040H


end_of_send:
retr

;------------------------------------

Delay:
retr

Clear:
retr

ExtInterrupt:
retr

TimerInterrupt:
retr
