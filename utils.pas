unit Utils; { дополнительное }

interface
    uses
        SysUtils, { стандартное }
        Global,   { глобальное }
        Output,   { отладка, вывод ошибок и ответов }
        Parser;   { обработка ввода и нахождение последовательностей }

    procedure Prepare_output_file(var output: Text; const file_path: string);

    procedure Prepare_input_file(var input: Text; const file_path: string);

    function Current_time(): string;

    function Is_inside(const str: string): boolean;

    procedure Restore_default_seq_item();

    function If_EOLN(): boolean;
    
    function If_whitespace(): boolean;

    procedure Read_parse_char(var input: text);


implementation
    { подготовиться к выводу }
    procedure Prepare_output_file(var output: Text; const file_path: string);
    begin
        if not(FileExists(file_path)) then
            FileCreate(file_path);
        Assign(output, file_path);
        Rewrite(output);
    end;

    { подготовиться к вводу }
    procedure Prepare_input_file(var input: Text; const file_path: string);
    begin
        if not(FileExists(file_path)) then
            Write_err(MSG_NO_FILE, file_path);
        Assign(input, file_path);
        Reset(input);
    end;

    { получить текущее время }
    function Current_time(): string;
    begin
        Current_time := FormatDateTime('hh:nn:ss.zzz', Now);
    end;

    { проверить, есть ли элемент внутри строки }
    function Is_inside(const str: string): boolean;
    var
        i: integer;
    begin
        Is_inside := false;
        for i := 1 to Length(str) do
        begin
            if seq_item.ch = str[i] then
            begin
                Is_inside := true;
                break;
            end;
        end;
    end;

    { инициализировать исходные значения у символа }
    procedure Restore_default_seq_item();
    begin
        seq_item.ch := #0;
        seq_item.ord := 0;
        seq_item.row := 1;
        seq_item.col := 0;
    end;

    { если ввод - новая строка }
    function If_EOLN(): boolean;
    begin
        If_EOLN := seq_item.ch = #10;
    end;

    { если ввод - пробельный символ }
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

    { обработать символ из ввода }
    procedure Read_parse_char(var input: text);
    begin
        Read(input, seq_item.ch);
        while not EOF(input) do
        begin   
            if If_EOLN() then
            begin
                inc(seq_item.row);
                seq_item.col := 0;
                if EOF(input) then break;
                Read(input, seq_item.ch);
            end
            else
            begin
                if If_whitespace() then
                begin
                    inc(seq_item.col);
                    Read(input, seq_item.ch);
                end
                else 
                begin
                    inc(seq_item.ord);
                    inc(seq_item.col);
                    break;
                end;
            end;
        end;
    end;
end.
