unit Handler;

interface
    const
        MSG_BAD_PARAMS = 'ERR0: Неправильное кол-во аргументов';
        MSG_BAD_MODE   = 'ERR1: Неправильное режим. Доступны: ''1'', ''3''';
        MSG_NO_FASTA_FILE = 'ERR2: Нет FASTA файла';
        MSG_NO_RNA_DNA_FILE = 'ERR2: Нет RNA-DNA файла';


    procedure WriteErr(msg: string);

implementation
    procedure WriteErr(msg: string);
    begin
        WriteLn(msg);
    end;

end.
