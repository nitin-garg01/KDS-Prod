table 50152 "Project Commission"
{
    Caption = 'Project Commission';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Commission Level"; Code[50])
        {
            Caption = 'Level';
        }
        field(2; "Level Descritpion"; Text[250])
        {
            Caption = 'Level Descritpion';
        }
    }
    keys
    {
        key(PK; "Commission Level")
        {
            Clustered = true;
        }
    }
}
