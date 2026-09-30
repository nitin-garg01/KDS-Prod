tableextension 50113 "Job Planning Line Table Ext" extends "Job Planning Line"
{
    fields
    {
        field(50100; "Attach To Milestone"; Code[50])
        {
            Caption = 'Attach To Milestone';
            DataClassification = ToBeClassified;
            TableRelation = "Project Commission Calculation".Milestone
                where("Project No." = field("Job No."));
        }
    }
}
