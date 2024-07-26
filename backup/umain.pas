unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
  ExtCtrls, Spin,   mqtt, TypInfo, opensslsockets;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnExit: TButton;
    btnConnect: TButton;
    btnDisConnect: TButton;
    btnSubscribe: TButton;
    btnUnSubscribe: TButton;
    btnPublish: TButton;
    cbBroker: TComboBox;
    cbSSL: TCheckBox;
    eConnTopic: TEdit;
    eStateTopic: TEdit;
    ePublish: TEdit;
    eID: TEdit;
    eTopic: TEdit;
    ePassword: TEdit;
    eUser: TEdit;
    ePort: TEdit;
    iConn: TImage;
    ilLEDs: TImageList;
    iState: TImage;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label9: TLabel;
    Memo1: TMemo;
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisConnectClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnPublishClick(Sender: TObject);
    procedure btnSubscribeClick(Sender: TObject);
    procedure btnUnSubscribeClick(Sender: TObject);
    procedure cbSSLChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure iStateClick(Sender: TObject);
  private
    FClient: TMQTTClient;
    ledState:boolean;
    procedure WriteLog(AMsg:string);
    procedure MQTTConnect;
    procedure MQTTDisConnect;
    procedure MQTTSubscribe;
    procedure MQTTUnSubscribe;
    procedure MQTTSubscribeOther;
    procedure MQTTUnSubscribeOther;
    procedure MQTTPublish;
    procedure OnReceive(Client: TMQTTClient; Msg: TMQTTRXData);
    procedure ShowLedState;
    procedure SwitchState;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnExitClick(Sender: TObject);
begin
  Close;
end;


procedure TForm1.btnPublishClick(Sender: TObject);
begin
  MQTTPublish;
end;

procedure TForm1.btnSubscribeClick(Sender: TObject);
begin
  MQTTSubscribeOther;
end;

procedure TForm1.btnUnSubscribeClick(Sender: TObject);
begin
  MQTTUnSubscribeOther;
end;

procedure TForm1.cbSSLChange(Sender: TObject);
begin
  if cbSSL.Checked then ePort.Text:='8883' else ePort.Text:='1883';
end;


procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if FClient.Connected then MQTTDisConnect;
  FClient.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FClient := TMQTTClient.Create(Self);
  FClient.OnReceive := @OnReceive;
  ledState:=False;
  MQTTConnect;
  //MQTTSubscribe;
end;

procedure TForm1.iStateClick(Sender: TObject);
begin
  SwitchState;
end;


procedure TForm1.btnConnectClick(Sender: TObject);
begin
  MQTTConnect;
end;

procedure TForm1.btnDisConnectClick(Sender: TObject);
begin
  MQTTDisConnect;
end;




procedure TForm1.WriteLog(AMsg:string);
begin
  Memo1.Lines.Add(FormatDateTime('YYYY.MM.DD hh:nn:ss',Now)+': '+AMsg);
  Memo1.SelStart:=MaxInt;
end;

procedure TForm1.MQTTConnect;
var
  Res: TMQTTError;
