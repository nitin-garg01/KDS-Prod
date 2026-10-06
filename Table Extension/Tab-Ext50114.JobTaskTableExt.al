tableextension 50114 JobTaskTableExt extends "Job Task"
{
    fields
    {
        field(50100; Milestone; Code[50])
        {
            Caption = 'Milestone';
            DataClassification = ToBeClassified;
            tableRelation = "Project Milestone".Code;
            trigger OnValidate()
            var
                JobPlanningLine: Record "Job Planning Line";
            begin
                JobPlanningLine.Reset();
                JobPlanningLine.SetRange("Job No.", "Job No.");
                JobPlanningLine.SetRange("Job Task No.", "Job Task No.");

                if JobPlanningLine.FindSet(true) then
                    repeat
                        JobPlanningLine."Attach To Milestone" := Milestone;
                        JobPlanningLine.Modify(true);
                    until JobPlanningLine.Next() = 0;
            end;
        }
    }
}
