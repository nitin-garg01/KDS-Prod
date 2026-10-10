// codeunit 50209 "GST Advance Tax Purchase"
// {
//     SingleInstance = false;

//     var
//         AdvanceTaxPurchaseURL: Label 'http://103.100.217.51:81/gstapi/api/UploadData/AdvanceTaxPurchase';
//         AuthorizationValue: Label 'Authorization /IalkRmh3z4=:::ZH4TUvIeJ3A=';


//     // ============================================================
//     // UPLOAD PURCHASE INVOICE
//     // ============================================================

//     procedure UploadPurchaseInvoice(
//         PurchInvoiceHeader: Record "Purch. Inv. Header")
//     var
//         JsonText: Text;
//     begin
//         ValidatePurchaseInvoice(
//             PurchInvoiceHeader);

//         JsonText :=
//             BuildAdvanceTaxPurchaseJSON(
//                 PurchInvoiceHeader);

//         SendRequest(
//             JsonText,
//             PurchInvoiceHeader."No.");
//     end;


//     // ============================================================
//     // PREVIEW JSON
//     // ============================================================

//     procedure PreviewAdvanceTaxPurchaseJSON(
//         PurchInvoiceHeader: Record "Purch. Inv. Header")
//     var
//         JsonText: Text;
//     begin
//         ValidatePurchaseInvoice(
//             PurchInvoiceHeader);

//         JsonText :=
//             BuildAdvanceTaxPurchaseJSON(
//                 PurchInvoiceHeader);

//         Message(
//             '%1',
//             JsonText);
//     end;


//     // ============================================================
//     // VALIDATION
//     // ============================================================

//     local procedure ValidatePurchaseInvoice(
//         PurchInvoiceHeader: Record "Purch. Inv. Header")
//     begin

//         if PurchInvoiceHeader."No." = '' then
//             Error(
//                 'Purchase Invoice No. cannot be blank.');

//         if PurchInvoiceHeader."Buy-from Vendor No." = '' then
//             Error(
//                 'Vendor No. is blank on Purchase Invoice %1.',
//                 PurchInvoiceHeader."No.");

//         if PurchInvoiceHeader."Posting Date" = 0D then
//             Error(
//                 'Posting Date is blank on Purchase Invoice %1.',
//                 PurchInvoiceHeader."No.");
//     end;


//     // ============================================================
//     // BUILD ADVANCE TAX PURCHASE JSON
//     // ============================================================

//     local procedure BuildAdvanceTaxPurchaseJSON(
//         PurchInvoiceHeader: Record "Purch. Inv. Header") JsonText: Text
//     var
//         PurchInvoiceLine: Record "Purch. Inv. Line";
//         RootObject: JsonObject;
//         PushDataArray: JsonArray;
//         AdvanceTaxObject: JsonObject;

//         CompanyInfo: Record "Company Information";
//         Vendor: Record Vendor;

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

//         if not Vendor.Get(
//             PurchInvoiceHeader."Buy-from Vendor No.")
//         then
//             Error(
//                 'Vendor %1 does not exist.',
//                 PurchInvoiceHeader."Buy-from Vendor No.");


//         PurchInvoiceLine.Reset();

//         PurchInvoiceLine.SetRange(
//             "Document No.",
//             PurchInvoiceHeader."No.");


//         if PurchInvoiceLine.FindSet() then
//             repeat

//                 // ------------------------------------------------
//                 // Ignore blank/comment lines
//                 // ------------------------------------------------

//                 if PurchInvoiceLine.Type <>
//                    PurchInvoiceLine.Type::" "
//                 then begin

//                     // ------------------------------------------------
//                     // Ignore zero quantity lines
//                     // ------------------------------------------------

//                     if PurchInvoiceLine.Quantity <> 0 then begin

//                         LineCount += 1;

//                         if LineCount > 10000 then
//                             Error(
//                                 'Advance Tax Purchase API allows maximum 10,000 item records.');


//                         Clear(AdvanceTaxObject);

//                         Clear(TotalCGST);
//                         Clear(TotalSGST);
//                         Clear(TotalIGST);
//                         Clear(TotalCESS);


//                         // ------------------------------------------------
//                         // GET GST AMOUNTS
//                         // ------------------------------------------------

//                         GetGSTAmounts(
//                             PurchInvoiceHeader."No.",
//                             PurchInvoiceLine."Line No.",
//                             TotalCGST,
//                             TotalSGST,
//                             TotalIGST,
//                             TotalCESS);


//                         // ------------------------------------------------
//                         // BUILD LINE
//                         // ------------------------------------------------

//                         AddAdvanceTaxPurchaseLine(
//                             AdvanceTaxObject,
//                             PurchInvoiceHeader,
//                             PurchInvoiceLine,
//                             Vendor,
//                             CompanyInfo,
//                             TotalCGST,
//                             TotalSGST,
//                             TotalIGST,
//                             TotalCESS);


//                         PushDataArray.Add(
//                             AdvanceTaxObject);

//                     end;
//                 end;

