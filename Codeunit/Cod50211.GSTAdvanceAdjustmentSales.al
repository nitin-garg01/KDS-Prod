// codeunit 50211 "GST Advance Adjustment Sale"
// {
//     SingleInstance = false;

//     var
//         AdvanceAdjustmentURL: Label 'http://103.100.217.51:81/gstapi/api/UploadData/AdvanceAdjustmentSale';
//         AuthorizationValue: Label 'Authorization /IalkRmh3z4=:::ZH4TUvIeJ3A=';


//     // ============================================================
//     // PREVIEW ADVANCE ADJUSTMENT JSON
//     // ============================================================

//     procedure PreviewAdvanceAdjustmentJSON(
//         SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         JsonText: Text;
//     begin
//         JsonText := GetAdvanceAdjustmentJSON(SalesInvoiceHeader);

//         Message('%1', JsonText);
//     end;


//     // ============================================================
//     // GET ADVANCE ADJUSTMENT JSON
//     // ============================================================

//     procedure GetAdvanceAdjustmentJSON(
//         SalesInvoiceHeader: Record "Sales Invoice Header"): Text
//     var
//         RootObject: JsonObject;
//         PushDataArray: JsonArray;
//         JsonText: Text;
//         SalesInvoiceLine: Record "Sales Invoice Line";
//         YearValue: Integer;
//         MonthValue: Integer;
//         LineCount: Integer;
//     begin
//         Clear(LineCount);

//         // --------------------------------------------------------
//         // Year
//         // --------------------------------------------------------

//         YearValue :=
//             Date2DMY(
//                 SalesInvoiceHeader."Posting Date",
//                 3);

//         // --------------------------------------------------------
//         // Month
//         // --------------------------------------------------------

//         MonthValue :=
//             Date2DMY(
//                 SalesInvoiceHeader."Posting Date",
//                 2);

//         // --------------------------------------------------------
//         // Get Posted Sales Invoice Lines
//         // --------------------------------------------------------

//         SalesInvoiceLine.Reset();

//         SalesInvoiceLine.SetRange(
//             "Document No.",
//             SalesInvoiceHeader."No.");

//         if SalesInvoiceLine.FindSet() then
//             repeat

//                 // Ignore blank lines
//                 if (SalesInvoiceLine.Type <> SalesInvoiceLine.Type::" ") and
//                    (SalesInvoiceLine.Quantity <> 0) then begin

//                     LineCount += 1;

//                     // API maximum 10,000 records
//                     if LineCount > 10000 then
//                         Error(
//                             'Advance Adjustment Sale API allows maximum 10,000 records.');

//                     AddAdvanceAdjustmentLine(
//                         PushDataArray,
//                         SalesInvoiceHeader,
//                         SalesInvoiceLine);
//                 end;

//             until SalesInvoiceLine.Next() = 0;

//         // --------------------------------------------------------
//         // Root Object
//         // --------------------------------------------------------

//         RootObject.Add(
//             'Push_Data_List',
//             PushDataArray);

//         RootObject.Add(
//             'Year',
//             YearValue);

//         RootObject.Add(
//             'Month',
//             MonthValue);

//         RootObject.WriteTo(JsonText);

//         exit(JsonText);
//     end;


//     // ============================================================
//     // ADD ADVANCE ADJUSTMENT LINE
//     // ============================================================

//     local procedure AddAdvanceAdjustmentLine(
//         var PushDataArray: JsonArray;
//         SalesInvoiceHeader: Record "Sales Invoice Header";
//         SalesInvoiceLine: Record "Sales Invoice Line")
//     var
//         LineObject: JsonObject;
//         AdjustAmount: Decimal;
//         IGSTValue: Decimal;
//         CGSTValue: Decimal;
//         SGSTValue: Decimal;
//         CessValue: Decimal;
//         GSTIN: Text;
//     begin

//         // --------------------------------------------------------
//         // Get GST values
//         // --------------------------------------------------------

