codeunit 50203 "E-Invoice Cancel CR Prod"
{
    Permissions = tabledata "Sales Cr.Memo Header" = rimd;

    procedure CancelIRN(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        Client: HttpClient;
        Content: HttpContent;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        JsonText: Text;
        ResultText: Text;
    begin
        JsonText := GetCancelJSON(SalesCrMemoHeader);
        message(JsonText);

        Content.WriteFrom(JsonText);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');
        if Client.Post('http://einvlive.webtel.in/v1.03/CanIRN', Content, Response) then begin
            Response.Content().ReadAs(ResultText);
            if Response.IsSuccessStatusCode() then
                ProcessCancelResponse(SalesCrMemoHeader, ResultText)
            else
                Error('Cancel API Error: %1', ResultText);
        end;
    end;

    local procedure SaveJSONResponse(var Rec: Record "Sales Cr.Memo Header"; ResponseText: Text)
    var
        OutStream: OutStream;
    begin
        Rec.JSONResponse.CreateOutStream(OutStream);
        OutStream.WriteText(ResponseText);
        Rec.Modify(true);
    end;


    local procedure GetCancelJSON(Rec: Record "Sales Cr.Memo Header") JsonText: Text
    var
        DataObj: JsonObject;
        DataArray: JsonArray;
        PushData: JsonObject;
        FinalObj: JsonObject;
        GSTRegNos: Record "GST Registration Nos.";
    //  CancelTable: Record "Posted Sales Cancel Detail";
    begin
        GSTRegNos.Reset();
        GSTRegNos.SetRange(Code, Rec."Location GST Reg. No.");
        if not GSTRegNos.FindFirst() then
            Error('GST Registration No. %1 not found.', Rec."Location GST Reg. No.");

        DataObj.Add('Irn', Rec."IRN No.");
        DataObj.Add('Gstin', GstRegNos.Code);
        DataObj.Add('CnlRsn', Rec."IRN Cancel Reason");
        DataObj.Add('CnlRem', Rec."IRN Cancel Remarks");
        DataObj.Add('CDKey', '1236623');
        DataObj.Add('EFUserName', '02E6E172-2E9B-4A64-88E9-03930D925A0C');
        DataObj.Add('EFPassword', '0CA20102-2A90-4385-9F3B-693E98929986');
        DataObj.Add('EInvUserName', GSTRegNos."E-Invoice User Name");
        DataObj.Add('EInvPassword', GSTRegNos."E-Invoice Password");

        DataArray.Add(DataObj);
        PushData.Add('Data', DataArray);
        FinalObj.Add('Push_Data_List', PushData);
        FinalObj.WriteTo(JsonText);
        Message(JsonText);
        exit(JsonText);
    end;

    local procedure ProcessCancelResponse(var Rec: Record "Sales Cr.Memo Header"; ResponseText: Text)
    var
        JToken: JsonToken;
        JObj: JsonObject;
        JArray: JsonArray;
        InnerToken: JsonToken;
        Status: Text;
        CancelDateText: Text;
        CancelDateTime: DateTime;
        CancelDate: Date;
        CancelTime: Time;
        ErrorMsg: Text;
    begin
        if not JToken.ReadFrom(ResponseText) then
            Error('Invalid response: %1', ResponseText);

        if JToken.IsArray() then begin
            JArray := JToken.AsArray();
            JArray.Get(0, InnerToken);
            JObj := InnerToken.AsObject();
        end else
            JObj := JToken.AsObject();

        Status := GetJsonValue(JObj, 'Status');

        if Status = '1' then begin

            CancelDateText := GetJsonValue(JObj, 'CancelDate');

            if CancelDateText <> '' then
                if Evaluate(CancelDate, CopyStr(CancelDateText, 1, 10)) then begin

                    if Evaluate(CancelTime, CopyStr(CancelDateText, 12, 8)) then
                        CancelDateTime := CreateDateTime(CancelDate, CancelTime)
                    else
                        CancelDateTime := CreateDateTime(CancelDate, 0T);

                    Rec."Cancel Date" := CancelDateTime;
                end;


            Clear(Rec."Ack No.");
            Clear(Rec."Ack Date");
            Clear(Rec."QR Signed Code Image");


            Rec."IRN Status" := Rec."IRN Status"::Cancelled;

            Rec.Modify(true);
            // Commit();

            Message('IRN Cancelled Successfully.\' + 'Cancel Date : %1', Rec."Cancel Date");

        end else begin

            ErrorMsg := GetJsonValue(JObj, 'ErrorMessage');

            if ErrorMsg = '' then
                ErrorMsg := ResponseText;

            Error(ErrorMsg);
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

    procedure ShowCancelJSON(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        JsonText: Text;
    begin
        JsonText := GetCancelJSON(SalesCrMemoHeader);
        Message(JsonText);
    end;

}