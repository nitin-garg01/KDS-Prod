page 50253 "Project Comm Calculation"
{
    ApplicationArea = All;
    Caption = 'Project Commission Calculation';
    PageType = List;
    SourceTable = "Project Commission Calculation";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Project No."; Rec."Project No.")
                {
                    ToolTip = 'Specifies the value of the Project No. field.', Comment = '%';
                }
                field("Project Descritpion"; Rec."Project Descritpion")
                {
                    ToolTip = 'Specifies the value of the Project Descritpion field.', Comment = '%';
                }
                field(Milestone; Rec.Milestone)
                {
                    ToolTip = 'Specifies the value of the Milestone field.', Comment = '%';
                }
                field("% Comletion"; Rec."% Comletion")
                {
                    ToolTip = 'Specifies the value of the % Comletion field.', Comment = '%';
                }
                field("Milestone Amount"; Rec."Milestone Amount")
                {
                    ToolTip = 'Specifies the value of the Milestone Amount field.', Comment = '%';
                }
                field("Payment Receive Applicable"; Rec."Payment Receive Applicable")
                {
                    ToolTip = 'Specifies the value of the Payment Receive Applicable field.', Comment = '%';
                }
                field("Commission Level Applicable"; Rec."Commission Level Applicable")
                {
                    ToolTip = 'Specifies the value of the Commission Level Applicable field.', Comment = '%';
                    Visible = false;
                }
                field("Commission Level"; Rec."Commission Level")
                {
                    ToolTip = 'Specifies the value of the Commission Level field.', Comment = '%';
                }
                field(payableToType; Rec."Payable To Type")
                {
                    ToolTip = 'Specifies the value of the Payable To Type field.', Comment = '%';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the No. field.', Comment = '%';
                }

            }
        }
    }
}
