report 50503 "KDS Sales Invoice"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    DefaultLayout = RDLC;
    RDLCLayout = './layouts/KDSSalesInvoice.rdl';

    Permissions =
        TableData "Company Information" = rimd,
        TableData "Sales Header" = rimd,
        TableData "Sales Line" = rimd,
        TableData State = rimd,
        TableData Customer = rimd;

    dataset
    {
        dataitem("Company Information"; "Company Information")
        {
            column(Address; Address) { }
            column(Address_2; "Address 2") { }
            column(Name; Name) { }
            column(PhoneNo; '+91 ' + "Phone No.") { }
            column(Picture; Picture) { }
            column(GST_Registration_No_; "GST Registration No.") { }
            column(P_A_N__No_; "P.A.N. No.") { }
            column(E_Mail; "E-Mail") { }

            column(SWIFT_Code; "SWIFT Code") { }
            column(Bank_Account_No_; "Bank Account No.") { }
            column(Bank_Name; "Bank Name") { }
            column(Bank_Branch_No_; "Bank Branch No.") { }

            dataitem(SalesHeader; "Sales Header")
            {
                DataItemTableView =
                    where("Document Type" = const(Invoice));

                RequestFilterFields = "No.";

                PrintOnlyIfDetail = true;

                // -------------------------
                // SALES HEADER
                // -------------------------

                column(Document_Type; "Document Type") { }
                column(No; "No.") { }

                column(SelltoCustomerNo; "Sell-to Customer No.") { }

                column(BilltoCustomerNo; "Bill-to Customer No.") { }

                column(BilltoName; "Bill-to Name") { }
                column(BilltoName2; "Bill-to Name 2") { }
                column(BilltoAddress; "Bill-to Address") { }
                column(BilltoAddress2; "Bill-to Address 2") { }
                column(BilltoCity; "Bill-to City") { }
                column(Bill_to_Post_Code; "Bill-to Post Code") { }
                column(Bill_to_County; "Bill-to County") { }

                column(External_Document_No_; "External Document No.") { }

                column(PartyRefLabel; PartyRefLabel) { }
                column(PartyRefNo; PartyRefNo) { }
                column(BilltoContact; "Bill-to Contact") { }
                column(YourReference; "Your Reference") { }

                column(ShiptoCode; "Ship-to Code") { }
                column(ShiptoName; "Ship-to Name") { }
                column(ShiptoName2; "Ship-to Name 2") { }
                column(ShiptoAddress; "Ship-to Address") { }
                column(ShiptoAddress2; "Ship-to Address 2") { }
                column(ShiptoCity; "Ship-to City") { }
                column(ShiptoContact; "Ship-to Contact") { }

                column(PostingDate; "Posting Date") { }
                column(ShipmentDate; "Shipment Date") { }
                column(PostingDescription; "Posting Description") { }

                column(Sell_to_Country_Region_Code; "Sell-to Country/Region Code") { }

                column(TaxableAmount; TaxableAmount) { }
                column(IGSTAmount; IGSTAmount) { }
                column(CGSTAmount; CGSTAmount) { }
                column(SGSTAmount; SGSTAmount) { }

                column(CustomerPANNo; CustomerPANNo) { }
                column(GrandTotal; GrandTotal) { }

                column(IGSTPercent; IGSTPercent) { }
                column(CGSTPercent; CGSTPercent) { }
                column(SGSTPercent; SGSTPercent) { }

                column(IGST_Label; IGSTLabel) { }
                column(CGST_Label; CGSTLabel) { }
                column(SGST_Label; SGSTLabel) { }

                column(IsForeign; IsForeign) { }

                column(VATRegNo; VATRegNo) { }

                column(Customer_GST_Reg__No_; CustomerGSTRegNo) { }

                column(GSTBilltoStateCode; GSTBilltoStateCode) { }

                column(PlaceOfSupplyCode; StateName) { }

                column(Currency_Code; "Currency Code") { }

                // --------------------------------
                // E-INVOICE DETAILS
                // --------------------------------

                column(IRN_No_; IRNNo) { }
                column(Ack_No_; AckNo) { }
                column(Ack_Date; AckDate) { }

                // --------------------------------
                // SALES LINES
                // --------------------------------

                dataitem(SalesLine; "Sales Line")
                {
                    DataItemLinkReference = SalesHeader;

                    DataItemLink =
                        "Document Type" = field("Document Type"),
                        "Document No." = field("No.");


                    column(SalesLineNo; "Line No.") { }

                    column(SrNo; SrNo) { }

                    column(Type; Type) { }

                    column(No_; "No.") { }

                    column(Description; Description) { }

                    column(Quantity; Quantity) { }

                    column(Unit_Price; "Unit Price") { }

                    column(UnitOfMeasure; "Unit of Measure") { }

                    column(LineAmount; "Line Amount") { }

                    column(HSN_SAC_Code; "HSN/SAC Code") { }

                    column(AmountText; AmountText) { }

                    trigger OnPreDataItem()
                    begin
                        SrNo := 0;

                        CalculateInvoiceTotals(
                            SalesHeader."Document Type",
                            SalesHeader."No.");

                        //    GetEInvoiceDetails();
                    end;


                    trigger OnAfterGetRecord()
                    begin
                        if "No." <> '' then
                            SrNo += 1;

                        Clear(StateName);

                        if SalesHeader."Sell-to Country/Region Code" = 'IN' then begin
                            if StateRec.Get(
                                SalesHeader."GST Bill-to State Code")
                            then
                                StateName := StateRec.Description;
                        end else begin
                            if CountryRegion.Get(
                                SalesHeader."Sell-to Country/Region Code")
                            then
                                StateName := CountryRegion.Name
                            else
                                StateName := '';
                        end;

                        Clear(CountryName);

                        if SalesHeader."Sell-to Country/Region Code" <> 'IN' then
                            if CountryRegion.Get(
                                SalesHeader."Sell-to Country/Region Code")
                            then
                                CountryName := CountryRegion.Name;

                        Clear(PartyRefLabel);
                        Clear(PartyRefNo);

                        if SalesHeader."External Document No." <> '' then begin
                            PartyRefLabel := 'PARTY REF NO.';
                            PartyRefNo := SalesHeader."External Document No.";
                        end;

                    end;
                }

                // --------------------------------
                // BLANK LINES
                // --------------------------------

                dataitem(BlankLines; Integer)
                {
                    DataItemTableView = sorting(Number);

                    column(Number_BlankLines; Number) { }

                    trigger OnPreDataItem()
                    var
                        TotalRowsPerPage: Integer;
                        UsedRows: Integer;
                        TempSalesLine: Record "Sales Line";
                        CharsPerLine: Integer;
                        LinesRequired: Integer;
                    begin
                        TotalRowsPerPage := 18;

                        CharsPerLine := 42;

                        UsedRows := 0;

                        TempSalesLine.SetRange(
                            "Document Type",
                            SalesHeader."Document Type");

                        TempSalesLine.SetRange(
                            "Document No.",
                            SalesHeader."No.");

                        if TempSalesLine.FindSet() then
                            repeat
                                LinesRequired := 1;

                                if StrLen(TempSalesLine.Description) >
                                    CharsPerLine
                                then
                                    LinesRequired :=
                                        (StrLen(TempSalesLine.Description) +
                                        CharsPerLine - 1) div CharsPerLine;

                                UsedRows += LinesRequired;

                            until TempSalesLine.Next() = 0;

                        if UsedRows >= TotalRowsPerPage then
                            CurrReport.Break()
                        else
                            BlankLines.SetRange(
                                Number,
                                1,
                                TotalRowsPerPage - UsedRows);
                    end;
                }
            }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                }
            }
        }
    }

    var
        SrNo: Integer;

        AmountInWordsCU: Codeunit "Amount In Words";

        AmountText: Text;

        TaxableAmount: Decimal;
        IGSTAmount: Decimal;
        CGSTAmount: Decimal;
        SGSTAmount: Decimal;
        PartyRefLabel: Text;
        PartyRefNo: Text;
        CountryName: Text[100];

        GrandTotal: Decimal;

        IGSTPercent: Decimal;
        CGSTPercent: Decimal;
        SGSTPercent: Decimal;

        CountryRegion: Record "Country/Region";

        IGSTLabel: Text;
        CGSTLabel: Text;
        SGSTLabel: Text;

        IsForeign: Boolean;

        CustomerPANNo: Code[20];

        StateName: Text[50];

        StateRec: Record State;

        VATRegNo: Text[20];

        CustomerGSTRegNo: Text[30];

        GSTBilltoStateCode: Code[20];

        // -------------------------
        // E-INVOICE VARIABLES
        // -------------------------

        IRNNo: Text[100];

        AckNo: Text[50];

        AckDate: Date;

    local procedure CalculateInvoiceTotals(
        DocumentType: Enum "Sales Document Type";
        DocNo: Code[20])
    var
        SalesLineRec: Record "Sales Line";
        DetailedGSTEntry: Record "Detailed GST Ledger Entry";
        CustomerRec: Record Customer;
    begin
        Clear(TaxableAmount);
        Clear(IGSTAmount);
        Clear(CGSTAmount);
        Clear(SGSTAmount);

        Clear(IGSTPercent);
        Clear(CGSTPercent);
        Clear(SGSTPercent);

        Clear(IGSTLabel);
        Clear(CGSTLabel);
        Clear(SGSTLabel);

        Clear(VATRegNo);
        Clear(CustomerPANNo);

        Clear(CustomerGSTRegNo);
        Clear(GSTBilltoStateCode);

        Clear(GrandTotal);

        IsForeign :=
            SalesHeader."Sell-to Country/Region Code" <> 'IN';

        SalesLineRec.SetRange(
            "Document Type",
            DocumentType);

        SalesLineRec.SetRange(
            "Document No.",
            DocNo);

        if SalesLineRec.FindSet() then
            repeat
                TaxableAmount +=
                    SalesLineRec."Line Amount";
            until SalesLineRec.Next() = 0;

        // -------------------------
        // GST ENTRIES
        // -------------------------

        DetailedGSTEntry.SetRange(
            "Document No.",
            DocNo);

        DetailedGSTEntry.SetRange(
            "Entry Type",
            DetailedGSTEntry."Entry Type"::"Initial Entry");

        if DetailedGSTEntry.FindSet() then
            repeat

                case DetailedGSTEntry."GST Component Code" of

                    'IGST':
                        begin
                            IGSTAmount +=
                                Abs(
                                    DetailedGSTEntry."GST Amount");

                            IGSTPercent :=
                                DetailedGSTEntry."GST %";
                        end;

                    'CGST':
                        begin
                            CGSTAmount +=
                                Abs(
                                    DetailedGSTEntry."GST Amount");

                            CGSTPercent :=
                                DetailedGSTEntry."GST %";
                        end;

                    'SGST', 'UTGST':
                        begin
                            SGSTAmount +=
                                Abs(
                                    DetailedGSTEntry."GST Amount");

                            SGSTPercent :=
                                DetailedGSTEntry."GST %";
                        end;
                end;

            until DetailedGSTEntry.Next() = 0;

        // -------------------------
        // GST LABELS
        // -------------------------

        if IGSTPercent <> 0 then
            IGSTLabel :=
                StrSubstNo(
                    'IGST @ %1%',
                    IGSTPercent)
        else
            IGSTLabel := 'IGST';

        if CGSTPercent <> 0 then
            CGSTLabel :=
                StrSubstNo(
                    'CGST @ %1%',
                    CGSTPercent)
        else
            CGSTLabel := 'CGST';

        if SGSTPercent <> 0 then
            SGSTLabel :=
                StrSubstNo(
                    'SGST @ %1%',
                    SGSTPercent)
        else
            SGSTLabel := 'SGST';

        // -------------------------
        // GRAND TOTAL
        // -------------------------

        GrandTotal :=
            TaxableAmount +
            IGSTAmount +
            CGSTAmount +
            SGSTAmount;

        // -------------------------
        // CUSTOMER
        // -------------------------

        if CustomerRec.Get(
            SalesHeader."Sell-to Customer No.")
        then begin

            VATRegNo :=
                CustomerRec."VAT Registration No.";

            CustomerPANNo :=
                CustomerRec."P.A.N. No.";

            CustomerGSTRegNo :=
                CustomerRec."GST Registration No.";

        end else begin

            VATRegNo := '';
            CustomerPANNo := '';
            CustomerGSTRegNo := '';

        end;

        GSTBilltoStateCode :=
            SalesHeader."GST Bill-to State Code";



        AmountText :=
            AmountInWordsCU.AmountInWords(
                GrandTotal,
                SalesHeader."Currency Code");
    end;


}