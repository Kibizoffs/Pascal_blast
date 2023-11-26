unit Utils;

interface

    procedure Prepare_file(var input: Text; const file_path: string);

    procedure Parse_EOLN(var input: text);

    function In_string(const ch: char; const str: string): boolean;

    function Escaped_whitespace(): boolean;


implementation
    uses
        SysUtils, { стандартные модули }
        Global, { глобальные переменные }
        Handler;  { обработка ошибок }

    procedure Prepare_file(var input: Text; const file_path: string);
    begin
        if not(FileExists(file_path)) then
            WriteErr(MSG_NO_FILE, file_path);
        Assign(input, file_path);
        Reset(input);
    end;

    procedure Parse_EOLN(var input: text);
    begin
        while EOLN(input) do
        begin
            ReadLn(input);
            seq_item.row := seq_item.row + 1;
        end;
    end;

    function In_string(const ch: char; const str: string): boolean;
    begin
        In_string := false;
        for i := 1 to Length(str) do
        begin
            if ch = str[i] then
            begin
                In_string := true;
                break
            end;
        end;
    end;

    function Escaped_whitespace(): boolean;
    const
        WhiteSpaces: array[1..4] of char = (#0, #9, #13, #32);
    begin
        Escaped_whitespace := false;
        for i := 1 to High(WhiteSpaces) do
        begin
            if seq_item.ch = WhiteSpaces[i] then
            begin
                seq_item.row := seq_item.row + 1;
                Escaped_whitespace := true;
                break
            end;
        end;
    end;
end.
