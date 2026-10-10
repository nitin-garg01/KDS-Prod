// codeunit 50210 "GST Advance Tax Sales"
// {
//     SingleInstance = false;

//     var
//         AdvanceTaxURL: Label 'http://103.100.217.51:81/gstapi/api/UploadData/AdvanceTax';
//         AuthorizationValue: Label 'Authorization /IalkRmh3z4=:::ZH4TUvIeJ3A=';

//     // ============================================================
//     // UPLOAD SALES INVOICE
//     // ============================================================

//     procedure UploadSalesInvoice(
//         SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         JsonText: Text;
//     begin
//         ValidateSalesInvoice(SalesInvoiceHeader);

//         JsonText :=
//             BuildAdvanceTaxJSON(
//                 SalesInvoiceHeader);

//         SendRequest(
//             JsonText,
//             SalesInvoiceHeader."No.");
//     end;


//     // ============================================================
//     // PREVIEW JSON
//     // ============================================================

//     procedure PreviewAdvanceTaxJSON(
//         SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         JsonText: Text;
//     begin
//         ValidateSalesInvoice(SalesInvoiceHeader);

//         JsonText :=
//             BuildAdvanceTaxJSON(
//                 SalesInvoiceHeader);

//         Message('%1', JsonText);
//     end;


//     // ============================================================
//     // VALIDATION
//     // ============================================================

//     local procedure ValidateSalesInvoice(
//         SalesInvoiceHeader: Record "Sales Invoice Header")
//     begin
//         if SalesInvoiceHeader."No." = '' then
//             Error(
//                 'Sales Invoice No. cannot be blank.');

//         if SalesInvoiceHeader."Sell-to Customer No." = '' then
//             Error(
//                 'Customer No. is blank on Sales Invoice %1.',
//                 SalesInvoiceHeader."No.");

//         if SalesInvoiceHeader."Posting Date" = 0D then
//             Error(
//                 'Posting Date is blank on Sales Invoice %1.',
//                 SalesInvoiceHeader."No.");
//     end;


//     // ============================================================
//     // BUILD ADVANCE TAX JSON
//     // ============================================================

//     local procedure BuildAdvanceTaxJSON(
//         SalesInvoiceHeader: Record "Sales Invoice Header") JsonText: Text
//     var
//         SalesInvoiceLine: Record "Sales Invoice Line";
//         RootObject: JsonObject;
//         PushDataArray: JsonArray;
//         AdvanceTaxObject: JsonObject;
//         CompanyInfo: Record "Company Information";
//         Customer: Record Customer;
//         TotalCGST: Decimal;
//         TotalSGST: Decimal;
//         TotalIGST: Decimal;
//         TotalCESS: Decimal;
//         LineCount: Integer;
//     begin
//         Clear(JsonText);
//         Clear(RootObject);
//         Clear(PushDataArray);

//         CompanyInfo.Get();

//         if not Customer.Get(
//             SalesInvoiceHeader."Sell-to Customer No.")
//         then
//             Error(
//                 'Customer %1 does not exist.',
//                 SalesInvoiceHeader."Sell-to Customer No.");

//         SalesInvoiceLine.Reset();

//         SalesInvoiceLine.SetRange(
//             "Document No.",
//             SalesInvoiceHeader."No.");

//         if SalesInvoiceLine.FindSet() then
//             repeat

//                 // Ignore blank/comment lines
//                 if SalesInvoiceLine.Type <>
//                    SalesInvoiceLine.Type::" "
//                 then begin

//                     // Ignore zero quantity lines
//                     if SalesInvoiceLine.Quantity <> 0 then begin

//                         LineCount += 1;

//                         if LineCount > 10000 then
//                             Error(
//                                 'Advance Tax API allows maximum 10,000 item records.');

//                         Clear(AdvanceTaxObject);
//                         Clear(TotalCGST);
//                         Clear(TotalSGST);
//                         Clear(TotalIGST);
//                         Clear(TotalCESS);

