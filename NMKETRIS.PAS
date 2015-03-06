Program Tetris;
{$M 4000,0,40000}                      {Not more heap than needed}
{$O+}
{$G+}                                  {286 instruktioner till†tna}
Uses Dos,Crt,Diverse{,Mse_tp};
Type BlockTyp=Array[1..8]Of Word;      {j„mna tal=X-v„rden,oj„mna tal=Y-v„rden}
     HighScoreListTyp=Record
       Name,Result:String[20];
     End;
     FilInfo=Record
       Name:String[8];
       Ending:String[3];
       Dir,Disk:Boolean;
     End;
     ConfigTyp=Record
       Sound_Card_Exists:Boolean;
       SoundCardName:String;
       BaseIO:Word;
       IRQ,DMA:Byte;
       ModFil:String;
       Player_Keys:Array[1..2,1..5]Of Byte;
       Player_Input_Device:Array[1..2]Of Byte;
     End;
Const BlockShape:Array[1..7]Of BlockTyp=(
      (10, 0,10,10,10,20,10,30),       {rak fyra}
      ( 0, 0, 0,10,10,10,10, 0),       {kvadrat}
      ( 0, 0, 0,10,10,10,10,20),       {2+2,h”ger}
      (10, 0, 0,10,10,10, 0,20),       {2+2,v„nster}
      (10, 0,10,10, 0,20,10,20),       {3+1,h”ger}
      (10, 0,10,10,10,20,20,20),       {3+1,v„nster}
      (10, 0, 0,10,10,10,20,10));      {3+1,mitten}
    Delays:Array[0..21]Of Word=
    (89,83,77,71,65,59,54,49,44,39,34,30,26,22,18,15,12,9,7,6,5,0);
    VerNr='2.1';

Var HiScores:Array[1..10]Of Longint;
    HiLevels:Array[1..10]Of Byte;
    LineScores:Array[1..4]Of Longint;
    FreeCol,X,Y,Typ,WaitsToGo,WaitsDone,Next,MaxHeight:Array[1..2]Of Integer;
    BlockColor:Array[1..2]Of Byte;
    HighScoreList,HighLevelList:Array[1..10]Of HighScoreListTyp;
    Block:Array[1..2]Of BlockTyp;
    Check:BlockTyp;
    LastBarValue:Array[1..32]Of Byte;
    BlocksDown:Array[1..600]Of Byte;
    LinesMade,Level,Menyval,StartLevel,StartHeight,BarStartX,PixelsPerBar:Integer;
    FilPosition,Score:Longint;
    I,J,K,DefPlayer,EMSFlag,MusicChannels,DMABuffer,SampleRate:Word;
    TextX,TextY,Players,ToNext,BarWidth,KeyCode:Byte;
    MusicOn,SFX,Slut,Ok,NewDir:Boolean;
    SS:FilInfo;
    OSS:SearchRec;
    StartDir,Katalog,LevelString,ScoreString:String;
    Key:Char;
    HSFil,HLFil:File Of HighScoreListTyp;
    ConfigFile:File Of ConfigTyp;
    FileList:File Of FilInfo;
    Handle,Oldmod: File;
    Config:ConfigTyp;
    {Header : GDMHeader;}

procedure sortfilelist;
var a,b:string[3];
    ss2:FilInfo;
    FL:integer;
begin
  reset(FileList);
  FL:=filesize(FileList)-1;
  for I:=1 to fl do begin
    seek(FileList,i);
    read(FileList,ss);
    for j:=(i+1) to fl do begin
      seek(FileList,j);
      read(FileList,ss2);
      If ss.Dir xor ss2.Dir then begin
        {om en av posterna „r katalog och den andra inte „r det}
        if ss2.Dir then begin
          seek(FileList,i);
          write(FileList,ss2);
          seek(FileList,j);
          write(FileList,ss);
          ss:=ss2;
        end;
      end
      else if (SS.Ending>SS2.Ending) or ((SS.Ending=SS2.Ending) and (ss.name>ss2.name)) then begin
        seek(FileList,i);
        write(FileList,ss2);
        seek(FileList,j);
        write(FileList,ss);
        ss:=ss2;
      end;
    end;
  end;
end;

Procedure ResetBars;
Begin
  If MusicOn Then Begin
    For I:=1 To MusicChannels Do Begin
      LastBarValue[I]:=0;
      {ChannelVU(I,1);}
    End;
    PixelsPerBar:=116 div MusicChannels;
    BarWidth:=PixelsPerBar-(50-MusicChannels) div 10;
    BarStartX:=(120-(PixelsPerBar*MusicChannels)) div 2-PixelsPerBar;
    If PixelsPerBar*(MusicChannels-1)+BarWidth>=114 then
      Dec(BarStartX);
    If (Menyval=1) Or (Menyval=4) Then
      Inc(BarStartX,22);
  End;
End;

Procedure DrawVUBars;
Var BarValue:array[1..32]Of Byte;
Begin
  Inc(Tonext);
  If ToNext>10 Then ToNext:=0;
  If ToNext=0 then
    For I:=1 To MusicChannels Do Begin
      {j:=channelvu(i,$ff);}
      If (j=0) Then
        Barvalue[I]:=0
      {Else
        BarValue[I]:=ChannelVU(I,ChannelVU(I,$FF)-1)};
      If BarValue[I]>LastBarValue[I] Then
        For J:=LastBarValue[I] To BarValue[I] Do
          HLine(BarStartX+I*PixelsPerBar,132-J,BarStartX+I*PixelsPerBar+BarWidth,J+100);
      If BarValue[I]<LastBarValue[I] Then
        For J:=BarValue[I] To LastBarValue[I] Do
          HLine(BarStartX+I*PixelsPerBar,132-J,BarStartX+I*PixelsPerBar+BarWidth,0);
      LastBarValue[I]:=BarValue[I];
    End;
End;

Procedure Meny;
Const Texts:Array[1..9]Of String[40]=
      ('          One player game',
      '      Two players, same computer',
      ' Two players, same computer, team play',
     '      Two players, two computers',
     '      Four players, two computers',
     '     Set starting level and height',
     '         Configure controls',
     '          View high scores',
     '             Quit game');
Begin
  SetColor(15,0,0,0);
  PrintXY('Ketris Main Menu',11,1,15);
  PrintXY('--------------------------------------',1,2,15);
  For I:=1 To 9 Do
    PrintXY(Texts[I],1,I+2,15);
  Key:=' ';
  For I:=0 To 63 Do Begin
    SetColor(15,I,I,I);
    Delay(5);
  End;
  I:=1;
  Repeat
    PrintXY(texts[I],1,I+2,34);
    If KeyPressed Then Begin
      Key:=ReadKey;
      If Key=#0 Then Key:=ReadKey;
      Case Ord(Key) Of
	72,56:If I>1 Then Begin
			    PrintXY(texts[I],1,I+2,15);
			    Dec(I);
			  End
		     Else Begin
			    PrintXY(texts[I],1,3,15);
			    I:=9;
			  End;
	80,50:If I<9 Then Begin
			    PrintXY(texts[I],1,I+2,15);
			    Inc(I);
			  End
		     Else Begin
			    PrintXY(texts[I],1,11,15);
			    I:=1;
			  End;
      End;
    End;
  Until Ord(Key)=13;
  Menyval:=I;
