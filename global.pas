unit Global;

interface
    type    
        seq_item_r = record
            ch:  char;
            ord: longword;
            row: longword;
            col: longword;
        end;
        seq_r_form = (AMINO, DNA, RNA, UNKNOWN);
        seq_r = record
            form: seq_r_form;
            name: string;
            seq:  array of seq_item_r;
            size: longword;
        end;
    var
        debug, finish, flag: boolean;
        mode, code:          byte;
        i:                   integer;
        seq_item:            seq_item_r;

implementation

end.
