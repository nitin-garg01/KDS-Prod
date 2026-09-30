page 50252 "Project Commission List Page"
{
    ApplicationArea = All;
    Caption = 'Project Commission List';
    PageType = List;
    SourceTable = "Project Commission";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Commission Level"; Rec."Commission Level")
                {
                    caption = 'Level';
                    ToolTip = 'Specifies the value of the Commission Level field.', Comment = '%';
                }
                field("Level Descritpion"; Rec."Level Descritpion")
                {
                    caption = 'Level Description';
                    ToolTip = 'Specifies the value of the Level Descritpion field.', Comment = '%';
                }
            }
        }
    }

}
