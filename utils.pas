unit Utils;

interface
    uses
        Parser;  { обработка ошибок }

    procedure Prepare_file(file_path: string; var input: Text);

    procedure Parse_EOLN(var input: text; var seq_item: seq_item_r);

    function Escaped_whitespace(var seq_item: seq_item_r): boolean;

    function In_string(var seq_item: seq_item_r; const str: string): boolean;


implementation
    uses
        SysUtils, { стандартные модули }
        Global,   { глобальные переменные }
        Handler;  { обработка ошибок }

    procedure Prepare_file(file_path: string; var input: Text);
    begin
        if not(FileExists(file_path)) then
            WriteErr(MSG_NO_FILE, file_path);
        Assign(input, file_path);
        Reset(input);
    end;

    procedure Parse_EOLN(var input: text; var seq_item: seq_item_r);
    begin
        while EOLN(input) do
        begin
            ReadLn(input);
            seq_item.col := seq_item.col + 1;
        end;
    end;

    function In_string(var seq_item: seq_item_r; const str: string): boolean;
    begin
        In_string := false;
        for i := 1 to Length(str) do
        begin
            if seq_item.ch = str[i] then
            begin
                In_string := true;
                break
            end;
        end;
    end;

    function Escaped_whitespace(var seq_item: seq_item_r): boolean;
    const
        WhiteSpaces: array[1..4] of char = (#9, #10, #13, #32);
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
