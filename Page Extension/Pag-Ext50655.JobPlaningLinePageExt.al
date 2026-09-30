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
        }
    }
}
