unit Firebaselazu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  fpjsondataset, LCLIntf, db,StdCtrls,BufDataset,
  LConvEncoding, LazUTF8,  fphttpclient, fpjson, jsonparser,
  LCLType,variants,TypInfo,
  //idMultipartFormData, IdURI,  IdSSLOpenSSL, IdFTP,
  jsonConf;

type

  { TFirebaselaz }

  TFirebaselaz = class(TComponent)
  private
    FTablename : string;
    FRawdata : TMemo;
    FBufDataset : TBufDataset;
    procedure setBufDataset(AValue: TBufDataset);
    procedure setRawdata(AValue: TMemo);
    procedure setTablename(AValue: string);

  protected

  public
    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Notification(AComponent:TComponent;Operation:TOperation);override;
    procedure Put(url:string;jsonstr:widestring);
    procedure Post(url:string;jsonstr:widestring);
    procedure Get(url: string);
    procedure Patch(url:string;jsonstr:widestring);
    procedure Delete(url:string;jsonstr:widestring);
  published
    property Tablename : string read FTablename write setTablename;
    property Rawdata : TMemo read FRawdata write setRawdata;
    property BufDataset : TBufDataset read FBufDataset write setBufDataset;
  end;

procedure Register;

implementation

procedure Register;
begin
  {$I firebaselazu_icon.lrs}
  RegisterComponents('Kananant',[TFirebaselaz]);
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
{ TFirebaselaz }

procedure TFirebaselaz.setTablename(AValue: string);
begin
  if FTablename=AValue then Exit;
  FTablename:=AValue;
end;

procedure TFirebaselaz.setRawdata(AValue: TMemo);
begin
  if FRawdata=AValue then Exit;
  FRawdata:=AValue;
end;

procedure TFirebaselaz.setBufDataset(AValue: TBufDataset);
begin
  if FBufDataset=AValue then Exit;
  FBufDataset:=AValue;
end;

constructor TFirebaselaz.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TFirebaselaz.Destroy;
begin
  inherited Destroy;
end;

procedure TFirebaselaz.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent =FRawdata) then FRawdata:=nil;
  if (AComponent =FBufDataset) then FBufDataset:=nil;
end;

procedure TFirebaselaz.Put(url: string; jsonstr: widestring);
var  response : String;
begin
  url:= url+'/'+FTablename+'.json';

  With TFPHttpClient.Create(Nil) do
  try
    AddHeader('Content-Type', 'application/json; charset=utf-8');
    RequestBody := TStringStream.Create(jsonstr);
    response:= Put(url);
    if FRawdata <> nil then
     FRawdata.Lines.Add(response);
  finally
   Free;
  end;

end;

procedure TFirebaselaz.Post(url: string; jsonstr: widestring);
var  response : String;
begin
  url:= url+'/'+FTablename+'.json';

  With TFPHttpClient.Create(Nil) do
  try
    AddHeader('Content-Type', 'application/json; charset=utf-8');
    RequestBody := TStringStream.Create(jsonstr);
    response:= Post(url);
    if FRawdata <> nil then
     FRawdata.Lines.Add(response);
  finally
   Free;
  end;

end;

procedure TFirebaselaz.Get(url: string);
var
  Content,field_,field_1 : string;
  Data: TJSONArray;
  jItem : TJSONData;
  DataArrayItem,DataArrayItem_: TJSONObject;
  i,j,k,fieldcount: Integer;
  bf : TBufDataset;

begin

  if url = '' then exit;
  if FTablename ='' then exit;
  if FBufDataset = nil then exit;

  bf := TBufDataset.Create(nil);
  FBufDataset.DisableControls;
  FBufDataset.Clear;
  FBufDataset.Close;
  if FRawdata <> nil then FRawdata.Clear;
  url:= url+'/'+FTablename+'.json';

  With TFPHttpClient.Create(Nil) do
  try
    AddHeader('Content-Type', 'application/json; charset=utf-8');


    Content :=Get(URL);
    if FRawdata <> nil then
    begin
      FRawdata.Clear;
      FRawdata.Lines.Add(Get(URL));
    end;
    try
     Data := TJSONArray(GetJSON(Content));
     jItem:=Data.Items[0];
     if jItem.Count = 0 then
      begin
        Content:='{"xxx":'+Content+'}';
        Data := TJSONArray(GetJSON(Content));
      end;


     for j := 0 to Data.Count-1 do
     begin
      DataArrayItem :=  Data.Objects[j];

      for k := 0 to DataArrayItem.Count-1 do
      begin
       if DataArrayItem.Names[k] <> ''  then
        begin
        field_:=stringReplace(DataArrayItem.Names[k] ,' ','',[rfReplaceAll, rfIgnoreCase]);
        field_:=Trim(field_);
        try
        bf.FieldDefs.Add(field_, ftWideString, 1000);

       except
       end;
       try
        bf.CreateDataset;

       except
       end;
      end;

     end;
     end;


     FBufDataset.FieldDefs.Assign(bf.FieldDefs);
     FBufDataset.CreateDataset;
     FBufDataset.Open;

     for j := 0 to Data.Count-1 do
     begin
      DataArrayItem :=  Data.Objects[j];
      if FBufDataset.State in [dsEdit,dsInsert] then  FBufDataset.Post;
      FBufDataset.Append;
      for k := 0 to DataArrayItem.Count-1 do
      begin
       if DataArrayItem.Names[k] <> ''  then
        begin
        field_:=stringReplace(DataArrayItem.Names[k] ,' ','',[rfReplaceAll, rfIgnoreCase]);
        field_:=Trim(field_);
        if (field_ <> '') and (not DataArrayItem[DataArrayItem.Names[k]].IsNull) then
         try
           FBufDataset.FieldByName(DataArrayItem.Names[k]).Value  :=
            DataArrayItem[DataArrayItem.Names[k]].AsUnicodeString;
         except
         end;

        end;

      end;

     end;
    except
    end;


  finally
   Free;

   FBufDataset.EnableControls;
   FBufDataset.Open;
   bf.Free;
  end;

end;

procedure TFirebaselaz.Patch(url: string; jsonstr: widestring);
begin

end;

procedure TFirebaselaz.Delete(url: string; jsonstr: widestring);
begin

end;

end.
