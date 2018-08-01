unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Unix, BaseUnix;

type

  { TForm1 }

  TForm1 = class(TForm)
    quit: TButton;
    apply: TButton;
    speedGroup: TGroupBox;
    senseGroup: TGroupBox;
    speedBar: TTrackBar;
    senseBar: TTrackBar;
    procedure applyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure quitClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

const
  conpath = '/etc/tmpfiles.d/tpconfig.conf';
  devpath1 = '/sys/devices/platform/i8042/serio1/serio2/'; //hardcoded paths to devices
  devpath2 = '/sys/devices/platform/i8042/serio1/'; //TODO: make less arse

var
  Form1: TForm1;
  confH: textfile;
  confile: string;
  tp: boolean;
  workingpath: string;
  sysfile: text;
  sensitivityt: string;
  speedt: string;
  sensitivity: byte;
  speed: byte;
  tempfile: text;
  user: LongWord;
  messagereturn: longint;
  assembledStr: string;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  fpsystem('touch '+conpath);
  tp := false;
  if FileExists(devpath1+'sensitivity') then
  begin
     tp := true;
     workingpath := devpath1;
  end;
  if FileExists(devpath2+'sensitivity') then
  begin
     tp := true;
     workingpath := devpath2;
  end;
  if not tp then
     begin
        messagereturn := Application.MessageBox('ERROR: No TrackPoint found!', 'Fatal Error');
        halt;
     end;
  if FileExists(conpath) then
  begin
     user := fpgeteuid;
     if not (user=0) then
     begin
        messagereturn := Application.MessageBox('ERROR: Not root!', 'Fatal Error');
        halt;
     end;
     {check current sensitivity}
     AssignFile(sysfile, workingpath+'sensitivity');
     reset(sysfile);
     readln(sysfile, sensitivityt);
     val(sensitivityt, sensitivity);
     senseBar.Position := sensitivity; {initialises the slider with current setting}

     {check current speed}
     AssignFile(sysfile, workingpath+'speed');
     reset(sysfile);
     readln(sysfile, speedt);
     val(speedt, speed);
     speedBar.Position := speed;  {ditto above}
  end;
end;

procedure TForm1.applyClick(Sender: TObject);
begin
  //copies the value on the sliders into bytes for IntToStr later.
  sensitivity := senseBar.Position;
  speed := speedBar.Position;

  AssignFile(confH, conpath);
  rewrite(confH);
  {puts together the line of the SystemD script which sets the sensitivity
  on boot}
  assembledStr := 'w '+workingpath+'sensitivity - - - - '+IntToStr(sensitivity);
  writeln(confH, assembledStr);
  //ditto above but for speed.
  assembledStr := 'w '+workingpath+'speed - - - - '+IntToStr(speed);
  writeln(confH, assembledStr);

  CloseFile(confH); //closes the script, writing the contents to the disk
  fpsystem('systemd-tmpfiles --prefix=/sys --create'); {so that this system call
  can tell systemD to run the script}
end;

procedure TForm1.quitClick(Sender: TObject);
begin
  {$I-}
  halt;
end;


end.

