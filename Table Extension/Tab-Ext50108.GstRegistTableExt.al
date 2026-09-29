tableextension 50108 "Gst Regist Table Ext" extends "GST Registration Nos."
{
    fields
    {
        field(50100; "E-Invoice User Name"; Text[100])
        {
            Caption = 'E-Invoice User Name';
            DataClassification = ToBeClassified;
        }
        field(50101; "E-Invoice Password"; Text[100])
        {
            Caption = 'E-Invoice Password';
            DataClassification = ToBeClassified;
        }
    }
}
