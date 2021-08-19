unit MemStrTools;

interface

uses Windows;

type
	Utils = class
		Stack: PByte;
		offset: Integer;
	private
		function DoubleAsInt64(Value: double): int64;
		function IsDigit(c: Char): Boolean;
		function IsLetter(c: Char): Boolean;
		function CdeclCall(p: Pointer; StackData: Pointer; StackDataLen: Longint; ResultLength: Longint; ResEDX: Pointer): Longint; Stdcall;
	public
		function StrPos(const Str1, Str2: PChar): PChar;
		procedure memcpy(Destination, Source: Pointer; Size: Cardinal);
		procedure UnicodeToAnsi(pszW: PWideChar; pszA: PChar);
		function Pos(SubStr, Str:PAnsiChar):Boolean;
		function UrlEncode(str: PByte):PChar;
		function Format(Buffer, Format: PChar; const Args: array of const): Integer;
		procedure InstallJump(Address: Pointer; Direction: Cardinal; NopLength: Integer);
		function Crypt(s:string;code:boolean):string;
		function PushEax: Cardinal;
    function memchr(Buffer: Pointer; C: Byte; Count: Cardinal): Pointer;
   end;
   
	TDint64 = record
		case boolean of
		true : (i: int64);
		false : (d: double);
	end;

var
	Tools: Utils;

implementation

function sprintf(S: PAnsiChar; const Format: PAnsiChar): Integer;
    cdecl; varargs; external 'msvcrt.dll';
	
function Utils.DoubleAsInt64(Value: double): int64;
var
	Dint64 : TDint64;
begin
	Dint64.d := Value;
	result := Dint64.i;
end;

function Utils.CdeclCall(p: Pointer; StackData: Pointer; StackDataLen: Longint; ResultLength: Longint; ResEDX: Pointer): Longint; Stdcall;
var
	r: Longint;
begin
	asm
		mov ecx, stackdatalen
		jecxz @@2
		mov eax, stackdata
		@@1:
		mov edx, [eax]
		push edx
		sub eax, 4
		dec ecx
		or ecx, ecx
		jnz @@1
		@@2:
		call p
		mov ecx, resultlength
		cmp ecx, 0
		je @@5
		cmp ecx, 1
		je @@3
		cmp ecx, 2
		je @@4
		mov r, eax
		jmp @@5
		@@3:
		xor ecx, ecx
		mov cl, al
		mov r, ecx
		jmp @@5
		@@4:
		xor ecx, ecx
		mov cx, ax
		mov r, ecx
		@@5:
		mov ecx, stackdatalen
		jecxz @@7
		@@6:
		pop eax
		dec ecx
		or ecx, ecx
		jnz @@6
		mov ecx, resedx
		jecxz @@7
		mov [ecx], edx
		@@7:
	end;
	Result := r;
end;

procedure Utils.memcpy(Destination, Source: Pointer; Size: Cardinal); assembler;
asm
	mov esi, Source
	mov edi, Destination
	mov ecx, Size
	rep movsb
end;

{$O-}
function Utils.Format(Buffer, Format: PChar; const Args: array of const): Integer;
var
	i, resp: Integer;
	p: Pointer;
	tmp: Int64;
begin
	Stack := GlobalAllocPtr(0, 8192);
	ZeroMemory(Stack, 8191);
	offset := 0;
	memcpy(Pointer(Cardinal(Stack) + offset), Pointer(@Buffer), 4);
	Inc(offset, 4);
	memcpy(Pointer(Cardinal(Stack) + offset), Pointer(@Format), 4);
	Inc(offset, 4);
	for i := Low(Args) to High(Args) do
	begin
		if Args[i].VType = vtExtended then
		begin
			tmp := DoubleAsInt64(TVarRec(Args[i]).VExtended^);
			memcpy(Pointer(Cardinal(Stack) + offset), @tmp, 8);
			Inc(offset, 8);
		end
		else
		begin
			p := TVarRec(Args[i]).VPointer;
			memcpy(Pointer(Cardinal(Stack) + offset), @p, 4);
			Inc(offset, 4);
		end;
	end;
	
	resp := CdeclCall(@sprintf, Pointer(Cardinal(Stack) + offset - 4), offset div 4, 4, nil);
	GlobalFreePtr(Stack);
	Result := resp;
end;
{$O+}

procedure Utils.UnicodeToAnsi(pszW: PWideChar; pszA: PChar);
var
	strlen: Integer;
begin
	strlen := lstrlenW(pszW);
	WideCharToMultiByte(CP_ACP, 0, pszW, -1, pszA, strlen, 0, 0);
	pszA[strlen] := #0;
end;

