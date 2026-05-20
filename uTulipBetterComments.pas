(****************************************************************************)
(* Plugin Name: Tulip Better Comments                                       *)
(* Author:      Samer Assil                                                 *)
(* Date:        20 May 2026                                                 *)
(* Description: Delphi IDE Plugin to customize comment colors based on      *)
(*                                                                          *)
(*              //!                                                         *)
(*              //*                                                         *)
(*              //?                                                         *)
(*              //                                                          *)
(*                                                                          *)
(****************************************************************************)

//! example comment
//* example comment
//? example comment
// Normal comment

unit uTulipBetterComments;

interface

uses
  System.SysUtils,
  System.Classes,
  System.StrUtils,
  Winapi.Windows,
  Vcl.Graphics,
  Vcl.Controls,
  ToolsAPI,
  ToolsAPI.Editor;

type
  TTulipBetterComments = class(TNotifierObject, INTACodeEditorEvents)
  private
    procedure EditorScrolled(const Editor: TWinControl; const Direction: TCodeEditorScrollDirection);
    procedure EditorResized(const Editor: TWinControl);
    procedure EditorElided(const Editor: TWinControl; const LogicalLineNum: Integer);
    procedure EditorUnElided(const Editor: TWinControl; const LogicalLineNum: Integer);
    procedure EditorMouseDown(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure EditorMouseMove(const Editor: TWinControl; Shift: TShiftState; X, Y: Integer);
    procedure EditorMouseUp(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BeginPaint(const Editor: TWinControl; const ForceFullRepaint: Boolean);
    procedure EndPaint(const Editor: TWinControl);
    procedure PaintGutter(const Rect: TRect; const Stage: TPaintGutterStage; const BeforeEvent: Boolean;
        var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
    procedure PaintLine(const Rect: TRect; const Stage: TPaintLineStage; const BeforeEvent: Boolean;
        var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
    procedure PaintText(const Rect: TRect; const ColNum: SmallInt; const Text: string; const SyntaxCode: TOTASyntaxCode;
        const Hilight, BeforeEvent: Boolean; var AllowDefaultPainting: Boolean;
        const Context: INTACodeEditorPaintContext);
    function AllowedEvents: TCodeEditorEvents;
    function AllowedGutterStages: TPaintGutterStages;
    function AllowedLineStages: TPaintLineStages;
    function UIOptions: TCodeEditorUIOptions;

  public
    destructor Destroy; override;
    procedure AfterSave;
    procedure BeforeSave;
  end;

procedure Register;
procedure Unregister;

var
  EventNotifierIndex: integer = -1;
  GNotifier: INTACodeEditorEvents = nil;

implementation

procedure Register;
var
  EditorServices: INTACodeEditorServices;
begin
  if EventNotifierIndex = -1 then
  begin
    if Assigned(BorlandIDEServices) and Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
    begin
      GNotifier := TTulipBetterComments.Create;
      EventNotifierIndex := EditorServices.AddEditorEventsNotifier(GNotifier);
    end;
  end;
end;

procedure Unregister;
var
  EditorServices: INTACodeEditorServices;
begin
  if EventNotifierIndex <> -1 then
  begin
    try
      if Assigned(BorlandIDEServices) and Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
      begin
        EditorServices.RemoveEditorEventsNotifier(EventNotifierIndex);
      end;
    except
    end;

    EventNotifierIndex := -1;
    GNotifier := nil;
  end;
end;

{ TTulipBetterComments }

destructor TTulipBetterComments.Destroy;
begin
  inherited;
end;

procedure TTulipBetterComments.AfterSave;
begin

end;

function TTulipBetterComments.AllowedEvents: TCodeEditorEvents;
begin
  Result := [cevPaintTextEvents];
end;

function TTulipBetterComments.AllowedGutterStages: TPaintGutterStages;
begin
  Result := [];
end;

function TTulipBetterComments.AllowedLineStages: TPaintLineStages;
begin
  Result := [];
end;

procedure TTulipBetterComments.PaintText(const Rect: TRect; const ColNum: SmallInt; const Text: string;
  const SyntaxCode: TOTASyntaxCode; const Hilight, BeforeEvent: Boolean; var AllowDefaultPainting: Boolean;
  const Context: INTACodeEditorPaintContext);
var
  TrimmedText: string;
begin
  begin
    TrimmedText := TrimLeft(Text);
    if StartsText('//*', TrimmedText) then
      Context.Canvas.Font.Color := clRed
    else if StartsText('//!', TrimmedText) then
      Context.Canvas.Font.Color := RGB(255, 128, 0)
    else if StartsText('//?', TrimmedText) then
      Context.Canvas.Font.Color := clHighlight;
  end;

  AllowDefaultPainting := true;
end;

procedure TTulipBetterComments.BeforeSave;
begin

end;

procedure TTulipBetterComments.BeginPaint(const Editor: TWinControl; const ForceFullRepaint: Boolean); begin end;
procedure TTulipBetterComments.EditorElided(const Editor: TWinControl; const LogicalLineNum: Integer); begin end;
procedure TTulipBetterComments.EditorMouseDown(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer); begin end;
procedure TTulipBetterComments.EditorMouseMove(const Editor: TWinControl; Shift: TShiftState; X, Y: Integer); begin end;
procedure TTulipBetterComments.EditorMouseUp(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer); begin end;
procedure TTulipBetterComments.EditorResized(const Editor: TWinControl); begin end;
procedure TTulipBetterComments.EditorScrolled(const Editor: TWinControl; const Direction: TCodeEditorScrollDirection); begin end;
procedure TTulipBetterComments.EditorUnElided(const Editor: TWinControl; const LogicalLineNum: Integer); begin end;
procedure TTulipBetterComments.EndPaint(const Editor: TWinControl); begin end;
procedure TTulipBetterComments.PaintGutter(const Rect: TRect; const Stage: TPaintGutterStage; const BeforeEvent: Boolean; var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext); begin AllowDefaultPainting := true; end;
procedure TTulipBetterComments.PaintLine(const Rect: TRect; const Stage: TPaintLineStage; const BeforeEvent: Boolean; var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext); begin AllowDefaultPainting := true; end;

function TTulipBetterComments.UIOptions: TCodeEditorUIOptions;
begin
  Result := [];
end;

initialization

finalization
  Unregister;
end.
