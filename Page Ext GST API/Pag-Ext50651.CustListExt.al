pageextension 50651 "Customer Card GST Ext" extends "Customer Card"
{

    layout
    {
        addlast(General)
        {
            group("GST API")
            {
                Caption = 'GST API';
                field("GST Upload Status"; Rec."GST Upload Status")
                {
                    Editable = false;
                    ApplicationArea = All;
                }
                field("GST Upload Error"; Rec."GST Upload Error")
                {
                    Editable = false;
                    ApplicationArea = All;
                    visible = false;
                }
            }
        }
    }
    actions
    {
        addlast(Processing)
        {
            action(ShowCustomerJson)
            {
                Caption = 'Show Customer JSON';
                ApplicationArea = All;

                trigger OnAction()
                var
                    GSTPartyJSONBuilder: Codeunit "GST Part Master API";

                begin
                    GSTPartyJSONBuilder.ShowCustomerJson(Rec."No.");
                end;
            }

            action(UploadGSTData)
            {
                Caption = 'Upload GST Data';
                Image = SendTo;

                ApplicationArea = All;

                trigger OnAction()
                var
                    GSTJson: Codeunit "GST Part Master API";
                begin
                    GSTJson.UploadCustomer(Rec."No.");
                    CurrPage.Update(true);
                end;
            }
        }
    }
}