function Utils.Crypt(s:string;code:boolean):string;
const
	Pas=10;
var
	i,Delta,Res:integer;
begin
	Result:='';
	for i:=1 to Length(s) do
	begin
		Delta:=((i xor Pas) mod (256-32));
		if code then
			Res:=((ord(s[i])+Delta) mod (256-32))+32
		else
		begin
			Res:=ord(s[i])-Delta-32;
			if Res<32 then
			Res:=Res+256-32;
		end;
		Result:=Result+chr(Res);
	end;
end;

function Utils.StrPos(const Str1, Str2: PChar): PChar; assembler;
asm
	PUSH	EDI
	PUSH	ESI
	PUSH	EBX
	MOV		EAX,Str1
	MOV		EDX,Str2
	OR		EAX,EAX
	JE		@@2
	OR		EDX,EDX
	JE		@@2
	MOV		EBX,EAX
	MOV		EDI,EDX
	XOR		AL,AL
	MOV		ECX,0FFFFFFFFH
	REPNE	SCASB
	NOT		ECX
	DEC		ECX
	JE		@@2
	MOV		ESI,ECX
	MOV		EDI,EBX
	MOV		ECX,0FFFFFFFFH
	REPNE	SCASB
	NOT		ECX
	SUB		ECX,ESI
	JBE		@@2
	MOV		EDI,EBX
	LEA		EBX,[ESI-1]
@@1:MOV		ESI,EDX
	LODSB
	REPNE	SCASB
	JNE		@@2
	MOV		EAX,ECX
	PUSH	EDI
	MOV		ECX,EBX
	REPE	CMPSB
	POP		EDI
	MOV		ECX,EAX
	JNE		@@1
	LEA		EAX,[EDI-1]
	JMP		@@3
@@2:XOR		EAX,EAX
@@3:POP		EBX
	POP		ESI
	POP		EDI
end;

function Utils.Pos(SubStr, Str:PAnsiChar):Boolean;
begin
	if Cardinal(StrPos(Str, SubStr))<>0 then Result:=True
	else Result:=false;
end;

function Utils.IsDigit(c: Char): Boolean;
begin
	if (c >= '0') and (c <= '9') then Result := True else Result := False;
end;
 
function Utils.IsLetter(c: Char): Boolean;
begin
	if ((c >= 'a') and (c <= 'z')) or
		((c >= 'A') and (c <= 'Z')) or
		(c = '_') or (c = '-') or (c = '~') or (c = '.') then Result := True else Result := False;
end;

function Utils.UrlEncode(str: PByte):PChar;
const
	hex = '0123456789ABCDEF';
var
	len, reslen, i: Integer;
	input: PChar;
begin
	len := lstrlen(PChar(str));
	Result := PChar(GetMemory(len * 3 + 1));
	reslen := 0;
	input := PChar(str);
	for i:=0 to len-1 do begin
		if (IsLetter(input[i])) or (IsDigit(input[i])) then
		begin
			Result[reslen] := input[i];
			reslen := reslen + 1;
		end
		else
		begin
			Result[reslen] := '%';
			Result[reslen + 1] := hex[1 + Ord(input[i]) shr 4];
			Result[reslen + 2] := hex[1 + Ord(input[i]) and $f];
			reslen := reslen + 3;
		end;
	end; 
	Result[reslen] := #0;
end;

procedure Utils.InstallJump(Address: Pointer; Direction: Cardinal; NopLength: Integer);
var
	dwOldProt, JumpAddr: Cardinal;
	i: Integer;
	nopaddr: Pointer;
begin
	VirtualProtect(Address, 5 + NopLength, PAGE_EXECUTE_READWRITE, dwOldProt);
	if NopLength > 0 then
	begin
		for i:=0 to NopLength-1 do
		begin
			nopaddr := Pointer(Cardinal(Address) + 5 + i);
			PByte(nopaddr)^ := $90;
		end;
	end;
	PByte(Address)^ := $E9;
	JumpAddr := Direction - (Cardinal(Address) + 5);
	PDword(Pointer(Cardinal(Address) + 1))^ := JumpAddr;
	VirtualProtect(Address, 5 + NopLength, dwOldProt, dwOldProt);
end;

function Utils.PushEax: Cardinal; assembler;
asm
	push eax
	ret
end;

function Utils.memchr(Buffer: Pointer; C: Byte; Count: Cardinal): Pointer;
var
	i: Integer;
begin
	Result := nil;

	for i:=0 to Count-1 do
	begin
		if PByte(Cardinal(Buffer) + i)^ = C then
		begin
			Result := Pointer(Cardinal(Buffer) + i);
			break;
		end;
	end;
end;

end.