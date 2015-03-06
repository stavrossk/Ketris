uses crt,dos;
Type ConfigTyp=Record
       Sound_Card_Exists:Boolean;
       SoundCardName:String;
       BaseIO:Word;
       IRQ,DMA:Byte;
       ModFil:String;
       Player_Keys:Array[1..2,1..5]Of Byte;
       Player_Input_Device:Array[1..2]Of Byte;
     End;
     HighScoreListTyp=Record
       Name,Result:String[20];
     End;
var i,j:word;
    key:char;
    startdir:string;
    config:configtyp;
    confil:file of configtyp;
    HSFil,HLFil:file of highscorelisttyp;
    highscorelist,highlevellist:array[1..10]of highscorelisttyp;

procedure ruta(x1,y1,x2,y2:integer);
begin
  textbackground(blue);
  textcolor(yellow);
  gotoxy(x1,y1);
  write(chr(201));
  for i:=1 to (x2-x1-1) do
    write(chr(205));
  write(chr(187));
  for i:=(y1+1)to (y2-1) do begin
    gotoxy(x1,i);
    write(chr(186));
    for j:=1 to (x2-x1-1) do
      write(' ');
    gotoxy(x2,i);
    write(chr(186));
  end;
  gotoxy(x1,y2);
  write(chr(200));
  for i:=1 to (x2-x1-1) do
    write(chr(205));
  write(chr(188));
end;

begin
  textbackground(0);
  textcolor(lightgray);
  clrscr;
  for i:=1 to 2000 do
    write(chr(176));
  ruta(20,2,60,7);
  gotoxy(34,4);
  write('Ketris Setup');
  gotoxy(27,5);
  write(chr(184),'Kapsilon Productions 1996');
  ruta(10,9,70,21);
  window(25,11,70,20);
  Config.Sound_Card_Exists:=True;
  Writeln(' Select Sound Card: ');
  Writeln;
  Writeln(' 1. Gravis Ultrasound (Stereo)');
  Writeln(' 2. Sound Blaster 1.0 (Mono)');
  Writeln(' 3. Sound Blaster 2.0 (Mono)');
  Writeln(' 4. Sound Blaster Pro (Mono)');
  Writeln(' 5. Sound Blaster 16 (Stereo)');
  Writeln(' 6. Pro Audio Spectrum (Stereo)');
  Writeln(' 7. No Sound Card (Sucks)');
  Gotoxy(21,1);
  Case ReadKey of
    '1' : config.Soundcardname := 'GUS.MSE';
    '2' : config.Soundcardname := 'SB1X.MSE';
    '3' : config.Soundcardname := 'SB2X.MSE';
    '4' : config.Soundcardname := 'SBPRO.MSE';
    '5' : config.Soundcardname := 'SB16.MSE';
    '6' : config.Soundcardname := 'PAS.MSE';
    '7' : config.Sound_Card_Exists:=False;
  End;
  If Config.Sound_Card_Exists then Begin
    Window(1,1,80,25);
    ruta(13,10,50,22);
    Window(15,12,49,22);
    Writeln(' Select Base I/O Address: ');
    Writeln;
    Writeln(' 1. 210h');
    Writeln(' 2. 220h');
    Writeln(' 3. 230h');
    Writeln(' 4. 240h');
    Writeln(' 5. 250h');
    Writeln(' 6. 260h');
    GotoXY(27,1);
    Case ReadKey of
      '1' : Config.BaseIO := $210;
      '2' : Config.BaseIO := $220;
      '3' : Config.BaseIO := $230;
      '4' : Config.BaseIO := $240;
      '5' : Config.BaseIO := $250;
      '6' : Config.BaseIO := $260;
    Else Config.BaseIO := $FFFF;
    End;
    Window(1,1,80,25);
    ruta(16,11,53,23);
    Window(18,13,50,24);
    Writeln(' Select IRQ: ');
    Writeln;
    Writeln(' 1. IRQ 2');
    Writeln(' 2. IRQ 3');
    Writeln(' 3. IRQ 5');
    Writeln(' 4. IRQ 7');
    Writeln(' 5. IRQ 11');
    Writeln(' 6. IRQ 12');
    Gotoxy(14,1);
    Case ReadKey of
      '1' : Config.IRQ := 2;
      '2' : Config.IRQ := 3;
      '3' : Config.IRQ := 5;
      '4' : Config.IRQ := 7;
      '5' : Config.IRQ := 11;
      '6' : Config.IRQ := 12;
    Else
      Config.IRQ := $F
    End;
    Window(1,1,80,25);
    ruta(19,12,56,22);
    Window(21,14,55,23);
    Writeln(' Select DMA Channel: ');
    Writeln;
    Writeln(' 1. DMA Channel 1');
    Writeln(' 2. DMA Channel 2');
    Writeln(' 3. DMA Channel 3');
    Writeln(' 4. DMA Channel 5');
    Gotoxy(22,1);
    Case ReadKey of
      '1' : Config.DMA := 1;
      '2' : Config.DMA := 2;
      '3' : Config.DMA := 3;
      '4' : Config.DMA := 5;
    Else Config.DMA := $FF;
    End;
  End;
  Window(1,1,80,25);
  ruta(22,13,65,21);
  Window(24,15,65,24);
  writeln('Setup Complete.');
  writeln('Saving Config.');
  assign(confil,'Config.sve');
  rewrite(confil);
  getdir(0,startdir);
  config.modfil:=startdir+'\'+'tetris.mod';
  Config.player_input_device[1]:=1;
  Config.player_input_device[2]:=1;
  Config.Player_Keys[1,1]:=52;
  Config.Player_Keys[1,2]:=54;
  Config.Player_Keys[1,3]:=50;
  Config.Player_Keys[1,4]:=13;
  Config.Player_Keys[1,5]:=53;
  Config.Player_Keys[2,1]:=97;
  Config.Player_Keys[2,2]:=100;
  Config.Player_Keys[2,3]:=122;
  Config.Player_Keys[2,4]:=120;
  Config.Player_Keys[2,5]:=115;
  write(confil,Config);
  close(confil);
  Writeln;
  Write('Create new score/level lists (Y/N): ');
  key:=' ';
  while (upcase(key)<>'Y') and (upcase(key)<>'N') do begin
    gotoxy(72,21);
    key:=readkey;
  end;
  if upcase(key)='Y' then begin
    assign(HSfil,'hiscore.lst');
    rewrite(HSfil);
    assign(HLFil,'Hilevel.lst');
    rewrite(HLFil);
    for i:=1 to 10 do begin
      highscorelist[i].name:=' ';
      highscorelist[i].result:='0';
      highlevellist[i].name:=' ';
      highlevellist[i].result:='0';
      write(HSfil,highscorelist[i]);
      write(HLFil,highlevellist[i]);
    end;
    close(HSFil);
    Close(HLFil);
  end;
  textbackground(black);
  textcolor(lightgray);
  window(1,1,80,25);
  clrscr;
  Writeln('Ketris Setup Done!');
end.
