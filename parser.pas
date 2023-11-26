unit Parser;

interface
    type    
        seq_item_r = record
            ch:  char;
            ord: longword;
            row: longword;
            col: longword;
        end;
        seq_r = record
            form: (AMINO, DNA, RNA, UNKNOWN);
            name: string;
            sequ: array of seq_item_r;
            size: longword;
        end;

    procedure Prepare_file(file_path: string; var input: text);

    procedure Parse_input(amino_path: string; nucl_path: string);

implementation
    uses
        Global,   { глобальные переменные }
        Handler,  { обработка ошибок }
        Utils;    { дополнительное }

    var
        ch, amino_ch:            char;
        amino_input, nucl_input: text;
        codon_str:               string[3];
        amino_target:            sequence_r;

    function Seq_name(var input: Text): string;
    const
        SEQ_NAME_PUNCTUATION: string = '!''"(),-.:;[]_{}';
    begin
        Seq_Name := '';
        
        while True do
        begin
            if EOF(input) then break;
            while EOLN(nucl_input) do ReadLn(nucl_input);
            Read(input, ch); { считывание название последовательности }
            if ch = '>' then
                while true do
                begin
                    if EOF(input) then 
                        WriteErr(MSG_UNEXPECTED_END_OF_FILE, '');
                    Read(input, ch);
                    if ch = ' ' then break;
                    if not(
                        ('A' < UpCase(ch)) and (UpCase(ch) < 'Z') or
                        ('0' < ch) and (ch < '9') or
                        In_string(ch, SEQ_NAME_PUNCTUATION)
                        ) then 
                        WriteErr(MSG_BAD_FASTA_SEQ_NAME, '');
                    Seq_Name := Seq_Name + ch
                end
            else
            begin
                if finish and (UpCase(ch) = 'Ё') then Halt(1);
                WriteErr(MSG_BAD_FASTA_FORMAT, '');
            end;
        end;
    end;

    function Seq_form(var input: Text): sequence_r;
    var
        form_str: string = '';
    begin
        while not EOLN(input) do { считывание типа последовательности }
        begin
            if EOF(input) then 
                WriteErr(MSG_UNEXPECTED_END_OF_FILE, '');
            Read(input, ch);
            if finish and (UpCase(ch) = 'Ё') then Halt(1);
            form_str := form_str + UpCase(ch);
            if Length(form_str) > 5 then break { наибольшая длина = 5 у 'AMINO' }
        end;
        case form_str of
            'AMINO': Seq_Form.form := AMINO; { останов }
            'DNA':   Seq_Form.form := DNA;
            'RNA':   Seq_Form.form := RNA;
            else     Seq_Form.form := UNKNOWN; { останов }
        end;
        if (Seq_Form.form = AMINO) or (Seq_Form.form = UNKNOWN) then
            WriteErr(MSG_BAD_TYPE, '');
    end;

    procedure Read_amino_seq(var input: Text);
    const 
        SEQ_AMINO_CHARS = 'ACDEFGHIKLMNPQRSTVWY';
    begin
        while true do
        begin
            while EOLN(input) do ReadLn(input);
            if EOF then
            begin
                if amino_target.size = 0 then
                    WriteErr(MSG_UNEXPECTED_END_OF_FILE)
                else
                    break
            end;
            Read(ch, input);
            if not(In_string(ch, SEQ_AMINO_CHARS)) and
            not(Escaped_whitespace) then
                WriteErr(MSG_BAD_AMINO_SEQ);
            if Length(amino_target.seq) = amino_target.size then
                amino_target.size := amino_target.size + 1024
            SetLength(amino_target.seq, amino_target.size);
            amino_target.seq := amino_target.seq + ch;
        end;
    end;

    procedure Searcher(form: seq_item.form; var input: text);
    const
        SEQ_NUCL_CHARS: string = 'ACGTU';
    var
        amino_seq: seq_r;
        nucl_seq: seq_r;
        seq_item: seq_item_r;
    begin
        amino_seq.name 
        seq_item.item := #0;
        seq_item.row := 1;
        seq_item.col := 1;

        Parse_EOLN(input, seq_item.row);
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

    procedure Parse_input(amino_path: string; nucl_path: string); { обработка входных данных }
    begin
        Prepare_file(amino_path, amino_input);
        amino_target.form := AMINO;
        amino_target.name := Seq_name(amino_input);
        amino_target.seq := Read_amino_seq(amino_input);
        if debug then writeln('D99: ', amino_target.seq);
        Close(amino_input);

        Prepare_file(nucl_path, nucl_input);
        sequence_item.form := Seq_form(nucl_input);
        sequence_item.name := Seq_name(nucl_input);
        Close(nucl_input);
    end;

end.
