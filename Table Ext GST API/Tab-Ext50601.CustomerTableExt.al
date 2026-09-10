tableextension 50601 "Customer GST Ext" extends Customer
{

    fields
    {
        field(50900; "GST Upload Status"; Enum "GST Upload Status")
        {
            Caption = 'GST Upload Status';
            DataClassification = CustomerContent;
        }
        field(50901; "GST Upload Error"; Text[250])
        {
            Caption = 'GST Upload Error';
            DataClassification = CustomerContent;
        }
    }
}