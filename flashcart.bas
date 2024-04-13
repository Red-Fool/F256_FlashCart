90    :
91    :rem "flashcart.bas - write flash cartidge."
92    :version$="Version 0.3 Beta."
93    :copyright$="Copyright (c) 2024, Ken Taylor.  All rights reserved."
94    :
95    :rem "this program released to public domain."
96    :rem "author attribution in derivative works is appreciated,"
97    :rem "not mandatory."
98    :
1000  cls 
1010  print "FlashCart F256 ";version$
1015  print copyright$
1020  input "Enter file name: ";filename$
1030  print "Attempting to load ";filename$;" to $10000..."
1040  bload filename$,$10000
1050  print "Erasing Flash..."
1060  eraseflash($100000)
1070  print "Writing 256KB..."
1080  writeflash($100000,$10000,$40000)
1085  print "Verifying 256KB";
1090  verifyflash($10000,$100000,$40000)
1100  end 
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
8010  offset=0
8020  while offset<len
8100  chklen=len-offset
8110  if chklen>$1000 then chklen=$1000
8120  chkoff=0:chkless=chklen-1
8130  memcpy($6000,adra+offset,chklen)
8140  memcpy($7000,adrb+offset,chklen)
8200  for pass=0 to 1
8210  assemble $5800,pass
8300  .loop
8310  .basea:lda $6000
8320  .baseb:cmp $7000:bne cmpfail
8330  .decchkless:dec @chkless:lda @chkless:cmp #$FF:bne incbasea
8340  dec @chkless+1:lda @chkless+1:cmp #$FF:beq done
8350  .incbasea:inc basea+1:bne incbaseb:inc basea+1
8360  .incbaseb:inc baseb+1:bne loop:inc baseb+2:jmp loop
8400  .cmpfail:lda basea+1:sta @chkoff:lda basea+2:sta @chkoff+1
8410  .done:rts 
8500  next 
8600  if chkoff>0
8610  print "":print "Compare fail at ";(chkoff-$6000)+addra+offset;"."
8620  print "    ";?(chkoff);" <> ";?(chkoff+$1000)
8630  end 
8640  else 
8650  print ".";
8660  endif 
8670  offset=offset+chklen
8680  wend 
8700  print "":print "Compare success."
8710  endproc 
