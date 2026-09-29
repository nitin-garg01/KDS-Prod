pageextension 50604 "Project Job Card Type Ext" extends "Job Card"
{
    layout
    {
        addafter("Description")
        {
            field("Project Type"; Rec."Project Type")
            {
                Visible = true;
                ApplicationArea = All;
                ToolTip = 'Specifies the type of the project.';
            }
        }
    }
    actions
    {
        addafter("F&unctions")
        {
            action("Project Commission Calculation")
            {
                ApplicationArea = All;
                Caption = 'Project Commission Calculation Details';
                Image = Calculate;
                ToolTip = 'Open the commission calculation details for the current project.';

                RunObject = page "Project Comm Calculation";
                RunPageLink = "Project No." = field("No.");
            }
        }
    }
}