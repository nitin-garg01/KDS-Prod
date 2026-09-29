// codeunit 50206 "GST Purchase API"
// {
//     Permissions =
// tabledata "Purch. Inv. Header" = RIMD,
// tabledata "Purch. Inv. Line" = RIMD,
// tabledata Vendor = RIMD,
// tabledata "Company Information" = RIMD,
// tabledata "Detailed GST Ledger Entry" = RIMD,
// tabledata State = RIMD,
// tabledata "Unit of Measure" = RIMD,
// tabledata Item = RIMD,
// tabledata "G/L Account" = RIMD;




//     procedure GetGSTApiUrl(): Text
//     begin
//         exit('http://103.100.217.51:81/gstapi/api/UploadData/Purchase');
//     end;



//     procedure GetGSTApiAuthorization(): Text
//     begin
//         exit('Authorization /IalkRmh3z4=:::ZH4TUvIeJ3A=');
//     end;


//     procedure GetPurchaseJSON(PurchInvHeader: Record "Purch. Inv. Header"): Text
//     var
//         CompanyInfo: Record "Company Information";
//         PurchInvLine: Record "Purch. Inv. Line";
//         DataObj: JsonObject;
//         DataArray: JsonArray;
//         FinalObj: JsonObject;
//         LineCount: Integer;
//         JsonText: Text;
//     begin
//         CompanyInfo.Get();
//         Clear(DataArray);
//         Clear(FinalObj);

//         PurchInvLine.Reset();
//         PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");

//         if PurchInvLine.FindSet() then begin
//             repeat
//                 if not ((PurchInvLine.Type = PurchInvLine.Type::" ") or (PurchInvLine."No." = '')) then begin
//                     LineCount += 1;

//                     if LineCount > 10000 then
//                         Error('Purchase API supports maximum 10000 item-wise records. Purchase Invoice %1 contains more than 10000 records.', PurchInvHeader."No.");

//                     Clear(DataObj);
//                     BuildPurchaseLineJSON(PurchInvHeader, PurchInvLine, CompanyInfo, DataObj);
//                     DataArray.Add(DataObj);
//                 end;
//             until PurchInvLine.Next() = 0;
//         end;

//         if LineCount = 0 then
//             Error('No valid purchase invoice lines found for Purchase Invoice %1.', PurchInvHeader."No.");

//         FinalObj.Add('Push_Data_List', DataArray);
//         FinalObj.Add('Year', Date2DMY(PurchInvHeader."Posting Date", 3));
//         FinalObj.Add('Month', Date2DMY(PurchInvHeader."Posting Date", 2));

//         FinalObj.WriteTo(JsonText);
//         exit(JsonText);
//     end;

//     // =========================================================
//     // BUILD ONE PURCHASE LINE
//     // =========================================================

//     local procedure BuildPurchaseLineJSON(PurchInvHeader: Record "Purch. Inv. Header"; PurchInvLine: Record "Purch. Inv. Line"; CompanyInfo: Record "Company Information"; var DataObj: JsonObject)
//     var
//         Vendor: Record Vendor;
//         StateRec: Record State;
//         UnitOfMeasure: Record "Unit of Measure";
//         IgstAmt: Decimal;
//         CgstAmt: Decimal;
//         SgstAmt: Decimal;
//         CessAmt: Decimal;
//         IgstRate: Decimal;
//         CgstRate: Decimal;
//         SgstRate: Decimal;
//         CessRate: Decimal;
//         GstRate: Decimal;
//         TaxableValue: Decimal;
//         Value: Decimal;
//         PartyState: Text;
//         ItemType: Text;
//         SupplyType: Text;
//         ReverseCharge: Text;
//         IsImplaneded: Text;
//         UQC: Text;
//         HSNCode: Text;
//         EligibilityITC: Text;
//         GLCode: Text;
//         VendorInvoiceNo: Text;
//         VoucherNo: Text;
//         VoucherDate: Text;
//         LineItemCode: Text;
//     begin
//         if not Vendor.Get(PurchInvHeader."Buy-from Vendor No.") then
//             Error('Vendor %1 not found for Purchase Invoice %2.', PurchInvHeader."Buy-from Vendor No.", PurchInvHeader."No.");

//         // =====================================================
//         // PARTY CODE
//         // =====================================================

