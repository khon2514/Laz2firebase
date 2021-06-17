unit FireBaseDatasetu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, BufDataset,
  fpjsondataset, LCLIntf, db,StdCtrls,
  LConvEncoding, LazUTF8,  fphttpclient, fpjson, jsonparser,
  LCLType,variants,
  //idMultipartFormData, IdURI,  IdSSLOpenSSL, IdFTP,
  jsonConf;

type

  { TFireBaseDataset }

  TFireBaseDataset = class(TBufDataset)
  private
    //FUrl : string;
    FTablename : string;
    FRawdata : TMemo;
    procedure setTablename(AValue: string);
  protected

  public
    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Notification(AComponent:TComponent;Operation:TOperation);override;
    procedure Put(url:string);
    procedure Post(url:string);
    procedure Get(url:string);
    procedure Patch(url:string);
    procedure Delete(url:string);
  published
    property Tablename : string read FTablename write setTablename ;
  end;
procedure Register;

implementation

procedure Register;
begin
  {$I firebasedatasetu_icon.lrs}
  RegisterComponents('Kananant',[TFireBaseDataset]);
end;
function EncodeUrl(url: string): string;
var
  x: integer;
  sBuff: string;
const
  SafeMask = ['A'..'Z', '0'..'9', 'a'..'z', '*', '@', '.', '_', '-'];
begin
  //Init
  sBuff := '';

  for x := 1 to Length(url) do
  begin
    //Check if we have a safe char
    if url[x] in SafeMask then
    begin
      //Append all other chars
      sBuff := sBuff + url[x];
    end
    else if url[x] = ' ' then
    begin
      //Append space
      sBuff := sBuff + '+';
    end
    else
    begin
      //Convert to hex
      sBuff := sBuff + '%' + IntToHex(Ord(url[x]), 2);
    end;
  end;

  Result := sBuff;
end;

function DecodeUrl(url: string): string;
var
  x: integer;
  ch: string;
  sVal: string;
  Buff: string;
begin
  //Init
  Buff := '';
  x := 1;
  while x <= Length(url) do
  begin
    //Get single char
    ch := url[x];

    if ch = '+' then
    begin
      //Append space
      Buff := Buff + ' ';
    end
    else if ch <> '%' then
    begin
      //Append other chars
      Buff := Buff + ch;
    end
    else
    begin
      //Get value
      sVal := Copy(url, x + 1, 2);
      //Convert sval to int then to char
      Buff := Buff + char(StrToInt('$' + sVal));
      //Inc counter by 2
      Inc(x, 2);
    end;
    //Inc counter
    Inc(x);
  end;
  //Return result
  Result := Buff;
end;

{ TFireBaseDataset }

procedure TFireBaseDataset.setTablename(AValue: string);
begin
  if FTablename=AValue then Exit;
  FTablename:=AValue;
end;

constructor TFireBaseDataset.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTablename:='';
end;

destructor TFireBaseDataset.Destroy;
begin
  inherited Destroy;
end;

procedure TFireBaseDataset.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent =FRawdata) then FRawdata:=nil;
end;

procedure TFireBaseDataset.Put(url: string);
begin

end;

procedure TFireBaseDataset.Post(url: string);
var
  jsonPost: TJSONObject;
  i : integer;
  response : String;
begin
//
  if not Active then exit;
  if FieldCount = 0 then exit;
//
  url:= url+'/'+FTablename+'.json';

  jsonPost := TJSONObject.Create;
  for i := 0 to FieldCount-1 do
  begin
    try
     jsonPost.Add(Fields[i].FieldName,VarToStr(Fields[i].AsVariant));

    except
    end;
  end;
//  jsonPost.Add('cid',  txtCID.Text);
//  jsonPost.Add('username',  txtName.Text);
//  jsonPost.Add('birthdate', FormatDateTime('yyyy-mm-dd',txtBirthdate.DateTime));
//  jsonPost.Add('sex', cmbSex.Text);
  With TFPHttpClient.Create(Nil) do
  try
    AddHeader('Content-Type', 'application/json; charset=utf-8');
    RequestBody := TStringStream.Create(jsonPost.AsJSON);
    response:= Post(url);
    if FRawdata <> nil then
     FRawdata.Lines.Add(response);
  finally
   Free;
  end;


end;

procedure TFireBaseDataset.Get(url: string);
begin

end;

procedure TFireBaseDataset.Patch(url: string);
begin

end;

procedure TFireBaseDataset.Delete(url: string);
begin

end;

end.
