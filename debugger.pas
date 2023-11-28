Unit Debugger;

interface
    var
        debug_mode: boolean;

    procedure Debug(const msg: string);

implementation
    uses
        Crt, SysUtils;   { стандартные модули }
        
    procedure Debug(const msg: string);
    begin
        if debug_mode then
        begin
            TextColor(Magenta);
            WriteLn(FormatDateTime('hh:nn:ss.zzz', Now), ' ', msg);
            NormVideo();
        end;
    end;

end.
