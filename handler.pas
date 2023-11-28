unit Handler;

interface
    const
        MSG_BAD_PARAMS         = 'ERR00: Неправильное кол-во аргументов (читать ''Readme.md'')';
        MSG_BAD_MODE           = 'ERR01: Неправильный режим. Доступны: ''1'', ''3''';
        MSG_NO_FILE            = 'ERR02: Файл не был найден: ';
        MSG_UNEXPECTED_EOF     = 'ERR03: Неожиданный конец файла: ';
        MSG_BAD_FASTA_FORMAT   = 'ERR04: Плохой формат FASTA файла: ';
        MSG_BAD_FASTA_SEQ_NAME = 'ERR05: Плохое название последовательности: ';
        MSG_BAD_TYPE           = 'ERR06: Плохой тип последовательности. ';
        MSG_BAD_AMINO_SEQ      = 'ERR07: Плохая аминокислотная последовательность. ';
        MSG_BAD_NUCL_SEQ       = 'ERR08: Плохая нуклеотидная последовательность. ';

    procedure WriteErr(main_msg: string; add_msg: string);

implementation
    uses
        Crt, SysUtils, { Модули }
        Global,        { Глобальное }
        Debugger,      { Разработка }
        Utils;         { дополнительное }

    procedure WriteErr(main_msg: string; add_msg: string);
    begin
        if debug_mode then
            WriteLn(output, Current_time(), ' ', main_msg, add_msg);
        TextColor(red);
        WriteLn(main_msg, add_msg);
        Halt(1);
    end;
end.