//         if Vendor."No." = '' then
//             Error('PartyCode is blank for Purchase Invoice %1.', PurchInvHeader."No.");

//         // =====================================================
//         // STATE
//         // =====================================================

//         PartyState := '';

//         if Vendor."State Code" <> '' then begin
//             if StateRec.Get(Vendor."State Code") then
//                 PartyState := StateRec."State Code (GST Reg. No.)";
//         end;

//         // =====================================================
//         // PARTY IMPLEMENTED
//         // =====================================================

//         if Vendor."GST Registration No." <> '' then
//             IsImplaneded := 'Y'
//         else
//             IsImplaneded := 'N';


//         if PurchInvLine.Type = PurchInvLine.Type::Item then
//             ItemType := 'G'
//         else
//             ItemType := 'S';



//         HSNCode := GetHSNSACCode(PurchInvLine);



//         GetGSTAmountsForLine(PurchInvHeader."No.", PurchInvLine."Line No.", PurchInvLine."Line Amount", IgstAmt, CgstAmt, SgstAmt, CessAmt, IgstRate, CgstRate, SgstRate, CessRate, GstRate, TaxableValue);

//         // =====================================================
//         // VALUE
//         // =====================================================

//         Value := Round(PurchInvLine."Line Amount", 0.01);

//         // =====================================================
//         // SUPPLY TYPE
//         // =====================================================

//         SupplyType := GetSupplyType(PurchInvHeader, Vendor);

//         // =====================================================
//         // REVERSE CHARGE
//         // =====================================================

//         ReverseCharge := GetReverseCharge(PurchInvHeader);

//         // =====================================================
//         // UQC
//         // =====================================================

//         UQC := '';

//         if PurchInvLine."Unit of Measure Code" <> '' then begin
//             UnitOfMeasure.Reset();
//             UnitOfMeasure.SetRange(Code, PurchInvLine."Unit of Measure Code");

//             if UnitOfMeasure.FindFirst() then
//                 UQC := UnitOfMeasure."International Standard Code";
//         end;

//         // =====================================================
//         // ITC ELIGIBILITY
//         // =====================================================

//         EligibilityITC := GetEligibilityOfITC(PurchInvLine);

//         // =====================================================
//         // GL CODE
//         // =====================================================

//         GLCode := GetGLCode(PurchInvLine);

//         // =====================================================
//         // INVOICE NO
//         // =====================================================

//         VendorInvoiceNo := PurchInvHeader."Vendor Invoice No.";

//         if VendorInvoiceNo = '' then
//             VendorInvoiceNo := PurchInvHeader."No.";

//         VendorInvoiceNo := CopyStr(VendorInvoiceNo, 1, 16);

//         // =====================================================
//         // VOUCHER
//         // =====================================================

//         VoucherNo := PurchInvHeader."No.";
//         VoucherDate := FormatGSTDate(PurchInvHeader."Posting Date");

//         // =====================================================
//         // UNIQUE LINE ITEM CODE
//         // =====================================================

//         LineItemCode := CopyStr(PurchInvHeader."No." + '-' + Format(PurchInvLine."Line No."), 1, 100);

//         // =====================================================
//         // JSON
//         // =====================================================

//         DataObj.Add('PartyCode', Vendor."No.");
//         DataObj.Add('InvoiceNo', VendorInvoiceNo);
//         DataObj.Add('Date', VoucherDate);
//         DataObj.Add('Value', Value);
//         DataObj.Add('HSNCode', HSNCode);
//         DataObj.Add('TaxableValue', TaxableValue);
//         DataObj.Add('IGSTRate', IgstRate);
//         DataObj.Add('IGSTValue', IgstAmt);
//         DataObj.Add('CGSTRate', CgstRate);
//         DataObj.Add('CGSTValue', CgstAmt);
//         DataObj.Add('SGSTRate', SgstRate);
//         DataObj.Add('SGSTValue', SgstAmt);
//         DataObj.Add('CESSRate', CessRate);
//         DataObj.Add('CESSValue', CessAmt);

//         // =====================================================
//         // TOTAL GST
//         // =====================================================

//         DataObj.Add('TotalCGSTValue', CgstAmt);
//         DataObj.Add('TotalIGSTValue', IgstAmt);
//         DataObj.Add('TotalSGSTValue', SgstAmt);
//         DataObj.Add('TotalCessValue', CessAmt);