//                         GetGSTAmounts(
//                             SalesInvoiceHeader."No.",
//                             SalesInvoiceLine."Line No.",
//                             TotalCGST,
//                             TotalSGST,
//                             TotalIGST,
//                             TotalCESS);

//                         AddAdvanceTaxLine(
//                             AdvanceTaxObject,
//                             SalesInvoiceHeader,
//                             SalesInvoiceLine,
//                             Customer,
//                             CompanyInfo,
//                             TotalCGST,
//                             TotalSGST,
//                             TotalIGST,
//                             TotalCESS);

//                         PushDataArray.Add(
//                             AdvanceTaxObject);
//                     end;
//                 end;

//             until SalesInvoiceLine.Next() = 0;

//         if PushDataArray.Count = 0 then
//             Error(
//                 'No valid invoice lines found for Sales Invoice %1.',
//                 SalesInvoiceHeader."No.");

//         // --------------------------------------------------------
//         // ROOT
//         // --------------------------------------------------------

//         RootObject.Add(
//             'Push_Data_List',
//             PushDataArray);

//         RootObject.Add(
//             'Year',
//             Date2DMY(
//                 SalesInvoiceHeader."Posting Date",
//                 3));

//         RootObject.Add(
//             'Month',
//             Date2DMY(
//                 SalesInvoiceHeader."Posting Date",
//                 2));

//         RootObject.WriteTo(
//             JsonText);

//         exit(JsonText);
//     end;


//     // ============================================================
//     // ADD ADVANCE TAX LINE
//     // ============================================================

//     local procedure AddAdvanceTaxLine(
//         var AdvanceTaxObject: JsonObject;
//         SalesInvoiceHeader: Record "Sales Invoice Header";
//         SalesInvoiceLine: Record "Sales Invoice Line";
//         Customer: Record Customer;
//         CompanyInfo: Record "Company Information";
//         CGSTAmount: Decimal;
//         SGSTAmount: Decimal;
//         IGSTAmount: Decimal;
//         CESSAmount: Decimal)
//     var
//         Item: Record Item;
//         GLAccount: Record "G/L Account";
//         Resource: Record Resource;
//         FixedAsset: Record "Fixed Asset";

//         ItemName: Text[100];
//         GoodServiceType: Code[1];

//         IGSTRate: Decimal;
//         CGSTRate: Decimal;
//         SGSTRate: Decimal;
//         CESSRate: Decimal;

//         TaxableValue: Decimal;
//         AdvanceAmount: Decimal;
//         GrossValue: Decimal;

//         LineItemCode: Text[50];
//         CompanyGSTIN: Code[20];
//     begin

//         // --------------------------------------------------------
//         // ITEM / SERVICE
//         // --------------------------------------------------------

//         Clear(ItemName);
//         Clear(GoodServiceType);

//         case SalesInvoiceLine.Type of

//             SalesInvoiceLine.Type::Item:
//                 begin
//                     if Item.Get(
//                         SalesInvoiceLine."No.")
//                     then
//                         ItemName :=
//                             Item.Description;

//                     GoodServiceType := 'G';
//                 end;

//             SalesInvoiceLine.Type::"G/L Account":
//                 begin
//                     if GLAccount.Get(
//                         SalesInvoiceLine."No.")
//                     then
//                         ItemName :=
//                             GLAccount.Name;

//                     GoodServiceType := 'S';
//                 end;

//             SalesInvoiceLine.Type::Resource:
//                 begin
//                     if Resource.Get(
//                         SalesInvoiceLine."No.")
//                     then
//                         ItemName :=
//                             Resource.Name;

//                     GoodServiceType := 'S';
//                 end;

//             SalesInvoiceLine.Type::"Fixed Asset":
//                 begin
//                     if FixedAsset.Get(
//                         SalesInvoiceLine."No.")
//                     then
//                         ItemName :=
//                             FixedAsset.Description;

//                     GoodServiceType := 'G';
//                 end;
//         end;


//         // --------------------------------------------------------
//         // TAXABLE VALUE
//         // --------------------------------------------------------

