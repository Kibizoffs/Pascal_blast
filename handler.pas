unit Handler;

interface
    const
        MSG_BAD_PARAMS      = 'ERR0: Неправильное кол-во аргументов';
        MSG_BAD_MODE        = 'ERR1: Неправильное режим. Доступны: ''1'', ''3''';
        MSG_NO_FILE         = 'ERR2: Файл не был найден: ';
        MSG_BAD_FASTA_SEQ_NAME = 'ERR3';
        MSG_BAD_FASTA_FORMAT       = 'ERR4: Плохой формат FASTA файла';
        MSG_BAD_TYPE       = 'ERR5: Плохой тип последовательности';


    procedure WriteErr(main_msg: string; add_msg: string);

implementation
    uses
        Crt; { стандартные модули }

    procedure WriteErr(main_msg: string; add_msg: string);
    begin   
        TextColor(red);
        WriteLn(main_msg, add_msg);
        Halt(1)
    end;

end.
