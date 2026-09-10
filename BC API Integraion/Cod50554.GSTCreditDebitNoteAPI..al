codeunit 50554 "GST Credit Debit Sale API"
{
    Permissions =
        tabledata "Sales Cr.Memo Header" = RIMD,
        tabledata "Sales Cr.Memo Line" = RIMD,
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
        exit(
            'http://103.100.217.51:81/gstapi/api/UploadData/Crdrnote'
        );
    end;

    procedure GetGSTApiAuthorization(): Text
    begin
        exit('Authorization /IalkRmh3z4=:::ZH4TUvIeJ3A=');
    end;

    // ============================================================
    // Generate Credit/Debit Note JSON
    // ============================================================
    procedure GetCreditDebitJSON(
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NoteType: Text): Text
    var
        CompanyInfo: Record "Company Information";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DataObj: JsonObject;
        DataArray: JsonArray;
        FinalObj: JsonObject;
        LineCount: Integer;
        JsonText: Text;
    begin
        CompanyInfo.Get();

        if (NoteType <> 'CR') and (NoteType <> 'DR') then
            Error(
                'Invalid NoteType %1. Allowed values are CR or DR.',
                NoteType);

        Clear(DataArray);
        Clear(FinalObj);

        SalesCrMemoLine.Reset();
        SalesCrMemoLine.SetRange(
            "Document No.",
            SalesCrMemoHeader."No.");

        if SalesCrMemoLine.FindSet() then begin
            repeat

                if not (
                    (SalesCrMemoLine.Type =
                        SalesCrMemoLine.Type::" ")
                    or
                    (SalesCrMemoLine."No." = '')
                    or
                    (SalesCrMemoLine.Quantity = 0)
                ) then begin

                    LineCount += 1;

                    if LineCount > 10000 then
                        Error(
                            'GST Credit/Debit Note API supports maximum 10000 item-wise records. Document %1 contains more than 10000 valid item records.',
                            SalesCrMemoHeader."No.");

                    Clear(DataObj);

                    BuildCreditDebitLineJSON(
                        SalesCrMemoHeader,
                        SalesCrMemoLine,
                        CompanyInfo,
                        NoteType,
                        DataObj);

                    DataArray.Add(DataObj);
                end;

            until SalesCrMemoLine.Next() = 0;
        end;

        if LineCount = 0 then
            Error(
                'No valid item lines found for Credit/Debit Note %1.',
                SalesCrMemoHeader."No.");

        FinalObj.Add(
            'Push_Data_List',
            DataArray);

        FinalObj.Add(
            'Year',
            Date2DMY(
                SalesCrMemoHeader."Posting Date",
                3));

        FinalObj.Add(
            'Month',
            Date2DMY(
                SalesCrMemoHeader."Posting Date",
                2));

        FinalObj.WriteTo(JsonText);

        exit(JsonText);
    end;


    // ============================================================
    // Build Individual Credit/Debit Note Line JSON
    // ============================================================
    local procedure BuildCreditDebitLineJSON(
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CompanyInfo: Record "Company Information";
        NoteType: Text;
        var DataObj: JsonObject)
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
        DifferenceValue: Decimal;
        ItemValue: Decimal;

        CurrencyFactor: Decimal;

        PartyState: Text;
        ItemType: Text;
        SupplyType: Text;
        ReverseCharge: Text;
        UQC: Text;
        HSNCode: Text;

        NoteNumber: Text;
        CreditDebitDate: Text;

        InvoiceNo: Text;
        InvoiceDate: Text;

        VoucherNo: Text;
        VoucherDate: Text;

        PartyGSTIN: Text;
        CompanyGSTIN: Text;

        PartyUnitCode: Text;
        UnitCode: Text;

        ItemName: Text;
        ItemHead: Text;

        PreGSTRegime: Text;
        EcomGSTIN: Text;

        IRN: Text;
        AckNo: Text;
        AckDate: Integer;

        SupplyTypeNIL: Integer;
        LeaseOFOldCar: Integer;

        OtherCharges: Decimal;
    begin

        // --------------------------------------------------------
        // Customer / Party
        // --------------------------------------------------------
        if not Customer.Get(
            SalesCrMemoHeader."Sell-to Customer No.")
        then
            Error(
                'Customer %1 not found for Credit/Debit Note %2.',
                SalesCrMemoHeader."Sell-to Customer No.",
                SalesCrMemoHeader."No.");

        if Customer."No." = '' then
            Error(
                'PartyCode is blank for Credit/Debit Note %1.',
                SalesCrMemoHeader."No.");

        PartyGSTIN :=
            Customer."GST Registration No.";

        CompanyGSTIN :=
            CompanyInfo."GST Registration No.";


        // --------------------------------------------------------
        // State / POS
        // --------------------------------------------------------
        PartyState := '';

        if Customer."State Code" <> '' then
            if StateRec.Get(Customer."State Code") then
                PartyState :=
                    StateRec."State Code (GST Reg. No.)";


        // --------------------------------------------------------
        // Item Type
        // --------------------------------------------------------
        if SalesCrMemoLine.Type =
            SalesCrMemoLine.Type::Item
        then
            ItemType := 'G'
        else
            ItemType := 'S';


        // --------------------------------------------------------
        // HSN / SAC
        // --------------------------------------------------------
        HSNCode :=
            GetHSNSACCode(SalesCrMemoLine);


        // --------------------------------------------------------
        // GST Amounts
        // --------------------------------------------------------
        GetGSTAmountsForLine(
            SalesCrMemoHeader."No.",
            SalesCrMemoLine."Line No.",
            SalesCrMemoLine."Line Amount",
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


        // --------------------------------------------------------
        // Currency
        // --------------------------------------------------------
        if SalesCrMemoHeader."Currency Factor" <> 0 then
            CurrencyFactor :=
                SalesCrMemoHeader."Currency Factor"
        else
            CurrencyFactor := 1;


        ItemValue :=
            Round(
                SalesCrMemoLine."Line Amount" /
                CurrencyFactor,
                0.01);

        TaxableValue :=
            Round(
                TaxableValue /
                CurrencyFactor,
                0.01);


        // --------------------------------------------------------
        // Difference Value
        // For Credit/Debit Note this represents taxable/value
        // difference of the note.
        // --------------------------------------------------------
        DifferenceValue :=
            Round(
                SalesCrMemoLine."Line Amount" /
                CurrencyFactor,
                0.01);


        // --------------------------------------------------------
        // Supply Type
        // --------------------------------------------------------
        SupplyType :=
            GetSupplyType(
                SalesCrMemoHeader,
                Customer);


        // --------------------------------------------------------
        // Reverse Charge
        // --------------------------------------------------------
        ReverseCharge :=
            GetReverseCharge(
                SalesCrMemoHeader);


        // --------------------------------------------------------
        // UQC
        // --------------------------------------------------------
        UQC := '';

        if SalesCrMemoLine."Unit of Measure Code" <> '' then begin

            UnitOfMeasure.Reset();

            UnitOfMeasure.SetRange(
                Code,
                SalesCrMemoLine."Unit of Measure Code");

            if UnitOfMeasure.FindFirst() then
                UQC :=
                    UnitOfMeasure."International Standard Code";
        end;


        // --------------------------------------------------------
        // Note Number
        // --------------------------------------------------------
        NoteNumber :=
            CopyStr(
                SalesCrMemoHeader."No.",
                1,
                50);


        CreditDebitDate :=
            FormatGSTDate(
                SalesCrMemoHeader."Posting Date");


        // --------------------------------------------------------
        // Original Invoice Information
        // --------------------------------------------------------
        InvoiceNo :=
            CopyStr(
                SalesCrMemoHeader."Applies-to Doc. No.",
                1,
                50);

        if InvoiceNo = '' then
            InvoiceNo :=
                GetOriginalInvoiceNo(
                    SalesCrMemoHeader);


        InvoiceDate := '';

        if SalesCrMemoHeader."Posting Date" <> 0D then
            InvoiceDate :=
                FormatGSTDate(
                    SalesCrMemoHeader."Posting Date");


        // --------------------------------------------------------
        // Voucher
        // --------------------------------------------------------
        VoucherNo :=
            SalesCrMemoHeader."No.";

        VoucherDate :=
            FormatGSTDate(
                SalesCrMemoHeader."Posting Date");


        // --------------------------------------------------------
        // Other fields
        // --------------------------------------------------------
        PartyUnitCode := '';
        UnitCode := '';

        ItemName :=
            SalesCrMemoLine.Description;

        ItemHead := 'Sale';

        PreGSTRegime := 'N';

        EcomGSTIN := '';

        SupplyTypeNIL := 1;

        LeaseOFOldCar := 0;

        OtherCharges := 0;


        // --------------------------------------------------------
        // E-Invoice information
        // --------------------------------------------------------
        IRN := '';
        AckNo := '';
        AckDate := 0;

        // If your Sales Cr.Memo Header extension contains
        // these fields, replace the above values with:
        //
        // IRN := SalesCrMemoHeader."IRN No.";
        // AckNo := SalesCrMemoHeader."Ack No.";
        // AckDate := DateToInteger(
        //     DT2Date(SalesCrMemoHeader."Ack Date"));


        // --------------------------------------------------------
        // JSON
        // --------------------------------------------------------
        DataObj.Add(
            'NoteType',
            NoteType);

        DataObj.Add(
            'NoteNum',
            NoteNumber);

        DataObj.Add(
            'Crdbdate',
            CreditDebitDate);

        DataObj.Add(
            'Reasoncode',
            '02');

        DataObj.Add(
            'ReverseCharge',
            ReverseCharge);

        DataObj.Add(
            'InvoiceNo',
            InvoiceNo);

        DataObj.Add(
            'InvoiceDate',
            InvoiceDate);

        DataObj.Add(
            'DifferVal',
            DifferenceValue);

        DataObj.Add(
            'IGSTRate',
            IgstRate);

        DataObj.Add(
            'IGSTValue',
            Round(
                IgstAmt / CurrencyFactor,
                0.01));

        DataObj.Add(
            'CGSTRate',
            CgstRate);

        DataObj.Add(
            'CGSTValue',
            Round(
                CgstAmt / CurrencyFactor,
                0.01));

        DataObj.Add(
            'SGSTRate',
            SgstRate);

        DataObj.Add(
            'SGSTValue',
            Round(
                SgstAmt / CurrencyFactor,
                0.01));

        DataObj.Add(
            'CESSRate',
            CessRate);

        DataObj.Add(
            'CESSValue',
            Round(
                CessAmt / CurrencyFactor,
                0.01));

        DataObj.Add(
            'EcomGSTIN',
            EcomGSTIN);

        DataObj.Add(
            'GSTIN',
            CompanyGSTIN);

        DataObj.Add(
            'VoucherNo',
            VoucherNo);

        DataObj.Add(
            'VoucherDate',
            VoucherDate);

        DataObj.Add(
            'PreGSTRegime',
            PreGSTRegime);

        DataObj.Add(
            'POS',
            PartyState);

        DataObj.Add(
            'PartyCode',
            Customer."No.");

        DataObj.Add(
            'PartyGSTIN',
            PartyGSTIN);

        DataObj.Add(
            'UnitCode',
            UnitCode);

        DataObj.Add(
            'VoucherType',
            'Sale');

        DataObj.Add(
            'MismatchFlag',
            0);

        DataObj.Add(
            'ItemName',
            ItemName);

        DataObj.Add(
            'ItemHead',
            ItemHead);

        DataObj.Add(
            'PartyUnitCode',
            PartyUnitCode);

        DataObj.Add(
            'IsModified',
            'N');

        DataObj.Add(
            'SupplyType',
            SupplyType);

        DataObj.Add(
            'HSNCode',
            HSNCode);

        DataObj.Add(
            'UQC',
            UQC);

        DataObj.Add(
            'ItemType',
            ItemType);

        DataObj.Add(
            'ItemQuantity',
            SalesCrMemoLine.Quantity);

        DataObj.Add(
            'SupplyTypeNIL',
            SupplyTypeNIL);

        DataObj.Add(
            'LeaseOFOldCar',
            LeaseOFOldCar);

        DataObj.Add(
            'OtherCharges',
            OtherCharges);

        DataObj.Add(
            'IRN',
            IRN);

        DataObj.Add(
            'AckNo',
            AckNo);

        DataObj.Add(
            'AckDate',
            AckDate);
    end;


    // ============================================================
    // Upload Credit/Debit Note
    // ============================================================
    procedure UploadCreditDebit(
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NoteType: Text): Text
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        RequestHeaders: HttpHeaders;

        JsonText: Text;
        ResultText: Text;
    begin

        JsonText :=
            GetCreditDebitJSON(
                SalesCrMemoHeader,
                NoteType);


        // --------------------------------------------------------
        // Content
        // --------------------------------------------------------
        Content.WriteFrom(JsonText);

        Content.GetHeaders(Headers);

        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');

        Headers.Add(
            'Content-Type',
            'application/json');


        // --------------------------------------------------------
        // Authorization
        // --------------------------------------------------------
        RequestHeaders :=
            Client.DefaultRequestHeaders();

        if RequestHeaders.Contains('Authorization') then
            RequestHeaders.Remove('Authorization');

        if not RequestHeaders.TryAddWithoutValidation(
            'Authorization',
            GetGSTApiAuthorization())
        then
            Error(
                'Unable to add Authorization header.');


        Client.Timeout :=
            30000;


        // --------------------------------------------------------
        // POST
        // --------------------------------------------------------
        if Client.Post(
            GetGSTApiUrl(),
            Content,
            Response)
        then begin

            Response.Content().ReadAs(
                ResultText);

            if not Response.IsSuccessStatusCode() then
                Error(
                    'GST Credit/Debit Note API Error. HTTP Status: %1 %2',
                    Response.HttpStatusCode(),
                    ResultText);

            exit(ResultText);
        end;


        Error(
            'GST Credit/Debit Note API server not reachable.');
    end;


    // ============================================================
    // GST Amount Calculation
    // ============================================================
    local procedure GetGSTAmountsForLine(
        DocNo: Code[20];
        LineNo: Integer;
        LineAmount: Decimal;
        var IgstAmt: Decimal;
        var CgstAmt: Decimal;
        var SgstAmt: Decimal;
        var CessAmt: Decimal;
        var IgstRate: Decimal;
        var CgstRate: Decimal;
        var SgstRate: Decimal;
        var CessRate: Decimal;
        var GstRate: Decimal;
        var PreTaxVal: Decimal)
    var
        DetailedGSTEntry:
            Record "Detailed GST Ledger Entry";
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

        PreTaxVal :=
            Round(
                Abs(LineAmount),
                0.01);


        DetailedGSTEntry.Reset();

        DetailedGSTEntry.SetRange(
            "Document No.",
            DocNo);

        DetailedGSTEntry.SetRange(
            "Document Line No.",
            LineNo);

        DetailedGSTEntry.SetRange(
            "Entry Type",
            DetailedGSTEntry."Entry Type"::"Initial Entry");


        if DetailedGSTEntry.FindSet() then
            repeat

                case DetailedGSTEntry."GST Component Code" of

                    'IGST':
                        begin
                            IgstAmt +=
                                Abs(
                                    DetailedGSTEntry."GST Amount");

                            if IgstRate = 0 then
                                IgstRate :=
                                    DetailedGSTEntry."GST %";
                        end;

                    'CGST':
                        begin
                            CgstAmt +=
                                Abs(
                                    DetailedGSTEntry."GST Amount");

                            if CgstRate = 0 then
                                CgstRate :=
                                    DetailedGSTEntry."GST %";
                        end;

                    'SGST', 'UTGST':
                        begin
                            SgstAmt +=
                                Abs(
                                    DetailedGSTEntry."GST Amount");

                            if SgstRate = 0 then
                                SgstRate :=
                                    DetailedGSTEntry."GST %";
                        end;

                    'CESS':
                        begin
                            CessAmt +=
                                Abs(
                                    DetailedGSTEntry."GST Amount");

                            if CessRate = 0 then
                                CessRate :=
                                    DetailedGSTEntry."GST %";
                        end;
                end;

            until DetailedGSTEntry.Next() = 0;


        if IgstRate <> 0 then
            GstRate := IgstRate
        else
            GstRate :=
                CgstRate + SgstRate;


        IgstAmt :=
            Round(
                IgstAmt,
                0.01);

        CgstAmt :=
            Round(
                CgstAmt,
                0.01);

        SgstAmt :=
            Round(
                SgstAmt,
                0.01);

        CessAmt :=
            Round(
                CessAmt,
                0.01);
    end;


    // ============================================================
    // HSN / SAC
    // ============================================================
    local procedure GetHSNSACCode(
        SalesCrMemoLine: Record "Sales Cr.Memo Line"): Text
    begin

        if SalesCrMemoLine."HSN/SAC Code" <> '' then
            exit(
                SalesCrMemoLine."HSN/SAC Code");

        exit('');
    end;


    // ============================================================
    // Supply Type
    // ============================================================
    local procedure GetSupplyType(
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer): Text
    begin

        if Customer."Country/Region Code" <> '' then
            if Customer."Country/Region Code" <> 'IN' then
                exit('EXPWP');


        // B2B when GSTIN exists
        if Customer."GST Registration No." <> '' then
            exit('B2B');


        // Otherwise B2C
        exit('B2C');
    end;


    // ============================================================
    // Reverse Charge
    // ============================================================
    local procedure GetReverseCharge(
        SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Text
    begin
        exit('N');
    end;


    // ============================================================
    // GST Date Format YYYYMMDD
    // ============================================================
    local procedure FormatGSTDate(
        PostingDate: Date): Text
    begin

        if PostingDate = 0D then
            exit('');

        exit(
            Format(
                PostingDate,
                0,
                '<Year4><Month,2><Day,2>'));
    end;


    // ============================================================
    // Date -> Integer YYYYMMDD
    // ============================================================
    local procedure DateToInteger(
        InputDate: Date): Integer
    begin

        if InputDate = 0D then
            exit(0);

        exit(
            (Date2DMY(InputDate, 3) * 10000) +
            (Date2DMY(InputDate, 2) * 100) +
            Date2DMY(InputDate, 1));
    end;


    // ============================================================
    // Get Original Invoice No.
    // ============================================================
    local procedure GetOriginalInvoiceNo(
        SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Text
    var
        SalesInvoiceHeader:
            Record "Sales Invoice Header";
    begin

        SalesInvoiceHeader.Reset();

        SalesInvoiceHeader.SetRange(
            "Sell-to Customer No.",
            SalesCrMemoHeader."Sell-to Customer No.");

        if SalesInvoiceHeader.FindLast() then
            exit(
                SalesInvoiceHeader."No.");

        exit('');
    end;
}