End;

Procedure DrawBlocks(Color:Byte);       {rita klossar}
Begin
  I:=1;
  Repeat
    FillBlock(X[DefPlayer]+Block[DefPlayer,I]+1,Y[DefPlayer]+Block[DefPlayer,
      I+1]+1,X[DefPlayer]+Block[DefPlayer,I]+8,Y[DefPlayer]+Block[DefPlayer,
      I+1]+8,Color);
    Inc(I,2);
  Until I>8;
End;

Procedure Correct(xl1,xl2:Integer);
Begin
  I:=1;
  Repeat
    If (Check[I]+X[DefPlayer])<xl1 Then
      Inc(X[DefPlayer],10);
    If (Check[I]+X[DefPlayer])>xl2 Then
      Dec(X[DefPlayer],10);
    Inc(I,2);
  Until I>8;
End;

Procedure Rotate;                                {rotera klossar}
var OtherPlayer:Byte;
Begin
  If Not (Typ[DefPlayer]=2) Then Begin
    I:=1;
    If Typ[DefPlayer]>2 Then
      Repeat
	Check[I+1]:=20-Block[DefPlayer,I];       {nytt Y-v„rde}
	Check[I]:=Block[DefPlayer,I+1];          {nytt X-v„rde}
	Inc(I,2);
      Until I>8
    Else
      Repeat
	Check[I+1]:=Block[DefPlayer,I];
	Check[I]:=Block[DefPlayer,I+1];
	Inc(I,2);
      Until I>8;
    Case Menyval Of
      1,4:Correct(160,290);
      2:If DefPlayer=1 Then Correct(10,140) Else Correct(170,300);
      3,5:Correct(120,310);
    End;
    I:=1;
    Ok:=True;
    Repeat
      J:=(Check[I+1]+Y[DefPlayer])*320+Check[I]+X[DefPlayer];
      If (Mem[$A000:J]>3) Or (Mem[$A000:J+2880]>3) Then
        Ok:=False;
      If Players=2 Then Begin
        J:=1;
        If DefPlayer=2 then OtherPlayer:=1 else OtherPlayer:=2;
        Repeat
          If X[DefPlayer]+Check[I]=X[OtherPlayer]+Block[OtherPlayer,J] Then
            If Abs((Y[DefPlayer]+Check[I+1])-(Y[OtherPlayer]+Block[OtherPlayer,J+1]))<10 Then
              Ok:=False;
          Inc(J,2);
        Until J>8;
      End;
      Inc(I,2);
    Until I>8;
    If Ok Then
      Block[DefPlayer]:=Check;
  End;
End;

Procedure Ram(Color1,Color2:Byte);            {Ram p† klossarna}
Var xp,yp:Integer;
Begin
  I:=1;
  Repeat
    xp:=X[DefPlayer]+Block[DefPlayer,I];
    yp:=Y[DefPlayer]+Block[DefPlayer,I+1];
    HLine(xp,yp,xp+9,Color1);
    VLine(xp,yp,yp+9,Color1);
    HLine(xp,yp+9,xp+9,Color2);
    VLine(xp+9,yp,yp+9,Color2);
    Inc(I,2);
  Until I>8;
End;

Function DownOk:boolean;             {kolla om fritt ned†t}
Begin
  Ok:=True;
  I:=1;
  Repeat
    If Mem[$A000:(Y[DefPlayer]+Block[DefPlayer,I+1]+10)*320+Block
      [DefPlayer,I]+X[DefPlayer]]>253 Then
      Ok:=False;
    If (Y[DefPlayer]+Block[DefPlayer,I+1])>189 Then
      Ok:=False;
    If Players=2 Then Begin
      J:=1;
      Repeat
        If X[1]+Block[1,I]=X[2]+Block[2,J] Then
          If Abs((Y[1]+Block[1,I+1])-(Y[2]+Block[2,J+1]))<10 Then
            WaitsToGo[DefPlayer]:=Delays[Level];
        Inc(J,2);
      Until J>8;
    End;
    Inc(I,2);
  Until I>8;
  DownOk:=Ok;
End;

Function LeftRightOk(Tal1,Tal2:Integer):Boolean;  {kolla om fritt till v„nster eller h”ger}
Var OtherPlayer:Byte;
Begin
  I:=1;
  Ok:=True;
  Repeat
    J:=(Block[DefPlayer,I+1]+Y[DefPlayer])*320+Block[DefPlayer,I]+X[DefPlayer];
    If (Mem[$A000:J+Tal1]>3) Or (Mem[$A000:J+Tal2]>3) Then
      Ok:=False;
    If (tal1=10) And (X[DefPlayer]+Block[DefPlayer,I]>=310) Then
      Ok:=False;
    If Players=2 Then Begin
      J:=1;
      If DefPlayer=2 then OtherPlayer:=1 else OtherPlayer:=2;
      If Tal1=-1 Then Tal1:=-10;
      Repeat
        If X[DefPlayer]+Block[Defplayer,I]+Tal1=X[OtherPlayer]+Block[OtherPlayer,J] Then
          If Abs((Y[DefPlayer]+Block[DefPlayer,I+1])-(Y[OtherPlayer]+Block[OtherPlayer,J+1]))<10 Then
            Ok:=False;
        Inc(J,2);
      Until J>8;
    End;
    Inc(I,2);
  Until I>8;
  LeftRightOk:=Ok;
End;

Procedure ScrollDown;             {scrolla ner klossar ett steg}
Var Color:Byte;
Begin
  I:=1;
  Color:=BlockColor[DefPlayer];
  Repeat
    J:=X[DefPlayer]+Block[DefPlayer,I]+(Block[DefPlayer,I+1]+Y[DefPlayer])*320;
    Asm
      MOV AX,$A000
      MOV ES,AX
      MOV BX,J
      MOV AL,2
      CMP ES:[BX],AL          {„r punkten J vit?}
      JNE @NEXT1              {om inte, s† g† till n„sta}
      MOV CX,10               {annars rita en tio punkters}
      XOR AL,AL
      @L1:                    {horisontell svart linje}
      MOV ES:[BX],AL
      INC BX
      LOOP @L1
      SUB BX,10               {svart linje klar}
      @NEXT1:
      ADD BX,320              {g† till n„sta rad}
      MOV AL,2
      MOV CX,9                {rita en 9 punkters}
      @L2:                    {horisontell vit linje}
      MOV ES:[BX],AL
      INC BX
      LOOP @L2
      INC AL
      MOV ES:[BX],AL          {rita en gr† punkt}
      ADD BX,2551
      DEC AL
      MOV ES:[BX],AL          {rita en vit punkt}
      INC BX
      MOV AL,COLOR            {rita en 8 punkters horisontell}
      MOV CX,8                {linje med f„rgen BlockColor}
      @L3:
      MOV ES:[BX],AL
      INC BX
      LOOP @L3
      ADD BX,311              {linje klar,g† till n„sta rad}
      MOV AL,3                {avslutningsvis, rita en}
      MOV CX,10               {horisontell 10 punkters gr† linje}
      @L4:
      MOV ES:[BX],AL
      INC BX
      LOOP @L4
    End;                      {klart!}
    Inc(I,2);
  Until I>8;
  Inc(Y[DefPlayer]);                    {”ka Y}
