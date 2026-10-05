pageextension 50655 "Job Planing Line Page Ext" extends "Job Planning Lines"
{
    layout
    {
        addafter("Document No.")
        {
            field("Is Commission ?"; Rec."Is Commission ?")
            {
                ApplicationArea = All;
                visible = true;
                ToolTip = 'Specifies the value of the Is Commission field.';
            }
            field("Attach To Milestone"; Rec."Attach To Milestone")
            {
                ApplicationArea = All;
                visible = true;
                Editable = Rec."Is Commission ?";
                ToolTip = 'Specifies the value of the Attach To Milestone field.';
            }
            field("Comm Level"; Rec."Comm Level")
            {
                ApplicationArea = All;
                visible = true;
                Editable = Rec."Is Commission ?";
                ToolTip = 'Specifies the value of the Commission Level field.';
            }

        }
    }
}
