Unit Debugger;

interface

    procedure Debug(const msg_in: string);

implementation
    uses
        Crt, SysUtils, { Стандартное }
        Global,        { Глобальное }
        Utils;         { Дополнительное }

    procedure Debug(const msg_in: string);
    var
        msg_out: string;
    begin
        msg_out := Current_time() + ' ' + msg_in;
        WriteLn(output, msg_out);
        if debug_mode then
        begin
            TextColor(Magenta);
            WriteLn(msg_out);
            NormVideo();
        end;
    end;

end.
