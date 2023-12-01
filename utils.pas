unit Utils;

interface
    uses
        SysUtils, { Стандартное }
        Debugger, { Разработка }
        Global,   { Глобальное }
        Handler,  { Обработка ошибок }
        Parser;   { Обработка ввода и нахождение последовательностей }

    procedure Prepare_output_file(var output: Text; const file_path: string);

    procedure Prepare_input_file(var input: Text; const file_path: string);

    function Current_time(): string;

    function Is_inside(const str: string): boolean;
    function Is_inside(const arr: array of string): boolean;

    procedure Restore_default_seq_item();

    function If_EOLN(): boolean;
    
    function If_whitespace(): boolean;

    procedure Read_parse_char(var input: text);


implementation
    procedure Prepare_output_file(var output: Text; const file_path: string);
    begin
        if not(FileExists(file_path)) then
            FileCreate(file_path);
        Assign(output, file_path);
        Rewrite(output);
    end;

    procedure Prepare_input_file(var input: Text; const file_path: string);
    begin
        if not(FileExists(file_path)) then
            WriteErr(MSG_NO_FILE, file_path);
        Assign(input, file_path);
        Reset(input);
    end;

    function Current_time(): string;
    begin
        Current_time := FormatDateTime('hh:nn:ss.zzz', Now);
    end;

    function Is_inside(const str: string): boolean;
    var
        i: integer;
    begin
        In_inside := false;
        for i := 1 to Length(str) do
        begin
            if seq_item.ch = str[i] then
            begin
                In_inside := true;
                break;
            end;
        end;
    end;

    function Is_inside(const arr: array of string): boolean;
    var
        i: integer;
    begin
        Is_inside := false;
        for i := 1 to Length(arr) do
        begin
            if seq_item.ch = arr[i] then
            begin
                Is_inside := true;
                break;
            end;
        end;
    end;

    procedure Restore_default_seq_item();
    begin
        seq_item.ch := #0;
        seq_item.ord := 0;
        seq_item.row := 1;
        seq_item.col := 0;
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

case codon_str of
    'GCU', 'GCC', 'GCA', 'GCG':               amino_ch := 'A';
    'UGU', 'UGC':                             amino_ch := 'C';
    'GAU', 'GAC':                             amino_ch := 'D';
    'GAA', 'GAG':                             amino_ch := 'E';
    'UUU', 'UUC':                             amino_ch := 'F';
    'GGU', 'GGC', 'GGA', 'GGG':               amino_ch := 'G';
    'CAU', 'CAC':                             amino_ch := 'H';
    'AUU', 'AUC', 'AUA':                      amino_ch := 'I';
    'AAA', 'AAG':                             amino_ch := 'K';
    'UUA', 'UUG', 'CUU', 'CUC', 'CUA', 'CUG': amino_ch := 'L';
    'AUG':                                    amino_ch := 'M';
    'AAU', 'AAC':                             amino_ch := 'N';
    'CCU', 'CCC', 'CCA', 'CCG':               amino_ch := 'P';
    'CAA', 'CAG':                             amino_ch := 'Q';
    'CGU', 'CGC', 'CGA', 'CGG', 'AGA', 'AGG': amino_ch := 'R';
    'UCU', 'UCC', 'UCA', 'UCG', 'AGU', 'AGC': amino_ch := 'S';
    'ACU', 'ACC', 'ACA', 'ACG':               amino_ch := 'T';
    'GUU', 'GUC', 'GUA', 'GUG':               amino_ch := 'V';
    'UGG':                                    amino_ch := 'W';
    'UAU', 'UAC':                             amino_ch := 'Y';
end;
