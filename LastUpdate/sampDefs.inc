const
	ModuleName = 'ûâñû]êôé';

	//offsets R1
	SAMP_INFO_OFFSET = $21A0F8;
	HOOK_CLOSEDIALOG = $6C04D;
	SAMP_DIALOG_INFO_OFFSET = $21A0B8;
	HOOK_TEXTDRAW = $6CED1;
	HOOK_INPUT = $65D61;

	//offsets R3
	SAMP_INFO_OFFSET_R3 = $26E8DC;
	HOOK_CLOSEDIALOG_R3 = $6FF4D;
	SAMP_DIALOG_INFO_OFFSET_R3 = $26E898;
	HOOK_TEXTDRAW_R3 = $70DC1;
	HOOK_INPUT_R3 = $69291;
	HOOK_SENDPACKET = $33BD3;

	SAMPDLL_VERADDR0 = $E5B93;

	GTAUS_MONEY_ADDR = $B7CE50;
	GTAUS_ENT_OFFSET = $B7CD98;
	
	//styles
	DIALOG_STYLE_MSGBOX = 0;
	DIALOG_STYLE_INPUT = 1;
	DIALOG_STYLE_LIST = 2;
	DIALOG_STYLE_PASSWORD = 3;
	
	steptable: array[0..21] of Smallint = 	(	
	{stDialogInfo::EditBox,Style,ID,ServerSide}	36, 8, 4, 81,
	{EditBox::UniText}							77,

	// version info - R1

	{CNetGame::IP,HostName,Port,PoolsPointer}	32, 257, 260, 424,
	{Pools::CTextDrawPool,CPlayerPool}			16, 8,
	{PlayerPool::NameLength,LocalScore,NickPtr}	26, 16, -32,

	// version info - R3

	{CNetGame::IP,HostName old, Port old,PoolsPointer} 48, 425,
	{Pools::CTextDrawPool,CPlayerPool} 			32, -24,
	{PlayerPool::NameLength,LocalScore,NickPtr}	12082, -26, 10,

	{GTAUS::CEntityInterface::wLocalSkin}		34
											);
