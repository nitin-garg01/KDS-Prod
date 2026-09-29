report 50501 "Posted Sales Cr Memo Report"
{
    //  ApplicationArea = All;
    //   Caption = 'KDS Posted Sales Credit Memo Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './layouts/KDSPostedSalesCreditMemoReport.rdl';

    Permissions =
        TableData "Company Information" = rimd,
        TableData "Sales Cr.Memo Header" = rimd,
        TableData "Sales Cr.Memo Line" = rimd,
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
            column(Signature; "Signature") { }
            column(E_Mail; "E-Mail") { }

            column(PrintSignature; PrintSignature) { }
            column(SWIFT_Code; "SWIFT Code") { }
            column(Bank_Account_No_; "Bank Account No.") { }
            column(Bank_Name; "Bank Name") { }
            column(Bank_Branch_No_; "Bank Branch No.") { }

            dataitem(SalesCreditmemo; "Sales Cr.Memo Header")
            {
                RequestFilterFields = "No.";
                PrintOnlyIfDetail = true;

                column(SelltoCustomerNo; "Sell-to Customer No.") { }
                column(No; "No.") { }
                column(BilltoCustomerNo; "Bill-to Customer No.") { }

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

                //column(OrderDate; "Order Date") { }
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

                column(IRN_Status; "IRN Status")
                {

                }
                column(Cancel_Date; "Cancel Date")
                {

                }
                column(Customer_GST_Reg__No_; "Customer GST Reg. No.") { }
                column(GSTBilltoStateCode; "GST Bill-to State Code") { }
                column(PlaceOfSupplyCode; StateName) { }

                column(Currency_Code; "Currency Code") { }

                column(IRN_No_; "IRN No.") { }
                column(Ack_No_; "Ack No.") { }
                column(Ack_Date; "Ack Date") { }

                column(QR_Signed_Code_Image; "QR Signed Code Image") { }

                dataitem(SalesCreditLine; "Sales Cr.Memo Line")
                {
                    DataItemLinkReference = SalesCreditmemo;
                    DataItemLink = "Document No." = field("No.");

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
                        CalculateInvoiceTotals(SalesCreditmemo."No.");
                    end;

                    trigger OnAfterGetRecord()
                    begin
                        Clear(StateName);

                        if SalesCreditLine."No." <> '' then
                            SrNo += 1;

                        if SalesCreditmemo."Sell-to Country/Region Code" = 'IN' then begin
                            if StateRec.Get(SalesCreditmemo."GST Bill-to State Code") then
                                StateName := StateRec.Description;
                        end else begin
                            if CountryRegion.Get(SalesCreditmemo."Sell-to Country/Region Code") then
                                StateName := CountryRegion.Name
                            else
                                StateName := '';
                        end;
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
                        TempSalesLine: Record "Sales Cr.Memo Line";
                        CharsPerLine: Integer;
                        LinesRequired: Integer;
                    begin
                        TotalRowsPerPage := 18;
                        CharsPerLine := 42;

                        UsedRows := 0;

                        TempSalesLine.SetRange("Document No.", SalesCreditmemo."No.");

                        if TempSalesLine.FindSet() then
                            repeat
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
                group(SignatureGroup)
                {
                    Caption = 'Signature';
                    field(PrintSignature; PrintSignature)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Select to print signature on report.';


                    }
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

        GrandTotal: Decimal;

        PrintSignature: Boolean;
        IGSTPercent: Decimal;
        CGSTPercent: Decimal;
        SGSTPercent: Decimal;

        IGSTLabel: Text;
        CGSTLabel: Text;
        SGSTLabel: Text;

        IsForeign: Boolean;

        CustomerPANNo: Code[20];

        StateName: Text[50];
        StateRec: Record State;

        VATRegNo: Text[20];
        CountryRegion: Record "Country/Region";

    local procedure CalculateInvoiceTotals(DocNo: Code[20])
    var
        SalesLine: Record "Sales Cr.Memo Line";
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

        // Foreign Customer Check
        IsForeign := SalesCreditmemo."Sell-to Country/Region Code" <> 'IN';

        // Taxable Amount
        SalesLine.SetRange("Document No.", DocNo);

        if SalesLine.FindSet() then
            repeat
                TaxableAmount += SalesLine."Line Amount";
            until SalesLine.Next() = 0;

        // GST Calculation
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

        // Dynamic Labels
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

        // Grand Total
        GrandTotal :=
            TaxableAmount +
            IGSTAmount +
            CGSTAmount +
            SGSTAmount;

        // Customer Details
        if CustomerRec.Get(SalesCreditmemo."Sell-to Customer No.") then begin
            VATRegNo := CustomerRec."VAT Registration No.";
            CustomerPANNo := CustomerRec."P.A.N. No.";
        end else begin
            VATRegNo := '';
            CustomerPANNo := '';
        end;

        // Amount in Words
        AmountText :=
            AmountInWordsCU.AmountInWords(
                GrandTotal,
                SalesCreditmemo."Currency Code");
    end;

    trigger OnInitReport()
    begin
        PrintSignature := true;
    end;
}