begin
  Res := FClient.Connect(cbBroker.Text, StrToIntDef(ePort.Text, 1883),
    eID.Text, eUser.Text, ePassword.Text, cbSSL.Checked, False);
  if Res <> mqeNoError then
    WriteLog(Format('connect: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
  btnConnect.Enabled:=not FClient.Connected;
  btnDisConnect.Enabled:=FClient.Connected;
  btnSubscribe.Enabled:=FClient.Connected;
  btnUnSubscribe.Enabled:=not FClient.Connected;
  cbBroker.Enabled:=not FClient.Connected;
  if FClient.Connected then begin
    WriteLog('Connected to '+cbBroker.Text);
    MQTTSubscribe;
  end;
end;

procedure TForm1.MQTTDisConnect;
begin
  if btnUnSubscribe.Enabled then MQTTUnSubscribeOther;
  MQTTUnSubscribe;
  FClient.Disconnect;
  btnConnect.Enabled:=not FClient.Connected;
  btnDisConnect.Enabled:=FClient.Connected;
  btnSubscribe.Enabled:=FClient.Connected;
  btnUnSubscribe.Enabled:=FClient.Connected;
  cbBroker.Enabled:=not FClient.Connected;
  if not FClient.Connected then begin
    WriteLog('DisConnected from '+cbBroker.Text);
    iConn.ImageIndex:=0;
    iState.ImageIndex:=0;
  end;
end;

procedure TForm1.MQTTSubscribe;
var
  Res: TMQTTError;
begin
  Res := FClient.Subscribe(eConnTopic.Text, 2, 1);
  if Res <> mqeNoError then begin
    WriteLog(Format('Subscribe: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
  end
  else begin
    WriteLog('Subscribed to '+eConnTopic.Text);
  end;
  Res := FClient.Subscribe(eStateTopic.Text, 2, 1);
  if Res <> mqeNoError then begin
    WriteLog(Format('Subscribe: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
    iState.Enabled:=False;
  end
  else begin
    WriteLog('Subscribed to '+eStateTopic.Text);
    iState.Enabled:=True;
  end;
  eConnTopic.Enabled:=not FClient.Connected;
  eStateTopic.Enabled:=not FClient.Connected;
end;

procedure TForm1.MQTTUnSubscribe;
var
  Res: TMQTTError;
begin
  Res := FClient.Unsubscribe(eConnTopic.Text);
  if Res <> mqeNoError then begin
    WriteLog(Format('UnSubscribe: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
  end
  else begin
    WriteLog('UnSubscribed from '+eConnTopic.Text);
  end;
  Res := FClient.Unsubscribe(eStateTopic.Text);
  if Res <> mqeNoError then begin
    WriteLog(Format('UnSubscribe: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
  end
  else begin
    WriteLog('UnSubscribed from '+eStateTopic.Text);
    iState.Enabled:=False;
  end;
  eConnTopic.Enabled:=not FClient.Connected;
  eStateTopic.Enabled:=not FClient.Connected;
end;


procedure TForm1.MQTTSubscribeOther;
var
  Res: TMQTTError;
begin
  Res := FClient.Subscribe(eTopic.Text, 2, 2);
  if Res <> mqeNoError then begin
    WriteLog(Format('Subscribe: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
  end
  else begin
    WriteLog('Subscribed to '+eTopic.Text);
    btnSubscribe.Enabled:=False;
    btnUnSubscribe.Enabled:=True;
    btnPublish.Enabled:=True;
    eTopic.Enabled:=False;
  end;
end;

procedure TForm1.MQTTUnSubscribeOther;
var
  Res: TMQTTError;
begin
  Res := FClient.Unsubscribe(eTopic.Text);
  if Res <> mqeNoError then begin
    WriteLog(Format('UnSubscribe: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
  end
  else begin
    WriteLog('UnSubscribed from '+eTopic.Text);
    btnSubscribe.Enabled:=True;
    btnUnSubscribe.Enabled:=False;
    btnPublish.Enabled:=False;
    eTopic.Enabled:=True;
  end;

end;



procedure TForm1.MQTTPublish;
var
  Res: TMQTTError;
begin
  //Az utolsó True a Retain, vagyis a megtartás flag!
  Res := FClient.Publish(eTopic.Text, ePublish.Text, '',  '', 0, True);//, UserProps);

  if Res <> mqeNoError then
    WriteLog(Format('publish: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));

end;

procedure TForm1.OnReceive(Client: TMQTTClient; Msg: TMQTTRXData);
var
  i:integer;
begin
  WriteLog(Format('OnReceive: QoS %d %d %d %s = %s',
    [Msg.QoS, Msg.SubsID, Msg.ID, Msg.Topic, Msg.Message]));
  if (Msg.Topic = eStateTopic.Text) then begin
    ledState:= (Msg.Message='1');
  end;
  if Msg.RespTopic <> '' then
    WriteLog(Format('           Response Topic: %s', [Msg.RespTopic]));
  if Msg.CorrelData <> '' then
    WriteLog(Format('           Correlation Data: %s', [Msg.CorrelData]));
  with Msg.UserProps do begin
    if Count > 0 then begin
      for I := 0 to Count - 1 do begin
        WriteLog(Format('           Prop %s: %s', [GetKey(I), GetVal(I)]));
      end;
    end;
  end;
  ShowLedState;
  if (Msg.Topic = eConnTopic.Text) then begin
    if (Msg.Message='1') then begin
      iConn.ImageIndex:=1;
    end
    else begin
      iConn.ImageIndex:=0;
    end;
  end;
end;

procedure TForm1.ShowLedState;
begin
  if ledState then begin
    iState.ImageIndex:=2;
  end
  else begin
    iState.ImageIndex:=0;
  end;
end;

procedure TForm1.SwitchState;
var
  sMsg:string;
  Res: TMQTTError;
begin
  ledState:=not ledState;
  sMsg:='0';
  if ledState then sMsg:='1';
  Res := FClient.Publish(eStateTopic.Text, sMsg, 0, True);
  if Res <> mqeNoError then
    WriteLog(Format('publish: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));

  //FClient.Publish(eTopic.Text, sMsg, '', '', 0, False);
  //ShowLedState;
end;


end.

