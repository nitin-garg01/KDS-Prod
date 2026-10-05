tableextension 50113 "Job Planning Line Table Ext" extends "Job Planning Line"
{
    fields
    {
        field(50100; "Is Commission ?"; Boolean)
        {
            Caption = 'Is Commission ?';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                if not "Is Commission ?" then begin
                    Clear("Attach To Milestone");
                    Clear("Comm Level");
                end;
            end;
        }

        field(50101; "Attach To Milestone"; Code[50])
        {
            Caption = 'Attach To Milestone';
            DataClassification = ToBeClassified;

            TableRelation =
                "Project Commission Calculation".Milestone
                where("Project No." = field("Job No."));

            trigger OnValidate()
            begin
                if not "Is Commission ?" then begin
                    Clear("Attach To Milestone");
                    Clear("Comm Level");
                end;

                if "Attach To Milestone" = '' then
                    Clear("Comm Level");
            end;
        }

        field(50102; "Comm Level"; Code[20])
        {
            Caption = 'Commission Level';
            DataClassification = ToBeClassified;

            TableRelation =
                "Project Commission Calculation"."Commission Level";
        }
    }
}