//         // =====================================================
//         // ITEM INFORMATION
//         // =====================================================

//         DataObj.Add('ItemType', ItemType);
//         DataObj.Add('SupplyType', SupplyType);
//         DataObj.Add('POS', PartyState);
//         DataObj.Add('ReverseCharge', ReverseCharge);
//         DataObj.Add('PortCode', '');
//         DataObj.Add('State', PartyState);
//         DataObj.Add('ItemQuantity', PurchInvLine.Quantity);
//         DataObj.Add('UQC', UQC);
//         DataObj.Add('LineItemCode', LineItemCode);

//         // =====================================================
//         // ASSESSEE
//         // =====================================================

//         DataObj.Add('GSTIN', CompanyInfo."GST Registration No.");
//         DataObj.Add('UnitCode', '');
//         DataObj.Add('IsImplaneded', IsImplaneded);

//         // =====================================================
//         // PARTY
//         // =====================================================

//         DataObj.Add('PartyName', Vendor.Name);
//         DataObj.Add('PartyGSTIN', Vendor."GST Registration No.");
//         DataObj.Add('PartyUIN', '');
//         DataObj.Add('PartyState', PartyState);
//         DataObj.Add('Address', Vendor.Address);

//         // =====================================================
//         // VOUCHER INFORMATION
//         // =====================================================

//         DataObj.Add('VoucherType', 'Purchase');
//         DataObj.Add('MismatchFlag', 0);
//         DataObj.Add('ItemName', PurchInvLine.Description);
//         DataObj.Add('ItemHead', 'Purchase');
//         DataObj.Add('EligibilityOfITC', EligibilityITC);
//         DataObj.Add('VoucherNo', VoucherNo);
//         DataObj.Add('VoucherDate', VoucherDate);
//         DataObj.Add('IsModified', 'N');
//         DataObj.Add('PartyUnitCode', '');
//         DataObj.Add('InEligibility_US_17_5', '0');
//         DataObj.Add('LeaseOFOldCar', 0);
//         DataObj.Add('OtherCharges', 0);
//         DataObj.Add('IsTaxableZero', 0);
//         DataObj.Add('GLCode', GLCode);
//     end;

//     // =========================================================
//     // UPLOAD PURCHASE
//     // =========================================================

//     procedure UploadPurchase(PurchInvHeader: Record "Purch. Inv. Header"): Text
//     var
//         Client: HttpClient;
//         Content: HttpContent;
//         Response: HttpResponseMessage;
//         Headers: HttpHeaders;
//         RequestHeaders: HttpHeaders;
//         JsonText: Text;
//         ResultText: Text;
//     begin
//         // Generate JSON
//         JsonText := GetPurchaseJSON(PurchInvHeader);

//         // Prepare Content
//         Content.WriteFrom(JsonText);

//         Content.GetHeaders(Headers);

//         if Headers.Contains('Content-Type') then
//             Headers.Remove('Content-Type');

//         Headers.Add('Content-Type', 'application/json');

//         // Authorization Header
//         RequestHeaders := Client.DefaultRequestHeaders();

//         if RequestHeaders.Contains('Authorization') then
//             RequestHeaders.Remove('Authorization');

//         if not RequestHeaders.TryAddWithoutValidation(
//             'Authorization',
//             GetGSTApiAuthorization())
//         then
//             Error('Unable to add Authorization header.');

//         Client.Timeout := 30000;

//         // POST API
//         if Client.Post(GetGSTApiUrl(), Content, Response) then begin

//             Response.Content().ReadAs(ResultText);

//             // API Error
//             if not Response.IsSuccessStatusCode() then begin
//                 Error(
//                     'GST Purchase API Error. HTTP Status: %1\%2',
//                     Response.HttpStatusCode(),
//                     ResultText);
//             end;

//             // Return API response to Page
//             exit(ResultText);

//         end else begin
//             Error('GST Purchase API server not reachable.');
//         end;
//     end;
//     // =========================================================
//     // GST AMOUNTS
//     // =========================================================

