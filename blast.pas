Program Blast;

uses
    Crt, IniFiles, { Стандартные модули }
    Debugger,      { Модуль разработчика }
    Global,        { Глобальные переменные }
    Handler,       { Обработка ошибок }
    Parser;        { Обработка ввода }

const
    modes: array[1..2] of Byte = (1, 3);

var
    ini:                   TIniFile;
    amino_path, nucl_path: string;
    i:                     integer;

begin
    ClrScr();
    NormVideo();

    debug_mode := false;
    ini := TIniFile.Create('config.ini');
    if ini.ReadString('settings', 'debug', '0') = '1' then
    begin
        debug_mode := true;
        debug(ParamStr(0) + ' был запущен...')
    end;

    if ParamCount > 3 then
        WriteErr(MSG_BAD_PARAMS, '');

    { ParamStr(0) равен названию исполняемого файла }
    amino_path := ParamStr(1);
    nucl_path := ParamStr(2);
    Val(ParamStr(3), mode, code);
    flag := false;
    for i := 1 to Length(modes) do
    if mode = modes[i] then
    begin
        flag := true;
        break
    end;
    if (code <> 0) or (flag = false) then
        WriteErr(MSG_BAD_MODE, '');
        
    Main(amino_path, nucl_path) { процедура из parser.pas } 
end.
