// codeunit 50232 "E-Invoice Cancel IRN"
// {
//     Permissions = tabledata "Sales Invoice Header" = rimd,
//                   tabledata "GST Registration Nos." = rimd;

//     procedure CancelIRN(var SalesInvHeader: Record "Sales Invoice Header")
//     var
//         Client: HttpClient;
//         Content: HttpContent;
//         Response: HttpResponseMessage;
//         Headers: HttpHeaders;
//         JsonText: Text;
//         ResultText: Text;
//         FreshRec: Record "Sales Invoice Header";
//     begin
//         if SalesInvHeader."IRN No." = '' then
//             Error('IRN not generated.');

//         JsonText := GetCancelJSON(SalesInvHeader);

//         //JsonText := GetCancelJSON(SalesInvHeader);
//         Message(JsonText);

//         Content.WriteFrom(JsonText);

//         Content.GetHeaders(Headers);
//         Headers.Clear();
//         Headers.Add('Content-Type', 'application/json');

//         if Client.Post('http://einvsandbox.webtel.in/v1.03/CanIRN', Content, Response)
//         then begin
//             Response.Content().ReadAs(ResultText);
//             if Response.IsSuccessStatusCode() then begin
//                 FreshRec.Get(SalesInvHeader."No.");

//                 ProcessCancelResponse(FreshRec, ResultText);

//                 SalesInvHeader := FreshRec;

//             end else
//                 Error('Cancel API Error: %1', ResultText);

//         end else
//             Error('Server not reachable.');
//     end;

//     local procedure GetCancelJSON(Rec: Record "Sales Invoice Header") JsonText: Text
//     var
//         DataObj: JsonObject;
//         DataArray: JsonArray;
//         PushData: JsonObject;
//         FinalObj: JsonObject;
//         GSTRegNos: Record "GST Registration Nos.";
//         CancelReasonCode: Integer;
//     begin
//         GSTRegNos.Reset();
//         GSTRegNos.SetRange(Code, Rec."Location GST Reg. No.");

//         if not GSTRegNos.FindFirst() then
//             Error('GST Registration No. %1 not found.', Rec."Location GST Reg. No.");

//         case Rec."IRN Cancel Reason" of
//             Rec."IRN Cancel Reason"::Others:
//                 CancelReasonCode := 1;

//             Rec."IRN Cancel Reason"::Duplicate:
//                 CancelReasonCode := 2;

//             Rec."IRN Cancel Reason"::DataEntryMistake:
//                 CancelReasonCode := 3;

//             Rec."IRN Cancel Reason"::OrderCancelled:
//                 CancelReasonCode := 4;
//         end;

//         DataObj.Add('Irn', Rec."IRN No.");
//         DataObj.Add('Gstin', '29AAACW3775F000');

//         // Numeric Reason Code
//         DataObj.Add('CnlRsn', CancelReasonCode);

//         // Remarks
//         DataObj.Add('CnlRem', Rec."IRN Cancel Remarks");

//         DataObj.Add('CDKey', '1000687');

//         DataObj.Add('EFUserName', GSTRegNos."E-Invoice User Name");
//         DataObj.Add('EFPassword', GSTRegNos."E-Invoice Password");

//         DataObj.Add('EInvUserName', GSTRegNos."E-Invoice User Name");
//         DataObj.Add('EInvPassword', GSTRegNos."E-Invoice Password");

//         DataArray.Add(DataObj);

//         PushData.Add('Data', DataArray);

//         FinalObj.Add('Push_Data_List', PushData);

//         FinalObj.WriteTo(JsonText);

//         exit(JsonText);
//     end;

//     local procedure ProcessCancelResponse(
//         var Rec: Record "Sales Invoice Header";
//         ResponseText: Text)
//     var
//         JToken: JsonToken;
//         JObj: JsonObject;
//         JArray: JsonArray;
//         InnerToken: JsonToken;
//         Status: Text;
//         CancelDateText: Text;
//         CancelDateTime: DateTime;
//         CancelDate: Date;
//         CancelTime: Time;
//         ErrorMsg: Text;
//     begin
//         if not JToken.ReadFrom(ResponseText) then
//             Error('Invalid response: %1', ResponseText);

//         if JToken.IsArray() then begin
//             JArray := JToken.AsArray();
//             JArray.Get(0, InnerToken);
//             JObj := InnerToken.AsObject();
//         end else
//             JObj := JToken.AsObject();
//         Status := GetJsonValue(JObj, 'Status');
//         if Status = '1' then begin
//             CancelDateText := GetJsonValue(JObj, 'CancelDate');
//             if CancelDateText <> '' then
//                 if Evaluate(CancelDate, CopyStr(CancelDateText, 1, 10)) then begin

//                     if Evaluate(CancelTime, CopyStr(CancelDateText, 12, 8)) then
//                         CancelDateTime := CreateDateTime(CancelDate, CancelTime)
//                     else
//                         CancelDateTime := CreateDateTime(CancelDate, 0T);

//                     Rec."Cancel Date" := CancelDateTime;
//                 end;
//             Clear(rec."Ack No.");
//             Clear(Rec."Ack Date");
//             Clear(Rec."QR Signed Code Image");
//             Rec."IRN Status" := Rec."IRN Status"::Cancelled;

//             Rec.Modify(true);
//             Message('IRN Cancelled Successfully.\' + 'Cancel Date : %1', Rec."Cancel Date");

//         end else begin

//             ErrorMsg := GetJsonValue(JObj, 'ErrorMessage');

//             if ErrorMsg = '' then
//                 ErrorMsg := ResponseText;

//             Error(ErrorMsg);
//         end;
//     end;

//     local procedure GetJsonValue(JObj: JsonObject; KeyName: Text): Text
//     var
//         JToken: JsonToken;
//     begin
//         if JObj.Get(KeyName, JToken) then
//             exit(JToken.AsValue().AsText());
//         exit('');
//     end;


// }