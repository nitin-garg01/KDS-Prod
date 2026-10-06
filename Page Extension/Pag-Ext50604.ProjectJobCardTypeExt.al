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

        addlast(Content)
        {
            group("Project Values")
            {
                Caption = 'Project Values';

                field("Project Budget"; Rec."Project Budget")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total project budget.';
                    Editable = false;
                }

                field("Project Actual Cost"; Rec."Project Actual Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the actual cost of the project.';
                    Editable = false;
                }

                field("Project Billable Cost"; Rec."Project Billable Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total billable cost of the project.';
                    Editable = false;
                    caption = 'Project Billable';
                }


                field("Project Invoice Cost"; Rec."Project Invoice Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total invoiced cost of the project.';
                    Editable = false;
                    caption = 'Project Invoiced';
                }
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