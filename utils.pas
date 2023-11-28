unit Utils;

interface
    uses
        SysUtils, { стандартные модули }
        Debugger, { Модуль разработчика }
        Global,   { глобальные переменные }
        Handler,  { обработка ошибок }
        Parser;   { обработка ввода и нахождение последовательностей }

    procedure Prepare_file(var input: Text; const file_path: string);

    function In_string(const str: string): boolean;

    procedure Restore_default_seq_item();

    function If_EOLN(): boolean;
    
    function If_whitespace(): boolean;

    procedure Read_parse_char(var input: text);


implementation
    procedure Prepare_file(var input: Text; const file_path: string);
    begin
        if not(FileExists(file_path)) then
            WriteErr(MSG_NO_FILE, file_path);
        Assign(input, file_path);
        Reset(input);
    end;

    function In_string(const str: string): boolean;
    var
        i: integer;
    begin
        In_string := false;
        for i := 1 to Length(str) do
        begin
            if seq_item.ch = str[i] then
            begin
                In_string := true;
                break;
            end;
        end;
    end;

    procedure Restore_default_seq_item();
    begin
        seq_item.ch := #0;
        seq_item.ord := 0;
        seq_item.col := 1;
        seq_item.row := 0;
    end;

    function If_EOLN(): boolean;
    begin
        If_EOLN := seq_item.ch = #10;
    end;

    function If_whitespace(): boolean;
    const
        WhiteSpaces: array[1..3] of char = (#9, #13, #32);
    var
        i: integer;
    begin
        If_whitespace := false;
        for i := 1 to High(WhiteSpaces) do
        begin
            if seq_item.ch = WhiteSpaces[i] then
            begin
                If_whitespace := true;
                break;
            end;
        end;
    end;

    procedure Read_parse_char(var input: text);
    begin
        Read(input, seq_item.ch);
        while not EOF(input) do
        begin
            if If_EOLN() then
            begin
                inc(seq_item.col);
                seq_item.row := 0;
                ReadLn(input, seq_item.ch);
            end
            else
            begin
                if If_whitespace() then
                begin
                    inc(seq_item.row);
                    Read(input, seq_item.ch);
                end
                else 
                begin
                    inc(seq_item.ord);
                    inc(seq_item.row);
                    break;
                end;
            end;
        end;
    end;
end.
