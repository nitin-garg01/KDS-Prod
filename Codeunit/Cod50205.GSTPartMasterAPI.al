codeunit 50205 "GST Part Master API"
{
    SingleInstance = false;
    permissions = tabledata Vendor = RIMD,
                    tabledata Customer = RIMD,
                    tabledata "Company Information" = RIMD,
                    tabledata State = RIMD;

    procedure GetGSTApiUrl(): Text
    begin
        exit('http://103.100.217.51:81/gstapi/api/UploadData/Party');
    end;

    procedure GetGSTApiAuthorization(): Text
    begin
        exit('Authorization /IalkRmh3z4=:::ZH4TUvIeJ3A=');
    end;

    procedure BuildCustomerJson(CustomerNo: Code[20]; var JsonText: Text)
    var
        Customer: Record Customer;
        PartyArray: JsonArray;
        RootObject: JsonObject;
    begin
        Clear(JsonText);
        Clear(PartyArray);
        Clear(RootObject);

        if not Customer.Get(CustomerNo) then
            Error('Customer %1 not found.', CustomerNo);

        AddCustomer(PartyArray, Customer);
        RootObject.Add('Push_Data_List', PartyArray);
        RootObject.WriteTo(JsonText);
    end;

    procedure BuildVendorJson(VendorNo: Code[20]; var JsonText: Text)
    var
        Vendor: Record Vendor;
        PartyArray: JsonArray;
        RootObject: JsonObject;
    begin
        Clear(JsonText);
        Clear(PartyArray);
        Clear(RootObject);

        if not Vendor.Get(VendorNo) then
            Error('Vendor %1 not found.', VendorNo);

        AddVendor(PartyArray, Vendor);
        RootObject.Add('Push_Data_List', PartyArray);
        RootObject.WriteTo(JsonText);
    end;

    procedure ShowCustomerJson(CustomerNo: Code[20])
    var
        JsonText: Text;
    begin
        BuildCustomerJson(CustomerNo, JsonText);
        Message(JsonText);
    end;

    procedure ShowVendorJson(VendorNo: Code[20])
    var
        JsonText: Text;
    begin
        BuildVendorJson(VendorNo, JsonText);
        Message(JsonText);
    end;

    local procedure GetStateCode(StateCode: Code[10]): Code[10]
    var
        State: Record State;
    begin
        if State.Get(StateCode) then
            exit(State."State Code (GST Reg. No.)");

        exit('');
    end;

    local procedure IsRegistered(GSTNo: Code[20]): Integer
    begin
        if GSTNo <> '' then
            exit(1);

        exit(0);
    end;

    // =========================================================
    // ADD CUSTOMER
    // =========================================================

    local procedure AddCustomer(var PartyArray: JsonArray; Customer: Record Customer)
    var
        PartyObject: JsonObject;
        CompanyInfo: Record "Company Information";
    begin
        Clear(PartyObject);

        PartyObject.Add('PartyName', Customer.Name);
        PartyObject.Add('PartyCode', Customer."No.");
        PartyObject.Add('TIN', Customer."GST Registration No.");
        PartyObject.Add('UIN', '');// It can be blank for customers, as UIN is typically used for government entities.
        PartyObject.Add('PAN', Customer."P.A.N. No.");
        PartyObject.Add('Line1', Customer.Address);
        PartyObject.Add('StateCode', GetStateCode(Customer."State Code"));
        PartyObject.Add('City', Customer.City);
        PartyObject.Add('PIN', Customer."Post Code");
        PartyObject.Add('MobileNo', Customer."Mobile Phone No.");
        PartyObject.Add('Email', Customer."E-Mail");
        PartyObject.Add('IsCR', 1);
        PartyObject.Add('IsDR', 0);

        CompanyInfo.Get();

        PartyObject.Add('GSTIN', CompanyInfo."GST Registration No.");
        PartyObject.Add('IsPartyRegistered', IsRegistered(Customer."GST Registration No."));
        PartyObject.Add('UnitName', '');// it can be blank
        PartyObject.Add('PartyUnitCode', '');//it can be blank

        PartyArray.Add(PartyObject);
    end;

    // =========================================================
    // ADD VENDOR
    // =========================================================

    local procedure AddVendor(var PartyArray: JsonArray; Vendor: Record Vendor)
    var
        PartyObject: JsonObject;
        CompanyInfo: Record "Company Information";
    begin
        Clear(PartyObject);

        PartyObject.Add('PartyName', Vendor.Name);
        PartyObject.Add('PartyCode', Vendor."No.");
        PartyObject.Add('TIN', Vendor."GST Registration No.");
        PartyObject.Add('UIN', '');// It can be blank for vendors, as UIN is typically used for government entities.
        PartyObject.Add('PAN', Vendor."P.A.N. No.");
        PartyObject.Add('Line1', Vendor.Address);
        PartyObject.Add('StateCode', GetStateCode(Vendor."State Code"));
        PartyObject.Add('City', Vendor.City);
        PartyObject.Add('PIN', Vendor."Post Code");
        PartyObject.Add('MobileNo', Vendor."Mobile Phone No.");
        PartyObject.Add('Email', Vendor."E-Mail");
        PartyObject.Add('IsCR', 0);
        PartyObject.Add('IsDR', 1);

        CompanyInfo.Get();

        PartyObject.Add('GSTIN', CompanyInfo."GST Registration No.");
        PartyObject.Add('IsPartyRegistered', IsRegistered(Vendor."GST Registration No."));
        PartyObject.Add('UnitName', ''); // it can be blank
        PartyObject.Add('PartyUnitCode', '');// it can be blank

        PartyArray.Add(PartyObject);
    end;

    // =========================================================
    // UPLOAD CUSTOMER
    // =========================================================

    procedure UploadCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        JsonText: Text;
    begin
        if not Customer.Get(CustomerNo) then
            Error('Customer %1 not found.', CustomerNo);

        BuildCustomerJson(CustomerNo, JsonText);
        SendRequest(JsonText, Database::Customer, Customer."No.");
    end;

    // =========================================================
    // UPLOAD VENDOR
    // =========================================================

    procedure UploadVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        JsonText: Text;
    begin
        if not Vendor.Get(VendorNo) then
            Error('Vendor %1 not found.', VendorNo);

        BuildVendorJson(VendorNo, JsonText);
        SendRequest(JsonText, Database::Vendor, Vendor."No.");
    end;

    // =========================================================
    // SEND REQUEST
    // =========================================================

    local procedure SendRequest(JsonText: Text; TableID: Integer; No: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseText: Text;
        ErrorMsg: Text;
        JObject: JsonObject;
        Token: JsonToken;
        IsSuccess: Boolean;
    begin
        Content.WriteFrom(JsonText);

        Content.GetHeaders(ContentHeaders);

        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');

        ContentHeaders.Add('Content-Type', 'application/json');

        RequestHeaders := Client.DefaultRequestHeaders();

        if RequestHeaders.Contains('Authorization') then
            RequestHeaders.Remove('Authorization');

        if not RequestHeaders.TryAddWithoutValidation('Authorization', GetGSTApiAuthorization()) then begin
            UpdateUploadStatus(TableID, No, false, 'Unable to add Authorization header.');
            Error('Unable to add Authorization header.');
        end;

        Client.Timeout := 30000;

        if not Client.Post(GetGSTApiUrl(), Content, Response) then begin
            ErrorMsg := GetLastErrorText();

            if ErrorMsg = '' then
                ErrorMsg := 'Unable to connect to GST API server.';

            UpdateUploadStatus(TableID, No, false, ErrorMsg);
            Error('GST API Connection Failed:\%1', ErrorMsg);
        end;

        Response.Content().ReadAs(ResponseText);
        Clear(JObject);
        Clear(Token);

        if not Token.ReadFrom(ResponseText) then begin
            ErrorMsg := 'Invalid JSON response from GST API: ' + ResponseText;
            UpdateUploadStatus(TableID, No, false, ErrorMsg);
            Error('%1', ErrorMsg);
        end;



        if Token.IsValue() then begin
            ResponseText := Token.AsValue().AsText();

            if not JObject.ReadFrom(ResponseText) then begin
                ErrorMsg := 'Invalid JSON response from GST API: ' + ResponseText;
                UpdateUploadStatus(TableID, No, false, ErrorMsg);
                Error('%1', ErrorMsg);
            end;
        end else begin
            if Token.IsObject() then
                JObject := Token.AsObject()
            else begin
                ErrorMsg := 'Invalid JSON response from GST API: ' + ResponseText;
                UpdateUploadStatus(TableID, No, false, ErrorMsg);
                Error('%1', ErrorMsg);
            end;
        end;

        Clear(IsSuccess);

        if JObject.Get('IsSuccess', Token) then
            IsSuccess := Token.AsValue().AsBoolean();

        Clear(ErrorMsg);

        if JObject.Get('Error', Token) then
            ErrorMsg := Token.AsValue().AsText();

        if ErrorMsg = '' then
            ErrorMsg := GetErrorListMessage(JObject);

        // =====================================================
        // CUSTOMER STATUS
        // =====================================================

        if TableID = Database::Customer then begin
            if Customer.Get(No) then begin
                if IsSuccess then begin
                    Customer."GST Upload Status" := Customer."GST Upload Status"::Success;
                    Customer."GST Upload Error" := '';
                end else begin
                    Customer."GST Upload Status" := Customer."GST Upload Status"::Failed;
                    Customer."GST Upload Error" := CopyStr(ErrorMsg, 1, MaxStrLen(Customer."GST Upload Error"));
                end;

                Customer.Modify(true);

            end;
        end;

        // =====================================================
        // VENDOR STATUS
        // =====================================================

        if TableID = Database::Vendor then begin
            if Vendor.Get(No) then begin
                if IsSuccess then begin
                    Vendor."GST Upload Status" := Vendor."GST Upload Status"::Success;
                    Vendor."GST Upload Error" := '';
                end else begin
                    Vendor."GST Upload Status" := Vendor."GST Upload Status"::Failed;
                    Vendor."GST Upload Error" := CopyStr(ErrorMsg, 1, MaxStrLen(Vendor."GST Upload Error"));
                end;

                Vendor.Modify(true);
            end;
        end;
        if IsSuccess then begin
            Message(
                'Party Master uploaded successfully.\Response:\%1',
                ResponseText
            );
        end else begin
            Error(
                'Upload Failed.\%1',
                ErrorMsg
            );
        end;
    end;



    local procedure GetErrorListMessage(JObject: JsonObject): Text
    var
        Token: JsonToken;
        ErrorArray: JsonArray;
        ErrorToken: JsonToken;
        ErrorObject: JsonObject;
    begin
        if JObject.Get('ErrorList', Token) then begin
            ErrorArray := Token.AsArray();

            if ErrorArray.Count > 0 then begin
                ErrorArray.Get(0, ErrorToken);
                ErrorObject := ErrorToken.AsObject();

                if ErrorObject.Get('ErrorMessage', Token) then
                    exit(Token.AsValue().AsText());
            end;
        end;

        exit('');
    end;



    local procedure UpdateUploadStatus(TableID: Integer; No: Code[20]; Success: Boolean; ErrorMsg: Text)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;

    begin
        if TableID = Database::Customer then begin
            if Customer.Get(No) then begin
                if Success then begin
                    Customer."GST Upload Status" := Customer."GST Upload Status"::Success;
                    Customer."GST Upload Error" := '';
                end else begin
                    Customer."GST Upload Status" := Customer."GST Upload Status"::Failed;
                    Customer."GST Upload Error" := CopyStr(ErrorMsg, 1, MaxStrLen(Customer."GST Upload Error"));
                end;

                Customer.Modify(true);
            end;
        end;

        if TableID = Database::Vendor then begin
            if Vendor.Get(No) then begin
                if Success then begin
                    Vendor."GST Upload Status" := Vendor."GST Upload Status"::Success;
                    Vendor."GST Upload Error" := '';
                end else begin
                    Vendor."GST Upload Status" := Vendor."GST Upload Status"::Failed;
                    Vendor."GST Upload Error" := CopyStr(ErrorMsg, 1, MaxStrLen(Vendor."GST Upload Error"));
                end;

                Vendor.Modify(true);
            end;
        end;
    end;
}