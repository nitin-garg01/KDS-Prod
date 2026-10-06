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
    }
}
