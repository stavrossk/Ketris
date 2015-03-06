{$O+}                                  {Overlays till†tna}
{$G+}                                  {286 instruktioner till†tna}
Unit Diverse;

INTERFACE

uses crt;

Procedure SetColor(c: word; r,g,b: byte);
procedure effect1;         {olika ljudeffekter}
procedure effect2;
procedure effect3;
procedure setmode(mode:word);        {s„tt grafikl„ge}
procedure setfont(font:word);        {v„lj font}
procedure moveup(x1,y1,x2,y2,newy:word);
procedure movedown(x1,y1,x2,y2,newy:word);
procedure printxy(s:string;x,y:byte;c:byte);{skriv ut str„ng s vid x,y med f„rg c}
procedure fillblock(x1,y1,x2,y2:word;color:byte);{fyll en rektangel med f„rgen color}
procedure hline(x1,y1,x2:word;color:byte);
procedure vline(x1,y1,y2:word;color:byte);
procedure cursorpos(xpos,ypos:byte);
procedure maxkbspeed;
procedure cls;

IMPLEMENTATION

Procedure maxkbspeed;assembler;
asm
    mov ah,$03
    mov al,$05
    xor bx,bx
    int 16h
end;                                    {st„ll in tangentbordets hastighet}

Procedure SetColor(c: word; r,g,b: byte);
Begin
  Port[$3c8]:=c;
  Port[$3c9]:=r;
  Port[$3c9]:=g;
  Port[$3c9]:=b;
End;

procedure effect1;         {olika ljudeffekter}
var frec:word;
begin
  frec:=100;
  repeat
    sound(frec);
    delay(1);
    inc(frec,20);
  until frec>2000;
  repeat
    sound(frec);
    delay(1);
    dec(frec,20);
  until frec<100;
  nosound;
end;

procedure effect2;
var frec,uppr:word;
begin
  for uppr:=1 to 5 do begin
    frec:=100;
    repeat
      sound(frec);
      delay(1);
      inc(frec,40);
    until frec>3000;
  end;
  repeat
    sound(frec);
    delay(1);
    dec(frec,10);
  until frec<100;
  nosound;
end;

procedure effect3;
begin
  sound(200);
  delay(50);
  nosound;
end;

procedure setmode(mode:word);assembler;        {s„tt grafikl„ge}
asm
  mov ax,mode
  int 10h
end;

procedure setfont(font:word);assembler;        {v„lj font}
asm                       {0=8*8}
  mov ax,1120h            {2=8*14}
  add ax,font             {3=8*8}
  int 10h                 {4=8*16}
end;

procedure moveup(x1,y1,x2,y2,newy:word);assembler;
asm
  cld
  push ds
  mov ax,$a000
  mov es,ax
  mov ds,ax
  mov ax,320
  mul y1
  mov si,x1
  add si,ax    {si=”vre v„nstra punkten p† k„llrutan}
  mov ax,320
  mul newy
  mov di,x1
  add di,ax    {di=”vre v„nstra punkten p† destinationsrutan}
  mov dx,x2
  sub dx,x1    {dx=antal punkter i x-led}
  inc dx       {korrektion}
  mov ax,320
  sub ax,dx    {ax=320-antal punkter}
  mov bx,y2
  sub bx,y1    {bx=antal rader}
  @yledloop:
  mov cx,dx
  rep movsb
  add di,ax
  add si,ax
  dec bx
  jns @yledloop
  pop ds
end;

procedure movedown(x1,y1,x2,y2,newy:word);assembler;
asm
  std
  push ds
  mov ax,$a000
  mov es,ax
  mov ds,ax
  mov ax,320
  mov bx,y2
  mul bx
  mov si,x2
  add si,ax    {si=nedre h”gra punkten p† k„llrutan}
  sub bx,y1    {bx=antal rader}
  add newy,bx
  mov ax,320
  mul newy
  mov di,x2
  add di,ax    {di=nedre h”gra punkten p† destinationsrutan}
  mov dx,x2
  sub dx,x1    {dx=antal rader}
  inc dx       {korrektion}
  mov ax,320
  sub ax,dx    {ax=320-antal punkter}
  @yledloop:
  mov cx,dx
  rep movsb
  sub di,ax
  sub si,ax
  dec bx
  jns @yledloop
  pop ds
  cld
end;

procedure printxy(s:string;x,y:byte;c:byte);   {skriv ut str„ng s vid x,y med f„rg c}
var langd:word;
begin
  langd:=length(s);
  asm
    pusha
    mov ah,$13
    mov al,$1         {s„tt bit 1}
    xor bh,bh
    mov bl,c
    mov cx,langd
    mov dh,y
    mov dl,x
    lea bp,[s+1]
    int 10h
    popa
  end;
end;

procedure cls;assembler;
asm
  mov ax,$a000
  mov es,ax
  xor ax,ax
  xor di,di
  mov cx,32000
  rep stosw
end;

procedure fillblock(x1,y1,x2,y2:word;color:byte);assembler;   {fyll en rektangel med f„rgen color}
asm
    mov ax,$a000
    mov es,ax
    mov ax,y1
    mov di,x1
    mov bx,y2
    mov si,x2
    cmp ax,bx
    jb @nobyt1
    xchg ax,bx        {om y1>y2 s† byt}
  @nobyt1:
    cmp di,si
    jb @nobyt2
    xchg di,si        {om x1>x2 s† byt}
  @nobyt2:
    sub si,di
    inc si            {si=antal punkter i x-led}
    sub bx,ax
    inc bx            {bx=antal punkter i y-led}
    mov cx,140h
    mul cx
    add di,ax        {di=x1+y1*320}
    mov dx,cx        {dx=320}
    sub dx,si        {dx=320-antal punkter i x-led}
    mov al,color
  @fbloop:
    mov cx,si
    rep stosb
    add di,dx
    dec bx
    jnz @fbloop
end;

procedure hline(x1,y1,x2:word;color:byte);assembler;
asm
  mov ax,$a000
  mov es,ax
  mov bx,x1
  mov cx,x2
  cmp bx,cx
  jb @nobyt3
  xchg cx,bx     {om x1>x2 s† byt}
  @nobyt3:
  mov ax,140h
  mul y1         {ax=y1*320}
  sub cx,bx
  inc cx         {cx=antal punkter att rita}
  add bx,ax      {bx=y1*320+x1}
  mov al,color
  @hlinloop:
  mov es:[bx],al
  inc bx
  loop @hlinloop
end;

procedure vline(x1,y1,y2:word;color:byte);assembler;
asm
  mov ax,$a000
  mov es,ax
  mov si,y1
  mov di,y2
  cmp si,di
  jb @nobyt4
  xchg si,di       {om y1>y2 s† byt}
  @nobyt4:
  mov ax,140h
  mul si
  sub di,si
  inc di           {di=antal rader att rita}
  mov bx,ax
  add bx,x1
  mov al,color
  @vlinloop:
  mov es:[bx],al
  add bx,140h
  dec di
  jnz @vlinloop
end;

procedure cursorpos(xpos,ypos:byte);assembler;
asm
  mov ah,2
  xor bh,bh
  mov dl,xpos
  mov dh,ypos
  int 10h
end;
end.