End;

Procedure ShowNextBlock;
Var Xp,Yp:Word;
Begin
  J:=1;
  Repeat
    If Players=2 Then
      Xp:=DefPlayer*35+10+BlockShape[Next[DefPlayer],J]
    Else
      Xp:=80+BlockShape[Next[DefPlayer],J];
    Yp:=58+BlockShape[Next[DefPlayer],J+1];
    FillBlock(Xp,Yp,Xp+8,Yp+8,Next[DefPlayer]+9);
    HLine(Xp,Yp,Xp+9,2);
    VLine(Xp,Yp,Yp+9,2);
    HLine(Xp,Yp+9,Xp+9,3);
    VLine(Xp+9,Yp,Yp+9,3);
    Inc(J,2);
  Until J>8;
End;

Procedure RewriteInfoScreen;
Begin
  If Players=1 then
    FillBlock(21,21,138,178,0);
  if menyval=3 then
    FillBlock(0,20,118,178,0);
  If Config.Sound_Card_Exists then
    ResetBars;
  PrintXY('KETRIS',TextX,3,45);
  PrintXY('Ver '+VerNr,TextX,4,46);
  PrintXY('--------------',TextX,5,47);
  PrintXY('F10:View Keys',TextX,6,48);
  PrintXY('Next:',TextX,8,50);
  PrintXY('Level '+LevelString,TextX,17,52);
  If (Menyval=1) Or (Menyval=3) Then Begin
    PrintXY('Score:',TextX,19,53);
    PrintXY('--------------',TextX,20,54);
    PrintXY(ScoreString,TextX,21,55);
  End;
  For Defplayer:=1 To Players Do
    ShowNextBlock;
End;

Procedure WriteFil(Color:Byte);
Begin
  If SS.Disk Then
    PrintXY('Drives      ',TextX,TextY,Color)
  Else Begin
    If SS.Ending='' Then
      PrintXY(SS.Name,TextX,TextY,Color)
    Else
      PrintXY(SS.Name+'.'+SS.Ending,TextX,TextY,Color);
    If SS.Dir Then
      PrintXY('D',TextX+13,TextY,Color);
  End;
End;

