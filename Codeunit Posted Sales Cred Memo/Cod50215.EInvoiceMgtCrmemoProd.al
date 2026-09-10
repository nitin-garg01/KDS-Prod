codeunit 50215 "E-Invoice Mgt Cr Prod"
{
    Permissions = tabledata "Sales Cr.Memo Header" = rimd;

    procedure GenerateIRN(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        JsonText: Text;
        ResultText: Text;
    begin
        JsonText := GetInvoiceJSON(SalesCrMemoHeader);
        // message(JsonText);
        Content.WriteFrom(JsonText);
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');
        if Client.Post('http://einvlive.webtel.in/v1.03/GenIRN', Content, Response) then begin
            Response.Content().ReadAs(ResultText);
            SaveJSONResponse(SalesCrMemoHeader, ResultText);
            if Response.IsSuccessStatusCode() then
                ProcessResponse(SalesCrMemoHeader, ResultText)
            else
                Error('Webtel API Error: %1', ResultText);
        end else
            Error('Server not reachable.');
    end;



    local procedure SaveJSONResponse(var Rec: Record "Sales Cr.Memo Header"; ResponseText: Text)
    var
        OutStream: OutStream;
    begin
        Rec.JSONResponse.CreateOutStream(OutStream);
        OutStream.WriteText(ResponseText);
        Rec.Modify(true);
    end;

    procedure GetInvoiceJSON(Rec: Record "Sales Cr.Memo Header") JsonText: Text
    var
        DataObj: JsonObject;
        PushData: JsonObject;
        FinalObj: JsonObject;
        LocationRec: Record Location;
        CompanyInfo: Record "Company Information";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DataArray: JsonArray;
        GSTRegNos: Record "GST Registration Nos.";
        AssessableTotal: Decimal;
        SalesInvHeader: Record "Sales Invoice Header";

        IgstTotal: Decimal;
        CgstTotal: Decimal;
        SgstTotal: Decimal;
        CountryRegion: Record "Country/Region";
        GstRate: Decimal;
        LineIgst: Decimal;
        LineCgst: Decimal;
        UnitOfMeasureCode: Record "Unit of Measure";
        LineSgst: Decimal;
        InvoiceTotal: Decimal;
        StateRec: Record State;
        LineCount: Integer;
        Currencyfactor: decimal;
        PreTaxVal: Decimal;
    begin
        CompanyInfo.Get();
        Clear(AssessableTotal);
        Clear(IgstTotal);
        Clear(CgstTotal);
        Clear(SgstTotal);
        Clear(InvoiceTotal);

        SalesCrMemoLine.SetRange("Document No.", Rec."No.");
        if SalesCrMemoLine.FindSet() then begin
            repeat
                AssessableTotal += Round(SalesCrMemoLine."Line Amount", 0.01);
                GetGSTAmountsForLine(Rec."No.", SalesCrMemoLine."Line No.", SalesCrMemoLine."Line Amount", LineIgst, LineCgst, LineSgst, GstRate, PreTaxVal);
                IgstTotal += Round(LineIgst, 0.01);
                CgstTotal += Round(LineCgst, 0.01);
                SgstTotal += Round(LineSgst, 0.01);
            until SalesCrMemoLine.Next() = 0;
        end;
        if Rec."Currency Factor" <> 0 then
            Currencyfactor := Rec."Currency Factor"
        else
            Currencyfactor := 1;
        InvoiceTotal :=
            Round(AssessableTotal, 0.01) +
            Round(IgstTotal, 0.01) +
            Round(CgstTotal, 0.01) +
            Round(SgstTotal, 0.01);

        if SalesCrMemoLine.FindSet() then begin
            LineCount := 0;
            repeat
                if (SalesCrMemoLine.Type = SalesCrMemoLine.Type::" ") or
                   (SalesCrMemoLine."No." = '') or
                   (SalesCrMemoLine.Quantity = 0)
                then
                    continue;

                LineCount += 1;
                Clear(DataObj);

                DataObj.Add('Gstin', Rec."Location GST Reg. No."); // add when live


                DataObj.Add('Irn', '');

                if Rec."GST Customer Type" = Rec."GST Customer Type"::Registered then
                    DataObj.Add('Tran_SupTyp', 'B2B')

                else if Rec."GST Customer Type" = Rec."GST Customer Type"::Unregistered then
                    DataObj.Add('Tran_SupTyp', 'B2C')

                else if Rec."GST Without Payment of Duty" then
                    DataObj.Add('Tran_SupTyp', 'EXPWOP')

                else IF Rec."GST Without Payment of Duty" = false then
                    DataObj.Add('Tran_SupTyp', 'EXPWP');

                if Rec."GST Customer Type" = Rec."GST Customer Type"::Unregistered then
                    DataObj.Add('Tran_RegRev', 'Y')
                else
                    DataObj.Add('Tran_RegRev', 'N');

                DataObj.Add('Tran_Typ', 'REG');
                DataObj.Add('Tran_EcmGstin', '');
                DataObj.Add('Tran_IgstOnIntra', 'N');

                // *** KEY CHANGE: Doc_Typ = CRN for Credit Memo ***
                DataObj.Add('Doc_Typ', 'CRN');
                DataObj.Add('Doc_No', Rec."No.");
                DataObj.Add('Doc_Dt', Format(Rec."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));

                DataObj.Add('BillFrom_Gstin', CompanyInfo."GST Registration No."); // add when live

                DataObj.Add('BillFrom_LglNm', CompanyInfo.Name);
                DataObj.Add('BillFrom_TrdNm', '');

                if LocationRec.Get(Rec."Location Code") then begin
                    DataObj.Add('BillFrom_Addr1', LocationRec.Address);
                    DataObj.Add('BillFrom_Addr2', LocationRec."Address 2");
                    DataObj.Add('BillFrom_Loc', LocationRec.City);
                    DataObj.Add('BillFrom_Pin', LocationRec."Post Code"); // add when live

                    if StateRec.Get(LocationRec."State Code") then
                        DataObj.Add('BillFrom_Stcd', StateRec."State Code (GST Reg. No.)")
                    else
                        DataObj.Add('BillFrom_Stcd', ''); // add when live

                end else begin
                    DataObj.Add('BillFrom_Addr1', '');
                    DataObj.Add('BillFrom_Addr2', '');
                    DataObj.Add('BillFrom_Loc', '');
                    DataObj.Add('BillFrom_Pin', '');
                    DataObj.Add('BillFrom_Stcd', '');
                end;

                DataObj.Add('BillFrom_Ph', CompanyInfo."Phone No.");
                DataObj.Add('BillFrom_Em', CompanyInfo."E-Mail");

                if rec."GST Customer Type" = rec."GST Customer Type"::Export then
                    DataObj.Add('BillTo_Gstin', 'URP')
                else
                    DataObj.Add('BillTo_Gstin', Rec."Customer GST Reg. No.");
                DataObj.Add('BillTo_LglNm', Rec."Bill-to Name");
                DataObj.Add('BillTo_TrdNm', '');
                DataObj.Add('BillTo_Addr1', Rec."Bill-to Address");
                DataObj.Add('BillTo_Addr2', Rec."Bill-to Address 2");
                DataObj.Add('BillTo_Loc', Rec."Bill-to City");
                IF REC."GST Customer Type" = REC."GST Customer Type"::Export then
                    DataObj.Add('BillTo_Pin', '999999')
                ELSE
                    DataObj.Add('BillTo_Pin', Rec."Bill-to Post Code");

                if Rec."GST Customer Type" = rec."GST Customer Type"::Export then begin


                    DataObj.Add('BillTo_Pos', '96');
                    DataObj.Add('BillTo_Stcd', '96');

                end else begin

                    if (Rec."GST Bill-to State Code" <> '') and
                       StateRec.Get(Rec."GST Bill-to State Code") then begin

                        DataObj.Add('BillTo_Stcd', StateRec."State Code (GST Reg. No.)");
                        DataObj.Add('BillTo_Pos', StateRec."State Code (GST Reg. No.)");

                    end else begin

                        DataObj.Add('BillTo_Stcd', '');
                        DataObj.Add('BillTo_Pos', '');

                    end;
                end;

                DataObj.Add('BillTo_Ph', Format(Rec."Sell-to Phone No."));
                DataObj.Add('BillTo_Em', Rec."Sell-to E-Mail");

                DataObj.Add('Item_SlNo', Format(LineCount));
                DataObj.Add('Item_PrdDesc', SalesCrMemoLine.Description);

                if SalesCrMemoLine."GST Group Type" = SalesCrMemoLine."GST Group Type"::Service then
                    DataObj.Add('Item_IsServc', 'Y')
                else
                    DataObj.Add('Item_IsServc', 'N');

                DataObj.Add('Item_HsnCd', SalesCrMemoLine."HSN/SAC Code");
                DataObj.Add('Item_Barcde', '');
                DataObj.Add('Item_Qty', SalesCrMemoLine.Quantity);
                DataObj.Add('Item_FreeQty', '');

                UnitOfMeasureCode.Reset();
                UnitOfMeasureCode.SetRange(Code, SalesCrMemoLine."Unit of Measure Code");
                if not UnitOfMeasureCode.FindFirst() then
                    Error('Unit of Measure Code %1 not found in Unit of Measure table.', SalesCrMemoLine."Unit of Measure Code");
                DataObj.Add('Item_Unit', UnitOfMeasureCode."International Standard Code");

                DataObj.Add('Item_UnitPrice', Round(SalesCrMemoLine."Unit Price" / Currencyfactor, 0.01));

                DataObj.Add('Item_TotAmt', Round(SalesCrMemoLine.Quantity * (SalesCrMemoLine."Unit Price" / Currencyfactor), 0.01));
                DataObj.Add('Item_Discount', SalesCrMemoLine."Line Discount %");

                GetGSTAmountsForLine(Rec."No.", SalesCrMemoLine."Line No.", SalesCrMemoLine."Line Amount", LineIgst, LineCgst, LineSgst, GstRate, PreTaxVal);
                DataObj.Add('Item_PreTaxVal', Round(PreTaxVal / Currencyfactor, 0.01));

                DataObj.Add('Item_AssAmt', Round(SalesCrMemoLine."Line Amount" / Currencyfactor, 0.01));
                DataObj.Add('Item_GstRt', GstRate);
                DataObj.Add('Item_IgstAmt', LineIgst);
                DataObj.Add('Item_CgstAmt', LineCgst);
                DataObj.Add('Item_SgstAmt', LineSgst);
                DataObj.Add('Item_CesRt', 0);
                DataObj.Add('Item_CesAmt', 0);
                DataObj.Add('Item_CesNonAdvlAmt', 0);
                DataObj.Add('Item_StateCesRt', 0);
                DataObj.Add('Item_StateCesAmt', 0);
                DataObj.Add('Item_StateCesNonAdvlAmt', 0);
                DataObj.Add('Item_OthChrg', 0);
                DataObj.Add('Item_TotItemVal', Round(Round(SalesCrMemoLine."Line Amount" / Currencyfactor, 0.01) + Round(LineIgst, 0.01) + Round(LineCgst, 0.01) + Round(LineSgst, 0.01),
       0.01));
                DataObj.Add('Item_OrdLineRef', '');
                DataObj.Add('Item_OrgCntry', '');
                DataObj.Add('Item_PrdSlNo', '');
                DataObj.Add('Item_Attrib_Nm', '');
                DataObj.Add('Item_Attrib_Val', '');
                DataObj.Add('Item_Bch_Nm', '');
                DataObj.Add('Item_Bch_ExpDt', '');
                DataObj.Add('Item_Bch_WrDt', '');

                DataObj.Add('Val_AssVal', Round(AssessableTotal / Currencyfactor, 0.01));
                DataObj.Add('Val_CgstVal', CgstTotal);
                DataObj.Add('Val_SgstVal', SgstTotal);
                DataObj.Add('Val_IgstVal', IgstTotal);
                DataObj.Add('Val_CesVal', 0);
                DataObj.Add('Val_StCesVal', 0);
                DataObj.Add('Val_Discount', 0);
                DataObj.Add('Val_OthChrg', 0);
                DataObj.Add('Val_RndOffAmt', 0);
                DataObj.Add('Val_TotInvVal', Round(InvoiceTotal / Currencyfactor, 0.01));
                if Rec."GST Customer Type" = Rec."GST Customer Type"::Export then
                    DataObj.Add('Val_TotInvValFc', Round(InvoiceTotal, 0.01))
                else
                    DataObj.Add('Val_TotInvValFc', 0);

                DataObj.Add('Pay_Nm', '');
                DataObj.Add('Pay_AccDet', '');
                DataObj.Add('Pay_Mode', '');
                DataObj.Add('Pay_FinInsBr', '');
                DataObj.Add('Pay_PayTerm', '');
                DataObj.Add('Pay_PayInstr', '');
                DataObj.Add('Pay_CrTrn', '');
                DataObj.Add('Pay_DirDr', '');
                DataObj.Add('Pay_CrDay', '');
                DataObj.Add('Pay_PaidAmt', '');
                DataObj.Add('Pay_PaymtDue', '');

                // *** Ref fields: link back to original invoice for CRN ***
                DataObj.Add('Ref_InvRm', '');
                DataObj.Add('Ref_InvStDt', '');
                DataObj.Add('Ref_InvEndDt', '');
                if SalesInvHeader.Get(Rec."Applies-to Doc. No.") then begin
                    DataObj.Add('Ref_PrecDoc_InvNo', SalesInvHeader."Pre-Assigned No.");
                    DataObj.Add('Ref_PrecDoc_InvDt', Format(SalesInvHeader."Posting Date", 0, '<Day,2>/<Month,2>/<Year4>'));
                end else begin
                    DataObj.Add('Ref_PrecDoc_InvNo', '');
                    DataObj.Add('Ref_PrecDoc_InvDt', '');
                end;
                DataObj.Add('Ref_PrecDoc_OthRefNo', '');
                DataObj.Add('Ref_Contr_RecAdvRefr', '');
                DataObj.Add('Ref_Contr_RecAdvDt', '');
                DataObj.Add('Ref_Contr_TendRefr', '');
                DataObj.Add('Ref_Contr_ContrRefr', '');
                DataObj.Add('Ref_Contr_ExtRefr', '');
                DataObj.Add('Ref_Contr_ProjRefr', '');
                DataObj.Add('Ref_Contr_PORefr', '');
                DataObj.Add('Ref_Contr_PORefDt', '');
                DataObj.Add('AddlDoc_Url', '');
                DataObj.Add('AddlDoc_Docs', '');
                DataObj.Add('AddlDoc_Info', '');
                DataObj.Add('Exp_ShipBNo', '');
                DataObj.Add('Exp_ShipBDt', '');
                DataObj.Add('Exp_Port', '');
                DataObj.Add('Exp_RefClm', '');
                if Rec."GST Customer Type" = Rec."GST Customer Type"::Export then
                    DataObj.Add('Exp_ForCur', Rec."Currency Code")
                else
                    DataObj.Add('Exp_ForCur', '');

                CountryRegion.Reset();
                CountryRegion.SetRange(Code, Rec."Bill-to Country/Region Code");

                if CountryRegion.FindFirst() then
                    DataObj.Add('Exp_CntCode', CountryRegion."ISO Code")
                else
                    DataObj.Add('Exp_CntCode', '');

                DataObj.Add('Exp_ExpDuty', '');

                DataObj.Add('Ewb_TransId', '');
                DataObj.Add('Ewb_TransName', '');
                DataObj.Add('Ewb_TransMode', '');
                DataObj.Add('Ewb_Distance', '');
                DataObj.Add('Ewb_TransDocNo', '');
                DataObj.Add('Ewb_TransDocDt', '');
                DataObj.Add('Ewb_VehNo', '');
                DataObj.Add('Ewb_VehType', '');


                if Rec."Location GST Reg. No." = '' then
                    Error('Location GST Reg. No. is blank on Invoice %1. Please set the GST Registration No. on the Location card (Location: %2).', Rec."No.", Rec."Location Code");

                GstregNos.Reset();
                GSTRegNos.SetRange(Code, Rec."Location GST Reg. No.");

                if gstRegNos.FindFirst() then begin
                    DataObj.Add('CDKey', '1236623');
                    DataObj.Add('EFUserName', '02E6E172-2E9B-4A64-88E9-03930D925A0C');
                    DataObj.Add('EFPassword', '0CA20102-2A90-4385-9F3B-693E98929986');
                    DataObj.Add('EInvUserName', GSTRegNos."E-Invoice User Name");
                    DataObj.Add('EInvPassword', GSTRegNos."E-Invoice Password");
                    DataArray.Add(DataObj);
                end
                else
                    Error('GST Registration No. ''%1'' (used on Invoice %2, Location %3) was not found in the GST Registration Nos. table. Please add it there.',
                        Rec."Location GST Reg. No.", Rec."No.", Rec."Location Code");

            until SalesCrMemoLine.Next() = 0;
        end;

        PushData.Add('Data', DataArray);
        FinalObj.Add('Push_Data_List', PushData);
        FinalObj.WriteTo(JsonText);
        exit(JsonText);
    end;

    local procedure GetGSTAmountsForLine(DocNo: Code[20]; LineNo: Integer; LineAmount: Decimal; var IgstAmt: Decimal;
        var CgstAmt: Decimal;
        var SgstAmt: Decimal;
        var GstRate: Decimal;
        var PreTaxVal: Decimal)
    var
        DetailedGSTEntry: Record "Detailed GST Ledger Entry";
    begin
        IgstAmt := 0;
        CgstAmt := 0;
        SgstAmt := 0;
        GstRate := 0;
        PreTaxVal := Round(LineAmount, 0.01);

        DetailedGSTEntry.Reset();
        DetailedGSTEntry.SetRange("Document No.", DocNo);
        DetailedGSTEntry.SetRange("Document Line No.", LineNo);
        DetailedGSTEntry.SetRange("Entry Type", DetailedGSTEntry."Entry Type"::"Initial Entry");

        if DetailedGSTEntry.FindSet() then
            repeat
                case DetailedGSTEntry."GST Component Code" of
                    'IGST':
                        begin
                            IgstAmt += Abs(DetailedGSTEntry."GST Amount");
                            if GstRate = 0 then
                                GstRate := DetailedGSTEntry."GST %";
                        end;
                    'CGST':
                        begin
                            CgstAmt += Abs(DetailedGSTEntry."GST Amount");
                            if GstRate = 0 then
                                GstRate := DetailedGSTEntry."GST %" * 2;
                        end;
                    'SGST', 'UTGST':
                        begin
                            SgstAmt += Abs(DetailedGSTEntry."GST Amount");
                        end;
                end;
            until DetailedGSTEntry.Next() = 0;

        IgstAmt := Round(IgstAmt, 0.01);
        CgstAmt := Round(CgstAmt, 0.01);
        SgstAmt := Round(SgstAmt, 0.01);
    end;



    local procedure ProcessResponse(var Rec: Record "Sales Cr.Memo Header"; ResponseText: Text)
    var
        JToken: JsonToken;
        JObj: JsonObject;
        JArray: JsonArray;
        InnerToken: JsonToken;
        Status: Text;
        ErrorMsg: Text;
        QRText: Text;
        AckDateText: Text;
        AckDateTime: DateTime;
    begin
        if not JToken.ReadFrom(ResponseText) then
            Error('Invalid response: %1', ResponseText);

        if JToken.IsArray() then begin
            JArray := JToken.AsArray();
            JArray.Get(0, InnerToken);
            JObj := InnerToken.AsObject();
        end else
            JObj := JToken.AsObject();

        if JObj.Get('Status', JToken) then begin
            Status := JToken.AsValue().AsText();
            if Status = '1' then begin
                Rec."IRN No." := GetJsonValue(JObj, 'Irn');
                Rec."Ack No." := GetJsonValue(JObj, 'AckNo');
                if Evaluate(AckDateTime, GetJsonValue(JObj, 'AckDate')) then
                    Rec."Ack Date" := AckDateTime;
                Rec."IRN Status" := Rec."IRN Status"::Generated;

                QRText := GetJsonValue(JObj, 'SignedQRCode');
                if QRText <> '' then begin
                    Rec."QR Signed Code" := CopyStr(QRText, 1, MaxStrLen(Rec."QR Signed Code"));
                    GenerateAndStoreQRImage(Rec, QRText);
                end;

                Rec.Modify(true);
                Message('IRN Generated: %1', Rec."IRN No.");
            end else begin
                ErrorMsg := GetJsonValue(JObj, 'ErrorDetails');
                if ErrorMsg = '' then ErrorMsg := GetJsonValue(JObj, 'ErrorMessage');
                if ErrorMsg = '' then ErrorMsg := GetJsonValue(JObj, 'message');
                if ErrorMsg = '' then ErrorMsg := ResponseText;
                if Rec."IRN Status" = Rec."IRN Status"::Generated then begin
                    Message('IRN is already generated.' + '\' + ErrorMsg);
                    exit;
                end;


                Rec."IRN Status" := Rec."IRN Status"::Failed;
                Rec.Modify(true);
                Message('E-Invoice Failed!\n%1', ErrorMsg);
            end;
        end;
    end;


    local procedure GetJsonValue(JObj: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObj.Get(KeyName, JToken) then
            exit(JToken.AsValue().AsText());
        exit('');
    end;

    local procedure GenerateAndStoreQRImage(var Rec: Record "Sales Cr.Memo Header"; QRText: Text)
    var
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        InStr: InStream;
        OutStr: OutStream;
        HttpContent: HttpContent;
        Headers: HttpHeaders;
        JsonObj: JsonObject;
        JsonText: Text;
    begin
        if QRText = '' then
            exit;

        JsonObj.Add('text', QRText);
        JsonObj.Add('size', 400);
        JsonObj.WriteTo(JsonText);

        HttpContent.WriteFrom(JsonText);
        HttpContent.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'application/json');

        Client.Post('https://quickchart.io/qr', HttpContent, ResponseMessage);

        if ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content().ReadAs(InStr);
            Clear(Rec."QR Signed Code Image");
            Rec."QR Signed Code Image".CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
        end else
            Error('QR Image generation failed');
    end;
}