//             until PurchInvoiceLine.Next() = 0;


//         if PushDataArray.Count = 0 then
//             Error(
//                 'No valid invoice lines found for Purchase Invoice %1.',
//                 PurchInvoiceHeader."No.");


//         // ========================================================
//         // ROOT
//         // ========================================================

//         RootObject.Add(
//             'Push_Data_List',
//             PushDataArray);

//         RootObject.Add(
//             'Year',
//             Date2DMY(
//                 PurchInvoiceHeader."Posting Date",
//                 3));

//         RootObject.Add(
//             'Month',
//             Date2DMY(
//                 PurchInvoiceHeader."Posting Date",
//                 2));


//         RootObject.WriteTo(
//             JsonText);

//         exit(JsonText);
//     end;


//     // ============================================================
//     // ADD ADVANCE TAX PURCHASE LINE
//     // ============================================================

//     local procedure AddAdvanceTaxPurchaseLine(
//         var AdvanceTaxObject: JsonObject;
//         PurchInvoiceHeader: Record "Purch. Inv. Header";
//         PurchInvoiceLine: Record "Purch. Inv. Line";
//         Vendor: Record Vendor;
//         CompanyInfo: Record "Company Information";
//         CGSTAmount: Decimal;
//         SGSTAmount: Decimal;
//         IGSTAmount: Decimal;
//         CESSAmount: Decimal)
//     var
//         Item: Record Item;
//         GLAccount: Record "G/L Account";
//         FixedAsset: Record "Fixed Asset";
//         Resource: Record Resource;

//         GoodServiceType: Code[1];

//         IGSTRate: Decimal;
//         CGSTRate: Decimal;
//         SGSTRate: Decimal;
//         CESSRate: Decimal;

//         TaxableValue: Decimal;
//         GrossValue: Decimal;

//         LineItemCode: Text[50];

//         CompanyGSTIN: Code[20];
//     begin

//         // ========================================================
//         // GOOD / SERVICE TYPE
//         // ========================================================

//         Clear(GoodServiceType);

//         case PurchInvoiceLine.Type of

//             PurchInvoiceLine.Type::Item:
//                 begin

//                     if Item.Get(
//                         PurchInvoiceLine."No.")
//                     then
//                         GoodServiceType := 'G'
//                     else
//                         GoodServiceType := 'G';

//                 end;

//             PurchInvoiceLine.Type::"G/L Account":
//                 begin

//                     if GLAccount.Get(
//                         PurchInvoiceLine."No.")
//                     then
//                         GoodServiceType := 'S'
//                     else
//                         GoodServiceType := 'S';

//                 end;

//             PurchInvoiceLine.Type::Resource:
//                 begin

//                     if Resource.Get(
//                         PurchInvoiceLine."No.")
//                     then
//                         GoodServiceType := 'S'
//                     else
//                         GoodServiceType := 'S';

//                 end;

//             PurchInvoiceLine.Type::"Fixed Asset":
//                 begin

//                     if FixedAsset.Get(
//                         PurchInvoiceLine."No.")
//                     then
//                         GoodServiceType := 'G'
//                     else
//                         GoodServiceType := 'G';

//                 end;

//             else
//                 GoodServiceType := 'S';
//         end;


//         // ========================================================
//         // TAXABLE VALUE
//         // ========================================================

//         TaxableValue :=
//             Round(
//                 Abs(
//                     PurchInvoiceLine.Amount),
//                 0.01);


//         // ========================================================
//         // GROSS VALUE
//         // ========================================================

//         GrossValue :=
//             Round(
//                 TaxableValue +
//                 Abs(CGSTAmount) +
//                 Abs(SGSTAmount) +
//                 Abs(IGSTAmount) +
//                 Abs(CESSAmount),
//                 0.01);


//         // ========================================================
//         // GST RATES
//         // ========================================================

//         IGSTRate :=
//             GetComponentRate(
//                 PurchInvoiceHeader."No.",
//                 PurchInvoiceLine."Line No.",
//                 'IGST');


//         CGSTRate :=
//             GetComponentRate(
//                 PurchInvoiceHeader."No.",
//                 PurchInvoiceLine."Line No.",
//                 'CGST');


//         SGSTRate :=
//             GetComponentRate(
//                 PurchInvoiceHeader."No.",
//                 PurchInvoiceLine."Line No.",
//                 'SGST');


//         if SGSTRate = 0 then
//             SGSTRate :=
//                 GetComponentRate(
//                     PurchInvoiceHeader."No.",
//                     PurchInvoiceLine."Line No.",
//                     'UTGST');


//         CESSRate :=
//             GetComponentRate(
//                 PurchInvoiceHeader."No.",
//                 PurchInvoiceLine."Line No.",
//                 'CESS');


//         // ========================================================
//         // LINE ITEM CODE
//         // ========================================================

//         LineItemCode :=
//             CopyStr(
//                 StrSubstNo(
//                     '%1-%2',
//                     PurchInvoiceHeader."No.",
//                     PurchInvoiceLine."Line No."),
//                 1,
//                 50);


