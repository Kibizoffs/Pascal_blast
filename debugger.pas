Unit Debugger;

interface
    var
        debug_mode: boolean;

    procedure Debug(const msg: string);

implementation
    uses
        Crt;   { стандартные модули }

    function Random_string(const n: integer): string;
    var
        randomN1, randomN2, i, offset: integer;
    begin
        Random_string := '';

        randomize;
        for i := 1 to n do
        begin
            randomN1 := Random(2);
            randomN2 := Random(26);
            if randomN1 = 0 then
                offset := 65
            else if randomN1 = 1 then
                offset := 97;
            Random_string := Random_string + Chr(offset + randomN2);
        end;
    end;
        
    procedure Debug(const msg: string);
    begin
        if debug_mode then
        begin
            TextColor(Yellow);
            WriteLn(Random_string(4), ' ', msg);
            NormVideo();
        end;
    end;

end.
