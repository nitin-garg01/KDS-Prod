
codeunit 50200 "Amount In Words"
{
    procedure AmountInWords(Amount: Decimal; CurrencyCode: Code[10]): Text
    var
        WholePart: Integer;
        DecimalPart: Integer;
        Result: Text;
        MainCurrencyText: Text;
        DecimalCurrencyText: Text;
    begin
        WholePart := Round(Amount - (Amount mod 1), 1, '<');
        DecimalPart := Round((Amount mod 1) * 100, 1, '<');
        case UpperCase(CurrencyCode) of
            '', 'INR':
                begin
                    MainCurrencyText := 'Rupees';
                    DecimalCurrencyText := 'Paise';
                end;
            'USD':
                begin
                    MainCurrencyText := 'USD';
                    DecimalCurrencyText := 'Cents';
                end;
            'GBP':
                begin
                    MainCurrencyText := 'Pounds';
                    DecimalCurrencyText := 'Pence';
                end;
            'EUR':
                begin
                    MainCurrencyText := 'Euro';
                    DecimalCurrencyText := 'Cents';
                end;
            else begin
                MainCurrencyText := CurrencyCode;
                DecimalCurrencyText := '';
            end;
        end;

        
        Result := MainCurrencyText + ' ' + ConvertToWords(WholePart);

       
        if DecimalPart > 0 then begin
            if DecimalCurrencyText <> '' then
                Result := Result + ' and ' + ConvertToWords(DecimalPart) + ' ' + DecimalCurrencyText
            else
                Result := Result + ' and ' + ConvertToWords(DecimalPart);
        end;

        Result := Result + ' Only';

        exit(Result);
    end;

    local procedure ConvertToWords(Number: Integer): Text
    var
        Words: Text;
    begin
        if Number = 0 then
            exit('Zero');

        Words := '';

        if Number < 0 then begin
            Words := 'Negative ';
            Number := -Number;
        end;

        if Number >= 10000000 then begin
            Words += ConvertToWords(Number div 10000000) + ' Crore ';
            Number := Number mod 10000000;
        end;

        if Number >= 100000 then begin
            Words += ConvertToWords(Number div 100000) + ' Lakh ';
            Number := Number mod 100000;
        end;

        if Number >= 1000 then begin
            Words += ConvertToWords(Number div 1000) + ' Thousand ';
            Number := Number mod 1000;
        end;

        if Number >= 100 then begin
            Words += ConvertToWords(Number div 100) + ' Hundred ';
            Number := Number mod 100;
        end;

        if Number >= 20 then begin
            Words += GetTens(Number div 10) + ' ';
            Number := Number mod 10;
        end else
            if Number >= 10 then begin
                Words += GetTeens(Number) + ' ';
                Number := 0;
            end;

        if Number > 0 then
            Words += GetOnes(Number) + ' ';

        exit(DelChr(Words, '<>', ' '));
    end;

    local procedure GetOnes(Number: Integer): Text
    begin
        case Number of
            1:
                exit('One');
            2:
                exit('Two');
            3:
                exit('Three');
            4:
                exit('Four');
            5:
                exit('Five');
            6:
                exit('Six');
            7:
                exit('Seven');
            8:
                exit('Eight');
            9:
                exit('Nine');
        end;

        exit('');
    end;

    local procedure GetTeens(Number: Integer): Text
    begin
        case Number of
            10:
                exit('Ten');
            11:
                exit('Eleven');
            12:
                exit('Twelve');
            13:
                exit('Thirteen');
            14:
                exit('Fourteen');
            15:
                exit('Fifteen');
            16:
                exit('Sixteen');
            17:
                exit('Seventeen');
            18:
                exit('Eighteen');
            19:
                exit('Nineteen');
        end;

        exit('');
    end;

    local procedure GetTens(Number: Integer): Text
    begin
        case Number of
            2:
                exit('Twenty');
            3:
                exit('Thirty');
            4:
                exit('Forty');
            5:
                exit('Fifty');
            6:
                exit('Sixty');
            7:
                exit('Seventy');
            8:
                exit('Eighty');
            9:
                exit('Ninety');
        end;

        exit('');
    end;
}