//         // ========================================================
//         // COMPANY GSTIN
//         // ========================================================

//         CompanyGSTIN :=
//             PurchInvoiceHeader."Location GST Reg. No.";

//         if CompanyGSTIN = '' then
//             CompanyGSTIN :=
//                 CompanyInfo."GST Registration No.";


//         // ========================================================
//         // PARTY
//         // ========================================================

//         AdvanceTaxObject.Add(
//             'PartyCode',
//             Vendor."No.");

//         AdvanceTaxObject.Add(
//             'PartyGSTIN',
//             Vendor."GST Registration No.");


//         // ========================================================
//         // DOCUMENT
//         // ========================================================

//         AdvanceTaxObject.Add(
//             'DocumentNo',
//             PurchInvoiceHeader."No.");

//         AdvanceTaxObject.Add(
//             'DocumentDt',
//             FormatAPIDate(
//                 PurchInvoiceHeader."Posting Date"));


//         // ========================================================
//         // GOODS / SERVICE
//         // ========================================================

//         AdvanceTaxObject.Add(
//             'GoodServiceType',
//             GoodServiceType);

//         AdvanceTaxObject.Add(
//             'HSNCode',
//             PurchInvoiceLine."HSN/SAC Code");


//         // ========================================================
//         // VALUES
//         // ========================================================

//         AdvanceTaxObject.Add(
//             'TaxableValue',
//             TaxableValue);

//         AdvanceTaxObject.Add(
//             'GrossValue',
//             GrossValue);


//         // ========================================================
//         // IGST
//         // ========================================================

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


//         // ========================================================
//         // CGST
//         // ========================================================

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


//         // ========================================================
//         // SGST
//         // ========================================================

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


//         // ========================================================
//         // CESS
//         // ========================================================

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


//         // ========================================================
//         // LINE ITEM CODE
//         // ========================================================

//         AdvanceTaxObject.Add(
//             'LineItemCode',
//             LineItemCode);


//         // ========================================================
//         // COMPANY GSTIN
//         // ========================================================

//         AdvanceTaxObject.Add(
//             'GSTIN',
//             CompanyGSTIN);


//         // ========================================================
//         // TAX TYPE
//         // ========================================================
//         // 1 = Exclusive
//         // 2 = Inclusive

//         AdvanceTaxObject.Add(
//             'TaxType',
//             1);


//         // ========================================================
//         // PLACE OF SUPPLY
//         // ========================================================

//         AdvanceTaxObject.Add(
//             'POS',
//             GetVendorPOS(
//                 Vendor));


//         // ========================================================
//         // UNIT CODE
//         // ========================================================

//         AdvanceTaxObject.Add(
//             'UnitCode',
//             GetUnitCode());


//         // ========================================================
//         // PARTY UNIT CODE
//         // ========================================================

//         AdvanceTaxObject.Add(
//             'PartyUnitCode',
//             '');


//         // ========================================================
//         // MODIFICATION FLAG
//         // ========================================================

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


//         // ========================================================
//         // REQUEST BODY
//         // ========================================================

//         Content.WriteFrom(
//             JsonText);


//         Content.GetHeaders(
//             ContentHeaders);

//         ContentHeaders.Clear();

//         ContentHeaders.Add(
//             'Content-Type',
//             'application/json');


//         // ========================================================
//         // AUTHORIZATION HEADER
//         // ========================================================

//         RequestHeaders :=
//             Client.DefaultRequestHeaders();

//         RequestHeaders.Add(
//             'Authorization',
//             AuthorizationValue);


//         // ========================================================
//         // TIMEOUT
//         // ========================================================

//         Client.Timeout :=
//             30000;


//         // ========================================================
//         // POST
//         // ========================================================

//         if not Client.Post(
//             AdvanceTaxPurchaseURL,
//             Content,
//             Response)
//         then begin

//             Error(
//                 'Unable to connect to Advance Tax Purchase API. URL: %1',
//                 AdvanceTaxPurchaseURL);

//         end;


//         // ========================================================
//         // READ RESPONSE
//         // ========================================================

//         Response.Content().ReadAs(
//             ResponseText);


//         // ========================================================
//         // HTTP ERROR
//         // ========================================================

//         if not Response.IsSuccessStatusCode() then begin

//             Error(
//                 'Advance Tax Purchase API failed. HTTP Status: %1. Response: %2',
//                 Response.HttpStatusCode(),
//                 ResponseText);

//         end;


//         // ========================================================
//         // SHOW EXACT API RESPONSE
//         // ========================================================

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


//         exit(
//             ResultInteger);
//     end;


//     // ============================================================
//     // VENDOR POS
//     // ============================================================

//     local procedure GetVendorPOS(
//         Vendor: Record Vendor): Code[10]
//     var
//         State: Record State;
//     begin

//         if Vendor."State Code" = '' then
//             exit('');


//         if State.Get(
//             Vendor."State Code")
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
//         // Read Unit Code from GST API Setup.

//         exit('');
//     end;
// }