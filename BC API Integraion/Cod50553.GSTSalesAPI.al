
codeunit 50553 "GST Sales API"
{
    Permissions =
        tabledata "Sales Invoice Header" = RIMD,
        tabledata "Sales Invoice Line" = RIMD,
        tabledata Customer = RIMD,
        tabledata "Company Information" = RIMD,
        tabledata "Detailed GST Ledger Entry" = RIMD,
        tabledata State = RIMD,
        tabledata "Unit of Measure" = RIMD,
        tabledata Item = RIMD,
        tabledata "G/L Account" = RIMD,
        tabledata "GST Registration Nos." = RIMD;

    procedure GetGSTApiUrl(): Text
    begin
        exit('http://103.100.217.51:81/gstapi/api/UploadData/Sale');
    end;

    procedure GetGSTApiAuthorization(): Text
    begin
        exit('Authorization /IalkRmh3z4=:::ZH4TUvIeJ3A=');
    end;

    procedure GetSalesJSON(SalesInvHeader: Record "Sales Invoice Header"): Text
    var
        CompanyInfo: Record "Company Information";
        SalesInvLine: Record "Sales Invoice Line";
        DataObj: JsonObject;
        DataArray: JsonArray;
        FinalObj: JsonObject;
        LineCount: Integer;
        JsonText: Text;
    begin
        CompanyInfo.Get();
        Clear(DataArray);
        Clear(FinalObj);

        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");

        if SalesInvLine.FindSet() then begin
            repeat
                if not ((SalesInvLine.Type = SalesInvLine.Type::" ") or (SalesInvLine."No." = '') or (SalesInvLine.Quantity = 0)) then begin
                    LineCount += 1;

                    if LineCount > 10000 then
                        Error('GST Sale API supports maximum 10000 item-wise records. Sales Invoice %1 contains more than 10000 valid item records.', SalesInvHeader."No.");

                    Clear(DataObj);
                    BuildSalesLineJSON(SalesInvHeader, SalesInvLine, CompanyInfo, DataObj);
                    DataArray.Add(DataObj);
                end;
            until SalesInvLine.Next() = 0;
        end;

        if LineCount = 0 then
            Error('No valid sales invoice lines found for Sales Invoice %1.', SalesInvHeader."No.");

        FinalObj.Add('Push_Data_List', DataArray);
        FinalObj.Add('Year', Date2DMY(SalesInvHeader."Posting Date", 3));
        FinalObj.Add('Month', Date2DMY(SalesInvHeader."Posting Date", 2));

        FinalObj.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure BuildSalesLineJSON(SalesInvHeader: Record "Sales Invoice Header"; SalesInvLine: Record "Sales Invoice Line"; CompanyInfo: Record "Company Information"; var DataObj: JsonObject)
    var
        Customer: Record Customer;
        StateRec: Record State;
        UnitOfMeasure: Record "Unit of Measure";
        IgstAmt: Decimal;
        CgstAmt: Decimal;
        SgstAmt: Decimal;
        CessAmt: Decimal;
        IgstRate: Decimal;
        CgstRate: Decimal;
        SgstRate: Decimal;
        CessRate: Decimal;
        GstRate: Decimal;
        TaxableValue: Decimal;
        Value: Decimal;
        CurrencyFactor: Decimal;
        PartyState: Text;
        ItemType: Text;
        SupplyType: Text;
        ReverseCharge: Text;
        UQC: Text;
        HSNCode: Text;
        InvoiceNo: Text;
        VoucherNo: Text;
        VoucherDate: Text;
        LineItemCode: Text;
        PortCode: Text;
        ShippingBillNo: Text;
        ShippingBillDate: Text;
        IRN: Text;
        AckNo: Text;
        AckDate: Integer;
        IsExport: Boolean;
    begin
        if not Customer.Get(SalesInvHeader."Sell-to Customer No.") then
            Error('Customer %1 not found for Sales Invoice %2.', SalesInvHeader."Sell-to Customer No.", SalesInvHeader."No.");

        if Customer."No." = '' then
            Error('PartyCode is blank for Sales Invoice %1.', SalesInvHeader."No.");

        PartyState := '';

        if Customer."State Code" <> '' then
            if StateRec.Get(Customer."State Code") then
                PartyState := StateRec."State Code (GST Reg. No.)";

        IsExport := false;

        if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then
            IsExport := true
        else
            if Customer."Country/Region Code" <> '' then
                if Customer."Country/Region Code" <> 'IN' then
                    IsExport := true;

        if SalesInvLine.Type = SalesInvLine.Type::Item then
            ItemType := 'G'
        else
            ItemType := 'S';

        HSNCode := GetHSNSACCode(SalesInvLine);

        GetGSTAmountsForLine(
            SalesInvHeader."No.",
            SalesInvLine."Line No.",
            SalesInvLine."Line Amount",
            IgstAmt,
            CgstAmt,
            SgstAmt,
            CessAmt,
            IgstRate,
            CgstRate,
            SgstRate,
            CessRate,
            GstRate,
            TaxableValue);

        if SalesInvHeader."Currency Factor" <> 0 then
            CurrencyFactor := SalesInvHeader."Currency Factor"
        else
            CurrencyFactor := 1;

        Value := Round(SalesInvLine."Line Amount" / CurrencyFactor, 0.01);
        TaxableValue := Round(TaxableValue / CurrencyFactor, 0.01);

        SupplyType := GetSupplyType(SalesInvHeader, Customer);
        ReverseCharge := GetReverseCharge(SalesInvHeader);

        UQC := '';

        if SalesInvLine."Unit of Measure Code" <> '' then begin
            UnitOfMeasure.Reset();
            UnitOfMeasure.SetRange(Code, SalesInvLine."Unit of Measure Code");

            if UnitOfMeasure.FindFirst() then
                UQC := UnitOfMeasure."International Standard Code";
        end;

        InvoiceNo := CopyStr(SalesInvHeader."No.", 1, 16);
        VoucherNo := SalesInvHeader."No.";
        VoucherDate := FormatGSTDate(SalesInvHeader."Posting Date");
        LineItemCode := CopyStr(SalesInvHeader."No." + '-' + Format(SalesInvLine."Line No."), 1, 100);

        PortCode := '';
        ShippingBillNo := '';
        ShippingBillDate := '';

        IRN := SalesInvHeader."IRN No.";
        AckNo := SalesInvHeader."Ack No.";
        AckDate := 0;

        if SalesInvHeader."Ack Date" <> 0DT then
            AckDate := DateToInteger(DT2Date(SalesInvHeader."Ack Date"));

        DataObj.Add('PartyCode', Customer."No.");
        DataObj.Add('PartyGSTIN', Customer."GST Registration No.");
        DataObj.Add('PartyUnitCode', '');
        DataObj.Add('InvoiceNo', InvoiceNo);
        DataObj.Add('Date', VoucherDate);
        DataObj.Add('Value', Value);
        DataObj.Add('HSNCode', HSNCode);
        DataObj.Add('TaxableValue', TaxableValue);
        DataObj.Add('IGSTRate', IgstRate);
        DataObj.Add('IGSTValue', Round(IgstAmt / CurrencyFactor, 0.01));
        DataObj.Add('CGSTRate', CgstRate);
        DataObj.Add('CGSTValue', Round(CgstAmt / CurrencyFactor, 0.01));
        DataObj.Add('SGSTRate', SgstRate);
        DataObj.Add('SGSTValue', Round(SgstAmt / CurrencyFactor, 0.01));
        DataObj.Add('CESSRate', CessRate);
        DataObj.Add('CESSValue', Round(CessAmt / CurrencyFactor, 0.01));
        DataObj.Add('ItemType', ItemType);
        DataObj.Add('UQC', UQC);
        DataObj.Add('SupplyType', SupplyType);
        DataObj.Add('POS', PartyState);
        DataObj.Add('ReverseCharge', ReverseCharge);
        DataObj.Add('PortCode', PortCode);
        DataObj.Add('ShippingBillNo', ShippingBillNo);
        DataObj.Add('ShippingBillDate', ShippingBillDate);
        DataObj.Add('State', PartyState);
        DataObj.Add('LineItemCode', LineItemCode);
        DataObj.Add('GSTIN', CompanyInfo."GST Registration No.");
        DataObj.Add('UnitCode', '');
        DataObj.Add('VoucherType', 'Sale');
        DataObj.Add('MismatchFlag', 0);
        DataObj.Add('ItemName', SalesInvLine.Description);
        DataObj.Add('ItemHead', 'Sale');
        DataObj.Add('EcomGSTIN', '');
        DataObj.Add('ItemQuantity', SalesInvLine.Quantity);
        DataObj.Add('VoucherNo', VoucherNo);
        DataObj.Add('VoucherDate', VoucherDate);
        DataObj.Add('IsModified', 'N');
        DataObj.Add('LeaseOFOldCar', 0);
        DataObj.Add('OtherCharges', 0);
        DataObj.Add('IRN', IRN);
        DataObj.Add('AckNo', AckNo);
        DataObj.Add('AckDate', AckDate);
    end;

    procedure UploadSales(SalesInvHeader: Record "Sales Invoice Header"): Text
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        RequestHeaders: HttpHeaders;
        JsonText: Text;
        ResultText: Text;
    begin
        JsonText := GetSalesJSON(SalesInvHeader);

        Content.WriteFrom(JsonText);
        Content.GetHeaders(Headers);

        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');

        Headers.Add('Content-Type', 'application/json');

        RequestHeaders := Client.DefaultRequestHeaders();

        if RequestHeaders.Contains('Authorization') then
            RequestHeaders.Remove('Authorization');

        if not RequestHeaders.TryAddWithoutValidation('Authorization', GetGSTApiAuthorization()) then
            Error('Unable to add Authorization header.');

        Client.Timeout := 30000;

        if Client.Post(GetGSTApiUrl(), Content, Response) then begin
            Response.Content().ReadAs(ResultText);

            if not Response.IsSuccessStatusCode() then
                Error('GST Sale API Error. HTTP Status: %1 %2', Response.HttpStatusCode(), ResultText);

            exit(ResultText);
        end;

        Error('GST Sale API server not reachable.');
    end;

    local procedure GetGSTAmountsForLine(DocNo: Code[20]; LineNo: Integer; LineAmount: Decimal; var IgstAmt: Decimal; var CgstAmt: Decimal; var SgstAmt: Decimal; var CessAmt: Decimal; var IgstRate: Decimal; var CgstRate: Decimal; var SgstRate: Decimal; var CessRate: Decimal; var GstRate: Decimal; var PreTaxVal: Decimal)
    var
        DetailedGSTEntry: Record "Detailed GST Ledger Entry";
    begin
        Clear(IgstAmt);
        Clear(CgstAmt);
        Clear(SgstAmt);
        Clear(CessAmt);
        Clear(IgstRate);
        Clear(CgstRate);
        Clear(SgstRate);
        Clear(CessRate);
        Clear(GstRate);

        PreTaxVal := Round(LineAmount, 0.01);

        DetailedGSTEntry.Reset();
        DetailedGSTEntry.SetRange("Document No.", DocNo);
        DetailedGSTEntry.SetRange("Document Line No.", LineNo);
        DetailedGSTEntry.SetRange("Entry Type", DetailedGSTEntry."Entry Type"::"Initial Entry");

        if DetailedGSTEntry.FindSet() then
            repeat
                case DetailedGSTEntry."GST Component Code" of
                    'IGST':
                        begin
                            IgstAmt += Abs(DetailedGSTEntry."GST Amount");
                            if IgstRate = 0 then
                                IgstRate := DetailedGSTEntry."GST %";
                        end;
                    'CGST':
                        begin
                            CgstAmt += Abs(DetailedGSTEntry."GST Amount");
                            if CgstRate = 0 then
                                CgstRate := DetailedGSTEntry."GST %";
                        end;
                    'SGST', 'UTGST':
                        begin
                            SgstAmt += Abs(DetailedGSTEntry."GST Amount");
                            if SgstRate = 0 then
                                SgstRate := DetailedGSTEntry."GST %";
                        end;
                    'CESS':
                        begin
                            CessAmt += Abs(DetailedGSTEntry."GST Amount");
                            if CessRate = 0 then
                                CessRate := DetailedGSTEntry."GST %";
                        end;
                end;
            until DetailedGSTEntry.Next() = 0;

        if IgstRate <> 0 then
            GstRate := IgstRate
        else
            GstRate := CgstRate + SgstRate;

        IgstAmt := Round(IgstAmt, 0.01);
        CgstAmt := Round(CgstAmt, 0.01);
        SgstAmt := Round(SgstAmt, 0.01);
        CessAmt := Round(CessAmt, 0.01);
    end;

    local procedure GetHSNSACCode(SalesInvLine: Record "Sales Invoice Line"): Text
    begin
        if SalesInvLine."HSN/SAC Code" <> '' then
            exit(SalesInvLine."HSN/SAC Code");

        exit('');
    end;

    local procedure GetSupplyType(SalesInvHeader: Record "Sales Invoice Header"; Customer: Record Customer): Text
    begin
        if SalesInvHeader."GST Customer Type" = SalesInvHeader."GST Customer Type"::Export then
            exit('4');

        if Customer."Country/Region Code" <> '' then
            if Customer."Country/Region Code" <> 'IN' then
                exit('4');

        exit('1');
    end;

    local procedure GetReverseCharge(SalesInvHeader: Record "Sales Invoice Header"): Text
    begin
        exit('N');
    end;

    local procedure FormatGSTDate(PostingDate: Date): Text
    begin
        exit(Format(PostingDate, 0, '<Year4><Month,2><Day,2>'));
    end;

    local procedure DateToInteger(InputDate: Date): Integer
    begin
        exit((Date2DMY(InputDate, 3) * 10000) + (Date2DMY(InputDate, 2) * 100) + Date2DMY(InputDate, 1));
    end;
}
