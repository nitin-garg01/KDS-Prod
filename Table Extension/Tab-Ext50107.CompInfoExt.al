tableextension 50107 "Comp Info Ext" extends "Company Information"
{            
    fields
    {
       field(50100; "Signature"; Blob)
        {
            Caption = 'Signature ';
            DataClassification = CustomerContent;
            subtype = bitmap;
        }
    }
}
