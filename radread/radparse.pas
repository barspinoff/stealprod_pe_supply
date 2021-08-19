unit radparse;

interface

uses Windows, MemStrTools;

type
	PChar8 = array[0..7] of PChar;
                                                                                                                 
function BITS_TO_BYTES(bits: Cardinal): Cardinal;
function BreakWeaponData_Delphi(Data: Pointer; Size: Cardinal; var output: PChar8; var nRead: Integer): Integer;

implementation

function BITS_TO_BYTES(bits: Cardinal): Cardinal;
begin
	Result := (bits + 7) shr 3;
end;
  
{$O-}
// Data - bitstream array
// Size - number of unread bytes
function BreakWeaponData_Delphi(Data: Pointer; Size: Cardinal; var output: PChar8; var nRead: Integer): Integer;
label ret;
var	off, unread: Cardinal;
	listboxValue, dialogId: Word;
	buttonId: Byte;
	queueLen, queueInt: Integer;
	queueType: Char;
	queueString: array[0..255] of char;
begin
	Result := MAXWORD; 
	nRead := 0;
	for queueInt:=0 to 7 do output[queueInt] := nil;

	if (Data=nil) or (Size<1) then goto ret;

	off := 7; // skip 56 bits
	unread := Size - 7;

	if Tools.memchr(Data, $73, Size)=nil then goto ret;
	if unread < 5 then goto ret;

	queueLen := PInteger(Cardinal(Data) + off)^;

	Inc(off, SizeOf(queueLen));
	Dec(unread, SizeOf(queueLen));

	// trash filter
	if queueLen > unread then goto ret;

	Tools.memcpy(@queueString, PChar(Cardinal(Data) + off), queueLen);

	Inc(off, queueLen);
	Dec(unread, queueLen);
	if unread < 5 then goto ret;

	queueInt := PInteger(Cardinal(Data) + off)^;
	dialogId := Word(queueInt);

	Inc(off, SizeOf(queueInt));
	Dec(unread, SizeOf(queueInt));
	if unread < 5 then goto ret;

	if lstrcmp(queueString, 'OnDialogResponse')=0 then
	begin
		// default ingame dialog
		Inc(off, 6);
		queueInt := PInteger(Cardinal(Data) + off)^;
		Inc(off, SizeOf(queueInt));
		buttonId := queueInt;
		Inc(off);
		queueInt := PInteger(Cardinal(Data) + off)^; 
		Inc(off, SizeOf(queueInt));
		listboxValue := Word(queueInt);

		if listboxValue=$ffff then
		begin
			Inc(off);
			queueLen := PInteger(Cardinal(Data) + off)^; 
			if queueLen > unread then goto ret;

			Inc(off, SizeOf(queueLen));
			Dec(unread, SizeOf(queueLen));

			Tools.memcpy(@queueString, PChar(Cardinal(Data) + off), queueLen);
			queueString[queueLen] := #0;
			if queueString[0]<>#0 then
			begin                      
				output[0] := GetMemory(queueLen + 1);
				lstrcpy(output[0], queueString);
				nRead := 1;
			end;
		end;
	end
	else
	begin
		// auth/reg dialog window
		while unread > 5 do
		begin
			queueType := PChar(Cardinal(Data) + off)^;
			Inc(off);
			Dec(unread);
			if queueType='s' then
			begin
				queueLen := PInteger(Cardinal(Data) + off)^;
				if queueLen > unread then continue;

				Inc(off, SizeOf(queueLen));
				Dec(unread, SizeOf(queueLen));

				Tools.memcpy(@queueString, PChar(Cardinal(Data) + off), queueLen);
				queueString[queueLen] := #0;

				Inc(off, queueLen);
				Dec(unread, queueLen);

				if queueString[0]<>#0 then
				begin
					output[nRead] := GetMemory(queueLen + 1);
					lstrcpy(output[nRead], queueString);
					nRead := nRead + 1;
				end;
			end;
		end;
	end;

	Result := dialogId;

	ret:;
end;
{$O+}

end.
