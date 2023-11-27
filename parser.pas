unit Parser;

interface
    type    
        seq_item_r = record
            ch:  char;
            ord: longword;
            row: longword;
            col: longword;
        end;
        seq_r_form = (AMINO, DNA, RNA, UNKNOWN);
        seq_r = record
            form: seq_r_form;
            name: string;
            seq:  array of seq_item_r;
            size: longword;
        end;

    var
        seq_item: seq_item_r;

    procedure Parse_input(amino_path: string; nucl_path: string);

implementation
    uses
        SysUtils, { стандартные модули }
        Global,   { глобальные переменные }
        Handler,  { обработка ошибок }
        Utils;    { дополнительное }

    var
        amino_input, nucl_input: text;
        codon_str:               string;
        amino_seq:               seq_r;

    function Seq_name(var input: Text): string; { получить имя последовательности }
    const
        SEQ_NAME_PUNCTUATION: string = '!''"(),-.:;[]_{}';
    begin
        Seq_name := '';
        
        if EOF(input) then WriteErr(MSG_UNEXPECTED_END_OF_FILE, '');

        seq_item.ch := #0;
        Parse_EOLN_whitespaces();

        if seq_item.ch = '>' then
            while true do
            begin
                if EOF(input) then WriteErr(MSG_UNEXPECTED_END_OF_FILE, '');
                Read(input, seq_item.ch);
                if seq_item.ch = #10 then
                begin
                    seq_item.col := seq_item.col + 1;
                    break;
                end
                else if not(
                    ('A' < UpCase(seq_item.ch)) and (UpCase(seq_item.ch) < 'Z') or
                    ('0' < seq_item.ch) and (seq_item.ch < '9') or
                    In_string(seq_item.ch, SEQ_NAME_PUNCTUATION)
                ) then
                    WriteErr(MSG_BAD_FASTA_SEQ_NAME, '');
                Seq_Name := Seq_name + seq_item.ch;
            end
        else
        begin
            if finish and (UpCase(seq_item.ch) = 'Ё') then Halt(1);
            WriteErr(MSG_BAD_FASTA_FORMAT, '');
        end;
    end;

    procedure Get_amino_seq(); { прочитать аминокислотная последовательность }
    const 
        SEQ_AMIGO_LEGAL_CHARS = 'ACDEFGHIKLMNPQRSTVWY';
    var
        amino_seq_item: seq_item_r;
    begin
        amino_seq.form := AMINO;
        amino_seq.name := Seq_name(amino_input);
        seq_item.col := 1; { для названий amino и nucl используется Seq_name, и важно обнулить координаты }
        amino_seq.size := 0;
        while true do
        begin
            Read(amino_input, amino_seq_item.ch);
            Parse_EOLN(amino_input, AMINO, ch = #0);
            if EOF(input) then
            begin
                if Amino_seq.size = 0 then
                    WriteErr(MSG_UNEXPECTED_END_OF_FILE, '')
                else break
            end;
            if not(
                In_string(amino_seq_item.ch, SEQ_AMIGO_LEGAL_CHARS) or
                Escaped_whitespace()
            ) then
                WriteErr(MSG_BAD_AMINO_SEQ, '');
            
            Amino_seq.size := Amino_seq.size + 1;
            SetLength(Amino_seq.seq, Amino_seq.size);
            Amino_seq.seq[Amino_seq.size] := amino_seq_item;
            if debug then writeln('d93993: ', amino_seq_item.ch);
        end;
    end;

    procedure Searcher();
    const
        SEQ_NUCL_CHARS: string = 'ACGTU';
    var
        nucl_seq: seq_r;
        amino_ch: char;
    begin
        seq_item.ch := #0;
        seq_item.col := 1;
        seq_item.row := 0;
        seq_item.ord := 0;

        while true do
        begin
            nucl_seq.form := UNKNOWN;
            nucl_seq.name := Seq_name(nucl_input);

            Parse_EOLN(nucl_input);
            if EOF(input) then
                WriteErr(MSG_UNEXPECTED_END_OF_FILE, '');
            read(nucl_input, seq_item.ch);
            if seq_item.ch = #10 then
            begin
                seq_item.col := seq_item.col + 1;
                seq_item.row := 0;
            end
            else
            begin
                seq_item.ord := seq_item.ord + 1;
                if not Escaped_whitespace() then
                begin
                    codon_str := codon_str + seq_item.ch;
                    if Length(codon_str) > 3 then
                        codon_str := Copy(codon_str, 2, 3);
                    seq_item.row := seq_item.row + 1;
                end;
            end;

            if debug then writeln('d88: ', codon_str);

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
    end;

    procedure Parse_input(amino_path: string; nucl_path: string); { обработка входных данных }
    begin
        Prepare_file(amino_input, amino_path);
        Get_amino_seq();
        Close(amino_input);

        Prepare_file(nucl_input, nucl_path);
        Searcher();
        Close(nucl_input);
    end;
end.
