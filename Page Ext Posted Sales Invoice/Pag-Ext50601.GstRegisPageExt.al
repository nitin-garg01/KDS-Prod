pageextension 50601 "Gst Regis Page Ext" extends "GST Registration Nos."
{
    layout
    {
        addlast(General)
        {
            field("E-Invoice User Name"; Rec."E-Invoice User Name")
            {
                ApplicationArea = all;
                Visible = true;
                Caption = 'E-Invoice User Name';
            }
            field("E-Invoice Password"; Rec."E-Invoice Password")
            {
                ApplicationArea = all;
                Visible = true;
                Caption = 'E-Invoice Password';
            }
        }
    }
}
