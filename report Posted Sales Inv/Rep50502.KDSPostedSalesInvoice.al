report 50502 "KDS Posted Sales Invoice"
{

    UsageCategory = ReportsAndAnalysis;

    DefaultLayout = RDLC;
    RDLCLayout = './KDSPostedSalesInvoiceReport.rdl';

    Permissions =
        TableData "Company Information" = rimd,
        TableData "Sales Invoice Header" = rimd,
        TableData "Sales Invoice Line" = rimd,
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

            dataitem(SalesInvoiceHeader; "Sales Invoice Header")
            {
                RequestFilterFields = "No.";
                PrintOnlyIfDetail = true;

                column(SelltoCustomerNo; "Sell-to Customer No.") { }
                column(No; "No.") { }
                column(BilltoCustomerNo; "Bill-to Customer No.") { }
                column(CountryName; CountryName) { }
                column(BilltoName; "Bill-to Name") { }
                column(BilltoName2; "Bill-to Name 2") { }
                column(BilltoAddress; "Bill-to Address") { }
                column(BilltoAddress2; "Bill-to Address 2") { }
                column(BilltoCity; "Bill-to City") { }
                column(Bill_to_Post_Code; "Bill-to Post Code") { }
                column(Bill_to_County; "Bill-to County") { }

                column(External_Document_No_; "External Document No.") { }

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

                column(IRN_Status; "IRN Status") { }

                column(Cancel_Date; "Cancel Date") { }

                column(Customer_GST_Reg__No_; "Customer GST Reg. No.") { }

                column(GSTBilltoStateCode; "GST Bill-to State Code") { }

                column(PlaceOfSupplyCode; StateName) { }

                column(Currency_Code; "Currency Code") { }

                column(IRN_No_; "IRN No.") { }

                column(Ack_No_; "Ack No.") { }

                column(Ack_Date; "Ack Date") { }

                column(QR_Signed_Code_Image; "QR Signed Code Image") { }

                dataitem(SalesInvoiceLine; "Sales Invoice Line")
                {
                    DataItemLinkReference = SalesInvoiceHeader;
                    DataItemLink = "Document No." = field("No.");

                    column(SalesLineNo; "Line No.") { }

                    column(SrNo; SrNo) { }

                    column(Type; Type) { }

                    column(No_; "No.") { }

                    column(Description; SalesInvoiceLine.Description) { }

                    column(Quantity; Quantity) { }

                    column(Unit_Price; "Unit Price") { }

                    column(UnitOfMeasure; "Unit of Measure") { }

                    column(LineAmount; "Line Amount") { }

                    column(HSN_SAC_Code; "HSN/SAC Code") { }

                    column(AmountText; AmountText) { }

                    trigger OnPreDataItem()
                    begin
                        SrNo := 0;
                        CalculateInvoiceTotals(SalesInvoiceHeader."No.");
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Clear(StateName);

                        if SalesInvoiceLine."No." <> '' then
                            SrNo += 1;

                        if SalesInvoiceHeader."Sell-to Country/Region Code" = 'IN' then begin
                            if StateRec.Get(SalesInvoiceHeader."GST Bill-to State Code") then
                                StateName := StateRec.Description;
                        end else begin
                            if CountryRegion.Get(SalesInvoiceHeader."Sell-to Country/Region Code") then
                                StateName := CountryRegion.Name
                            else
                                StateName := '';
                        end;
                        Clear(CountryName);

                        if SalesInvoiceHeader."Sell-to Country/Region Code" <> 'IN' then
                            if CountryRegion.Get(SalesInvoiceHeader."Sell-to Country/Region Code") then
                                CountryName := CountryRegion.Name;
                    end;

                }

                dataitem(BlankLines; Integer)
                {
                    DataItemTableView = sorting(Number);

                    column(Number_BlankLines; Number) { }

                    trigger OnPreDataItem()
                    var
                        TotalRowsPerPage: Integer;
                        UsedRows: Integer;
                        TempSalesLine: Record "Sales Invoice Line";
                        CharsPerLine: Integer;
                        LinesRequired: Integer;
                    begin
                        TotalRowsPerPage := 18;
                        CharsPerLine := 42; // 6.11 cm + Segoe UI 9pt ke liye

                        UsedRows := 0;

                        TempSalesLine.SetRange("Document No.", SalesInvoiceHeader."No.");

                        if TempSalesLine.FindSet() then
                            repeat
                                // Minimum 1 row
                                LinesRequired := 1;

                                if StrLen(TempSalesLine.Description) > CharsPerLine then
                                    LinesRequired :=
                                        (StrLen(TempSalesLine.Description) + CharsPerLine - 1) div CharsPerLine;

                                UsedRows += LinesRequired;

                            until TempSalesLine.Next() = 0;

                        if UsedRows >= TotalRowsPerPage then
                            CurrReport.Break()
                        else
                            BlankLines.SetRange(Number, 1, TotalRowsPerPage - UsedRows);
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

        actions
        {
            area(Processing)
            {
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

    local procedure CalculateInvoiceTotals(DocNo: Code[20])
    var
        SalesLine: Record "Sales Invoice Line";
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
        Clear(GrandTotal);

        IsForeign := SalesInvoiceHeader."Sell-to Country/Region Code" <> 'IN';

        SalesLine.SetRange("Document No.", DocNo);

        if SalesLine.FindSet() then
            repeat
                TaxableAmount += SalesLine."Line Amount";
            until SalesLine.Next() = 0;

        DetailedGSTEntry.SetRange("Document No.", DocNo);
        DetailedGSTEntry.SetRange(
            "Entry Type",
            DetailedGSTEntry."Entry Type"::"Initial Entry");

        if DetailedGSTEntry.FindSet() then
            repeat
                case DetailedGSTEntry."GST Component Code" of

                    'IGST':
                        begin
                            IGSTAmount += Abs(DetailedGSTEntry."GST Amount");
                            IGSTPercent := DetailedGSTEntry."GST %";
                        end;

                    'CGST':
                        begin
                            CGSTAmount += Abs(DetailedGSTEntry."GST Amount");
                            CGSTPercent := DetailedGSTEntry."GST %";
                        end;

                    'SGST', 'UTGST':
                        begin
                            SGSTAmount += Abs(DetailedGSTEntry."GST Amount");
                            SGSTPercent := DetailedGSTEntry."GST %";
                        end;
                end;

            until DetailedGSTEntry.Next() = 0;

        if IGSTPercent <> 0 then
            IGSTLabel := StrSubstNo('IGST @ %1%', IGSTPercent)
        else
            IGSTLabel := 'IGST';

        if CGSTPercent <> 0 then
            CGSTLabel := StrSubstNo('CGST @ %1%', CGSTPercent)
        else
            CGSTLabel := 'CGST';

        if SGSTPercent <> 0 then
            SGSTLabel := StrSubstNo('SGST @ %1%', SGSTPercent)
        else
            SGSTLabel := 'SGST';

        GrandTotal :=
            TaxableAmount +
            IGSTAmount +
            CGSTAmount +
            SGSTAmount;

        if CustomerRec.Get(SalesInvoiceHeader."Sell-to Customer No.") then begin
            VATRegNo := CustomerRec."VAT Registration No.";
            CustomerPANNo := CustomerRec."P.A.N. No.";
        end else begin
            VATRegNo := '';
            CustomerPANNo := '';
        end;

        AmountText :=
            AmountInWordsCU.AmountInWords(
                GrandTotal,
                SalesInvoiceHeader."Currency Code");
    end;
}