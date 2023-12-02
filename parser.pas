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

    var
        amino_input, nucl_input: text;
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
        i := 0;
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
                if (i + 1) = Length(amino_seq.ctx) then
                    SetLength(amino_seq.ctx, amino_seq.size);
                amino_seq.size := i + 1;
                amino_seq.ctx[i] := seq_item;
                inc(i);
            end
            else if not (If_EOLN() or If_whitespace()) then
                WriteErr(MSG_BAD_AMINO, '');
        end;
    end;

    procedure Search_sub_seqs(); { Найти подпоследовательности }
    var
        i, j, j_temp, k,
        m_ord, m_row, m_col,
        n_mod_0, n_mod_1, n_mod_2, n: longword;
        codon_str:                    string;
        nothing_found, 
        start_mod_0, start_mod_1,
        start_mod_2, start:           boolean;
        amino_ch:                     char;
    begin
        nothing_found := true;

        Debug(
            'Поиск подпоследовательностей... | ' +
            'Нуклеотидные последовательности: ' + IntToStr(nucl.size) + '; ' +
            'Аминокислоты: ' + IntToStr(Length(amino_seq.ctx))
        );
        for i := 0 to (nucl.size - 1) do
        begin
            j := 0;
            start_mod_0 := false;
            start_mod_1 := false;
            start_mod_2 := false;
            n_mod_0 := 0;
            n_mod_1 := 0;
            n_mod_2 := 0;

            while j < (nucl.seqs[i].size - 3) do
            begin
                j_temp := j;

                while j_temp < (nucl.seqs[i].size - 3) do
                begin
                    codon_str := '';
                    for k := j_temp to (j_temp + 2) do
                        codon_str := codon_str + nucl.seqs[i].ctx[k].ch;
                    //Debug(IntToStr(j) + ' ' + codon_str + ' ' + IntToStr(j_temp) + ' ' + IntToStr(n) + '/' + IntToStr(amino_seq.size));

                    case (j_temp mod 3) of
                        0:
                        begin
                            start := start_mod_0;
                            n := n_mod_0;
                        end;
                        1:
                        begin
                            start := start_mod_1;
                            n := n_mod_1;
                        end;
                        2:
                        begin
                            start := start_mod_2;
                            n := n_mod_2;
                        end;
                    end;

                    if (start = true) or (codon_str = 'AUG') then
                    begin
                        case codon_str of
                            'UAA', 'UGA', 'UAG': { стоп кодоны }
                            begin
                                case (j_temp mod 3) of
                                    0: start_mod_0 := false;
                                    1: start_mod_1 := false;
                                    2: start_mod_2 := false;
                                end;
                                if n >= amino_seq.size then
                                begin
                                    nothing_found := false;
                                    WriteLn();
                                    WriteLn(amino_seq.name_);
                                    WriteLn(nucl.seqs[i].ctx[j].ord, ', ', m_ord);
                                    WriteLn('(', nucl.seqs[i].ctx[j].row, ',', nucl.seqs[i].ctx[j].col, ') - (', m_row, ',', m_col, ')');
                                    for k := j to (j_temp + 2) do
                                        Write(nucl.seqs[i].ctx[k].ch);
                                    WriteLn();
                                    break;
                                end;
                            end;
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
                            'AUG': { старт кодон }
                            begin
                                if (start = false) then
                                begin
                                    case (j_temp mod 3) of
                                        0: start_mod_0 := true;
                                        1: start_mod_1 := true;
                                        2: start_mod_2 := true;
                                    end;
                                    amino_ch := 'M';
                                end;
                            end;
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
                        if n < amino_seq.size then
                        begin
                            if amino_ch = amino_seq.ctx[n].ch then
                            begin
                                inc(n);
                                if n = amino_seq.size then
                                begin
                                    m_ord := nucl.seqs[i].ctx[j_temp].ord;
                                    m_row := nucl.seqs[i].ctx[j_temp].row;
                                    m_col := nucl.seqs[i].ctx[j_temp].col;
                                end;
                            end
                            else n := 0;
                            case (j_temp mod 3) of
                                0: n_mod_0 := n;
                                1: n_mod_1 := n;
                                2: n_mod_2 := n;
                            end;
                        end;
                        Debug(codon_str + ' ' + inttostr(j) + ' ' + inttostr(n) + '/' + inttostr(amino_seq.size));
                        j_temp := j_temp + 3;
                    end
                    else break;
                end;

                inc(j);
            end;
        end;
    end;

    procedure Read_nucls(); { Получить нуклеотидные последовательности }
    const
        SEQ_NUCL_CHARS: string = 'ACGTU';
    var
        i, j: longword;
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
                        
                    inc(j);
                end;
            end;

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
