Program Blast;

uses
    Crt, IniFiles, { Стандартные модули }
    Global,        { Глобальные переменные }
    Handler,       { Обработка ошибок }
    Parser;        { Обработка ввода }

const
    modes: array[1..2] of Byte = (1, 3);

var
    ini:                      TIniFile;
    amino_path, nucl_path: string;

begin
    ClrScr();
    NormVideo();

    debug := false;
    finish := false;
    ini := TIniFile.Create('config.ini');
    if ini.ReadString('settings', 'debug', '0') = '1' then
    begin
        debug := true;
        WriteLn(ParamStr(0), ' был запущен...')
    end;
    if ini.ReadString('settings', 'finish', '0') = '1' then
    begin
        finish := true
    end;

    if ParamCount > 3 then
        WriteErr(MSG_BAD_PARAMS);

    { ParamStr(0) равен названию исполняемого файла }
    fasta_name := ParamStr(1);
    dna_rna_name := ParamStr(2);
    Val(ParamStr(3), mode, code);
    flag := false;
    for i := 1 to Length(modes) do
    if mode = modes[i] then
    begin
        flag := true;
        break
    end;
    if (code <> 0) or (flag = false) then
        WriteErr(MSG_BAD_MODE);
        
    Parse_input(amino_path, nucl_path) { процедура из parser.pas } 
end.
