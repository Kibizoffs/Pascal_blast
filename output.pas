unit Output; { вывод }

interface
    const
        MSG_BAD_PARAMS         = 'ERR00: Неправильное кол-во аргументов (читать ''Readme.md'')';
        MSG_BAD_MODE           = 'ERR01: Неправильный режим. Доступны: ''1'', ''3''';
        MSG_NO_FILE            = 'ERR02: Файл не был найден: ';
        MSG_UNEXPECTED_EOF     = 'ERR03: Неожиданный конец файла: ';
        MSG_BAD_FASTA_FORMAT   = 'ERR04: Плохой формат FASTA файла: ';
        MSG_BAD_FASTA_SEQ_NAME = 'ERR05: Плохое название последовательности: ';
        MSG_BAD_TYPE           = 'ERR06: Плохой тип последовательности. ';
        MSG_BAD_AMINO          = 'ERR07: Плохая аминокислотная последовательность. ';
        MSG_BAD_NUCL           = 'ERR08: Плохая нуклеотидная последовательность. ';

    procedure Write_output_file(const msg: string);

    procedure Debug(const msg: string);

    procedure Write_err(const main_msg: string; const add_msg: string);

    procedure Write_ans(const msg: string);

implementation
    uses
        Crt, SysUtils, { стандартное }
        Global,        { глобальное }
        Utils;         { дополнительное }

    { вывод в файл }
    procedure Write_output_file(const msg: string);
    begin
        WriteLn(output_text, Current_time() + ' ' + msg);
    end;

    { отладка }
    procedure Debug(const msg: string);
    begin
        Write_output_file(msg);

        if debug_mode then
        begin
            TextColor(Magenta);
            WriteLn(msg);
            NormVideo();
        end;
    end;

    { вывести ошибку }
    procedure Write_err(const main_msg: string; const add_msg: string);
    begin
        Write_output_file(main_msg + add_msg);

        TextColor(red);
        WriteLn(main_msg + add_msg);
        NormVideo();

        Halt(1);
    end;

    { вывести ответ }
    procedure Write_ans(const msg: string);
    begin
        Write_output_file(msg);

        TextColor(green);
        WriteLn(msg);
        NormVideo();
    end;
end.
