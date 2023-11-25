unit Parser;

interface
    type    
        sequence_item_r = record
            item: char;
            ord:  longword;
            row:  longword;
            col:  longword;
        end;
        sequence_r = record
            name:     string;
            form:     (AMINO, DNA, RNA, UNKNOWN);
            sequence: array of sequence_item_r;
            size:     longword;
        end;

    procedure Parse_input(file_path: string; var input: text);

implementation
    uses
        SysUtils, { стандартные модули }
        Global,   { глобальные переменные }
        Handler;  { обработка ошибок }

    var
        ch, amino_ch:               char;
        amino_input, nucl_input: text;
        sequence:                   sequence_r;
        sequence_item:              sequence_item_r;
        form_str, seq_name_legal_chars :        string;
        codon_str: string[3];

    procedure Prepare_file(file_path: string; var input: Text);
    begin
        if not(FileExists(file_path)) then
            WriteErr(MSG_NO_FILE, file_path);
        Assign(input, file_path);
        Reset(input);
    end;

    procedure Parse_input(amino_path: string; nucl_path: string); { обработка входных данных }
    begin
        Prepare_file(nucl_path, nucl_input);

        sequence.name := '';

        while true do
        begin
            while EOLN(nucl_input) do ReadLn(nucl_input);

            while true do
            begin
                Read(nucl_input, ch); { считывание название последовательности }
                if ch = '>' then
                    while ch <> ' ' do
                    begin
                        Read(nucl_input, ch);
                        if not(
                            ('A' < UpCase(ch)) and (UpCase(ch) < 'Z') or
                            ('0' < ch) and (ch < '9')
                            ) then
                        begin
                            seq_name_legal_chars := '!"''(),-.:;[]_{}';
                            flag := false;
                            for i := 1 to Length(seq_name_legal_chars) do
                                if ch = seq_name_legal_chars[i] then
                                begin
                                    flag := true;
                                    break
                                end;
                            if flag = false then
                                WriteErr(MSG_BAD_FASTA_SEQ_NAME, '');
                        end;
                        sequence.name := sequence.name + ch
                    end
                else
                begin
                    if finish and (UpCase(ch) = 'Ё') then Halt(1);
                    WriteErr(MSG_BAD_FASTA_FORMAT, '');
                end;

                while not EOLN(nucl_input) do { считывание типа последовательности }
                begin
                    Read(nucl_input, ch);
                    if finish and (UpCase(ch) = 'Ё') then Halt(1);
                    form_str := form_str + UpCase(ch);
                    if Length(form_str) > 5 then break { наибольшая длина = 5 у 'AMINO' }
                end;
                case form_str of
                    'AMINO': sequence.form := AMINO;
                    'DNA':   sequence.form := DNA;
                    'RNA':   sequence.form := RNA;
                    else     sequence.form := UNKNOWN;
                end;
                if (sequence.form = AMINO) or (sequence.form = UNKNOWN) then
                    WriteErr(MSG_BAD_TYPE, '');
            end;

            sequence_item.item := #0;
            sequence_item.row := 1;
            sequence_item.col := 1;
            codon_str := '';
            writeln('d1: ', length(codon_str));
            codon_str := 'ad';
            writeln('d2: ', length(codon_str));
            while true do
            begin
                while EOLN(nucl_input) do
                begin
                    ReadLn(nucl_input);
                    sequence_item.col := sequence_item.col + 1;
                end;
                Read(nucl_input, ch);
            end;
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
        end;

        Close(nucl_input);

        {Prepare_file(amino_path, amino_input);
         ... 
        Close(amino_input);}
    end;

end.
