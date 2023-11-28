unit Parser;

interface
    type    
        seq_item_r = record
            ch:  char;
            ord: longword;
            col: longword;
            row: longword;
        end;
        seq_r_form = (AMINO, DNA, RNA, UNKNOWN);
        seq_r = record
            form: seq_r_form;
            name: string;
            seq:  array of seq_item_r;
        end;

    var
        seq_item: seq_item_r;

    procedure Main();

implementation
    uses
        SysUtils, { стандартные модули }
        Debugger, { Модуль разработчика }
        Global,   { глобальные переменные }
        Handler,  { обработка ошибок }
        Utils;    { дополнительное }

    var
        amino_input, nucl_input: text;
        codon_str:               string;
        amino_seq:               seq_r;
        nucl_seqs: array of seq_r;

    function Seq_name(var input: Text): string; { получить имя последовательности }
    const
        SEQ_NAME_PUNCTUATION: string = '!''"(),-.:;[]_{}';
    begin
        Seq_name := '';

        Debug('Читаем название последовательности...');
        if EOF(input) then WriteErr(MSG_UNEXPECTED_EOF, '');
        Read_parse_char(input);
        if seq_item.ch = '>' then
            while true do
            begin
                if EOF(input) then WriteErr(MSG_UNEXPECTED_EOF, '');
                Read(input, seq_item.ch);

                if If_EOLN() then
                begin
                    inc(seq_item.row);
                    seq_item.col := 0;
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
                inc(seq_item.col);
            end
        else WriteErr(MSG_BAD_FASTA_FORMAT, '');
        seq_item.ord := 0; { ord не зависит от названий последовательностей }

        Debug('Название последовательности: ' + Seq_name);
    end;

    procedure Read_amino_seq(); { получить аминокислотную последовательность }
    const 
        SEQ_AMIGO_LEGAL_CHARS = 'ACDEFGHIKLMNPQRSTVWY';
    var
        i: integer;
    begin
        amino_seq.form := AMINO;
        amino_seq.name := Seq_name(amino_input);
        SetLength(amino_seq.seq, 1);
        i := 1;

        Debug('Получаем последовательность...');
        while true do
        begin
            if EOF(amino_input) then break;
            Read_parse_char(amino_input);
            Debug(seq_item.ch + ' ' + IntToStr(seq_item.ord) + ' ' + IntToStr(seq_item.row) + ' ' + IntToStr(seq_item.col));
            if EOF(amino_input) then
            begin
                if i = 1 then
                    WriteErr(MSG_UNEXPECTED_EOF, '')
                else break
            end
            else if In_string(SEQ_AMIGO_LEGAL_CHARS) then
            begin
                if (i = Length(amino_seq.seq)) then
                    SetLength(amino_seq.seq, i * 2);
                Amino_seq.seq[i] := seq_item;
                inc(i);
            end
            else if not (If_EOLN() or If_whitespace()) then
                WriteErr(MSG_BAD_AMINO_SEQ, '');
        end;
    end;

    procedure Search_sub_seqs(); { найти подпоследовательности }
    var
        i, j, k: integer;
        amino_ch: char;
    begin
        Debug('Начинаем поиск подпоследовательностей...');
        for i := 1 to Length(nucl_seqs) do
        begin
            for j := 1 to Length(nucl_seqs[i].seq) do
            begin
                codon_str := codon_str + nucl_seqs[i].seq[j].ch;
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
    end;

    procedure Read_nucl_seqs(); { получить нуклеотидные последовательности }
    const
        SEQ_NUCL_CHARS: string = 'ACGTU';
    var
        nucl_seq: seq_r;
        i: integer;
    begin
        Restore_default_seq_item();
        Debug('Получаем последовательности...');

        SetLength(nucl_seqs, 1);
        i := 1;
        while true do
        begin
            if EOF(nucl_input) then
            begin
                if (i = 1) then WriteErr(MSG_UNEXPECTED_EOF, nucl_path)
                else break;
            end;
            nucl_seq.form := UNKNOWN;
            nucl_seq.name := Seq_name(nucl_input);

            Debug('Нуклеотидная последовательность #' + IntToStr(i) + ': ' + nucl_seq.name);
            while true do
            begin
                Read_parse_char(nucl_input);
                Debug(seq_item.ch + ' ' + IntToStr(seq_item.ord) + ' ' + IntToStr(seq_item.row) + ' ' + IntToStr(seq_item.col));

                if EOF(nucl_input) or (seq_item.ch = '>') then break { дошли до названия следующей последовательности }
                else if not If_whitespace() then
                begin
                    seq_item.ch := UpCase(seq_item.ch);
                    if not In_string(SEQ_NUCL_CHARS) then
                        WriteErr(MSG_BAD_NUCL_SEQ, '');
                    { определение типа последовательности }
                    if seq_item.ch = 'U' then
                        if nucl_seq.form = DNA then WriteErr(MSG_BAD_TYPE, 'Символ (' + IntToStr(seq_item.row) + ',' + IntToStr(seq_item.row) + '): ' + seq_item.ch)
                        else nucl_seq.form := RNA
                    else if seq_item.ch = 'T' then
                        if nucl_seq.form = RNA then WriteErr(MSG_BAD_TYPE, 'Символ (' + IntToStr(seq_item.row) + ',' + IntToStr(seq_item.row) + '): ' + seq_item.ch)
                        else nucl_seq.form := DNA;
                    if seq_item.ch = 'T' then
                        seq_item.ch := 'U'
                end;
            end;
            if i = Length(nucl_seqs) then
                SetLength(nucl_seqs, i * 2);
            nucl_seqs[i] := nucl_seq;
            inc(i);
        end;
        SetLength(nucl_seqs, i);
    end;

    procedure Main(); { обработка входных данных }
    begin
        Debug('Подготовка к обработке аминокислотной последовательности...');
        Prepare_file(amino_input, amino_path);
        Read_amino_seq();
        Close(amino_input);

        Debug('Подготовка к обработке нуклеотидной последовательности...');
        Prepare_file(nucl_input, nucl_path);
        Read_nucl_seqs();
        Search_sub_seqs();
        Close(nucl_input);
    end;
end.