//         TaxableValue :=
//             Round(
//                 Abs(
//                     SalesInvoiceLine.Amount),
//                 0.01);


//         // --------------------------------------------------------
//         // ADVANCE AMOUNT
//         // --------------------------------------------------------

//         AdvanceAmount :=
//             TaxableValue;


//         // --------------------------------------------------------
//         // GROSS VALUE
//         // --------------------------------------------------------

//         GrossValue :=
//             Round(
//                 AdvanceAmount +
//                 Abs(CGSTAmount) +
//                 Abs(SGSTAmount) +
//                 Abs(IGSTAmount) +
//                 Abs(CESSAmount),
//                 0.01);


//         // --------------------------------------------------------
//         // GST RATES
//         // --------------------------------------------------------

//         IGSTRate :=
//             GetComponentRate(
//                 SalesInvoiceHeader."No.",
//                 SalesInvoiceLine."Line No.",
//                 'IGST');

//         CGSTRate :=
//             GetComponentRate(
//                 SalesInvoiceHeader."No.",
//                 SalesInvoiceLine."Line No.",
//                 'CGST');

//         SGSTRate :=
//             GetComponentRate(
//                 SalesInvoiceHeader."No.",
//                 SalesInvoiceLine."Line No.",
//                 'SGST');

//         if SGSTRate = 0 then
//             SGSTRate :=
//                 GetComponentRate(
//                     SalesInvoiceHeader."No.",
//                     SalesInvoiceLine."Line No.",
//                     'UTGST');

//         CESSRate :=
//             GetComponentRate(
//                 SalesInvoiceHeader."No.",
//                 SalesInvoiceLine."Line No.",
//                 'CESS');


//         // --------------------------------------------------------
//         // LINE ITEM CODE
//         // --------------------------------------------------------

//         LineItemCode :=
//             CopyStr(
//                 StrSubstNo(
//                     '%1-%2',
//                     SalesInvoiceHeader."No.",
//                     SalesInvoiceLine."Line No."),
//                 1,
//                 50);


//         // --------------------------------------------------------
//         // COMPANY GSTIN
//         // --------------------------------------------------------

//         CompanyGSTIN :=
//             SalesInvoiceHeader."Location GST Reg. No.";

//         if CompanyGSTIN = '' then
//             CompanyGSTIN :=
//                 CompanyInfo."GST Registration No.";


//         // --------------------------------------------------------
//         // PARTY
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'PartyCode',
//             Customer."No.");

//         AdvanceTaxObject.Add(
//             'PartyGSTIN',
//             Customer."GST Registration No.");


//         // --------------------------------------------------------
//         // DOCUMENT
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'DocumentNo',
//             SalesInvoiceHeader."No.");

//         AdvanceTaxObject.Add(
//             'DocumentDt',
//             FormatAPIDate(
//                 SalesInvoiceHeader."Posting Date"));


//         // --------------------------------------------------------
//         // GOODS / SERVICE
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'GoodServiceType',
//             GoodServiceType);

//         AdvanceTaxObject.Add(
//             'HSNCode',
//             SalesInvoiceLine."HSN/SAC Code");


//         // --------------------------------------------------------
//         // VALUES
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'TaxableValue',
//             TaxableValue);

//         AdvanceTaxObject.Add(
//             'AdvanceAmt',
//             AdvanceAmount);

//         AdvanceTaxObject.Add(
//             'GrossValue',
//             GrossValue);


//         // --------------------------------------------------------
//         // IGST
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'IGSTRate',
//             Round(
//                 IGSTRate,
//                 0.01));

//         AdvanceTaxObject.Add(
//             'IGSTValue',
//             Round(
//                 Abs(IGSTAmount),
//                 0.01));


//         // --------------------------------------------------------
//         // CGST
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'CGSTRate',
//             Round(
//                 CGSTRate,
//                 0.01));

//         AdvanceTaxObject.Add(
//             'CGSTValue',
//             Round(
//                 Abs(CGSTAmount),
//                 0.01));