Procedure SelectFile;
Var Drive:Char;
Begin
  Key:=ReadKey;
  NewDir:=False;
  If Key=#0 Then
    Key:=ReadKey;
  Case Ord(Key) Of
    56,72:If FilPosition>0 Then Begin
		      WriteFil(LightGray);
		      Dec(FilPosition);
		      If TextY=5 Then Begin
                        Case Menyval Of
                          1,2,4:Begin
		  	        MoveDown(21,39,138,167,47);
			        FillBlock(22,40,138,47,0);
                              End;
                          3,5:Begin
		  	        MoveDown(0,39,118,167,47);
			        FillBlock(0,40,118,47,0);
                             End;
                        End;
                      End
		      Else
			Dec(TextY);
		      Seek(FileList,FilPosition);
		      Read(FileList,SS);
		      WriteFil(2);
		    End;
    50,80:If FilPosition<(FileSize(FileList)-1) Then Begin
		      WriteFil(LightGray);
		      Inc(FilPosition);
		      If TextY=21 Then Begin
                        Case Menyval Of
                          1,2,4:Begin
			        MoveUp(21,47,138,175,39);
			        FillBlock(22,168,138,175,0);
                              End;
                          3,5:Begin
			        MoveUp(0,47,118,175,39);
			        FillBlock(0,168,118,175,0);
                              End;
                        End;
                      End
		      Else
			Inc(TextY);
		      Seek(FileList,FilPosition);
		      Read(FileList,SS);
		      WriteFil(2);
		    End;
    13:Begin
	 If SS.Dir Then Begin
	   If SS.Name[1]='.' Then
             If SS.Name='..' Then
               ChDir('..')
             Else
               Chdir('\')
	   Else ChDir(SS.Name);
	   NewDir:=True;
	 End;
         If SS.Disk Then Begin
           Case Menyval Of
             1:FillBlock(21,21,138,178,0);
             2:FillBlock(21,21,138,178,0);
             3:FillBlock(0,21,118,178,0);
             4:FillBlock(21,21,138,178,0);
             5:FillBlock(0,21,118,178,0);
           End;
           PrintXY('Drive: ',TextX,3,2);
           Drive:=ReadKey;
           If ((Ord(Drive)>64) AND (Ord(Drive)<123)) Then
             ChDir(Drive+':');
           PrintXY('Select module:',TextX,3,2);
           NewDir:=True;
         End;
	 If (SS.Dir=False) And (SS.Disk=False) Then Begin
           if SS.Ending='MOD' then ok:=true;
           if SS.Ending='S3M' then ok:=true;
           if SS.Ending='669' then ok:=true;
           if SS.Ending='ULT' then ok:=true;
           if SS.Ending='MED' then ok:=true;
           if SS.Ending='FAR' then ok:=true;
           if SS.Ending='STM' then ok:=true;
           if SS.Ending='NST' then ok:=true;
           if SS.Ending='WOW' then ok:=true;
           if SS.Ending='OCT' then ok:=true;
           if SS.Ending='MTM' then ok:=true;
           if ok then begin
             GetDir(0,Katalog);
             If Copy(Katalog,Length(Katalog),1)='\' Then
       	       Config.ModFil:=Katalog+SS.Name+'.'+SS.Ending
             Else
               Config.ModFil:=Katalog+'\'+SS.Name+'.'+SS.Ending;
           end;
         End;
       End;
  End;
End;

Procedure Readdir;
Begin
  case menyval of
    1,2,4:FillBlock(21,31,138,178,0);
    3,5:FillBlock(0,31,118,178,0);
  end;
  if NewDir then begin
    Rewrite(FileList);
    Getdir(0,Katalog);
    FindFirst('*.*',$3F,OSS);
    Repeat
      If (oss.attr AND 16)=16 Then SS.Dir:=True Else SS.Dir:=False;
      If (oss.attr AND 8)=8 Then SS.Disk:=True Else SS.Disk:=False;
      If NOT (SS.Dir Or SS.Disk) Then Begin
        I:=0;
        Repeat
          Inc(I);
        Until (Oss.Name[i]='.') Or (i=Length(Oss.Name)+1);
        SS.Ending:=copy(oss.name,I+1,3);
        ss.name:=copy(oss.name,0,I-1);
      End
      Else Begin
        SS.Ending:='';
        SS.Name:=copy(oss.name,0,length(oss.name));
        If SS.Disk Then Begin
          SS.Dir:=True;
          SS.Name:='';
        End;
      End;
      Write(FileList,SS);
      FindNext(oss);
    Until DosError<>0;
    PrintXY('Sorting files.',TextX,3,2);
    SortFileList;
    PrintXY('Select module:',TextX,3,2);
  end;
  FilPosition:=0;
  reset(filelist);
  TextY:=5;
  Repeat
    Read(FileList,SS);
    WriteFil(LightGray);
    Inc(TextY);
  Until (TextY>=22) or Eof(FileList);
  reset(FileList);
  TextY:=5;
  Read(FileList,SS);
  WriteFil(2);
End;

Procedure ResetGameScreen;
Begin
  SetMode($13);
  SetFont(0);
  SetColor(1,50,40,30);       {bakgrundsf„rg}
  SetColor(2,63,63,63);      {ramf„rg 1}
  SetColor(3,30,30,30);      {ramf„rg 2}
  SetColor(10,63,10,10);     {f„rger p† blocken}
  SetColor(11,10,10,63);
  SetColor(12,20,20,20);
  SetColor(13,60, 0,50);
  SetColor(14,60,40,20);
  SetColor(15,0,0,20);
  SetColor(16,10,20,0);
  SetColor(254,63,63,63);    {ramf„rger f”r nedsatt Block}
  SetColor(253,30,30,30);
  For I:=0 To 12 Do                  {textf„rger}
    SetColor(I+44,I*3+27,0,64-I*5);
  For I:=100 To 132 Do               {bop-bars}
    SetColor(I,(132-I)*2,0,20);
End;

Procedure SetupGameScreen1;
Begin
  ResetGameScreen;
  FillBlock(0,0,160,199,1);
  FillBlock(300,0,319,199,1);
  For I:=0 To 19 Do
    HLine(0,I*10,319,254);
  For I:=0 To 31 Do Begin
    VLine(I*10,0,199,254);
    VLine(I*10+9,0,199,253);
  End;
  For I:=0 To 19 Do
    HLine(0,I*10+9,319,253);
  FillBlock(160,0,299,199,0);
  VLine(20,20,180,2);
  HLine(20,20,140,2);
  VLine(139,20,180,3);
  HLine(20,179,140,3);
  Textx:=3;
  RewriteInfoScreen;
End;

Procedure SetupGameScreen2;
Begin
  ResetGameScreen;
  FillBlock(0,0,319,199,1);
  For I:=0 To 19 Do
    HLine(0,I*10,319,254);
  For I:=0 To 31 Do Begin
    VLine(I*10,0,199,254);
    VLine(I*10+9,0,199,253);
  End;
  For I:=0 To 19 Do
    HLine(0,I*10+9,319,253);
  FillBlock(120,0,319,199,0);
  Textx:=0;
  RewriteInfoScreen;
End;

Procedure SetupGameScreen3;
Begin
  ResetGameScreen;
  FillBlock(0,0,319,199,1);
  For I:=0 To 19 Do
    HLine(0,I*10,319,254);
  For I:=0 To 31 Do Begin
    VLine(I*10,0,199,254);
    VLine(I*10+9,0,199,253);
  End;
  For I:=0 To 19 Do
    HLine(0,I*10+9,319,253);
  FillBlock(10,0,149,199,0);
  FillBlock(170,0,309,199,0);
  TextX:=3;
End;

Procedure SetupMusic;
Begin
  SampleRate := 45;                  { Initially set at 45Khz             }
  DMABuffer := 4096;                 { DMA Buffer Of 4096 bytes           }
  Write('Loading ',Config.SoundCardName,'...');
  {If LoadMSE(Config.SoundCardName, 0, SampleRate, DMABuffer, Config.BaseIO, Config.IRQ, Config.DMA)<>0 Then Begin
    Config.Sound_Card_Exists:=False;
    Writeln('Failed!');
  End
  Else
    Writeln('Ok');
  ExitProc := @FreeMSE;              { Call FreeMSE on abnormal program End }
  {If EMSExist                      { Check For EMS }
  {  Then Begin
      EMSFlag := 1;              { Yes, EMS exists, so use it }
  {    Writeln('EMS found.');
    End
    Else Begin
      EMSFlag := 0;             { EMS does Not exist }
  {    Writeln('No EMS found.');
    End; }
  writeln;
End;

Procedure StartModule;
Begin
  {MusicOn:=False;
  SwapVectors;
  Exec(StartDir+'\2gdm.exe',Config.ModFil);
  SwapVectors;
  Assign(Handle,Copy(Config.ModFil,0,Length(Config.ModFil)-3)+'GDM');
  Reset(Handle);
  If EMSExist                      { Check For EMS }
  {  Then EMSFlag := 1              { Yes, EMS exists, so use it }
  {  Else EMSFlag := 0;             { EMS does Not exist }
  {If LoadGDM(Handle, 0, EMSFlag, Header)<>0 Then
    Close(handle)
  Else Begin
    Close(Handle);
    MusicChannels := 0;            { Calculate the number Of channels in song }
  {  For I := 0 To 31 Do
      Begin
        If Header.PanMap[I] <> $FF
          Then MusicChannels := MusicChannels + 1;
      End;
    SampleRate := StartOutput(MusicChannels, 0);
    StartMusic;
    MusicOn:=True;
  End;}
End;

Procedure StopMusic;
Begin
  {StopOutput;
  UnloadModule;}
End;

Procedure SaveBlockPositions(x1,x2:Byte);
Begin
  K:=1;
  For I:=0 To 19 Do
    For J:=x1 To x2 Do Begin
      BlocksDown[K]:=Mem[$a000:(I*10+5)*320+J*10+5];
      Inc(K);
    End;
End;

Procedure RestoreBlockPositions(x1,x2:Integer);
Begin
  K:=1;
  For I:=0 To 19 Do
    For J:=x1 To x2 Do Begin
      If BlocksDown[K]<>0 Then Begin
        FillBlock(J*10+1,I*10+1,J*10+9,I*10+9,BlocksDown[K]);
        VLine(J*10,I*10,I*10+8,254);
        HLine(J*10+1,I*10,J*10+9,254);
        VLine(J*10+9,I*10,I*10+9,253);
        HLine(J*10,I*10+9,J*10+9,253);
      End;
      Inc(K);
    End;
End;

Procedure NewSong;
Begin
  Ok:=False;
  Assign(Oldmod,Copy(Config.ModFil,0,Length(Config.ModFil)-3)+'GDM');
  If Menyval=2 Then Begin
    For DefPlayer:=1 To Players Do Begin
      DrawBlocks(0);
      Ram(0,0);
    End;
    SaveBlockPositions(1,30);
    Fillblock(10,0,149,199,0);
  End;
  PrintXY('Select module:',TextX,3,2);
  ChDir(Katalog);
  ReadDir;
  Repeat
    If KeyPressed Then Begin
      SelectFile;
      If Newdir Then ReadDir;
    End;
  Until (Key=chr(27)) or Ok;
  If Ok Then Begin
    StopMusic;
    For DefPlayer:=1 To Players Do Begin
      DrawBlocks(0);
      Ram(0,0);
    End;
    Case Menyval Of
      1,4:SaveBlockPositions(16,29);
      3,5:SaveBlockPositions(12,31);
    End;
    SetMode($03);
    StartModule;
    SetMode($13);
    Case Menyval Of
      1,4:setupgamescreen1;
      2:setupgamescreen3;
      3,5:setupgamescreen2;
    End;
    Erase(oldmod);
    ChDir(StartDir);
    Case Menyval Of
      1,4:RestoreBlockPositions(16,29);
      3,5:RestoreBlockPositions(12,31);
      2:RestoreBlockPositions(1,30);
    End;
    For DefPlayer:=1 To Players Do Begin
      DrawBlocks(BlockColor[DefPlayer]);
      Ram(2,3);
    End;
  End
  Else If Menyval=2 Then Begin
    Fillblock(10,0,309,199,0);
    RestoreBlockPositions(1,30);
    For DefPlayer:=1 To Players Do Begin
      DrawBlocks(BlockColor[DefPlayer]);
      Ram(2,3);
    End;
  End;
  If (Menyval<>2) Then
    RewriteInfoScreen;
  Key:=' ';
End;

Procedure GameOverScreen;
Var Message:String;
Begin
  SetMode($13);
  SetFont(4);
  For I:=40 To 43 Do
    SetColor(I,0,0,0);
  If Score=      0 Then Message:='         You suck!';
  If Score>      0 Then Message:='     Did you even try?';
  If Score>   1000 Then Message:='         Pathetic!';
  If Score>   2000 Then Message:='    First time you play?';
  If Score>   4000 Then Message:='Is that the best you can do?';
  If Score>   8000 Then Message:='   You need more practice';
  If Score>  16000 Then Message:='      Could be worse...';
  If Score>  32000 Then Message:='       Well...not bad';
  If Score>  64000 Then Message:='        Pretty Good';
  If Score> 128000 Then Message:='      Hey, good work!';
  If Score> 256000 Then Message:='         Exellent!';
  If Score> 512000 Then Message:='     Damn, you'+chr(39)+'re good!';
  If Score>1024000 Then Message:='  You'+chr(39)+'re a real champion!';
  If Score>2048000 Then Message:='  Have you been cheating?';
  PrintXY('Game Over',15,6,40);
  If Odd(Menyval) Then
    PrintXY('Score: ',0,0,41)
  Else Begin
    If K=2 Then
      ScoreString:='Player 1 wins       '
    Else
      ScoreString:='Player 2 wins       ';
    Message:='      Congratulations!';
  End;
  PrintXY(Message,0,1,41);
  PrintXY(ScoreString,7,0,41);
  For I:=0 To 16 Do
    For J:=0 To (7+Length(ScoreString))*8 Do Begin
      K:=I*320+J;
      If Mem[$A000:K]=41 Then
        If Mem[$A000:K+29570-Length(ScoreString)*4]=40 Then
	  Mem[$A000:K+29570-Length(ScoreString)*4]:=42 Else
  	  Mem[$A000:K+29570-Length(ScoreString)*4]:=43;
    End;
  For I:=17 To 32 Do
    For J:=0 To 224 Do Begin
      K:=I*320+J;
      If Mem[$A000:K]=41 Then
        If Mem[$A000:K+28210]=40 Then
	  Mem[$A000:K+28210]:=42 Else
	  Mem[$A000:K+28210]:=43;
    End;
  For I:=1 To 63 Do Begin
    SetColor(40,I,0,0);
    SetColor(42,I,0,0);
    Delay(20);
  End;
  For I:=1 To 63 Do Begin
    SetColor(43,I,0,0);
    SetColor(40,63-I,0,0);
    If I<32 Then
      SetColor(42,63-I,0,0)
    Else
      SetColor(42,I,0,0);
    Delay(20);
  End;
  For I:=63 DownTo 0 Do Begin
    SetColor(43,I,0,0);
    SetColor(42,I,0,0);
    Delay(20);
  End;
End;

Procedure CheckScores;
Var HSPos,HLPos:Byte;
    PlayersName:String;
Begin
  SetMode($13);
  SetFont(0);
  HSPos:=100;
  HLPos:=100;
  For I:=10 DownTo 1 Do Begin                         {kolla om po„ng h”g}
    If (Score>HiScores[I]) Then
      HSPos:=I;
    If (Level>StartLevel) And (Level>HiLevels[I]) Then
      HLPos:=I;
  End;
  If (HSPos<=10) Or (HLPos<=10) Then Begin
    SetColor(7,10,10,50);
    If (HSPos<=10) And (HLPos<=10) Then Begin
      PrintXY('You have made it to the Highscore List',1,1,7);
      PrintXY('      and to the High Level List      ',1,2,7);
    End;
    If (HLPos=100) Then
      PrintXY('You have made it to the Highscore List',1,2,7);
    If (HSPos=100) Then
      PrintXY('You have completed a high Level',4,2,7);
    PrintXY('ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ',0,3,7);
    PrintXY('Enter Your name: ',0,5,7);
    ReadLn(PlayersName);
    If HSPos<10 Then
      For J:=10 DownTo (HSPos+1) Do Begin
	HighScoreList[J].Result:=HighScoreList[J-1].Result;
	HighScoreList[J].Name:=HighScoreList[J-1].Name;
      End;
    If HLPos<10 Then
      For J:=10 DownTo (HLPos+1) Do Begin
	HighLevelList[J].Result:=HighLevelList[J-1].Result;
	HighLevelList[J].Name:=HighLevelList[J-1].Name;
      End;
    If HSPos<=10 Then Begin
      HighScoreList[HSPos].Result:=ScoreString;
      HighScoreList[HSPos].Name:=PlayersName;
    End;
    If HLPos<=10 Then Begin
      Str(Level-1,HighLevelList[HLPos].Result);
      HighLevelList[HLPos].Name:=PlayersName;
    End;
    For I:=1 To 10 Do Begin
      Val(HighScoreList[I].Result,HiScores[I],J);
      Val(HighLevelList[I].Result,HiLevels[I],J);
    End;
  End;
End;

Procedure ShowHighScores;
Begin
  SetMode($13);
  SetFont(0);
  For I:=1 To 12 Do
    SetColor(13-I,I*3+20,0,40-I*3);
  PrintXY('Highest Scores',13,1,1);
  PrintXY('---------------------------------------',1,2,2);
  For I:=1 To 10 Do Begin
    PrintXY(HighScoreList[I].Name,1,I*2+2,I+2);
    PrintXY(HighScoreList[I].Result,40-Length(HighScoreList[I].Result),I*2+2,I+2);
  End;
  While KeyPressed Do
    Key:=ReadKey;
  Repeat Until KeyPressed;
  For I:=0 To 64000 Do
    Mem[$A000:I]:=0;
  PrintXY('Highest Levels',13,1,1);
  PrintXY('---------------------------------------',1,2,2);
  For I:=1 To 10 Do Begin
    PrintXY(HighLevelList[I].Name,1,I*2+2,I+2);
    PrintXY(HighLevelList[I].Result,40-Length(HighLevelList[I].Result),I*2+2,I+2);
  End;
  While KeyPressed Do
    Key:=ReadKey;
  Repeat Until KeyPressed;
End;

Procedure NewBlock;
Begin
  If (Menyval=3) Or (Menyval=4) Then
    FillBlock(DefPlayer*35+10,58,DefPlayer*35+40,98,0);
  If Menyval=1 Then
    FillBlock(80,58,110,98,0);
  Typ[DefPlayer]:=Next[DefPlayer];
  Next[DefPlayer]:=Random(7)+1;
  If Menyval<>2 Then
    ShowNextBlock;
  BlockColor[DefPlayer]:=Typ[DefPlayer]+9;
  If Menyval=1 Then
    X[DefPlayer]:=220
  Else
    If DefPlayer=1 Then
      If Menyval=2 Then
        X[DefPlayer]:=70
      Else
        X[DefPlayer]:=180
    Else
      If Menyval=2 Then
        X[DefPlayer]:=220
      Else
        X[DefPlayer]:=250;
  Y[DefPlayer]:=1;
  For I:=1 To 8 Do
    Block[DefPlayer,I]:=BlockShape[Typ[DefPlayer],I];
End;

Procedure ResetGameVariables;
Begin
  Level:=StartLevel;
  For I:=1 To Players Do
    MaxHeight[I]:=199;
  For I:=1 To Players Do Begin
    WaitsToGo[I]:=Delays[Level];
    WaitsDone[I]:=0;
  End;
  If Not Odd(Menyval) Then Begin
    FreeCol[1]:=Random(14)+1;
    FreeCol[2]:=Random(14)+17;
  End;
  Slut:=False;
  Score:=0;
  Str(Score,ScoreString);
  Str(Level,LevelString);
  For DefPlayer:=1 To Players Do Begin
    Next[DefPlayer]:=Random(7)+1;
    NewBlock;
  End;
  For I:=1 To 4 Do
    LineScores[I]:=I*I*(100-Delays[Level])*10;
  LinesMade:=0;
End;

Procedure Init;
Begin
  Textcolor(White);
  Setcolor(1,45,0,0);
  TextBackground(1);
  Write('         Ketris Version ',vernr,' - A 1995-1997 Kapsilon Software Production         ');
  Textcolor(7);
  TextBackground(0);
  writeln;
  writeln;
  Write('Reading Highscorelist...');
  Assign(HSFil,'HISCORE.LST');
  Assign(HLFil,'HILEVEL.LST');
  Reset(HSFil);
  Reset(HLFil);
  For I:=1 To 10 Do Begin                  {l„s in tidigare h”gsta po„ng}
    Read(HSFil,HighScoreList[I]);
    Read(HLFil,HighLevelList[I]);
    Val(HighScoreList[I].Result,HiScores[I],J);
    Val(HighLevelList[I].Result,HiLevels[I],J);
  End;
  Close(HSFil);
  Close(HLFil);
  Write('Config File...');
  Assign(ConfigFile,'CONFIG.SVE');
  Reset(ConfigFile);
  Read(ConfigFile,Config);
  Close(ConfigFile);
  Writeln('OK.');
  Writeln;
  Getdir(0,StartDir);
  Katalog:=StartDir;
  If Config.Sound_Card_Exists Then Begin
    WriteLn('Setting up music.');
    FindFirst(Config.ModFil,$3F,OSS);
    If DosError<>0 Then
      Config.ModFil:=Startdir+'\'+'TETRIS.MOD';
    SetupMusic;
    StartModule;
    ResetBars;
  End;
  Writeln;
  Write('Initializing some other stuff...');
  MaxKBSpeed;
  Mem[$40:$17]:=160;                      {se till att NUM LOCK „r I l„ge p†}
  Randomize;
  Assign(FileList,StartDir+'\FILES.LST');
  Rewrite(FileList);
  TextX:=3;
  StartLevel:=0;
  StartHeight:=0;
  SFX:=True;
  Key:=' ';
  Menyval:=1;
  Players:=1;
  Newdir:=True;
  ResetGameVariables;
  writeln('Done!');
  writeln;
  Writeln('All done! Cool!');
  Writeln('Here we go!');
  For I:=30 DownTo 0 Do Begin
    Setcolor(1,I,0,0);
    For J:=2 To 255 Do
      SetColor(J,I,I,I);
    Delay(20);
  End;
End;

Procedure CheckLines;
Var Count,Lines,x1,x2:Word;
Begin
  Lines:=0;
  Case Menyval Of
    1,4:Begin
          x1:=16;
          x2:=29;
        End;
    3,5:Begin
          x1:=12;
          x2:=31;
        End;
    2:Begin
        If DefPlayer=1 Then Begin
          x1:=1;
          x2:=14;
        End;
        If DefPlayer=2 Then Begin
          x1:=17;
          x2:=30;
        End;
      End;
  End;
  For I:=1 To 19 Do Begin              {spelare som satt ner kloss}
    Count:=0;
    For J:=x1 To x2 Do
      If Mem[$A000:(I*10+5)*320+(J*10+5)]>0 Then
        Inc(Count);
    If Count>(x2-x1) Then Begin
      Inc(Lines);
      MoveDown(x1*10-1,MaxHeight[DefPlayer]-10,x2*10+9,I*10-1,MaxHeight[DefPlayer]);
      Inc(MaxHeight[DefPlayer],10);
      If (Menyval=3) Or (Menyval=5) Then
        If MaxHeight[1]<MaxHeight[2] Then
           MaxHeight[2]:=MaxHeight[1]
        Else
          MaxHeight[1]:=MaxHeight[2];
    End;
  End;
  If Lines>0 Then Begin
    If SFX Then
      If Lines=4 Then
	Effect2 Else Effect1;
    If (Menyval=1) Or (Menyval=3) Then Begin
      Inc(Score,LineScores[Lines]);
      Str(Score,ScoreString);
      PrintXY(ScoreString,TextX,21,55);
      Inc(LinesMade);
      If LinesMade=10 Then Begin
        LinesMade:=0;
        Inc(Level);
        If Level>20 Then Slut:=True;
        str(Level,LevelString);
        PrintXY('Level '+LevelString,TextX,17,52);
      End;
      For I:=1 To 4 Do
        LineScores[I]:=I*I*(100-Delays[Level])*10;
    End;
    If Menyval=2 Then Begin
      If Lines=1 Then Lines:=0;
      If Lines=2 Then Lines:=10;
      If Lines=3 Then Lines:=20;
      If Lines=4 Then Lines:=40;
      If Lines>0 Then Begin
        If DefPlayer=1 Then Begin
          DefPlayer:=2;
          x1:=17;
          x2:=30;
        End
        Else Begin
          DefPlayer:=1;
          x1:=1;
          x2:=14;
        End;
        DrawBlocks(0);
        Ram(0,0);
        MoveUp(x1*10,MaxHeight[DefPlayer],x2*10+9,199,MaxHeight[DefPlayer]-Lines);
        Dec(MaxHeight[DefPlayer],Lines);
        FillBlock(x1*10,201-Lines,x2*10+8,198,20);
        For J:=1 To (Lines Div 10) Do
          HLine(x1*10,200-J*10,x2*10+8,254);
        For J:=x1 To x2 Do Begin
          VLine(J*10,201-Lines,198,254);
          VLine(J*10+9,200-Lines,198,253);
        End;
        For J:=1 To (Lines Div 10) Do
          HLine(x1*10,209-J*10,x2*10+9,253);
        FillBlock(FreeCol[DefPlayer]*10,200-Lines,FreeCol[DefPlayer]*10+9,199,0);
        If Not DownOk Then
          Dec(Y[DefPlayer],Lines);
        DrawBlocks(BlockColor[DefPlayer]);
        Ram(2,3);
        If DefPlayer=1 Then DefPlayer:=2 Else DefPlayer:=1;
      End;
    End;
  End;
  WaitsToGo[DefPlayer]:=Delays[Level];
End;

Procedure InfoScreen;
Begin
  case menyval of
    1:FillBlock(21,21,138,178,0);
    2:Begin
        DefPlayer:=1;
        DrawBlocks(0);
        Ram(0,0);
        SaveBlockPositions(1,14);
        Fillblock(10,0,149,199,0);
      end;
    3:FillBlock(0,21,118,178,0);
  end;
  PrintXY(' Ketris v'+VerNr,TextX,3,48);
  PrintXY('  A Kapsilon',TextX,5,49);
  PrintXY('  Production',TextX,6,49);
  PrintXY('F1:Music',TextX,8,50);
  PrintXY('   on/off',TextX,9,50);
  PrintXY('F2:Sound eff.',TextX,11,51);
  PrintXY('   on/off',TextX,12,51);
  PrintXY('F3:Play other',TextX,14,52);
  PrintXY('   module',TextX,15,52);
  PrintXY('F10:This info',TextX,17,53);
  PrintXY('    screen',TextX,18,53);
  PrintXY('Esc:Quit',TextX,20,54);
  Repeat Until KeyPressed;
  if menyval=2 then begin
    Fillblock(10,0,149,199,0);
    RestoreBlockPositions(1,14);
    Drawblocks(BlockColor[DefPlayer]);
    ram(2,3);
  end
  else
    RewriteInfoScreen;
  While KeyPressed Do
    Key:=ReadKey;
  Key:=' ';
End;

Procedure DoSomething;
Begin
  If Keypressed Then Begin
    Key:=ReadKey;
    If Ord(Key)=0 Then Begin
      Key:=ReadKey;
      KeyCode:=Ord(Key)+127;
    End
    Else
      KeyCode:=Ord(Key);
  End;
  If KeyCode=186 Then
    Begin
      If Config.Sound_Card_Exists Then
        If MusicOn Then Begin
	  MusicOn:=False;
	  {MusicVolume(0);}
        End
	Else Begin
	  MusicOn:=True;
	  {MusicVolume(64);}
        End;
    End;
  If KeyCode=187 Then
    If SFX=True Then SFX:=False Else SFX:=True;
  If (KeyCode=188) Then
    If Config.Sound_Card_Exists Then
      NewSong;
  If KeyCode=195 Then
    InfoScreen;
  For DefPlayer:=1 To Players Do Begin
    If KeyCode=Config.Player_Keys[DefPlayer,1] Then
      If LeftRightOk(-1,2879) Then
        Begin
	  WaitsToGo[DefPlayer]:=Delays[Level];
	  DrawBlocks(0);
	  Ram(0,0);
	  Dec(X[DefPlayer],10);
          DrawBlocks(BlockColor[DefPlayer]);
	  Ram(2,3);
	End;
    If KeyCode=Config.Player_Keys[DefPlayer,2] Then
      If LeftRightOk(10,2890) Then
        Begin
	  WaitsToGo[DefPlayer]:=Delays[Level];
	  DrawBlocks(0);
	  Ram(0,0);
	  Inc(X[DefPlayer],10);
	  DrawBlocks(BlockColor[DefPlayer]);
	  Ram(2,3);
	End;
    If KeyCode=Config.Player_Keys[DefPlayer,5] Then
      Begin
        WaitsToGo[DefPlayer]:=Delays[Level];
        DrawBlocks(0);
        Ram(0,0);
        Rotate;
        DrawBlocks(BlockColor[DefPlayer]);
        Ram(2,3);
      End;
    If KeyCode=Config.Player_Keys[DefPlayer,4] Then
      Begin
        WaitsToGo[DefPlayer]:=0;
	Inc(Score,Level*10);
	Str(Score,ScoreString);
        If Menyval=1 Then
	  PrintXY(ScoreString,3,21,55);
        End;
    If KeyCode=Config.Player_Keys[DefPlayer,3] Then
      If WaitsToGo[DefPlayer]<>5 Then WaitsToGo[DefPlayer]:=5 Else
        WaitsToGo[DefPlayer]:=Delays[Level];
  End;
End;

Function ReadAndWrite(KeyNr:Integer):String;
Var Tangent:String;
Begin
  Key:=ReadKey;
  If Ord(Key)<>0 Then
    Config.Player_Keys[DefPlayer,KeyNr]:=Ord(Key)
  Else Begin
    Key:=ReadKey;
    Config.Player_Keys[DefPlayer,KeyNr]:=Ord(Key)+127;
  End;
  Case Config.Player_Keys[DefPlayer,KeyNr] Of
    9:Tangent:='Tab';
    8:Tangent:='BkSp';
    13:Tangent:='Enter';
    27:Tangent:='Esc';
    32:Tangent:='Space';
    186..194:Tangent:='F'+chr(Config.Player_Keys[DefPlayer,KeyNr]-137);
    195:Tangent:='F10';
    202:Tangent:='Left';
    204:Tangent:='Right';
    207:Tangent:='Down';
    199:Tangent:='Up';
    209:Tangent:='Ins';
    198:Tangent:='Home';
    200:Tangent:='PgUp';
    210:Tangent:='Del';
    206:Tangent:='End';
    208:Tangent:='PgDn';
  Else
    Tangent:=Key;
  End;
  ReadAndWrite:=Tangent;
End;

Procedure RandomBlocks(AntalX,XStart:Integer);
Begin
  For I:=1 To StartHeight*20 Do Begin
    X[1]:=(Random(AntalX)+XStart)*10;
    Y[1]:=189-Random(StartHeight*2)*10;
    FillBlock(X[1]+1,Y[1]+1,X[1]+8,Y[1]+9,Random(7)+10);
    VLine(X[1],Y[1]+1,Y[1]+9,254);
    HLine(X[1]+1,Y[1]+1,X[1]+8,254);
    VLine(X[1]+9,Y[1]+1,Y[1]+9,253);
    HLine(X[1],Y[1]+10,X[1]+9,253);
  End;
End;

Procedure WinnerScreen;
Begin
  Setmode($13);
  Setfont(4);
  Setcolor(1,0,0,0);
  PrintXY('There was supposed to be',8,3,1);
  PrintXY('a "winner screen" here.',9,4,1);
  For I:=1 to 63 do Begin
    Setcolor(1,I,0,0);
    Delay(30);
  End;
  Setcolor(2,0,0,0);
  PrintXY('But it has not been fixed yet.',5,5,2);
  For I:=1 to 63 do Begin
    Setcolor(1,63-I,0,0);
    Setcolor(2,I,0,0);
    Delay(30);
  End;
  Setcolor(3,0,0,0);
  PrintXY('Sorry about that.',11,6,3);
  For I:=1 to 63 do Begin
    Setcolor(2,63-I,0,0);
    Setcolor(3,I,0,0);
    Delay(30);
  End;
  For I:=1 to 63 do Begin
    Setcolor(3,63-I,0,0);
    Delay(30);
  End;
End;

Begin
  Init;
  While Menyval<>9 Do Begin
    SetMode($13);
    SetFont(4);
    While KeyPressed Do
      Key:=ReadKey;
    Key:=' ';
    Meny;
    If Menyval=1 Then Begin
      Players:=1;
      ResetGameVariables;
      SetupGameScreen1;
      RandomBlocks(14,16);
    End;
    If Menyval=2 Then Begin
      Players:=2;
      ResetGameVariables;
      SetupGameScreen3;
      RandomBlocks(14,1);
      RandomBlocks(14,17);
    End;
    If Menyval=3 Then Begin
      Players:=2;
      ResetGameVariables;
      SetupGameScreen2;
      RandomBlocks(20,12);
    End;
    If (Menyval=4) Or (Menyval=5) Then Begin
      Cls;
      while keypressed do readkey;
      PrintXY('Sorry, that option is not',8,3,15);
      PrintXY('implemented in this version.',7,4,15);
      PrintXY('Please reselect.',12,7,15);
      repeat until keypressed;
    End;
    If Menyval<4 Then Begin
      For DefPlayer:=1 To Players Do Begin
        NewBlock;
        DrawBlocks(BlockColor[DefPlayer]);
        Ram(2,3);
      End;
      Repeat
        For DefPlayer:=1 To Players Do Begin
	  If Not DownOk Then Begin
            If (Keypressed or (Port[$60]<128)) Then
              DoSomething;
	    If Not DownOk Then Begin
	      Ram(254,253);
	      If SFX Then
	        Effect3;
              K:=2;
	      Repeat               {r„kna ut h”gsta h”jd av alla klossar}
                If (Block[DefPlayer,K]+Y[DefPlayer])<MaxHeight[DefPlayer] Then
	          MaxHeight[DefPlayer]:=Block[DefPlayer,K]+Y[DefPlayer];
                If (Menyval=3) Or (Menyval=5) Then
                  If MaxHeight[1]<MaxHeight[2] Then
                    MaxHeight[2]:=MaxHeight[1]
                  Else
                    MaxHeight[1]:=MaxHeight[2];
	        Inc(K,2);
	      Until K=10;
	      CheckLines;
	      WaitsToGo[DefPlayer]:=Delays[Level];
     	      NewBlock;
	      DrawBlocks(BlockColor[DefPlayer]);
	      Ram(2,3);
	      If Not DownOk Then Begin
                Slut:=True;
                K:=DefPlayer;
              End;
	    End;
	  End;
          If WaitsDone[DefPlayer]>=WaitsToGo[DefPlayer] Then Begin
            If BlockColor[DefPlayer]<>Typ[DefPlayer]+9 Then    {en #Ï%&õ! bugg igen!}
              BlockColor[DefPlayer]:=Typ[DefPlayer]+9;         {HATA PASCAL!}
	    ScrollDown;
            WaitsDone[DefPlayer]:=0;
          End;
        End;
	If (MusicOn And Config.Sound_Card_Exists) And (Menyval<>2) Then
          DrawVUBars;
        Delay(1);
        For I:=1 To Players Do
          Inc(WaitsDone[I]);
	If KeyPressed Then
	  DoSomething;
      Until (Ord(Key)=27) Or Slut;
      While Keypressed Do Readkey;
      If Slut And (Not Odd(Menyval)) Then
        GameOverScreen;
      If (Menyval=1) Or (Menyval=3) Then Begin
        If Level<21 Then GameOverScreen Else WinnerScreen;
        CheckScores;
        ShowHighScores;
      End;
    End;
    If Menyval=6 Then Begin
      SetMode($13);
      SetFont(0);
      SetColor(7,63,63,63);
      PrintXY('Starting Level And Height',8,3,15);
      PrintXY('---------------------------',7,4,15);
      PrintXY('Starting Level (0-20): ',1,7,15);
      ReadLn(StartLevel);
      While (StartLevel<0) Or (StartLevel>20) Do Begin
        Cls;
        PrintXY('Incorrect value entered',9,3,15);
        PrintXY('-------------------------',8,4,15);
        PrintXY('Starting Level (0-20): ',1,7,15);
        ReadLn(StartLevel);
      End;
      PrintXY('Starting Height (0-7): ',1,9,15);
      ReadLn(StartHeight);
      While (StartHeight<0) Or (StartHeight>7) Do Begin
        Cls;
        PrintXY('Incorrect value entered',9,3,15);
        PrintXY('-------------------------',8,4,15);
        PrintXY('Starting Height (0-7): ',1,7,15);
        ReadLn(StartHeight);
      End;
    End;
    If Menyval=7 Then
      For DefPlayer:=1 To 2 Do Begin
        OK:=False;
        Repeat
          SetMode($13);
          SetFont(0);
          While KeyPressed Do
            Key:=ReadKey;
          Key:=' ';
          PrintXY('Configure controls',10,1,15);
          PrintXY('--------------------',9,2,15);
          PrintXY('Player '+chr(DefPlayer+48),15,4,15);
          PrintXY('1. Keyboard',14,6,15);
          PrintXY('2. Mouse',14,7,15);
          PrintXY('3. Joystick',14,8,15);
          PrintXY('4. Gamepad',14,9,15);
          PrintXY('Press number (1-4)',10,11,15);
          Repeat
            If KeyPressed Then Key:=ReadKey;
          Until ((Ord(Key)>48) And (Ord(Key)<53)) or (Ord(Key)=27);
          If Ord(Key)<>27 Then
            Config.Player_Input_Device[DefPlayer]:=Ord(Key)-48;
          Case Ord(Key) of
            49:Begin
                 PrintXY('Press Key For LEFT: ',9,13,15);
                 PrintXY(ReadAndWrite(1),29,13,15);
                 PrintXY('Press Key For RIGHT: ',9,14,15);
                 PrintXY(ReadAndWrite(2),30,14,15);
                 PrintXY('Press Key For DOWN: ',9,15,15);
                 PrintXY(ReadAndWrite(3),29,15,15);
                 PrintXY('Press Key For DROP: ',9,16,15);
                 PrintXY(ReadAndWrite(4),29,16,15);
                 PrintXY('Press Key For Rotate: ',9,17,15);
                 PrintXY(ReadAndWrite(5),31,17,15);
                 OK:=True;
               End;
            50..52:Begin
              cls;
              while keypressed do readkey;
              PrintXY('Sorry, that option is not',8,7,15);
              PrintXY('implemented in this version.',7,9,15);
              PrintXY('Please reselect.',12,13,15);
              repeat until keypressed;
            end;
            27:OK:=True;
          End;
        until OK;
      End;
    If Menyval=8 Then
      ShowHighScores;
  End;
  SetMode($13);
  SetFont(4);
  SetColor(15,0,0,0);
  PrintXY('Credits',16,0,15);
  PrintXY('ÍÍÍÍÍÍÍÍÍ',15,1,15);
  PrintXY('Music system:',13,3,15);
  PrintXY('Bells, Whistles & Sound Boards',5,4,15);
  PrintXY('by Edward Schlunder',10,5,15);
  PrintXY('TETRIS.MOD was made by:',9,7,15);
  PrintXY('Mats C. Fredriksson',11,8,15);
  For I:=63 DownTo 0 Do Begin
    Delay(40);
    SetColor(15,63-I,63-I,63-I);
    {If Config.Sound_Card_Exists And MusicOn Then
      MusicVolume(I);}
  End;
  SetMode($03);
  Erase(FileList);
  ChDir(StartDir);
  Rewrite(HSFil);
  Rewrite(HLFil);
  For I:=1 To 10 Do Begin
    Write(HSFil,HighScoreList[I]);
    Write(HLFil,HighLevelList[I]);
  End;
  Close(HSFil);
  Close(HLFil);
  Rewrite(ConfigFile);
  Write(ConfigFile,Config);
  Close(ConfigFile);
  If Config.Sound_Card_Exists Then Begin
    {StopMusic;
    FreeMse;
    Assign(Oldmod,Copy(Config.ModFil,0,Length(Config.ModFil)-3)+'GDM');
    Erase(Oldmod);}
  End;
End.
