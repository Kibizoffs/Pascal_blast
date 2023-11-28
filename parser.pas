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

    function Seq_name(var input: Text; const form: seq_r_form): string; { получить имя последовательности }
    const
        SEQ_NAME_PUNCTUATION: string = '!''"(),-.:;[]_{}';
    begin
        Seq_name := '';

        if EOF(input) then WriteErr(MSG_UNEXPECTED_EOF, '');
        Read_parse_char(input);
        if seq_item.ch = '>' then
            while true do
            begin
                if EOF(input) then WriteErr(MSG_UNEXPECTED_EOF, '');
                Read(input, seq_item.ch);

                if If_EOLN() then
                begin
                    inc(seq_item.col);
                    seq_item.row := 0;
                    break;
                end
                else if not (
                    ('A' <= UpCase(seq_item.ch)) and (UpCase(seq_item.ch) <= 'Z') or
                    ('0' <= seq_item.ch) and (seq_item.ch <= '9') or
                    In_string(SEQ_NAME_PUNCTUATION) or
                    If_whitespace()
                ) then
                    WriteErr(MSG_BAD_FASTA_SEQ_NAME, '');

                Seq_name := Seq_name + seq_item.ch;
                
                inc(seq_item.row);
            end
        else WriteErr(MSG_BAD_FASTA_FORMAT, '');
    end;

    procedure Get_amino_seq(); { прочитать аминокислотная последовательность }
    const 
        SEQ_AMIGO_LEGAL_CHARS = 'ACDEFGHIKLMNPQRSTVWY';
    var
        i: integer;
    begin
        amino_seq.form := AMINO;
        amino_seq.name := Seq_name(amino_input, amino_seq.form);
        Restore_default_seq_item();
        amino_seq.size := 10;
        SetLength(amino_seq.seq, amino_seq.size);
        i := 0;
        while true do
        begin
            if EOF(input) then break;
            Read_parse_char(amino_input);
            if EOF(amino_input) then
                if Amino_seq.size = 0 then
                    WriteErr(MSG_UNEXPECTED_EOF, '')
                else break
            else if In_string(SEQ_AMIGO_LEGAL_CHARS) then
            begin
                inc(i);
                if (i > 10) then
                    WriteErr(MSG_BAD_AMINO_SEQ, '');
                Amino_seq.seq[i] := seq_item;
            end
            else if not (If_EOLN() or If_whitespace()) then
                WriteErr(MSG_BAD_AMINO_SEQ, '');
        end;
    end;

    procedure Searcher();
    const
        SEQ_NUCL_CHARS: string = 'ACGTU';
    var
        nucl_seq: seq_r;
        amino_ch: char;
        i: integer;
        nucl_seqs: array of seq_r;
    begin
        Restore_default_seq_item();

        SetLength(nucl_seqs, 1);
    
        while true do
        begin
            nucl_seq.form := UNKNOWN;
            nucl_seq.name := Seq_name(nucl_input, UNKNOWN);

            while true do
            begin
                Read_parse_char(nucl_input);
                if seq_item.ch = '>' then break { дошли до следующей последовательности }
                else if not If_whitespace() then
                begin
                    if UpCase(seq_item.ch) = 'U' then
                        if nucl_seq.form = DNA then WriteErr(MSG_BAD_TYPE, '')
                        else nucl_seq.form := RNA
                    else if UpCase(seq_item.ch) = 'T' then
                        if nucl_seq.form = RNA then WriteErr(MSG_BAD_TYPE, '')
                        else nucl_seq.form := DNA;
                    if UpCase(seq_item.ch) = 'T' then
                        seq_item.ch := 'U'
                end;
            end;


        end;

        codon_str := codon_str + seq_item.ch;
        if Length(codon_str) > 3 then
            codon_str := Copy(codon_str, 2, 3);
        if Length(codon_str) = 3 then
        begin
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
    end;

    procedure Parse_input(amino_path: string; nucl_path: string); { обработка входных данных }
    begin
        Prepare_file(amino_input, amino_path);
        if debug then writeln('d1');
        Get_amino_seq();
        if debug then writeln('d2');
        Close(amino_input);

        Prepare_file(nucl_input, nucl_path);
        if debug then writeln('d3');
        Searcher();
        if debug then writeln('d4');
        Close(nucl_input);
    end;
end.
