(****************************************************************************)
(* Plugin Name: Tulip Better Comments                                       *)
(* Author:      Samer Assil                                                 *)
(* Date:        20 May 2026                                                 *)
(* Description: Delphi IDE Plugin to customize comment colors based on      *)
(*              prefixes:                                                   *)
(*              //*  - Red (Critical, bugs, errors)                         *)
(*              //!  - Orange (Warnings, alerts)                            *)
(*              //?  - Blue (Questions, reviews, to-dos)                    *)
(*              //>  - Yellow / Gold (Notices, tips)                        *)
(*              //ai - Magenta / Violet (AI notes, generated code)          *)
(*              //-  - Strikethrough (Deprecated / to remove)               *)
(****************************************************************************)

//! example warning comment
//* example critical comment
//? example question comment
//> example notice comment
//ai example AI-generated comment
//- example strikethrough comment
// Normal comment

unit uTulipBetterComments;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows,
  Vcl.Graphics,
  Vcl.Controls,
  ToolsAPI,
  ToolsAPI.Editor;

type
  TTulipBetterComments = class(TNotifierObject, INTACodeEditorEvents)
  private
    { INTACodeEditorEvents }
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
  end;

procedure Register;
procedure Unregister;

var
  EventNotifierIndex: Integer = -1;
  GNotifier: INTACodeEditorEvents = nil;

implementation

type
  TCommentStyleKind = (cskNone, cskCritical, cskAlert, cskQuestion, cskNotice, cskStrikeOut, cskAI);

function GetCommentStyleKind(const AText: string): TCommentStyleKind;
var
  S: string;
  Len, I, J: Integer;
  HasNonDash: Boolean;
begin
  Result := cskNone;
  S := TrimLeft(AText);
  Len := Length(S);
  if Len < 2 then
    Exit;

  // Single-line comments starting with //
  if (S[1] = '/') and (S[2] = '/') then
  begin
    // Ignore XML doc comments (///) and section dividers (////)
    if (Len >= 3) and (S[3] = '/') then
      Exit;

    I := 3;
    // Skip optional whitespace after // (supports both "//! test" and "// ! test")
    while (I <= Len) and ((S[I] = ' ') or (S[I] = #9)) do
      Inc(I);

    if I <= Len then
    begin
      // Check for 'ai' prefix (case-insensitive: //ai, //AI, // ai, etc.)
      if (I + 1 <= Len) and
         ((S[I] = 'a') or (S[I] = 'A')) and
         ((S[I + 1] = 'i') or (S[I + 1] = 'I')) and
         ((I + 2 > Len) or not CharInSet(S[I + 2], ['a'..'z', 'A'..'Z', '0'..'9', '_'])) then
      begin
        Exit(cskAI);
      end;

      case S[I] of
        '*': Result := cskCritical;
        '!': Result := cskAlert;
        '?': Result := cskQuestion;
        '>': Result := cskNotice;
        '-':
        begin
          // Distinguish strikethrough comments (e.g. "//- text", "// - text")
          // from divider lines (e.g. "//-------------------")
          HasNonDash := False;
          for J := I + 1 to Len do
          begin
            if S[J] <> '-' then
            begin
              HasNonDash := True;
              Break;
            end;
          end;
          if HasNonDash or (Len <= 4) then
            Result := cskStrikeOut;
        end;
      end;
    end;
  end
  // Also support block comments starting with { (e.g. "{! warning}" or "{ai generated}")
  // Excluding compiler directives like {$IFDEF}
  else if (S[1] = '{') and not ((Len >= 2) and (S[2] = '$')) then
  begin
    I := 2;
    while (I <= Len) and ((S[I] = ' ') or (S[I] = #9)) do
      Inc(I);

    if I <= Len then
    begin
      // Check for 'ai' prefix in block comments: {ai ...} or { ai ... }
      if (I + 1 <= Len) and
         ((S[I] = 'a') or (S[I] = 'A')) and
         ((S[I + 1] = 'i') or (S[I + 1] = 'I')) and
         ((I + 2 > Len) or not CharInSet(S[I + 2], ['a'..'z', 'A'..'Z', '0'..'9', '_'])) then
      begin
        Exit(cskAI);
      end;

      case S[I] of
        '*': Result := cskCritical;
        '!': Result := cskAlert;
        '?': Result := cskQuestion;
        '>': Result := cskNotice;
        '-': Result := cskStrikeOut;
      end;
    end;
  end;
end;

function IsDarkBackground(const ACanvas: TCanvas): Boolean;
var
  BgRGB: Cardinal;
  R, G, B: Byte;
begin
  BgRGB := Cardinal(ColorToRGB(ACanvas.Brush.Color));
  R := GetRValue(BgRGB);
  G := GetGValue(BgRGB);
  B := GetBValue(BgRGB);
  Result := ((R * 299 + G * 587 + B * 114) div 1000) < 128;
end;

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
  Kind: TCommentStyleKind;
  IsDark: Boolean;
  Canvas: TCanvas;
begin
  AllowDefaultPainting := True;

  // 1. Only process BeforeEvent (before default painting occurs).
  // 2. Do not modify selected/highlighted text to preserve IDE selection colors.
  // 3. Only process comment tokens (SyntaxCode = atComment) for performance and accuracy.
  if (not BeforeEvent) or Hilight or (SyntaxCode <> atComment) or (Context = nil) then
    Exit;

  Canvas := Context.Canvas;
  if Canvas = nil then
    Exit;

  Kind := GetCommentStyleKind(Text);
  if Kind = cskNone then
  begin
    if fsStrikeOut in Canvas.Font.Style then
      Canvas.Font.Style := Canvas.Font.Style - [fsStrikeOut];
    Exit;
  end;

  IsDark := IsDarkBackground(Canvas);

  case Kind of
    cskCritical: // Red
    begin
      if fsStrikeOut in Canvas.Font.Style then
        Canvas.Font.Style := Canvas.Font.Style - [fsStrikeOut];
      if IsDark then
        Canvas.Font.Color := TColor($005050FF) // RGB(255, 80, 80)
      else
        Canvas.Font.Color := TColor($001E1ECC); // RGB(204, 30, 30)
    end;

    cskAlert: // Orange
    begin
      if fsStrikeOut in Canvas.Font.Style then
        Canvas.Font.Style := Canvas.Font.Style - [fsStrikeOut];
      if IsDark then
        Canvas.Font.Color := TColor($00008CFF) // RGB(255, 140, 0)
      else
        Canvas.Font.Color := TColor($000078D8); // RGB(216, 120, 0)
    end;

    cskQuestion: // Blue
    begin
      if fsStrikeOut in Canvas.Font.Style then
        Canvas.Font.Style := Canvas.Font.Style - [fsStrikeOut];
      if IsDark then
        Canvas.Font.Color := TColor($00F3A14E) // RGB(78, 161, 243)
      else
        Canvas.Font.Color := TColor($00DC6E00); // RGB(0, 110, 220)
    end;

    cskNotice: // Yellow / Gold
    begin
      if fsStrikeOut in Canvas.Font.Style then
        Canvas.Font.Style := Canvas.Font.Style - [fsStrikeOut];
      if IsDark then
        Canvas.Font.Color := TColor($0000D7FF) // RGB(255, 215, 0)
      else
        Canvas.Font.Color := TColor($000080B8); // RGB(184, 128, 0)
    end;

    cskAI: // Magenta / Violet (Very noticeable for AI-generated code / notes)
    begin
      if fsStrikeOut in Canvas.Font.Style then
        Canvas.Font.Style := Canvas.Font.Style - [fsStrikeOut];
      if IsDark then
        Canvas.Font.Color := TColor($00FF50E6) // Luminous Electric Magenta / Violet (RGB: 230, 80, 255)
      else
        Canvas.Font.Color := TColor($009C10B0); // Deep Vivid Magenta / Purple (RGB: 176, 16, 156)
    end;

    cskStrikeOut: // Strikethrough
    begin
      Canvas.Font.Style := Canvas.Font.Style + [fsStrikeOut];
      if IsDark then
        Canvas.Font.Color := TColor($008A8A8A) // RGB(138, 138, 138)
      else
        Canvas.Font.Color := TColor($006E6E6E); // RGB(110, 110, 110)
    end;
  end;
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
