pageextension 50656 JobTaskLineSubformPageExt extends "Job Task Lines Subform"
{
    layout
    {
        addafter("Description")
        {
            field(Milestone; Rec.Milestone)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the milestone.';
            }
        }
        modify("Global Dimension 1 Code")
        {
            visible = true;
            Caption = 'Global Dimension 1 Code';

        }
        modify("Global Dimension 2 Code")
        {
            visible = true;
            Caption = 'Global Dimension 2 Code';
        }
    }
}
