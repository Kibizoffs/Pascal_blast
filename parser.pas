unit Parser; { обработка ввода и нахождение последовательностей }

interface
    type    
        seq_item_r = record { запись символа }
            ch:  char;
            ord: longword;
            col: longword;
            row: longword;
        end;

    var
        seq_item:          seq_item_r;
        letter_in_line_fl: boolean; { для обработки в Read_parse_char() }

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

    var
        amino_input, nucl_input: text;
        amino_seq:               seq_r;
        no_findings:           boolean;

    { получить имя последовательности }
    function Seq_name(var input: Text): string;
    const
        SEQ_NAME_PUNCTUATION: string = '!''"(),-.:;[]_{}/';
    begin
        Seq_name := '';

        if EOF(input) then Write_err(MSG_UNEXPECTED_EOF, '')
        else if seq_item.ch <> '>' then Read_parse_char(input);

        if seq_item.ch = '>' then
            while true do
            begin
                if EOF(input) then Write_err(MSG_UNEXPECTED_EOF, '');
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
                    Write_err(MSG_BAD_FASTA_SEQ_NAME, seq_item.ch);

                Seq_name := Seq_name + seq_item.ch;
                Inc(seq_item.col);
            end
        else
            Write_err(MSG_BAD_FASTA_FORMAT, '');

        {
            Seq_name() принимает названия и аминокислотных, и нуклеотидных последовательностей.
            seq_item.row и seq_item.col учитываются в названиях нуклеотидных. 
            seq_item.row и seq_item.col не учитываются в названиях аминокислотных.
            seq_item.ord не учитывается в названиях.
            Использование seq_item обусловлено использованием Read_parse_char().
        }
        seq_item.ord := 0;
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
        i := 0; { индекс текущего символа }

        Debug('Получаем аминокислотную последовательность ''' + amino_seq.name_ + '''...');
        while true do
        begin
            if EOF(amino_input) then break;
            Read_parse_char(amino_input);
            
            if EOF(amino_input) then
            begin
                if i = 0 then
                    Write_err(MSG_UNEXPECTED_EOF, '')
                else break
            end
            else if Is_inside(SEQ_AMIGO_LEGAL_CHARS) then
            begin
                if i + 1 = Length(amino_seq.ctx) then
                    SetLength(amino_seq.ctx, amino_seq.size * 2);
                amino_seq.size := i + 1;
                
                amino_seq.ctx[i] := seq_item;
                inc(i);
            end
            else if not (If_EOLN() or If_whitespace()) then
                Write_err(MSG_BAD_AMINO, '');
        end;
    end;

    {
        Логика: Read_nucls() --> Search_sub_seqs() --> One_way_search()
        Вызовы: Read_nucls() вызывает Search_sub_seqs()
                Search_sub_seqs() вызывает One_way_search()
    }
    procedure One_way_search(nucl: seq_r; i: longword;
        var temp_ch: seq_item_r; var n: longword;
        reversed: boolean
    ); forward;
    procedure Search_sub_seqs(nucl: seq_r); forward;

    { читать нуклеотидные последовательности }
    procedure Read_nucls();
    const
        SEQ_NUCL_CHARS: string = 'ACGTU-';
    var
        nucl: seq_r;
        no_nucl_seqs: boolean;
    begin
        Restore_default_seq_item(seq_item); { после обработки амин посл обнулим глобальные переменные }
        no_findings := true; { если находок = 0 }
        no_nucl_seqs := true; { если нукл посл = 0 }

        while true do
        begin
            if EOF(nucl_input) then
            begin
                if no_nucl_seqs then
                    Write_err(MSG_UNEXPECTED_EOF, nucl_path)
                else break;
            end;

            nucl.type_ := UNKNOWN;
            nucl.name_ := Seq_name(nucl_input);
            nucl.size := 1;
            SetLength(nucl.ctx, nucl.size);
            letter_in_line_fl := false;

            while true do
            begin
                Read_parse_char(nucl_input);

                if EOF(nucl_input) or (seq_item.ch = '>') then { дошли до названия следующей нукл посл }
                    break
                else if not If_whitespace() then
                begin
                    if not (('0' <= seq_item.ch) and (seq_item.ch <= '9') and not letter_in_line_fl
                    or (seq_item.ch = '-')) then
                    begin
                        seq_item.ch := UpCase(seq_item.ch);
                        if not Is_inside(SEQ_NUCL_CHARS) then
                            Write_err(MSG_BAD_NUCL, nucl.name_);
                        letter_in_line_fl := true;

                        { определение типа последовательности }
                        if seq_item.ch = 'U' then
                            if nucl.type_ = DNA then Write_err(MSG_BAD_TYPE, 'Символ (' + IntToStr(seq_item.row) + ',' + IntToStr(seq_item.col) + '): ' + seq_item.ch)
                            else nucl.type_ := RNA
                        else if seq_item.ch = 'T' then
                            if nucl.type_ = RNA then Write_err(MSG_BAD_TYPE, 'Символ (' + IntToStr(seq_item.row) + ',' + IntToStr(seq_item.col) + '): ' + seq_item.ch)
                            else nucl.type_ := DNA;
                        if seq_item.ch = 'T' then
                            seq_item.ch := 'U';

                        if nucl.size = Length(nucl.ctx) then
                            SetLength(nucl.ctx, nucl.size * 2); 
                        nucl.ctx[nucl.size] := seq_item;
                        Inc(nucl.size);
                        letter_in_line_fl := true;
                    end;
                end;
            end;
            Dec(nucl.size);
            Search_sub_seqs(nucl);
            no_nucl_seqs := false;
        end;
        if no_findings then
            Write_ans('Нет совпадений');
    end;

    { искать подпоследовательности }
    procedure Search_sub_seqs(nucl: seq_r);
    var
        i, n:          longword;
        temp_ch:       seq_item_r;
        reversed:      boolean;
    begin
        reversed := false;

        for i := 1 to (nucl.size - 2) do
        begin
            n := 0;
            Restore_default_seq_item(temp_ch);
            One_way_search(nucl, i, temp_ch, n, reversed); { выводит в произвольном порядке }
        end;

        if nucl.type_ = DNA then
        begin
            reversed := true;
            
            for i := (nucl.size - 1) downto 3 do
            begin
                n := 0;
                Restore_default_seq_item(temp_ch);
                One_way_search(nucl, i, temp_ch, n, reversed); { выводит в произвольном порядке }
            end;
        end;
    end;

    { произвести односторонний поиск }
    procedure One_way_search(nucl: seq_r; i: longword; var temp_ch: seq_item_r; var n: longword; reversed: boolean);
    var
        temp_i, j: longword;
        codon_str: string;
        amino_ch:  char;
    begin
        temp_i := i;

        while true do
        begin
            codon_str := '';
            if not reversed then
                for j := i to (i + 2) do
                    codon_str := codon_str + nucl.ctx[j].ch
            else
                for j := i downto (i - 2) do
                    codon_str := codon_str + nucl.ctx[j].ch;

            case codon_str of
                'UAA', 'UGA', 'UAG':                      amino_ch := '0'; { почти бесполезные стоп-кодоны }
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
                'AUG':                                    amino_ch := 'M'; { почти бесполезный старт-кодон }
                'AAU', 'AAC':                             amino_ch := 'N';
                'CCU', 'CCC', 'CCA', 'CCG':               amino_ch := 'P';
                'CAA', 'CAG':                             amino_ch := 'Q';
                'CGU', 'CGC', 'CGA', 'CGG', 'AGA', 'AGG': amino_ch := 'R';
                'UCU', 'UCC', 'UCA', 'UCG', 'AGU', 'AGC': amino_ch := 'S';
                'ACU', 'ACC', 'ACA', 'ACG':               amino_ch := 'T';
                'GUU', 'GUC', 'GUA', 'GUG':               amino_ch := 'V';
                'UGG':                                    amino_ch := 'W';
                'UAU', 'UAC':                             amino_ch := 'Y';
            else
            begin
                Write_err(MSG_BAD_NUCL, '');
                writeln(codon_str, ' ', reversed);
            end
            end;

            if (amino_ch = amino_seq.ctx[n].ch) or
                (amino_seq.ctx[n].ch = '-') and (mode = 3) and (amino_ch <> '0') then
            begin
                Inc(n);
                if n = amino_seq.size then
                begin
                    no_findings := false;
                    temp_ch.ord := nucl.ctx[i].ord;
                    temp_ch.row := nucl.ctx[i].row;
                    temp_ch.col := nucl.ctx[i].col;

                    WriteLn();
                    Write_ans(nucl.name_);
                    if not reversed then
                        Write_ans(IntToStr(nucl.ctx[temp_i].ord) + ', ' + IntToStr(temp_ch.ord))
                    else
                        Write_ans('-' + IntToStr(nucl.size - nucl.ctx[i].ord + 1) + ', -' + IntToStr(nucl.size - temp_ch.ord + 1));
                    Write_ans('(' + IntToStr(nucl.ctx[temp_i].row) + ',' +
                        IntToStr(nucl.ctx[temp_i].col) + ') - (' +
                        IntToStr(temp_ch.row) + ',' + IntToStr(temp_ch.col) + ')');
                    if not reversed then
                        for j := temp_i to i do
                            Write(nucl.ctx[j].ch)
                    else
                        for j := i downto temp_i do
                            Write(nucl.ctx[j].ch);
                    WriteLn();
                    WriteLn();

                    break
                end;
            end
            else break;

            if not reversed then
            begin
                i := i + 3;
                if i > nucl.size - 2 then break;
            end
            else
            begin
                i := i - 3;
                if i < 3 then break;
            end;
        end;
    end;

    { основной ход программы }
    procedure Main();
    begin
        Debug('Начинаем обрабатывать аминокислотную последовательность...');
        Prepare_input_file(amino_input, amino_path);
        Read_amino();
        Close(amino_input);

        Debug('Начинаем обрабатывать нуклеотидные последовательности...');
        Prepare_input_file(nucl_input, nucl_path);
        Read_nucls();
        Close(nucl_input);
        Debug('Конец программы...');
    end;
end.
