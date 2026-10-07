tableextension 50112 "Project Job Table Ext" extends Job
{


    fields
    {


        field(50650; "Project Type"; Enum "Project Type")
        {
            Caption = 'Project Type';
            DataClassification = CustomerContent;
        }

        field(50651; "Project Budget"; Decimal)
        {
            Caption = 'Project Budget';
            FieldClass = FlowField;

            CalcFormula = Sum(
                "Job Planning Line"."Total Cost"
                where(
                    "Job No." = field("No."),
                    "Schedule Line" = const(true)
                )
            );

            Editable = false;
        }

        field(50652; "Project Actual Cost"; Decimal)
        {
            Caption = 'Project Actual Cost';
            FieldClass = FlowField;

            CalcFormula = Sum("Job Ledger Entry"."Total Cost (LCY)"
                where("Job No." = field("No."), "Entry Type" = const(Usage)));

            Editable = false;
        }

        field(50653; "Project Billable Cost"; Decimal)
        {
            Caption = 'Project Billable Cost';
            FieldClass = FlowField;

            CalcFormula = Sum(
                "Job Planning Line"."Line Amount"
                where(
                    "Job No." = field("No."),
                    "Contract Line" = const(true)
                )
            );

            Editable = false;
        }

        field(50654; "Project Invoice Cost"; Decimal)
        {
            Caption = 'Project Invoice Cost';
            FieldClass = FlowField;

            CalcFormula = - Sum(
        "Job Ledger Entry"."Line Amount (LCY)"
        where(
            "Job No." = field("No."),
            "Entry Type" = const(Sale)
        )
    );

            Editable = false;
        }
    }
}