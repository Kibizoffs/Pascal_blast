unit Parser;

interface
    type    
        { запись символа }
        seq_item_r = record
            ch:  char;
            ord: longword;
            col: longword;
            row: longword;
        end;

    var
        seq_item: seq_item_r;

    { основной ход программы }
    procedure Main();

implementation
    uses
        SysUtils, { стандартное }
        Global,   { глобальное }
        Output,   { отладка, вывод ошибок и ответов }
        Utils;    { дополнительное }

    type
        seq_type = (AMINO, DNA, RNA, UNKNOWN); { типы последовательностей }
        seq_r = record { запись последовательности }
            type_: seq_type; { 'type' - стандартное слово }
            name_: string; { 'name' - стандартное слово }
            size:  qword;
            ctx:   array of seq_item_r;
        end;
        seqs_r = record { запись последовательностей }
            size: qword;
            seqs: array of seq_r;
        end;
        mod_3_r = record { запись триплета последовательности }
            start: boolean;
            n:     longword;
        end;
        link_mod_3_r = ^mod_3_r; { ссылка на запись триплета последовательности }

    var
        amino_input, nucl_input: text;
        amino_seq:               seq_r;
        nucl:                    seqs_r;
        nothing_found:           boolean;

    { получить имя последовательности }
    function Seq_name(var input: Text): string;
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

    { получить аминокислотную последовательность }
    procedure Read_amino();
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

    { получить ссылку на нужный триплет последовательности }
    function Mod_link(temp_j: longword; var mod_0, mod_1, mod_2: mod_3_r): link_mod_3_r;
    begin
        case (temp_j mod 3) of
            0: mod_link := @mod_0;
            1: mod_link := @mod_1;
            2: mod_link := @mod_2;
        end;
    end;

    { получить ссылку на нужный триплет последовательности }
    procedure One_way_search(i, j: longword; temp_ch: seq_item_r; mod_0, mod_1, mod_2: mod_3_r; reversed: boolean);
    var
        temp_j, k: longword;
        mod_3:     link_mod_3_r;
        codon_str: string;
        amino_ch:  char;
        flag:      boolean;
    begin
        if not reversed then
        begin
            temp_j := j;
            flag := (temp_j < (nucl.seqs[i].size - 3))
        end
        else
        begin
            temp_j := nucl.seqs[i].size - 3;
            flag := (temp_j >= 0)
        end;
        while flag do
        begin
            codon_str := '';
            if not reversed then
                for k := temp_j to (temp_j + 2) do
                    codon_str := codon_str + nucl.seqs[i].ctx[k].ch
            else
                for k := temp_j to (temp_j + 2) do
                    codon_str := codon_str + nucl.seqs[i].ctx[k].ch;

            mod_3 := mod_link(temp_j, mod_0, mod_1, mod_2);

            if (mod_3^.start = true) or (codon_str = 'AUG') then
            begin
                case codon_str of
                    'UAA', 'UGA', 'UAG': { стоп кодоны }
                    begin
                        mod_3^.start := false;

                        if mod_3^.n >= amino_seq.size then
                        begin
                            nothing_found := false;
                            WriteAns(amino_seq.name_);
                            if not reversed then
                                WriteAns(IntToStr(nucl.seqs[i].ctx[j].ord) + ', ' + IntToStr(temp_ch.ord))
                            else
                                WriteAns('-' + IntToStr(nucl.seqs[i].size - nucl.seqs[i].ctx[j].ord) + ', -' + IntToStr(nucl.seqs[i].size - temp_ch.ord));
                            WriteAns('(' + IntToStr(nucl.seqs[i].ctx[j].row) + ',' +
                                IntToStr(nucl.seqs[i].ctx[j].col) + ') - (' +
                                IntToStr(temp_ch.row) + ',' + IntToStr(temp_ch.col) + ')');
                            if not reversed then
                                for k := j to (temp_j + 2) do
                                    Write(nucl.seqs[i].ctx[k].ch)
                            else for k := j downto (temp_j - 2) do
                                    Write(nucl.seqs[i].ctx[k].ch);
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
                        if (mod_3^.start = false) then
                        begin
                            mod_3^.start := true;
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

                if mod_3^.n < amino_seq.size then
                begin
                    if (amino_ch = amino_seq.ctx[mod_3^.n].ch) or
                        (mode = 3) and (amino_seq.ctx[mod_3^.n].ch = '-') then
                    begin
                        inc(mod_3^.n);
                        if mod_3^.n = amino_seq.size then
                        begin
                            temp_ch.ord := nucl.seqs[i].ctx[temp_j].ord;
                            temp_ch.row := nucl.seqs[i].ctx[temp_j].row;
                            temp_ch.col := nucl.seqs[i].ctx[temp_j].col;
                        end;
                    end
                    else mod_3^.n := 0
                end;
                if not reversed then
                begin
                    temp_j := temp_j + 3;
                    flag := (temp_j < (nucl.seqs[i].size - 3))
                end
                else
                begin
                    temp_j := temp_j - 3;
                    flag := (temp_j >= 0)
                end;
                Debug(codon_str + ' ' + inttostr(j) + ' ' + inttostr(mod_3^.n) + '/' + inttostr(amino_seq.size));
            end
            else break;
        end;
    end;

    procedure Search_sub_seqs(); { Найти подпоследовательности }
    var
        i, j:                longword;
        temp_ch:             seq_item_r;
        mod_0, mod_1, mod_2: mod_3_r; 
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
            temp_ch.ch := #0;
            temp_ch.ord := 0;
            temp_ch.row := 0;
            temp_ch.col := 0;
            mod_0.n := 0;
            mod_0.start := false;
            mod_1.n := 0;
            mod_1.start := false;
            mod_2.n := 0;
            mod_2.start := false;

            One_way_search(i, j, temp_ch, mod_0, mod_1, mod_2, false);
            if nucl.seqs[i].type_ = DNA then
                One_way_search(i, j, temp_ch, mod_0, mod_1, mod_2, true);

            inc(j);
        end;
        if nothing_found then WriteAns('Нет совпадений');
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
