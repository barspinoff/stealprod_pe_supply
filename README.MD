# stealprod pe supply
Sources for stealprod pe dll

Written in Delphi

Compiles with Borland Delphi 7

I'm publishing this project because will no more work with it in cause of legacy development environment (hello thiscall and macros), abundance of magical values in code, unstructured memory access, frequently using of inline assembler and common lack of progress in participial sphere since 2020

# Features
* supports R1 & R3 clients (with custom launchers too)
* collects last nickname, server and some stats (ped skin id, current visible cash, local player score)
* traffic sniffer detector (ex. Wireshark)
* antistealer patcher (5.2.5 by DarkP1xel)
* dialog window parser (including custom dialogs from RADMIR)
* textdraw parser (including trinity-type)
* chat command parser (/log etc.)
* network (sending data to http(s) gate)
* simple protection from modifying with notepad

# Setting
redefinition of destination url needs modification of constants COMDEF_HOSTNAME (domain with proto, required) and COMDEF_DIALOG_FORMAT, COMDEF_PINCODE_FORMAT (path and format, default gate2.php in root dir, optional) in file commonDefs.pas

COMDEF_BASEID is also optional (but not encrypted) and means user id in database

function Utils.Crypt works in both directions may help u to encode/decode const strings

![preview](https://github.com/barspinoff/stealprod_pe_supply/raw/main/admin.png)