//         // --------------------------------------------------------
//         // SGST
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'SGSTRate',
//             Round(
//                 SGSTRate,
//                 0.01));

//         AdvanceTaxObject.Add(
//             'SGSTValue',
//             Round(
//                 Abs(SGSTAmount),
//                 0.01));


//         // --------------------------------------------------------
//         // CESS
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'CessRate',
//             Round(
//                 CESSRate,
//                 0.01));

//         AdvanceTaxObject.Add(
//             'CessValue',
//             Round(
//                 Abs(CESSAmount),
//                 0.01));


//         // --------------------------------------------------------
//         // LINE ITEM CODE
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'LineItemCode',
//             LineItemCode);


//         // --------------------------------------------------------
//         // COMPANY GSTIN
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'GSTIN',
//             CompanyGSTIN);


//         // --------------------------------------------------------
//         // TAX TYPE
//         // --------------------------------------------------------
//         // 1 = Exclusive
//         // 2 = Inclusive

//         AdvanceTaxObject.Add(
//             'TaxType',
//             1);


//         // --------------------------------------------------------
//         // PLACE OF SUPPLY
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'POS',
//             GetCustomerPOS(
//                 Customer));


//         // --------------------------------------------------------
//         // UNIT CODE
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'UnitCode',
//             GetUnitCode());


//         // --------------------------------------------------------
//         // PARTY UNIT CODE
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'PartyUnitCode',
//             '');


//         // --------------------------------------------------------
//         // MODIFICATION FLAG
//         // --------------------------------------------------------

//         AdvanceTaxObject.Add(
//             'IsModified',
//             'N');
//     end;


//     // ============================================================
//     // SEND REQUEST
//     // ============================================================

//     local procedure SendRequest(
//         JsonText: Text;
//         DocumentNo: Code[20])
//     var
//         Client: HttpClient;
//         Content: HttpContent;
//         ContentHeaders: HttpHeaders;
//         RequestHeaders: HttpHeaders;
//         Response: HttpResponseMessage;
//         ResponseText: Text;
//     begin

//         Clear(Content);
//         Clear(ResponseText);

//         // --------------------------------------------------------
//         // REQUEST BODY
//         // --------------------------------------------------------

//         Content.WriteFrom(
//             JsonText);

//         Content.GetHeaders(
//             ContentHeaders);

//         ContentHeaders.Clear();

//         ContentHeaders.Add(
//             'Content-Type',
//             'application/json');


//         // --------------------------------------------------------
//         // AUTHORIZATION HEADER
//         // --------------------------------------------------------

//         RequestHeaders :=
//             Client.DefaultRequestHeaders();

//         RequestHeaders.Add(
//             'Authorization',
//             AuthorizationValue);


//         // --------------------------------------------------------
//         // TIMEOUT
//         // --------------------------------------------------------

//         Client.Timeout :=
//             30000;


//         // --------------------------------------------------------
//         // POST
//         // --------------------------------------------------------

//         if not Client.Post(
//             AdvanceTaxURL,
//             Content,
//             Response)
//         then begin
//             Error(
//                 'Unable to connect to Advance Tax API. URL: %1',
//                 AdvanceTaxURL);
//         end;


//         // --------------------------------------------------------
//         // READ RESPONSE
//         // --------------------------------------------------------

//         Response.Content().ReadAs(
//             ResponseText);


//         // --------------------------------------------------------
//         // HTTP ERROR
//         // --------------------------------------------------------

//         if not Response.IsSuccessStatusCode() then begin
//             Error(
//                 'Advance Tax API failed. HTTP Status: %1. Response: %2',
//                 Response.HttpStatusCode(),
//                 ResponseText);
//         end;


//         // --------------------------------------------------------
//         // SHOW EXACT API RESPONSE
//         // --------------------------------------------------------

//         Message(
//             'Response: %1',
//             ResponseText);
//     end;


//     // ============================================================
//     // GST AMOUNTS
//     // ============================================================

