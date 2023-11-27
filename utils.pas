unit Utils;

interface
    procedure Prepare_file(var input: Text; const file_path: string);

    function In_string(const str: string): boolean;

    function If_EOLN(): boolean;

    function If_whitespace(): boolean;

    procedure Parse_EOLN(var input: text; const form: seq_r_form);


implementation
    uses
        SysUtils, { стандартные модули }
        Global,   { глобальные переменные }
        Handler,  { обработка ошибок }
        Parser;   { обработка ввода и нахождение последовательностей }

    procedure Prepare_file(var input: Text; const file_path: string);
    begin
        if not(FileExists(file_path)) then
            WriteErr(MSG_NO_FILE, file_path);
        Assign(input, file_path);
        Reset(input);
    end;

    function In_string(const str: string): boolean;
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

    function If_EOLN(): boolean;
    begin
        If_EOLN := false;
        if In_string(Chr(10) + Chr(77)) then
            If_EOLN := true;
    end;

    function If_whitespace(): boolean;
    const
        WhiteSpaces: array[1..4] of char = (#0, #9, #13, #32);
    begin
        If_whitespace := false;
        for i := 1 to High(WhiteSpaces) do
        begin
            if seq_item.ch = WhiteSpaces[i] then
            begin
                seq_item.row := seq_item.row + 1;
                If_whitespace := true;
                break
            end;
        end;
    end;

    procedure Parse_EOLN_whitespaces(var input: text; const form: seq_r_form);
    begin
        while If_EOLN() or If_whitespace() do
        begin
            if If_EOLN() then
            begin
                ReadLn(input);
                if (form = DNA) or (form = RNA) then 
                    seq_item.col := seq_item.col + 1;
            end
            else if If_whitespace() then
                Read(input, seq_item.ch)
        end;
    end;
end.
