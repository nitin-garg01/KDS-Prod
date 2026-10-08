pageextension 50655 "Job Planing Line Page Ext" extends "Job Planning Lines"
{
    layout
    {
        addafter("Document No.")
        {
            field("Attach To Milestone"; Rec."Attach To Milestone")
            {
                ApplicationArea = All;
                visible = true;

                ToolTip = 'Specifies the value of the Attach To Milestone field.';
            }
            field("Is Commission ?"; Rec."Is Commission ?")
            {
                ApplicationArea = All;
                visible = true;
                ToolTip = 'Specifies the value of the Is Commission field.';
            }

            field("Comm Level"; Rec."Comm Level")
            {
                ApplicationArea = All;
                visible = true;
                Editable = Rec."Is Commission ?";
                ToolTip = 'Specifies the value of the Commission Level field.';
            }

        }
        addafter("Invoiced Amount (LCY)")
        {
            field(PaymentReceivedCalc; Rec.CalculatePaymentReceived())
            {
                ApplicationArea = All;
                Caption = 'Payment Received';
                Visible = true;
                Editable = false;
                ToolTip = 'Specifies the payment received against the posted invoice of this line.';
            }
        }

        //modify("Unit Price")
        // {
        //     Visible = true;
        //     Editable = Rec."Is Commission ?";
        //     ToolTip = 'Specifies the value of the Unit Price field.';
        // }
        modify("Line Amount")
        {
            ApplicationArea = All;
            visible = true;
            editable = false;
            ToolTip = 'Specifies the value of the Line Amount field.';
        }

    }


}
