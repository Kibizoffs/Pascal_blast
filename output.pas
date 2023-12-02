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

    procedure Debug(const msg_in: string); { вывод сообщения отладки }

    procedure WriteErr(const main_msg: string; const add_msg: string); { вывод ошибки }

    procedure WriteAns(const msg: string); { вывод ошибки }

implementation
    uses
        Crt, SysUtils, { стандартное }
        Global,        { глобальное }
        Utils;         { дополнительное }

    var
        override_debug_mode: boolean = false;

    { отладка }
    procedure Debug(const msg_in: string);
    var
        msg_out: string;
    begin
        msg_out := Current_time() + ' ' + msg_in;
        WriteLn(output_text, msg_out);

        if debug_mode and not override_debug_mode then
        begin
            TextColor(Magenta);
            WriteLn(msg_out);
            NormVideo();
        end;
    end;

    { вывести ошибку }
    procedure WriteErr(const main_msg: string; const add_msg: string); { вывод ошибки }
    begin
        override_debug_mode := true;
        Debug(main_msg + add_msg);
        override_debug_mode := false;

        TextColor(red);
        WriteLn(main_msg, add_msg);
        NormVideo();

        Halt(1);
    end;

    { вывести ответ }
    procedure WriteAns(const msg: string); { вывод ошибки }
    begin
        override_debug_mode := true;
        Debug(msg);
        override_debug_mode := false;

        TextColor(green);
        WriteLn(msg);
        NormVideo();
    end;
end.
