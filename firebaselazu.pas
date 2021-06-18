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
    FChild : string;
    FTokenid :string;
    FRawdata : TMemo;
    FBufDataset : TBufDataset;
    procedure setBufDataset(AValue: TBufDataset);
    procedure setChild(AValue: string);
    procedure setRawdata(AValue: TMemo);
    //procedure setTablename(AValue: string);
    procedure setTokenid(AValue: string);

  protected

  public
    constructor Create (AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Notification(AComponent:TComponent;Operation:TOperation);override;
    function Putx(url: string; jsonstr: widestring): Boolean;
    function Postx(url: string; jsonstr: widestring): Boolean;
    function Getx(url: string): Boolean;
    //function Patchx(url: string; jsonstr: widestring): Boolean;
    function Deletex(url: string; jsonstr: widestring): Boolean;
    function Search(url, Child, Key, Value: string): Boolean;
  published
    property Child : string read FChild write setChild;
    property Rawdata : TMemo read FRawdata write setRawdata;
    property BufDataset : TBufDataset read FBufDataset write setBufDataset;
    property Tokenid :string read FTokenid write setTokenid;
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

procedure TFirebaselaz.setTokenid(AValue: string);
begin
  if FTokenid=AValue then Exit;
  FTokenid:=AValue;
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

procedure TFirebaselaz.setChild(AValue: string);
begin
  if FChild=AValue then Exit;
  FChild:=AValue;
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

function TFirebaselaz.Putx(url: string; jsonstr: widestring): Boolean;
var  response : String;
begin
  url:= url+'/'+FChild+'.json';

  With TFPHttpClient.Create(Nil) do
  try
    AddHeader('Content-Type', 'application/json; charset=utf-8');
    RequestBody := TStringStream.Create(jsonstr);
    response:= Put(url);
   if(ResponseStatusCode = 200) then
   begin
     Result:=true;
   end else result:=false;

    if FRawdata <> nil then
     FRawdata.Lines.Add(response);
  finally
   Free;
  end;

end;

function TFirebaselaz.Postx(url: string; jsonstr: widestring): Boolean;
var  response : String;
begin
  Result:=false;
  url:= url+'/'+FChild+'.json';

  With TFPHttpClient.Create(Nil) do
  try
    AddHeader('Content-Type', 'application/json; charset=utf-8');
    RequestBody := TStringStream.Create(jsonstr);
    response:= Post(url);
    if(ResponseStatusCode = 200) then
    begin
      Result:=true;
    end else result:=false;
    if FRawdata <> nil then
     FRawdata.Lines.Add(response);
  finally
   Free;
  end;

end;

function TFirebaselaz.Getx(url: string): Boolean;
var
  Content,field_,field_1 : string;
  Data: TJSONArray;
  jItem : TJSONData;
  DataArrayItem,DataArrayItem_: TJSONObject;
  i,j,k,fieldcount: Integer;
  bf : TBufDataset;

begin
  result:=false;
  if url = '' then exit;
  if FChild ='' then exit;
  if FBufDataset = nil then exit;

  bf := TBufDataset.Create(nil);
  FBufDataset.DisableControls;
  FBufDataset.Clear;
  FBufDataset.Close;
  if FRawdata <> nil then FRawdata.Clear;
  url:= url+'/'+FChild+'.json';

  With TFPHttpClient.Create(Nil) do
  try
    AddHeader('Content-Type', 'application/json; charset=utf-8');
    Content :=Get(URL);
    if(ResponseStatusCode = 200) then
    begin
      Result:=true;
    if FRawdata <> nil then
    begin
      FRawdata.Clear;
      FRawdata.Lines.Add(Content);
    end;

    end else result:=false;

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
//
//function TFirebaselaz.Patchx(url: string; jsonstr: widestring): Boolean;
//var  response : String;
//begin
//  url:= url+'/'+FChild+'.json';
//
//  With TFPHttpClient.Create(Nil) do
//  try
//    AddHeader('Content-Type', 'application/json; charset=utf-8');
//    RequestBody := TStringStream.Create(jsonstr);
//    response:= Patch(url);
//   if(ResponseStatusCode = 200) then
//   begin
//     Result:=true;
//   end else result:=false;
//
//    if FRawdata <> nil then
//     FRawdata.Lines.Add(response);
//  finally
//   Free;
//  end;
//
//end;

function TFirebaselaz.Deletex(url: string; jsonstr: widestring): Boolean;
var  response : String;
begin
  url:= url+'/'+FChild+'.json';

  With TFPHttpClient.Create(Nil) do
  try
    AddHeader('Content-Type', 'application/json; charset=utf-8');
    RequestBody := TStringStream.Create(jsonstr);
    response:= Delete(url);
   if(ResponseStatusCode = 200) then
   begin
     Result:=true;
   end else result:=false;

    if FRawdata <> nil then
     FRawdata.Lines.Add(response);
  finally
   Free;
  end;

end;

function TFirebaselaz.Search(url, Child, Key,Value: string
  ): Boolean;
var
  Content,field_,urlx : string;
  Data: TJSONArray;
  DataArrayItem: TJSONObject;
  j,k: Integer;

 bf : TBufDataset;
begin
  if url = '' then exit;
  if Child='' then exit;
  //FBufDataset.DisableControls;
  FBufDataset.Close;
  FBufDataset.Clear;
  //Memo3.Clear;

  urlx:= EncodeUrl('"'+Key+'"')+
     //'&startTo='+ EncodeUrl('"'+txtValue.Text+'"')+
     //'&endTo='+ EncodeUrl('"*"')+
   '&equalTo='+ EncodeUrl('"'+Value+'"')+
   '';

  url:= url+'/'+Child+'.json'+
  '?orderBy='+urlx+
  '&print=pretty';

 //Memo3.Lines.Add(url);
 //exit;
  With TFPHttpClient.Create(Nil) do
  try
    RequestHeaders.Clear;
    AllowRedirect := true;
    AddHeader('Content-Type','application/json; charset=UTF-8');
    AddHeader('Accept', 'application/json');
    if FRawdata <> nil then
    FRawdata.Clear;

   try;
    Content:='';
    Content := Get(url);
    if FRawdata <> nil then
     FRawdata.Lines.Add(Content);
   except
    on E: Exception do
    begin
     if FRawdata <> nil then
      FRawdata.Lines.Add('An exception was raised: ' + E.Message);
    end;

   end;
    bf := TBufDataset.Create(nil);

    try
     Data := TJSONArray(GetJSON(Content));
     //DataArrayItem :=  Data.Objects[0];

     for j := 0 to Data.Count-1 do
     begin

      DataArrayItem :=  Data.Objects[j];
      //showmessage(inttostr(DataArrayItem.Count));
      for k := 0 to DataArrayItem.Count-1 do
      begin
       //ShowMessage(inttostr(k));
       if DataArrayItem.Names[k] <> ''  then
        begin
        //field_:='';
        field_:=stringReplace(DataArrayItem.Names[k] ,' ','',[rfReplaceAll, rfIgnoreCase]);
        field_:=Trim(field_);
        //showmessage(field_);
        try
        bf.FieldDefs.Add(field_, ftWideString, 1000);
        bf.CreateDataset;
       except
       end;
      end;

     end;

     end;

     //ShowMessage('0');
     FBufDataset.Clear;
     FBufDataset.FieldDefs.Assign(bf.FieldDefs);
     FBufDataset.CreateDataset;
     FBufDataset.Open;

     Data := TJSONArray(GetJSON(Content));
     //ShowMessage('1');
     for j := 0 to Data.Count-1 do
     begin
      DataArrayItem :=  Data.Objects[j];
      //ShowMessage(DataArrayItem[DataArrayItem.Names[0]].AsUnicodeString);
      if FBufDataset.State in [dsEdit,dsInsert] then  FBufDataset.Post;
      FBufDataset.Append;
      for k := 0 to DataArrayItem.Count-1 do
      begin
       //ShowMessage(DataArrayItem[DataArrayItem.Names[k]].AsUnicodeString);
       if DataArrayItem.Names[k] <> ''  then
        begin
        field_:='';
        field_:=stringReplace(DataArrayItem.Names[k] ,' ','',[rfReplaceAll, rfIgnoreCase]);
        field_:=Trim(field_);
        //showmessage(field_);
        if (field_ <> '') and (not DataArrayItem[DataArrayItem.Names[k]].IsNull) then
         try
           FBufDataset.FieldByName(DataArrayItem.Names[k]).Value  :=
            DataArrayItem[DataArrayItem.Names[k]].AsUnicodeString;
         except
         end;

        end;

      end;
      //if FBufDataset.State in [dsEdit,dsInsert] then  FBufDataset.Post;
     end;
     //end;

    except
    end;


  finally
   Free;
   //RequestBody:=Nil;
   FBufDataset.EnableControls;
   bf.Free;
   //DataArrayItem.Free;
   //Data.Free;
  end;

end;

end.
