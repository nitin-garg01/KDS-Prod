codeunit 50559 "GST Advance Adjust. Purchase"
{
    SingleInstance = false;

    var
        AdvanceAdjustmentPurchaseURL: Label 'http://103.100.217.51:81/gstapi/api/UploadData/AdvanceAdjustmentPurchase';
        AuthorizationValue: Label 'Authorization /IalkRmh3z4=:::ZH4TUvIeJ3A=';


    // ============================================================
    // PREVIEW ADVANCE ADJUSTMENT PURCHASE JSON
    // ============================================================

    procedure PreviewAdvanceAdjustmentPurchaseJSON(
        PurchInvHeader: Record "Purch. Inv. Header")
    var
        JsonText: Text;
    begin
        JsonText :=
            GetAdvanceAdjustmentPurchaseJSON(
                PurchInvHeader);

        Message(
            '%1',
            JsonText);
    end;


    // ============================================================
    // GET ADVANCE ADJUSTMENT PURCHASE JSON
    // ============================================================

    procedure GetAdvanceAdjustmentPurchaseJSON(
        PurchInvHeader: Record "Purch. Inv. Header"): Text
    var
        RootObject: JsonObject;
        PushDataArray: JsonArray;
        JsonText: Text;
        PurchInvLine: Record "Purch. Inv. Line";
        YearValue: Integer;
        MonthValue: Integer;
        LineCount: Integer;
    begin
        Clear(LineCount);

        // --------------------------------------------------------
        // Year
        // --------------------------------------------------------

        YearValue :=
            Date2DMY(
                PurchInvHeader."Posting Date",
                3);

        // --------------------------------------------------------
        // Month
        // --------------------------------------------------------

        MonthValue :=
            Date2DMY(
                PurchInvHeader."Posting Date",
                2);

        // --------------------------------------------------------
        // Posted Purchase Invoice Lines
        // --------------------------------------------------------

        PurchInvLine.Reset();

        PurchInvLine.SetRange(
            "Document No.",
            PurchInvHeader."No.");

        if PurchInvLine.FindSet() then
            repeat

                // Ignore blank lines
                if (PurchInvLine.Type <> PurchInvLine.Type::" ") and
                   (PurchInvLine.Quantity <> 0) then begin

                    LineCount += 1;

                    // API maximum 10,000 records
                    if LineCount > 10000 then
                        Error(
                            'Advance Adjustment Purchase API allows maximum 10,000 records.');

                    AddAdvanceAdjustmentPurchaseLine(
                        PushDataArray,
                        PurchInvHeader,
                        PurchInvLine);
                end;

            until PurchInvLine.Next() = 0;


        // --------------------------------------------------------
        // Root JSON
        // --------------------------------------------------------

        RootObject.Add(
            'Push_Data_List',
            PushDataArray);

        RootObject.Add(
            'Year',
            YearValue);

        RootObject.Add(
            'Month',
            MonthValue);

        RootObject.WriteTo(
            JsonText);

        exit(JsonText);
    end;


    // ============================================================
    // ADD ADVANCE ADJUSTMENT PURCHASE LINE
    // ============================================================

    local procedure AddAdvanceAdjustmentPurchaseLine(
        var PushDataArray: JsonArray;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line")
    var
        LineObject: JsonObject;
        AdjustAmount: Decimal;
        IGSTValue: Decimal;
        CGSTValue: Decimal;
        SGSTValue: Decimal;
        CessValue: Decimal;
        GSTIN: Text;
        PartyGSTIN: Text;
        PartyCode: Text;
        PartyUnitCode: Text;
    begin

        // --------------------------------------------------------
        // Get GST Values
        // --------------------------------------------------------

        GetGSTComponentValues(
            PurchInvHeader."No.",
            PurchInvLine."Line No.",
            IGSTValue,
            CGSTValue,
            SGSTValue,
            CessValue);


        // --------------------------------------------------------
        // Adjustment Amount
        // --------------------------------------------------------

        AdjustAmount :=
            Abs(
                PurchInvLine.Amount);


        // --------------------------------------------------------
        // Company GSTIN
        // --------------------------------------------------------

        GSTIN :=
            GetCompanyGSTIN();


        // --------------------------------------------------------
        // Vendor Details
        // --------------------------------------------------------

        PartyCode :=
            GetVendorNo(
                PurchInvHeader);


        PartyGSTIN :=
            GetVendorGSTIN(
                PurchInvHeader);


        // --------------------------------------------------------
        // Party Unit Code
        // --------------------------------------------------------
        // API requires this field but BC field mapping is not
        // specified in the API document.
        // Keeping it blank until the actual Vendor Unit Code
        // field is confirmed.
        // --------------------------------------------------------

        PartyUnitCode := '';


        // --------------------------------------------------------
        // InvoiceNo
        // --------------------------------------------------------

        LineObject.Add(
            'InvoiceNo',
            PurchInvHeader."No.");


        // --------------------------------------------------------
        // GSTIN
        // --------------------------------------------------------

        LineObject.Add(
            'GSTIN',
            GSTIN);


        // --------------------------------------------------------
        // DocumentNo
        // --------------------------------------------------------

        LineObject.Add(
            'DocumentNo',
            PurchInvHeader."No.");


        // --------------------------------------------------------
        // Adjustment Amount
        // --------------------------------------------------------

        LineObject.Add(
            'AdjustAmount',
            Round(
                AdjustAmount,
                0.01));


        // --------------------------------------------------------
        // IGST
        // --------------------------------------------------------

        LineObject.Add(
            'IGSTValue',
            Round(
                IGSTValue,
                0.01));


        // --------------------------------------------------------
        // CGST
        // --------------------------------------------------------

        LineObject.Add(
            'CGSTValue',
            Round(
                CGSTValue,
                0.01));


        // --------------------------------------------------------
        // SGST
        // --------------------------------------------------------

        LineObject.Add(
            'SGSTValue',
            Round(
                SGSTValue,
                0.01));


        // --------------------------------------------------------
        // Cess
        // --------------------------------------------------------

        LineObject.Add(
            'CessValue',
            Round(
                CessValue,
                0.01));


        // --------------------------------------------------------
        // Party Code
        // --------------------------------------------------------

        LineObject.Add(
            'PartyCode',
            PartyCode);


        // --------------------------------------------------------
        // Party GSTIN
        // --------------------------------------------------------

        LineObject.Add(
            'PartyGSTIN',
            PartyGSTIN);


        // --------------------------------------------------------
        // Party Unit Code
        // --------------------------------------------------------

        LineObject.Add(
            'PartyUnitCode',
            PartyUnitCode);


        // --------------------------------------------------------
        // IsModified
        // --------------------------------------------------------
        // N = New record
        // Y = Modify existing record
        // --------------------------------------------------------

        LineObject.Add(
            'IsModified',
            'N');


        // --------------------------------------------------------
        // Add Line
        // --------------------------------------------------------

        PushDataArray.Add(
            LineObject);
    end;


    // ============================================================
    // GET GST COMPONENT VALUES
    // ============================================================

    local procedure GetGSTComponentValues(
        DocumentNo: Code[20];
        DocumentLineNo: Integer;
        var IGSTValue: Decimal;
        var CGSTValue: Decimal;
        var SGSTValue: Decimal;
        var CessValue: Decimal)
    var
        DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
        ComponentCode: Text;
        GSTAmount: Decimal;
    begin

        Clear(IGSTValue);
        Clear(CGSTValue);
        Clear(SGSTValue);
        Clear(CessValue);


        // --------------------------------------------------------
        // Filter GST Ledger
        // --------------------------------------------------------

        DetailedGSTLedgerEntry.Reset();

        DetailedGSTLedgerEntry.SetRange(
            "Document No.",
            DocumentNo);

        DetailedGSTLedgerEntry.SetRange(
            "Document Line No.",
            DocumentLineNo);


        // --------------------------------------------------------
        // Read GST Ledger Entries
        // --------------------------------------------------------

        if DetailedGSTLedgerEntry.FindSet() then
            repeat

                GSTAmount :=
                    Abs(
                        DetailedGSTLedgerEntry."GST Amount");


                ComponentCode :=
                    UpperCase(
                        Format(
                            DetailedGSTLedgerEntry."GST Component Code"));


                // ------------------------------------------------
                // IGST
                // ------------------------------------------------

                if ComponentCode = 'IGST' then
                    IGSTValue += GSTAmount;


                // ------------------------------------------------
                // CGST
                // ------------------------------------------------

                if ComponentCode = 'CGST' then
                    CGSTValue += GSTAmount;


                // ------------------------------------------------
                // SGST
                // ------------------------------------------------

                if ComponentCode = 'SGST' then
                    SGSTValue += GSTAmount;


                // ------------------------------------------------
                // CESS
                // ------------------------------------------------

                if ComponentCode = 'CESS' then
                    CessValue += GSTAmount;

            until DetailedGSTLedgerEntry.Next() = 0;
    end;


    // ============================================================
    // UPLOAD ADVANCE ADJUSTMENT PURCHASE DATA
    // ============================================================

    procedure UploadPurchaseInvoice(
        PurchInvHeader: Record "Purch. Inv. Header")
    var
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        JsonText: Text;
        ResponseText: Text;
    begin

        // --------------------------------------------------------
        // Generate JSON
        // --------------------------------------------------------

        JsonText :=
            GetAdvanceAdjustmentPurchaseJSON(
                PurchInvHeader);


        // --------------------------------------------------------
        // HTTP Content
        // --------------------------------------------------------

        Content.WriteFrom(
            JsonText);


        // --------------------------------------------------------
        // Get Content Headers
        // --------------------------------------------------------

        Content.GetHeaders(
            ContentHeaders);


        // --------------------------------------------------------
        // Content-Type
        // --------------------------------------------------------

        if ContentHeaders.Contains(
            'Content-Type') then
            ContentHeaders.Remove(
                'Content-Type');


        ContentHeaders.Add(
            'Content-Type',
            'application/json');


        // --------------------------------------------------------
        // Authorization Header
        // --------------------------------------------------------

        RequestHeaders :=
            Client.DefaultRequestHeaders();


        if RequestHeaders.Contains(
            'Authorization') then
            RequestHeaders.Remove(
                'Authorization');


        RequestHeaders.Add(
            'Authorization',
            AuthorizationValue);


        // --------------------------------------------------------
        // Timeout
        // --------------------------------------------------------

        Client.Timeout :=
            30000;


        // --------------------------------------------------------
        // POST
        // --------------------------------------------------------

        if not Client.Post(
            AdvanceAdjustmentPurchaseURL,
            Content,
            Response) then
            Error(
                'Advance Adjustment Purchase API connection failed.');


        // --------------------------------------------------------
        // Read Response
        // --------------------------------------------------------

        Response.Content().ReadAs(
            ResponseText);


        // --------------------------------------------------------
        // HTTP Status
        // --------------------------------------------------------

        if not Response.IsSuccessStatusCode() then
            Error(
                'Advance Adjustment Purchase API failed. HTTP Status: %1. Response: %2',
                Response.HttpStatusCode(),
                ResponseText);


        // --------------------------------------------------------
        // API Response
        // --------------------------------------------------------

        Message(
            'Advance Adjustment Purchase API Response:\%1',
            ResponseText);
    end;


    // ============================================================
    // GET COMPANY GSTIN
    // ============================================================

    local procedure GetCompanyGSTIN(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();

        exit(
            CompanyInformation."GST Registration No.");
    end;


    // ============================================================
    // GET VENDOR NO.
    // ============================================================

    local procedure GetVendorNo(
        PurchInvHeader: Record "Purch. Inv. Header"): Text
    begin
        exit(
            PurchInvHeader."Buy-from Vendor No.");
    end;


    // ============================================================
    // GET VENDOR GSTIN
    // ============================================================

    local procedure GetVendorGSTIN(
        PurchInvHeader: Record "Purch. Inv. Header"): Text
    var
        Vendor: Record Vendor;
    begin

        if Vendor.Get(
            PurchInvHeader."Buy-from Vendor No.") then
            exit(
                Vendor."GST Registration No.");

        exit('');
    end;
}