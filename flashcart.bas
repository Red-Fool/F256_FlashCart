90    :
91    :rem "flashcart.bas - write flash cartidge."
92    :version$="Version 0.5 Beta."
93    :copyright$="Copyright (c) 2024, Ken Taylor.  All rights reserved."
94    :
95    :rem "this program released to public domain."
96    :rem "author attribution in derivative works is appreciated,"
97    :rem "not mandatory."
98    :
100   frontline=0:filename$="default.bin":bufferaddr=$10000:flashaddr=$100000:length=$40000
1000  while true 
1010  printheader()
1020  opt$=get$()
1025  frontline=0
1030  if opt$="f"
1034  input "Enter file name: ";filename$
1038  endif 
1040  if opt$="b"
1044  print "Enter Buffer Address:$";:gethex():bufferaddr=outvalue
1048  endif 
1050  if opt$="t"
1054  print "Enter Target Address:$";:gethex():flashaddr=outvalue
1058  endif 
1060  if opt$="s"
1064  print "Enter Buffer Size:$";:gethex():length=outvalue
1068  endif 
1070  if opt$="l"
1073  print "Loading ";filename$;" to ";bufferaddr;
1076  bload filename$,bufferaddr
1079  endif 
1080  if opt$="d"then frontline=2200
1090  if opt$="v"then frontline=2300
1100  if opt$="c"
1103  print "Enter Clear Value:$";:gethex()
1106  memset(bufferaddr,outvalue&$FF,length)
1109  endif 
1110  if opt$="e"
1114  print "Erasing Flash...":eraseflash(flashaddr)
1118  endif 
1120  if opt$="w"
1124  print "Writing Flash...":writeflash(flashaddr,bufferaddr,length)
1128  endif 
1130  if opt$="x"then print chr$(146);:cls :end 
1140  wend 
2000  proc printheader()
2010  print chr$(144);:cls 
2020  print chr$(135);"FlashCart F256 ";version$:print copyright$
2025  print chr$(134)
2030  print "File=";filename$;":";
2040  print "Buffer=";:printhex(bufferaddr):print ":";
2050  print "Target=";:printhex(flashaddr):print ":";
2060  print "Size=";:printhex(length):print ""
2065  print chr$(143)
2070  if frontline<>0 then gosub frontline
2075  print chr$(142)
2080  print "  f) Set file name    b) Buffer address   t) Target address   ";
2085  print "s) Buffer size"
2090  print "  l) Load file        d) Directory        v) Verify buffer    ";
2095  print "c) Clear buffer"
2100  print "  e) Erase Flash      w) Write Flash      x) Exit program"
2105  print chr$(143);
2110  endproc 
2200  dir :return 
2300  print "Verify Flash";:verifyflash(bufferaddr,flashaddr,length)
2310  return 
2990  :
2991  :rem "print a number in hex."
2992  :
3000  proc printhex(value)
3010  hex$="0123456789abcdef"
3020  print "$";
3030  for i=0 to 5
3040  print mid$(hex$,((value>>(20-(i*4)))&$F)+1,1);
3050  next 
3060  endproc 
3490  :
3491  :rem "get a hex number."
3492  :
3500  proc gethex()
3510  input value$
3520  outvalue=0:index=0
3530  for i=1 to len(value$)
3540  cur$=mid$(value$,i,1)
3550  if isval(cur$) then outvalue=outvalue*16+val(cur$)
3560  if (asc(cur$)>=asc("a"))&(asc(cur$)<=asc("f"))
3570  outvalue=outvalue*16+(asc(cur$)-asc("a"))+10
3580  endif 
3590  if (asc(cur$)>=asc("A"))&(asc(cur$)<=asc("F"))
3600  outvalue=outvalue*16+(asc(cur$)-asc("A"))+10
3610  endif 
3620  next 
3630  endproc 
4990  :
4991  :rem "copy memory using the cpu."
4992  :
5000  proc memcpy(dst,src,len)
5010  len=len-1
5020  codeaddr=$5800
5030  pagereg=$0B:pageaddr=$6000:pageahi=$60:pageaend=$80
5040  srcpg=src>>13:srcstart=src&$1FFF
5050  dstpg=dst>>13:dststart=dst&$1FFF
5060  for pass=0 to 1
5070  assemble codeaddr,pass
5080  lda $00:pha :ora #$80:sta $00
5090  lda pagereg:pha 
5100  ldx #srcpg:ldy #dstpg
5110  .loop
5120  stx pagereg
5130  .csrc:lda srcstart+pageaddr
5140  sty pagereg
5150  .cdst:sta dststart+pageaddr
5160  .declen:dec @len:lda @len:cmp #$FF:bne incsrc
5170  dec @len+1:lda @len+1:cmp #$FF:bne incsrc
5180  dec @len+2:lda @len+2:cmp #$FF:beq cpydone
5190  .incsrc:inc csrc+1:bne incdst
5200  inc csrc+2:lda csrc+2:cmp #pageaend:bne incdst
5210  lda #pageahi:sta csrc+2:inx 
5220  .incdst:inc cdst+1:bne loop
5230  inc cdst+2:lda cdst+2:cmp #pageaend:bne loop
5240  lda #pageahi:sta cdst+2:iny 
5250  jmp loop
5260  .cpydone
5270  pla :sta pagereg
5280  pla :sta $00
5290  rts 
5300  next 
5310  call codeaddr
5320  endproc 
5990  :
5991  :rem "write data to flash."
5992  :
6000  proc writeflash(dst,src,len)
6010  len=len-1
6020  codeaddr=$5800
6030  pagereg=$0B:pageaddr=$6000:pageahi=$60:pageaend=$80
6040  srcpg=src>>13:srcstart=src&$1FFF
6050  dstpg=dst>>13:dstzp=$FE
6060  dststartl=dst&$FF:dststarth=((dst>>8)&$1F)+pageahi
6070  pagea=($102AAA)>>13:addra=(($102AAA)&$1FFF)+pageaddr
6080  page5=($105555)>>13:addr5=(($105555)&$1FFF)+pageaddr
6100  for pass=0 to 1
6110  assemble codeaddr,pass
6200  lda dstzp+1:pha :lda dstzp:pha 
6210  lda #dststartl:sta dstzp:lda #dststarth:sta dstzp+1
6220  lda $00:pha :ora #$80:sta $00
6230  lda pagereg:pha 
6240  ldx #srcpg:ldy #dstpg
6400  .loop
6410  stx pagereg
6420  .csrc:lda srcstart+pageaddr
6425  sty pagereg:ldy #$00:and (dstzp),y:pha :ldy pagereg
6430  lda #page5:sta pagereg:lda #$AA:sta addr5
6440  lda #pagea:sta pagereg:lda #$55:sta addra
6450  lda #page5:sta pagereg:lda #$A0:sta addr5
6460  sty pagereg
6470  ldy #$00:pla :sta (dstzp),y
6480  .waitloop:cmp (dstzp),y:bne waitloop
6490  ldy pagereg
6500  .declen:dec @len:lda @len:cmp #$FF:bne incsrc
6510  dec @len+1:lda @len+1:cmp #$FF:bne incsrc
6520  dec @len+2:lda @len+2:cmp #$FF:beq cpydone
6530  .incsrc:inc csrc+1:bne incdst
6540  inc csrc+2:lda csrc+2:cmp #pageaend:bne incdst
6550  lda #pageahi:sta csrc+2:inx 
6560  .incdst:inc dstzp:bne loop
6570  inc dstzp+1:lda dstzp+1:cmp #pageaend:bne loop
6580  lda #pageahi:sta dstzp+1:iny :jmp loop
6600  .cpydone
6610  pla :sta pagereg
6620  pla :sta $00
6630  pla :sta dstzp
6640  pla :sta dstzp+1
6650  rts 
6700  next 
6800  call codeaddr
6900  endproc 
6990  :
6991  :rem "erase flash chip."
6992  :
7000  proc eraseflash(addr)
7010  pagereg=$0B:pageaddr=$6000
7020  page5=(addr+$5555)>>13:addr5=((addr+$5555)&$1FFF)+pageaddr
7030  pagea=(addr+$2AAA)>>13:addra=((addr+$2AAA)&$1FFF)+pageaddr
7040  savedpg=?pagereg
7100  ?pagereg=page5:?addr5=$AA:?pagereg=pagea:?addra=$55
7110  ?pagereg=page5:?addr5=$80
7120  ?pagereg=page5:?addr5=$AA:?pagereg=pagea:?addra=$55
7130  ?pagereg=page5:?addr5=$10
7200  ?pagereg=savedpg
7210  rem "delay roughly 1 second."
7220  rem "technically, could be 100ms, but longer is safer."
7230  myevent=0
7240  repeat 
7250  if event(eventtime,30) then myevent=myevent+1
7260  until myevent=2
7270  endproc 
7990  :
7991  :rem "compare two ranges and report."
7992  :
8000  proc verifyflash(adra,adrb,len)
8010  offset=0:chkoff=0
8020  while offset<len
8100  chklen=len-offset
8110  if chklen>$1000 then chklen=$1000
8120  chkless=chklen-1
8130  memcpy($6000,adra+offset,chklen)
8140  memcpy($7000,adrb+offset,chklen)
8200  for pass=0 to 1
8210  assemble $5800,pass
8300  .loop
8310  .basea:lda $6000
8320  .baseb:cmp $7000:bne cmpfail
8330  .decchkless:dec @chkless:lda @chkless:cmp #$FF:bne incbasea
8340  dec @chkless+1:lda @chkless+1:cmp #$FF:beq done
8350  .incbasea:inc basea+1:bne incbaseb:inc basea+2
8360  .incbaseb:inc baseb+1:bne loop:inc baseb+2:jmp loop
8400  .cmpfail:lda basea+1:sta @chkoff:lda basea+2:sta @chkoff+1
8410  .done:rts 
8500  next 
8510  call $5800
8600  if chkoff>0
8610  print "":print "Compare fail at ";(chkoff-$6000)+addra+offset;"."
8620  print "    ";?(chkoff);" <> ";?(chkoff+$1000)
8630  offset=len-chklen
8640  else 
8650  print ".";
8660  endif 
8670  offset=offset+chklen
8680  wend 
8700  if chkoff=0 then print "":print "Compare success."
8710  endproc 
8990  :
8991  :rem "setmem function to set memory to value."
8992  :
9000  proc memset(dst,val,len)
9010  len=len-1
9020  codeaddr=$5800
9030  pagereg=$0B:pageaddr=$6000:pageahi=$60:pageaend=$80
9040  dstpg=dst>>13:dststart=dst&$1FFF
9050  for pass=0 to 1
9060  assemble codeaddr,pass
9100  lda $00:pha :ora #$80:sta $00
9110  lda pagereg:pha :ldx #dstpg
9200  .loop
9210  lda #val:stx pagereg
9220  .cdst:sta dststart+pageaddr
9300  .declen:dec @len:lda @len:cmp #$FF:bne incdst
9310  dec @len+1:lda @len+1:cmp #$FF:bne incdst
9320  dec @len+2:lda @len+2:cmp #$FF:beq done
9400  .incdst:inc cdst+1:bne loop
9410  inc cdst+2:lda cdst+2:cmp #pageaend:bne loop
9420  lda #pageahi:sta cdst+2:inx :jmp loop
9500  .done
9510  pla :sta pagereg
9520  pla :sta $00
9530  rts 
9600  next 
9700  call codeaddr
9710  endproc 
