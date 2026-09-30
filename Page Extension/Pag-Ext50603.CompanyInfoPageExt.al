pageextension 50603 "Company Info Page Ext" extends "Company Information"
{
    layout
    {
        addlast(General)
        {
            group("Signature")
            {
                field("Signature "; Rec."Signature")
                {
                    ApplicationArea = All;
                    ShowCaption = true;
                    ToolTip = 'Signature';
                    caption = 'Signature ';
                }
            }
        }
    }
}
