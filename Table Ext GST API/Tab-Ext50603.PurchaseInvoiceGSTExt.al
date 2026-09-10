tableextension 50603 "Purchase Invoice GST Ext" extends "Purch. Inv. Header"
{
    fields
    {
        field(50900; "GST Upload Status"; Enum "GST Upload Status")
        {
            Caption = 'GST Upload Status';
            DataClassification = ToBeClassified;
            Description = 'Status of GST upload to compliance server';
        }

        field(50901; "GST Upload Error"; Text[1000])
        {
            Caption = 'GST Upload Error';
            DataClassification = ToBeClassified;
            Description = 'Error message from GST upload';
        }

    }
}
