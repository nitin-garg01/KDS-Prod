codeunit 50910 "GST HSN Summary Sale API"
{
    SingleInstance = false;

    var
        HSNURL: Label 'http://103.100.217.51:81/gstapi/api/UploadData/HSNSummarySale';
        AuthorizationValue: Label 'Authorization /IalkRmh3z4=:::ZH4TUvIeJ3A=';
        MaxItems: Integer;

    // ============================================================
    // PUBLIC PROCEDURE - PREVIEW JSON
    // ============================================================

    procedure PreviewHSNSummaryJSON(
        SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        JsonText: Text;
    begin
        JsonText := GetHSNSummaryJSON(SalesInvoiceHeader);

        Message(
            'HSN Summary Sale JSON:\%1',
            JsonText);
    end;


    // ============================================================
    // PUBLIC PROCEDURE - GET JSON
    // ============================================================

    procedure GetHSNSummaryJSON(
        SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        RootObject: JsonObject;
        PushDataList: JsonArray;
        CompanyInformation: Record "Company Information";
        JsonText: Text;
        YearValue: Integer;
        MonthValue: Integer;
    begin
        MaxItems := 0;

        CompanyInformation.Get();

        YearValue :=
            Date2DMY(
                SalesInvoiceHeader."Posting Date",
                3);

        MonthValue :=
            Date2DMY(
                SalesInvoiceHeader."Posting Date",
                2);

        BuildHSNSummary(
            SalesInvoiceHeader,
            PushDataList);

        RootObject.Add(
            'Push_Data_List',
            PushDataList);

        RootObject.Add(
            'Year',
            YearValue);

        RootObject.Add(
            'Month',
            MonthValue);

        RootObject.WriteTo(JsonText);

        exit(JsonText);
    end;


    // ============================================================
    // PUBLIC PROCEDURE - UPLOAD DATA
    // ============================================================

    procedure UploadSalesInvoice(
        SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        JsonText: Text;
        ResponseText: Text;
    begin
        JsonText :=
            GetHSNSummaryJSON(
                SalesInvoiceHeader);

        Content.WriteFrom(JsonText);

        Content.GetHeaders(ContentHeaders);

        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');

        ContentHeaders.Add(
            'Content-Type',
            'application/json');

        RequestHeaders :=
            Client.DefaultRequestHeaders();

        if RequestHeaders.Contains('Authorization') then
            RequestHeaders.Remove('Authorization');

        RequestHeaders.Add(
            'Authorization',
            AuthorizationValue);

        Client.Timeout := 30000;

        if not Client.Post(
            HSNURL,
            Content,
            Response)
        then begin
            Error(
                'Unable to connect to HSN Summary Sale API.');
        end;

        Response.Content().ReadAs(
            ResponseText);

        if not Response.IsSuccessStatusCode() then begin
            Error(
                'HSN Summary Sale API failed.\HTTP Status: %1\Response: %2',
                Response.HttpStatusCode(),
                ResponseText);
        end;

        Message(
            'HSN Summary Sale API Response:\%1',
            ResponseText);
    end;


    // ============================================================
    // BUILD HSN SUMMARY
    // ============================================================

    local procedure BuildHSNSummary(
        SalesInvoiceHeader: Record "Sales Invoice Header";
        var PushDataList: JsonArray)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SummaryObject: JsonObject;
        LineHSNCode: Code[20];
        LineUQC: Code[20];
        LineGSTIN: Code[20];
        LineDescription: Text;
        IGSTValue: Decimal;
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        CessValue: Decimal;
        TotalTax: Decimal;
        TotalQuantity: Decimal;
        TotalValue: Decimal;
        TotalTaxableValue: Decimal;
        ExistingIndex: Integer;
    begin
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange(
            "Document No.",
            SalesInvoiceHeader."No.");

        if SalesInvoiceLine.FindSet() then
            repeat

                // ------------------------------------------------
                // Ignore non-item/comment lines
                // ------------------------------------------------

                if not IsIgnorableLine(SalesInvoiceLine) then begin

                    if SalesInvoiceLine.Quantity <> 0 then begin

                        // ----------------------------------------
                        // HSN Code
                        // ----------------------------------------

                        LineHSNCode :=
                            SalesInvoiceLine."HSN/SAC Code";

                        // ----------------------------------------
                        // UQC
                        // ----------------------------------------

                        LineUQC :=
                            GetUQC(
                                SalesInvoiceLine."Unit of Measure Code");

                        // ----------------------------------------
                        // Seller GSTIN
                        // ----------------------------------------

                        LineGSTIN :=
                            GetGSTIN(
                                SalesInvoiceHeader);

                        // ----------------------------------------
                        // Description
                        // ----------------------------------------

                        LineDescription :=
                            SalesInvoiceLine.Description;

                        // ----------------------------------------
                        // GST Amounts
                        // ----------------------------------------

                        GetGSTAmounts(
                            SalesInvoiceHeader."No.",
                            SalesInvoiceLine."Line No.",
                            IGSTValue,
                            CGSTValue,
                            SGSTValue,
                            CessValue);

                        TotalTax :=
                            IGSTValue +
                            CGSTValue +
                            SGSTValue +
                            CessValue;

                        // ----------------------------------------
                        // Quantity
                        // ----------------------------------------

                        TotalQuantity :=
                            Abs(
                                SalesInvoiceLine.Quantity);

                        // ----------------------------------------
                        // Taxable Value
                        // ----------------------------------------

                        TotalTaxableValue :=
                            Abs(
                                SalesInvoiceLine.Amount);

                        // ----------------------------------------
                        // Total Value
                        // ----------------------------------------

                        TotalValue :=
                            TotalTaxableValue +
                            TotalTax;

                        // ----------------------------------------
                        // Find existing summary record
                        // ----------------------------------------

                        ExistingIndex :=
                            FindSummaryRecord(
                                PushDataList,
                                LineHSNCode,
                                LineUQC,
                                LineGSTIN);

                        if ExistingIndex = -1 then begin

                            if PushDataList.Count() >= 10000 then
                                Error(
                                    'HSN Summary Sale API supports maximum 10,000 items.');

                            //SummaryObject := JsonObject;

                            SummaryObject.Add(
                                'HSNCode',
                                LineHSNCode);

                            SummaryObject.Add(
                                'GSTIN',
                                LineGSTIN);

                            SummaryObject.Add(
                                'UQC',
                                LineUQC);

                            SummaryObject.Add(
                                'Description',
                                LineDescription);

                            SummaryObject.Add(
                                'IGSTValue',
                                IGSTValue);

                            SummaryObject.Add(
                                'CGSTValue',
                                CGSTValue);

                            SummaryObject.Add(
                                'SGSTValue',
                                SGSTValue);

                            SummaryObject.Add(
                                'CessValue',
                                CessValue);

                            SummaryObject.Add(
                                'TotalQuantity',
                                TotalQuantity);

                            SummaryObject.Add(
                                'TotalValue',
                                TotalValue);

                            SummaryObject.Add(
                                'TotalTaxableValue',
                                TotalTaxableValue);

                            SummaryObject.Add(
                                'IsModified',
                                'N');

                            PushDataList.Add(
                                SummaryObject);

                        end else begin

                            UpdateSummaryRecord(
                                PushDataList,
                                ExistingIndex,
                                LineDescription,
                                IGSTValue,
                                CGSTValue,
                                SGSTValue,
                                CessValue,
                                TotalQuantity,
                                TotalValue,
                                TotalTaxableValue);

                        end;
                    end;
                end;

            until SalesInvoiceLine.Next() = 0;
    end;


    // ============================================================
    // FIND EXISTING SUMMARY RECORD
    // ============================================================

    local procedure FindSummaryRecord(
        var PushDataList: JsonArray;
        HSNCode: Code[20];
        UQC: Code[20];
        GSTIN: Code[20]): Integer
    var
        Index: Integer;
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ExistingHSNCode: Text;
        ExistingUQC: Text;
        ExistingGSTIN: Text;
    begin
        for Index := 0 to PushDataList.Count() - 1 do begin

            PushDataList.Get(
                Index,
                JsonToken);

            JsonObject :=
                JsonToken.AsObject();

            ExistingHSNCode := '';
            ExistingUQC := '';
            ExistingGSTIN := '';

            if JsonObject.Get(
                'HSNCode',
                JsonToken)
            then
                ExistingHSNCode :=
                    JsonToken.AsValue().AsText();

            if JsonObject.Get(
                'UQC',
                JsonToken)
            then
                ExistingUQC :=
                    JsonToken.AsValue().AsText();

            if JsonObject.Get(
                'GSTIN',
                JsonToken)
            then
                ExistingGSTIN :=
                    JsonToken.AsValue().AsText();

            if
                (UpperCase(ExistingHSNCode) =
                    UpperCase(HSNCode)) and
                (UpperCase(ExistingUQC) =
                    UpperCase(UQC)) and
                (UpperCase(ExistingGSTIN) =
                    UpperCase(GSTIN))
            then
                exit(Index);
        end;

        exit(-1);
    end;


    // ============================================================
    // UPDATE EXISTING SUMMARY RECORD
    // ============================================================

    local procedure UpdateSummaryRecord(
        var PushDataList: JsonArray;
        Index: Integer;
        LineDescription: Text;
        IGSTValue: Decimal;
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        CessValue: Decimal;
        TotalQuantity: Decimal;
        TotalValue: Decimal;
        TotalTaxableValue: Decimal)
    var
        JsonToken: JsonToken;
        JsonObject: JsonObject;
        ExistingValue: Decimal;
        ExistingDescription: Text;
    begin
        PushDataList.Get(
            Index,
            JsonToken);

        JsonObject :=
            JsonToken.AsObject();

        // --------------------------------------------------------
        // Description
        // --------------------------------------------------------

        ExistingDescription := '';

        if JsonObject.Get(
            'Description',
            JsonToken)
        then
            ExistingDescription :=
                JsonToken.AsValue().AsText();

        if ExistingDescription = '' then
            JsonObject.Add(
                'Description',
                LineDescription);

        // --------------------------------------------------------
        // IGST
        // --------------------------------------------------------

        ExistingValue := 0;

        if JsonObject.Get(
            'IGSTValue',
            JsonToken)
        then
            ExistingValue :=
                JsonToken.AsValue().AsDecimal();

        JsonObject.Remove('IGSTValue');

        JsonObject.Add(
            'IGSTValue',
            ExistingValue + IGSTValue);

        // --------------------------------------------------------
        // CGST
        // --------------------------------------------------------

        ExistingValue := 0;

        if JsonObject.Get(
            'CGSTValue',
            JsonToken)
        then
            ExistingValue :=
                JsonToken.AsValue().AsDecimal();

        JsonObject.Remove('CGSTValue');

        JsonObject.Add(
            'CGSTValue',
            ExistingValue + CGSTValue);

        // --------------------------------------------------------
        // SGST
        // --------------------------------------------------------

        ExistingValue := 0;

        if JsonObject.Get(
            'SGSTValue',
            JsonToken)
        then
            ExistingValue :=
                JsonToken.AsValue().AsDecimal();

        JsonObject.Remove('SGSTValue');

        JsonObject.Add(
            'SGSTValue',
            ExistingValue + SGSTValue);

        // --------------------------------------------------------
        // Cess
        // --------------------------------------------------------

        ExistingValue := 0;

        if JsonObject.Get(
            'CessValue',
            JsonToken)
        then
            ExistingValue :=
                JsonToken.AsValue().AsDecimal();

        JsonObject.Remove('CessValue');

        JsonObject.Add(
            'CessValue',
            ExistingValue + CessValue);

        // --------------------------------------------------------
        // Total Quantity
        // --------------------------------------------------------

        ExistingValue := 0;

        if JsonObject.Get(
            'TotalQuantity',
            JsonToken)
        then
            ExistingValue :=
                JsonToken.AsValue().AsDecimal();

        JsonObject.Remove('TotalQuantity');

        JsonObject.Add(
            'TotalQuantity',
            ExistingValue + TotalQuantity);

        // --------------------------------------------------------
        // Total Value
        // --------------------------------------------------------

        ExistingValue := 0;

        if JsonObject.Get(
            'TotalValue',
            JsonToken)
        then
            ExistingValue :=
                JsonToken.AsValue().AsDecimal();

        JsonObject.Remove('TotalValue');

        JsonObject.Add(
            'TotalValue',
            ExistingValue + TotalValue);

        // --------------------------------------------------------
        // Total Taxable Value
        // --------------------------------------------------------

        ExistingValue := 0;

        if JsonObject.Get(
            'TotalTaxableValue',
            JsonToken)
        then
            ExistingValue :=
                JsonToken.AsValue().AsDecimal();

        JsonObject.Remove('TotalTaxableValue');

        JsonObject.Add(
            'TotalTaxableValue',
            ExistingValue + TotalTaxableValue);
    end;


    // ============================================================
    // GET UQC
    // ============================================================

    local procedure GetUQC(
        UnitOfMeasureCode: Code[10]): Code[20]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasureCode = '' then
            exit('');

        if UnitOfMeasure.Get(
            UnitOfMeasureCode)
        then
            exit(
                UnitOfMeasure."International Standard Code");

        exit('');
    end;


    // ============================================================
    // GET GSTIN
    // ============================================================

    local procedure GetGSTIN(
        SalesInvoiceHeader: Record "Sales Invoice Header"): Code[20]
    var
        Location: Record Location;
        CompanyInformation: Record "Company Information";
    begin
        if SalesInvoiceHeader."Location Code" <> '' then begin

            if Location.Get(
                SalesInvoiceHeader."Location Code")
            then begin

                if Location."GST Registration No." <> '' then
                    exit(
                        Location."GST Registration No.");
            end;
        end;

        CompanyInformation.Get();

        exit(
            CompanyInformation."GST Registration No.");
    end;


    // ============================================================
    // GET GST AMOUNTS FROM DETAILED GST LEDGER ENTRY
    // ============================================================

    local procedure GetGSTAmounts(
        DocumentNo: Code[20];
        DocumentLineNo: Integer;
        var IGSTValue: Decimal;
        var CGSTValue: Decimal;
        var SGSTValue: Decimal;
        var CessValue: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        GSTAmount: Decimal;
        ComponentCode: Text;
    begin
        IGSTValue := 0;
        CGSTValue := 0;
        SGSTValue := 0;
        CessValue := 0;

        DetailedGSTLedgerEntry.Reset();

        DetailedGSTLedgerEntry.SetRange(
            "Document No.",
            DocumentNo);

        DetailedGSTLedgerEntry.SetRange(
            "Document Line No.",
            DocumentLineNo);

        if DetailedGSTLedgerEntry.FindSet() then
            repeat

                GSTAmount :=
                    Abs(
                        DetailedGSTLedgerEntry."GST Amount");

                ComponentCode :=
                    UpperCase(
                        Format(
                            DetailedGSTLedgerEntry."GST Component Code"));

                if ComponentCode = 'IGST' then
                    IGSTValue :=
                        IGSTValue +
                        GSTAmount;

                if ComponentCode = 'CGST' then
                    CGSTValue :=
                        CGSTValue +
                        GSTAmount;

                if ComponentCode = 'SGST' then
                    SGSTValue :=
                        SGSTValue +
                        GSTAmount;

                if ComponentCode = 'CESS' then
                    CessValue :=
                        CessValue +
                        GSTAmount;

            until DetailedGSTLedgerEntry.Next() = 0;
    end;


    // ============================================================
    // IGNORE NON-ITEM / COMMENT LINES
    // ============================================================

    local procedure IsIgnorableLine(
        SalesInvoiceLine: Record "Sales Invoice Line"): Boolean
    begin
        if SalesInvoiceLine.Type =
            SalesInvoiceLine.Type::" "
        then
            exit(true);

        exit(false);
    end;
}