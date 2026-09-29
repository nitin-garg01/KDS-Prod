tableextension 50112 "Project Job  Table Ext " extends Job
{
    fields
    {
        field(50650; "Project Type"; Enum "Project Type")
        {
            Caption = 'Project Type';
            DataClassification = CustomerContent;
        }
    }
}
