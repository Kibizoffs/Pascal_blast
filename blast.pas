Program Blast;

uses
    Crt, IniFiles, { стандартное }
    Global,        { глобальное }
    Output,        { отладка, вывод ошибок и ответов }
    Parser,        { обработка ввода, основной алгоритм}
    Utils;         { дополнительное }

const
    modes: array[1..2] of Byte = (1, 3);

var
    ini:  TIniFile;
    flag: boolean;
    i:    byte;

begin
    { подготовка терминала }
    ClrScr();
    NormVideo();

    Prepare_output_file(output_text, DEBUG_PATH);

    { INI конфигурация }
    debug_mode := false;
    ini := TIniFile.Create(CONFIG_PATH);
    if ini.ReadString('settings', 'debug', '0') = '1' then
    begin
        debug_mode := true;
        debug(ParamStr(0) + ' был запущен...')
    end;

    { параметры запуска }
    if ParamCount > 3 then
        Write_err(MSG_BAD_PARAMS, '');
    { ParamStr(0) равен названию исполняемого файла }
    amino_path := ParamStr(1);
    nucl_path := ParamStr(2);
    { проверка корректности режима запуски }
    Val(ParamStr(3), mode, code);
    flag := false;
    for i := 1 to Length(modes) do
    if mode = modes[i] then
    begin
        flag := true;
        break
    end;
    if (code <> 0) or (flag = false) then
        Write_err(MSG_BAD_MODE, '');
        
    Main(); { процедура из parser.pas }
    Close(output_text);
end.
