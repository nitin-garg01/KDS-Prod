page 50251 "Project Milestone List Page"
{
    ApplicationArea = All;
    Caption = 'Project Milestone List';
    PageType = List;
    SourceTable = "Project Milestone";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code "; Rec."Code")
                {
                    ToolTip = 'Specifies the value of the Code field.', Comment = '%';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                }
            }
        }
    }
}
