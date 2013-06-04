.EQU P1STAT  #021H

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

key_not_pressed:

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
mov     r1,#021H

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

Delay:
retr

Clear:
retr

ExtInterrupt:
retr

TimerInterrupt:
retr
