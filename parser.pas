unit Parser;

interface
    type    
        seq_item_r = record
            ch:  char;
            ord: longword;
            col: longword;
            row: longword;
        end;

    var
        seq_item: seq_item_r;

    procedure Main();

implementation
    uses
        SysUtils, { Стандартное }
        Debugger, { Разработка }
        Global,   { Глобальное }
        Handler,  { Обработка ошибок }
        Utils;    { Дополнительное }

    type
        seq_type = (AMINO, DNA, RNA, UNKNOWN);
        seq_r = record
            type_: seq_type; { 'type' - стандартное слово }
            name_: string; { 'name' - стандартное слово }
            size:  qword;
            ctx:   array of seq_item_r;
        end;
        seqs_r = record
            size: qword;
            seqs: array of seq_r;
        end;

    const
        start_codon: string = 'AUG';
        stop_codons: array[1..3] of string = ('UAA', 'UGA', 'UAG');

    var
        amino_input, nucl_input: text;
        codon_str:               string;
        amino_seq:               seq_r;
        nucl:                    seqs_r;

    function Seq_name(var input: Text): string; { Получить имя последовательности }
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
                    inc(seq_item.row);
                    seq_item.col := 0;
                    break;
                end
                else if not (
                    ('A' <= UpCase(seq_item.ch)) and (UpCase(seq_item.ch) <= 'Z') or
                    ('0' <= seq_item.ch) and (seq_item.ch <= '9') or
                    Is_inside(SEQ_NAME_PUNCTUATION) or
                    If_whitespace()
                ) then
                    WriteErr(MSG_BAD_FASTA_SEQ_NAME, '');

                Seq_name := Seq_name + seq_item.ch;
                inc(seq_item.col);
            end
        else
            WriteErr(MSG_BAD_FASTA_FORMAT, '');
        seq_item.ord := 0; { ord не зависит от названий последовательностей }
    end;

    procedure Read_amino(); { Получить аминокислотную последовательность }
    const 
        SEQ_AMIGO_LEGAL_CHARS = 'ACDEFGHIKLMNPQRSTVWY';
    var
        i: integer;
    begin
        amino_seq.type_ := AMINO;
        amino_seq.name_ := Seq_name(amino_input);
        amino_seq.size := 1;
        SetLength(amino_seq.ctx, amino_seq.size);

        Debug('Получаем последовательность ''' + amino_seq.name_ + '''...');
        i := 1;
        while true do
        begin
            if EOF(amino_input) then break;
            Read_parse_char(amino_input);
            {Debug(
                IntToStr(ord(seq_item.ch)) + '; ' +
                IntToStr(seq_item.ord) + '; ' +
                IntToStr(seq_item.row) + '; ' +
                IntToStr(seq_item.col)
            );}
            if EOF(amino_input) then
            begin
                if i = 1 then
                    WriteErr(MSG_UNEXPECTED_EOF, '')
                else break
            end
            else if Is_inside(SEQ_AMIGO_LEGAL_CHARS) then
            begin
                if i = Length(amino_seq.ctx) then
                begin
                    amino_seq.size := i * 2;
                    SetLength(amino_seq.ctx, amino_seq.size);
                end;
                amino_seq.ctx[i] := seq_item;
                inc(i);
            end
            else if not (If_EOLN() or If_whitespace()) then
                WriteErr(MSG_BAD_AMINO, '');
        end;
    end;

    procedure Search_sub_seqs(); { Найти подпоследовательности }
    var
        i, j, k, m:        longword;
        start_0_fl, start_1_fl, start_2_fl, stop_fl: boolean;
        amino_ch:          char;
    begin
        codon_str := '';
        start_fl := false;
        stop_fl := false;

        Debug(
            'Поиск подпоследовательностей... | ' +
            'Нуклеотидные последовательности: ' + IntToStr(nucl.size) + '; ' +
            'Аминокислоты: ' + IntToStr(Length(amino_seq.ctx))
        );
        for i := 0 to (nucl.size - 1) do
        begin
            for j := 0 to (nucl.seqs[i].size - 3) do
            begin
                for k := j to (k + 3) do
                    codon_str := codon_str + nucl.seqs[i].ctx[k].ch;
                if (codon_str = start_codon) and (stop_fl = true) then
                    start_fl
                else if 
            end;
        end;
    end;

    procedure Read_nucls(); { Получить нуклеотидные последовательности }
    const
        SEQ_NUCL_CHARS: string = 'ACGTU';
    var
        i, j, k, first_start_codon, last_stop_codon: longword;
    begin
        Restore_default_seq_item();

        i := 0; { синоним для nucl.size }
        SetLength(nucl.seqs, 1);
        while true do
        begin
            if EOF(nucl_input) then
            begin
                if (i = 0) then
                    WriteErr(MSG_UNEXPECTED_EOF, nucl_path)
                else break;
            end;

            nucl.seqs[i].type_ := UNKNOWN;
            nucl.seqs[i].name_ := Seq_name(nucl_input);
            j := 0; { синоним для nucl.seqs[i].size }
            SetLength(nucl.seqs[i].ctx, 1);
            codon_str := '';
            first_start_codon := 0;
            last_stop_codon := 0;

            Debug('Нуклеотидная последовательность #' + IntToStr(i) + ' ''' + nucl.seqs[i].name_ + '''');
            while true do
            begin
                Read_parse_char(nucl_input);
                { Debug(IntToStr(ord(seq_item.ch)) + ' ' + IntToStr(seq_item.ord) + ' ' + IntToStr(seq_item.row) + ' ' + IntToStr(seq_item.col)); }

                if EOF(nucl_input) or (seq_item.ch = '>') then break { Дошли до названия следующей последовательности }
                else if not If_whitespace() then
                begin
                    seq_item.ch := UpCase(seq_item.ch);
                    if not Is_inside(SEQ_NUCL_CHARS) then
                        WriteErr(MSG_BAD_nucl, '');
                    { Определение типа последовательности }
                    if seq_item.ch = 'U' then
                        if nucl.seqs[i].type_ = DNA then WriteErr(MSG_BAD_TYPE, 'Символ (' + IntToStr(seq_item.row) + ',' + IntToStr(seq_item.row) + '): ' + seq_item.ch)
                        else nucl.seqs[i].type_ := RNA
                    else if seq_item.ch = 'T' then
                        if nucl.seqs[i].type_ = RNA then WriteErr(MSG_BAD_TYPE, 'Символ (' + IntToStr(seq_item.row) + ',' + IntToStr(seq_item.row) + '): ' + seq_item.ch)
                        else nucl.seqs[i].type_ := DNA;
                    if seq_item.ch = 'T' then
                        seq_item.ch := 'U';

                    if j + 1 = Length(nucl.seqs[i].ctx) then
                        SetLength(nucl.seqs[i].ctx, (j + 1) * 2); 
                    nucl.seqs[i].size := j + 1;
                    nucl.seqs[i].ctx[j] := seq_item;

                    codon_str := codon_str + nucl.seqs[i].ctx[j].ch;
                    if Length(codon_str) > 3 then
                        codon_str = Copy(codon_str, 2, 3);
                    if (first_start_codon = 0) and (codon_str = first_start_codon) then
                        first_start_codon := j + 1;
                    if codon_str = last_stop_codon then
                        last_stop_codon := j + 1;
                        
                    inc(j);
                end;
            end;

            for k := 1 to first_start_codon then
                nucl.seqs[i].ctx[k].ch := 'X';
            for k := last_stop_codon to (nucl.seqs[i].size - 1) then
                nucl.seqs[i].ctx[k].ch := 'X';

            if i + 1 = Length(nucl.seqs) then
                SetLength(nucl.seqs, (i + 1) * 2);
            nucl.size := i + 1;
            inc(i);
        end;
    end;

    procedure Main(); { Обработка входных данных }
    begin
        Debug('Начинаем обрабатывать аминокислотную последовательность...');
        Prepare_input_file(amino_input, amino_path);
        Read_amino();
        Close(amino_input);

        Debug('Начинаем обрабатывать нуклеотидные последовательности...');
        Prepare_input_file(nucl_input, nucl_path);
        Read_nucls();
        Search_sub_seqs();
        Close(nucl_input);
    end;
end.
