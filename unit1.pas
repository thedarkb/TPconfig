unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Unix, BaseUnix;

type

  { TForm1 }

  TForm1 = class(TForm)
    pathset: TButton;
    setbox: TCheckBox;
    pathbox: TEdit;
    pathGroup: TGroupBox;
    quit: TButton;
    apply: TButton;
    driftBar: TTrackBar;
    driftGroup: TGroupBox;
    speedGroup: TGroupBox;
    senseGroup: TGroupBox;
    speedBar: TTrackBar;
    senseBar: TTrackBar;
    procedure applyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pathsetClick(Sender: TObject);
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
  driftt: string;
  sett: string;
  sensitivity: byte;
  speed: byte;
  drift: byte;
  setnum: byte;
  setstr: string;
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
     pathbox.Text := workingpath;
  end;
  if FileExists(devpath2+'sensitivity') then
  begin
     tp := true;
     workingpath := devpath2;
     pathbox.Text := workingpath;
  end;
  if not tp then
     begin
        messagereturn := Application.MessageBox('No TrackPoint found, you must specify a path.', 'Error');
        apply.Enabled := false;
        pathbox.Enabled := true;
        pathset.Enabled := true;
     end;
  if FileExists(conpath) then
  begin
     user := fpgeteuid;
     if not (user=0) then
     begin
        messagereturn := Application.MessageBox('ERROR: Must be run as root!', 'Fatal Error');
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

     {check current drift time}
     AssignFile(sysfile, workingpath+'drift_time');
     reset(sysfile);
     readln(sysfile, driftt);
     val(driftt, drift);
     driftBar.Position := drift;  {ditto above}

     {check current "press to select" setting}
     AssignFile(sysfile, workingpath+'press_to_select');
     reset(sysfile);
     readln(sysfile, sett);
     val(sett, setnum);
     if not setnum = 0 then
        begin
           setbox.Checked := true;  {ditto above, just substitute box for slider}
        end;
  end;
end;

procedure TForm1.pathsetClick(Sender: TObject);
begin
  workingpath := pathbox.Text;

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

  {check current drift time}
  AssignFile(sysfile, workingpath+'drift_time');
  reset(sysfile);
  readln(sysfile, driftt);
  val(driftt, drift);
  driftBar.Position := drift;  {ditto above}

  {check current "press to select" setting}
  AssignFile(sysfile, workingpath+'press_to_select');
  reset(sysfile);
  readln(sysfile, sett);
  val(sett, setnum);
  if not setnum = 0 then
     begin
        setbox.Checked := true;  {ditto above, just substitute box for slider}
     end; //I'm well aware that having two of these check blocks is redundant
end; //I'm just too lazy to put them in a procedure when I can ctrl+c ctrl+v

procedure TForm1.applyClick(Sender: TObject);
begin
  //copies the value on the sliders into bytes for IntToStr later.
  sensitivity := senseBar.Position;
  speed := speedBar.Position;
  drift := driftBar.Position;
  setstr := '0';
  if setbox.Checked then
     setstr := '1';

  AssignFile(confH, conpath);
  rewrite(confH);
  {puts together the lines of the SystemD script which sets the sensitivity
  on boot}
  assembledStr := 'w '+workingpath+'sensitivity - - - - '+IntToStr(sensitivity);
  writeln(confH, assembledStr);
  //ditto above but for speed.
  assembledStr := 'w '+workingpath+'speed - - - - '+IntToStr(speed);
  writeln(confH, assembledStr);
  //drift this time
  assembledStr := 'w '+workingpath+'drift_time - - - - '+IntToStr(drift);
  writeln(confH, assembledStr);
  //now for press to select
  assembledStr := 'w '+workingpath+'press_to_select - - - - '+setstr;
  writeln(confH, assembledStr);

  CloseFile(confH); //closes the script, writing the contents to the disk
  fpsystem('systemd-tmpfiles --prefix=/sys --create'); {tells systemD to run the script}
end;

procedure TForm1.quitClick(Sender: TObject);
begin
  {$I-}
  halt;
end;


end.

