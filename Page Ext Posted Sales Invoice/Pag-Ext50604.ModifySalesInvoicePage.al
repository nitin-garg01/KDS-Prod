pageextension 50604 "Modify Sales Invoice Page " extends "Sales Invoice"
{
    layout
    {
        addafter("Posting Date")
        {
            field("Posting No. Series"; Rec."Posting No. Series")
            {
                ApplicationArea = All;
                Caption = 'Posting No. Series';
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales invoices when they are posted.';
                Visible = true;
                editable = false;
            }
        }
        addafter("Posting No. Series")
        {
            field(postingNo; Rec."Posting No.")
            {
                ApplicationArea = All;
                Caption = 'Posting No.';
                ToolTip = 'Specifies the number that will be assigned to sales invoices when they are posted.';
                Visible = true;
                editable = false;
            }
        }
        addafter("Work Description")
        {
            field("Currency Factor"; Rec."Currency Factor")
            {
                ApplicationArea = All;
                Caption = 'Currency Factor';
                ToolTip = 'Specifies the factor used to convert the amount on the sales invoice to the currency of the customer.';
                Visible = true;
                editable = false;
            }

        }

    }


}