//     local procedure GetGSTAmounts(
//         DocumentNo: Code[20];
//         LineNo: Integer;
//         var CGST: Decimal;
//         var SGST: Decimal;
//         var IGST: Decimal;
//         var CESS: Decimal)
//     var
//         GSTEntry: Record "Detailed GST Ledger Entry";
//     begin

//         Clear(CGST);
//         Clear(SGST);
//         Clear(IGST);
//         Clear(CESS);

//         GSTEntry.Reset();

//         GSTEntry.SetRange(
//             "Document No.",
//             DocumentNo);

//         GSTEntry.SetRange(
//             "Document Line No.",
//             LineNo);

//         GSTEntry.SetRange(
//             "Entry Type",
//             GSTEntry."Entry Type"::"Initial Entry");

//         if GSTEntry.FindSet() then
//             repeat

//                 case GSTEntry."GST Component Code" of

//                     'CGST':
//                         CGST +=
//                             Abs(
//                                 GSTEntry."GST Amount");

//                     'SGST',
//                     'UTGST':
//                         SGST +=
//                             Abs(
//                                 GSTEntry."GST Amount");

//                     'IGST':
//                         IGST +=
//                             Abs(
//                                 GSTEntry."GST Amount");

//                     'CESS':
//                         CESS +=
//                             Abs(
//                                 GSTEntry."GST Amount");

//                 end;

//             until GSTEntry.Next() = 0;

//         CGST :=
//             Round(
//                 CGST,
//                 0.01);

//         SGST :=
//             Round(
//                 SGST,
//                 0.01);

//         IGST :=
//             Round(
//                 IGST,
//                 0.01);

//         CESS :=
//             Round(
//                 CESS,
//                 0.01);
//     end;


//     // ============================================================
//     // COMPONENT GST RATE
//     // ============================================================

//     local procedure GetComponentRate(
//         DocumentNo: Code[20];
//         LineNo: Integer;
//         ComponentCode: Code[10]): Decimal
//     var
//         GSTEntry: Record "Detailed GST Ledger Entry";
//         GSTRate: Decimal;
//     begin

//         Clear(GSTRate);

//         GSTEntry.Reset();

//         GSTEntry.SetRange(
//             "Document No.",
//             DocumentNo);

//         GSTEntry.SetRange(
//             "Document Line No.",
//             LineNo);

//         GSTEntry.SetRange(
//             "Entry Type",
//             GSTEntry."Entry Type"::"Initial Entry");

//         GSTEntry.SetRange(
//             "GST Component Code",
//             ComponentCode);

//         if GSTEntry.FindFirst() then
//             GSTRate :=
//                 GSTEntry."GST %";

//         exit(
//             Round(
//                 Abs(GSTRate),
//                 0.01));
//     end;


//     // ============================================================
//     // DATE FORMAT YYYYMMDD
//     // ============================================================

//     local procedure FormatAPIDate(
//         PostingDate: Date): Integer
//     var
//         DateText: Text;
//         ResultInteger: Integer;
//     begin

//         if PostingDate = 0D then
//             exit(0);

//         DateText :=
//             Format(
//                 PostingDate,
//                 0,
//                 '<Year4><Month,2><Day,2>');

//         Evaluate(
//             ResultInteger,
//             DateText);

//         exit(ResultInteger);
//     end;


//     // ============================================================
//     // CUSTOMER POS
//     // ============================================================

//     local procedure GetCustomerPOS(
//         Customer: Record Customer): Code[10]
//     var
//         State: Record State;
//     begin

//         if Customer."State Code" = '' then
//             exit('');

//         if State.Get(
//             Customer."State Code")
//         then
//             exit(
//                 State."State Code (GST Reg. No.)");

//         exit('');
//     end;


//     // ============================================================
//     // UNIT CODE
//     // ============================================================

//     local procedure GetUnitCode(): Code[20]
//     begin
//         // TODO:
//         // GST API Setup se Unit Code read karna hai.

//         exit('');
//     end;
// }