//     local procedure GetGSTAmountsForLine(DocNo: Code[20]; LineNo: Integer; LineAmount: Decimal; var IgstAmt: Decimal; var CgstAmt: Decimal; var SgstAmt: Decimal; var CessAmt: Decimal; var IgstRate: Decimal; var CgstRate: Decimal; var SgstRate: Decimal; var CessRate: Decimal; var GstRate: Decimal; var PreTaxVal: Decimal)
//     var
//         DetailedGSTEntry: Record "Detailed GST Ledger Entry";
//     begin
//         Clear(IgstAmt);
//         Clear(CgstAmt);
//         Clear(SgstAmt);
//         Clear(CessAmt);
//         Clear(IgstRate);
//         Clear(CgstRate);
//         Clear(SgstRate);
//         Clear(CessRate);
//         Clear(GstRate);

//         PreTaxVal := Round(LineAmount, 0.01);

//         DetailedGSTEntry.Reset();
//         DetailedGSTEntry.SetRange("Document No.", DocNo);
//         DetailedGSTEntry.SetRange("Document Line No.", LineNo);
//         DetailedGSTEntry.SetRange("Entry Type", DetailedGSTEntry."Entry Type"::"Initial Entry");

//         if DetailedGSTEntry.FindSet() then
//             repeat
//                 case DetailedGSTEntry."GST Component Code" of
//                     'IGST':
//                         begin
//                             IgstAmt += Abs(DetailedGSTEntry."GST Amount");
//                             IgstRate := DetailedGSTEntry."GST %";
//                         end;

//                     'CGST':
//                         begin
//                             CgstAmt += Abs(DetailedGSTEntry."GST Amount");
//                             CgstRate := DetailedGSTEntry."GST %";
//                         end;

//                     'SGST', 'UTGST':
//                         begin
//                             SgstAmt += Abs(DetailedGSTEntry."GST Amount");
//                             SgstRate := DetailedGSTEntry."GST %";
//                         end;

//                     'CESS':
//                         begin
//                             CessAmt += Abs(DetailedGSTEntry."GST Amount");
//                             CessRate := DetailedGSTEntry."GST %";
//                         end;
//                 end;
//             until DetailedGSTEntry.Next() = 0;

//         if IgstRate <> 0 then
//             GstRate := IgstRate
//         else
//             GstRate := CgstRate + SgstRate;

//         IgstAmt := Round(IgstAmt, 0.01);
//         CgstAmt := Round(CgstAmt, 0.01);
//         SgstAmt := Round(SgstAmt, 0.01);
//         CessAmt := Round(CessAmt, 0.01);
//     end;

//     // =========================================================
//     // HSN / SAC
//     // =========================================================

//     local procedure GetHSNSACCode(PurchInvLine: Record "Purch. Inv. Line"): Text
//     begin
//         if PurchInvLine."HSN/SAC Code" <> '' then
//             exit(PurchInvLine."HSN/SAC Code");

//         exit('');
//     end;

//     // =========================================================
//     // SUPPLY TYPE
//     // =========================================================

//     local procedure GetSupplyType(PurchInvHeader: Record "Purch. Inv. Header"; Vendor: Record Vendor): Text
//     begin
//         if Vendor."Country/Region Code" <> '' then begin
//             if Vendor."Country/Region Code" <> 'IN' then
//                 exit('4');
//         end;

//         exit('1');
//     end;

//     // =========================================================
//     // REVERSE CHARGE
//     // =========================================================

//     local procedure GetReverseCharge(PurchInvHeader: Record "Purch. Inv. Header"): Text
//     begin
//         exit('N');
//     end;

//     // =========================================================
//     // ITC
//     // =========================================================

//     local procedure GetEligibilityOfITC(PurchInvLine: Record "Purch. Inv. Line"): Text
//     begin
//         exit('Input');
//     end;

//     // =========================================================
//     // GL CODE
//     // =========================================================

//     local procedure GetGLCode(PurchInvLine: Record "Purch. Inv. Line"): Text
//     begin
//         if PurchInvLine.Type = PurchInvLine.Type::"G/L Account" then
//             exit(PurchInvLine."No.");

//         exit('');
//     end;

//     // =========================================================
//     // DATE YYYYMMDD
//     // =========================================================

//     local procedure FormatGSTDate(PostingDate: Date): Text
//     begin
//         exit(Format(PostingDate, 0, '<Year4><Month,2><Day,2>'));
//     end;
// }