//         GetGSTComponentValues(
//             SalesInvoiceHeader."No.",
//             SalesInvoiceLine."Line No.",
//             IGSTValue,
//             CGSTValue,
//             SGSTValue,
//             CessValue);


//         // --------------------------------------------------------
//         // Adjustment Amount
//         // --------------------------------------------------------

//         AdjustAmount :=
//             Abs(
//                 SalesInvoiceLine.Amount);


//         // --------------------------------------------------------
//         // Company GSTIN
//         // --------------------------------------------------------

//         GSTIN :=
//             GetCompanyGSTIN();


//         // --------------------------------------------------------
//         // InvoiceNo
//         // --------------------------------------------------------

//         LineObject.Add(
//             'InvoiceNo',
//             SalesInvoiceHeader."No.");


//         // --------------------------------------------------------
//         // GSTIN
//         // --------------------------------------------------------

//         LineObject.Add(
//             'GSTIN',
//             GSTIN);


//         // --------------------------------------------------------
//         // DocumentNo
//         // --------------------------------------------------------

//         LineObject.Add(
//             'DocumentNo',
//             SalesInvoiceHeader."No.");


//         // --------------------------------------------------------
//         // AdjustAmount
//         // --------------------------------------------------------

//         LineObject.Add(
//             'AdjustAmount',
//             Round(
//                 AdjustAmount,
//                 0.01));


//         // --------------------------------------------------------
//         // IGST
//         // --------------------------------------------------------

//         LineObject.Add(
//             'IGSTValue',
//             Round(
//                 IGSTValue,
//                 0.01));


//         // --------------------------------------------------------
//         // CGST
//         // --------------------------------------------------------

//         LineObject.Add(
//             'CGSTValue',
//             Round(
//                 CGSTValue,
//                 0.01));


//         // --------------------------------------------------------
//         // SGST
//         // --------------------------------------------------------

//         LineObject.Add(
//             'SGSTValue',
//             Round(
//                 SGSTValue,
//                 0.01));


//         // --------------------------------------------------------
//         // Cess
//         // --------------------------------------------------------

//         LineObject.Add(
//             'CessValue',
//             Round(
//                 CessValue,
//                 0.01));


//         // --------------------------------------------------------
//         // IsModified
//         // --------------------------------------------------------
//         // N = New record
//         // Y = Modify existing record
//         // --------------------------------------------------------

//         LineObject.Add(
//             'IsModified',
//             'N');


//         // --------------------------------------------------------
//         // Add object into Push_Data_List
//         // --------------------------------------------------------

//         PushDataArray.Add(
//             LineObject);
//     end;


//     // ============================================================
//     // GET GST COMPONENT VALUES
//     // ============================================================

//     local procedure GetGSTComponentValues(
//         DocumentNo: Code[20];
//         DocumentLineNo: Integer;
//         var IGSTValue: Decimal;
//         var CGSTValue: Decimal;
//         var SGSTValue: Decimal;
//         var CessValue: Decimal)
//     var
//         DetailedGSTLedgerEntry: Record "Detailed GST Ledger Entry";
//         ComponentCode: Text;
//         GSTAmount: Decimal;
//     begin

//         Clear(IGSTValue);
//         Clear(CGSTValue);
//         Clear(SGSTValue);
//         Clear(CessValue);


//         // --------------------------------------------------------
//         // Filter Document
//         // --------------------------------------------------------

//         DetailedGSTLedgerEntry.Reset();

//         DetailedGSTLedgerEntry.SetRange(
//             "Document No.",
//             DocumentNo);

//         DetailedGSTLedgerEntry.SetRange(
//             "Document Line No.",
//             DocumentLineNo);


//         // --------------------------------------------------------
//         // Read GST Ledger
//         // --------------------------------------------------------

//         if DetailedGSTLedgerEntry.FindSet() then
//             repeat

//                 GSTAmount :=
//                     Abs(
//                         DetailedGSTLedgerEntry."GST Amount");


//                 // ------------------------------------------------
//                 // GST Component Code
//                 // ------------------------------------------------

