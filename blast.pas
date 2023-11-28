Program Blast;

uses
    Crt, IniFiles, { Стандартное модули }
    Debugger,      { Отладка }
    Global,        { Глобальное }
    Handler,       { Обработка ошибок }
    Parser,        { Обработка ввода }
    Utils;         { дополнительное }

const
    modes: array[1..2] of Byte = (1, 3);

var
    ini: TIniFile;
    i:   integer;

begin
    { Подготовка терминала }
    ClrScr();
    NormVideo();

    Prepare_output_file(output, DEBUG_PATH);

    { INI конфигурация }
    debug_mode := false;
    ini := TIniFile.Create(CONFIG_PATH);
    if ini.ReadString('settings', 'debug', '0') = '1' then
    begin
        debug_mode := true;
        debug(ParamStr(0) + ' был запущен...')
    end;

    { Параметры запуска }
    if ParamCount > 3 then
        WriteErr(MSG_BAD_PARAMS, '');
    { ParamStr(0) равен названию исполняемого файла }
    amino_path := ParamStr(1);
    nucl_path := ParamStr(2);
    { Проверка корректности режима запуски }
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
        
    Main(); { Процедура из parser.pas }
    Close(output);
end.
