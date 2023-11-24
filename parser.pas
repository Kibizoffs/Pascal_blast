unit Parser;

interface
    type    
        sequence_item_r = record
            item:   char;
            row:    longword;
            column: longword
        end;
        sequence_r = record
            name: string;
            biology_type: (AMINO, RNA, DNA, UNKNOWN);
            sequence: array of sequence_item;
            actual_size: qword
        end;

    procedure Parser(fasta_name: string; dna_rna_name: string);

implementation
    uses
        SysUtils, { стандартные модули }
        Global,   { глобальные переменные }
        Handler;  { обработка ошибок }

    var
        ch: char;
        r, c: integer;
        input: Text;
        sequence: sequence_r;
        sequence_item: sequence_item_r;

    procedure Parser(fasta_name: string; dna_rna_name: string); { обработка входных данных }
    begin
        if not(FileExists(dna_rna_name)) then
            WriteErr(MSG_NO_FASTA_FILE);
        Assign(input, dna_rna_name);
        Reset(input);
        r := 1;
        c := 1;
        while true do
        begin
            while true do
            begin
                if EOF then break;
                ReadLn() until EOLN = false;
                if EOF then break;
                Read(ch);
                if ch = '>' then
                while ch <> ' ' do
                    Read(ch)
                    sequence.name := sequence.name + ch;
                while EOlN = false do
                    Read(ch)
                    sequence.type := sequence.type + ch;
                WriteLn(sequence.name, sequence.type);

                {case c of
                    'GCU', 'GCC', 'GCA', 'GCG':               amino_acid := 'A';
                    'UGU', 'UGC':                             amino_acid := 'C';
                    'GAU', 'GAC':                             amino_acid := 'D';
                    'GAA', 'GAG':                             amino_acid := 'E';
                    'UUU', 'UUC':                             amino_acid := 'F';
                    'GGU', 'GGC', 'GGA', 'GGG':               amino_acid := 'G';
                    'CAU', 'CAC':                             amino_acid := 'H';
                    'AUU', 'AUC', 'AUA':                      amino_acid := 'I';
                    'AAA', 'AAG':                             amino_acid := 'K';
                    'UUA', 'UUG', 'CUU', 'CUC', 'CUA', 'CUG': amino_acid := 'L';
                    'AUG':                                    amino_acid := 'M';
                    'AAU', 'AAC':                             amino_acid := 'N';
                    'CCU', 'CCC', 'CCA', 'CCG':               amino_acid := 'P';
                    'CAA', 'CAG':                             amino_acid := 'Q';
                    'CGU', 'CGC', 'CGA', 'CGG', 'AGA', 'AGG': amino_acid := 'R';
                    'UCU', 'UCC', 'UCA', 'UCG', 'AGU', 'AGC': amino_acid := 'S';
                    'ACU', 'ACC', 'ACA', 'ACG':               amino_acid := 'T';
                    'GUU', 'GUC', 'GUA', 'GUG':               amino_acid := 'V';
                    'UGG':                                    amino_acid := 'W';
                    'UAU', 'UAC':                             amino_acid := 'Y'}
                end;
            end;
        end;

        CloseFile(dna_rna_file)

        if not(FileExists(fasta_name)) then
            WriteErr(MSG_NO_FASTA_FILE);
        Assign(fasta_file, fasta_name);
        Reset(fasta_file);
        Read(fasta_file)

        CloseFile(fasta_file);
    end;

end.