//                 ComponentCode :=
//                     UpperCase(
//                         Format(
//                             DetailedGSTLedgerEntry."GST Component Code"));


//                 // ------------------------------------------------
//                 // IGST
//                 // ------------------------------------------------

//                 if ComponentCode = 'IGST' then
//                     IGSTValue += GSTAmount;


//                 // ------------------------------------------------
//                 // CGST
//                 // ------------------------------------------------

//                 if ComponentCode = 'CGST' then
//                     CGSTValue += GSTAmount;


//                 // ------------------------------------------------
//                 // SGST
//                 // ------------------------------------------------

//                 if ComponentCode = 'SGST' then
//                     SGSTValue += GSTAmount;


//                 // ------------------------------------------------
//                 // CESS
//                 // ------------------------------------------------

//                 if ComponentCode = 'CESS' then
//                     CessValue += GSTAmount;

//             until DetailedGSTLedgerEntry.Next() = 0;
//     end;


//     // ============================================================
//     // UPLOAD ADVANCE ADJUSTMENT DATA
//     // ============================================================

//     procedure UploadSalesInvoice(
//         SalesInvoiceHeader: Record "Sales Invoice Header")
//     var
//         Client: HttpClient;
//         Content: HttpContent;
//         ContentHeaders: HttpHeaders;
//         RequestHeaders: HttpHeaders;
//         Response: HttpResponseMessage;
//         JsonText: Text;
//         ResponseText: Text;
//     begin

//         // --------------------------------------------------------
//         // Generate JSON
//         // --------------------------------------------------------

//         JsonText :=
//             GetAdvanceAdjustmentJSON(
//                 SalesInvoiceHeader);


//         // --------------------------------------------------------
//         // HTTP Content
//         // --------------------------------------------------------

//         Content.WriteFrom(
//             JsonText);


//         // --------------------------------------------------------
//         // Get Content Headers
//         // --------------------------------------------------------

//         Content.GetHeaders(
//             ContentHeaders);


//         // --------------------------------------------------------
//         // Content-Type
//         // --------------------------------------------------------

//         if ContentHeaders.Contains(
//             'Content-Type') then
//             ContentHeaders.Remove(
//                 'Content-Type');


//         ContentHeaders.Add(
//             'Content-Type',
//             'application/json');


//         // --------------------------------------------------------
//         // Authorization
//         // --------------------------------------------------------

//         RequestHeaders :=
//             Client.DefaultRequestHeaders();


//         if RequestHeaders.Contains(
//             'Authorization') then
//             RequestHeaders.Remove(
//                 'Authorization');


//         RequestHeaders.Add(
//             'Authorization',
//             AuthorizationValue);


//         // --------------------------------------------------------
//         // Timeout
//         // --------------------------------------------------------

//         Client.Timeout :=
//             30000;


//         // --------------------------------------------------------
//         // POST
//         // --------------------------------------------------------

//         if not Client.Post(
//             AdvanceAdjustmentURL,
//             Content,
//             Response) then
//             Error(
//                 'Advance Adjustment Sale API connection failed.');


//         // --------------------------------------------------------
//         // Read Response
//         // --------------------------------------------------------

//         Response.Content().ReadAs(
//             ResponseText);


//         // --------------------------------------------------------
//         // HTTP Error
//         // --------------------------------------------------------

//         if not Response.IsSuccessStatusCode() then
//             Error(
//                 'Advance Adjustment Sale API failed. HTTP Status: %1. Response: %2',
//                 Response.HttpStatusCode(),
//                 ResponseText);


//         // --------------------------------------------------------
//         // API Response
//         // --------------------------------------------------------

//         Message(
//             'Advance Adjustment Sale API Response:\%1',
//             ResponseText);
//     end;


//     // ============================================================
//     // GET COMPANY GSTIN
//     // ============================================================

//     local procedure GetCompanyGSTIN(): Text
//     var
//         CompanyInformation: Record "Company Information";
//     begin
//         CompanyInformation.Get();

//         exit(
//             CompanyInformation."GST Registration No.");
//     end;
// }