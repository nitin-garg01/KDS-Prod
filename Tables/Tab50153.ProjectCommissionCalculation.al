table 50153 "Project Commission Calculation"
{
    Caption = 'Project Commission Calculation';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Project No."; Code[50])
        {
            Caption = 'Project No.';
            TableRelation = Job."No.";
            Editable = false;

            trigger OnValidate()
            var
                JobRec: Record Job;
            begin
                Clear("Project Descritpion");
                Clear("Milestone Amount");
                Clear("Commission Amount");

                if "Project No." = '' then
                    exit;

                if JobRec.Get("Project No.") then
                    "Project Descritpion" := JobRec.Description;

                CalculateMilestoneAmount();
            end;
        }

        field(2; "Project Descritpion"; Text[100])
        {
            Caption = 'Project Descritpion';
            Editable = false;
        }

        field(3; Milestone; Code[50])
        {
            Caption = 'Milestone';

            TableRelation = "Project Milestone"."Code";

            trigger OnValidate()
            begin
                Clear("Milestone Amount");
                Clear("Commission Amount");

                CalculateMilestoneAmount();
            end;
        }

        field(4; "% Comletion"; Decimal)
        {
            Caption = '% Comletion';
            DecimalPlaces = 0 : 2;

            trigger OnValidate()
            begin
                if "% Comletion" < 0 then
                    Error(
                        '%1 cannot be less than 0.',
                        FieldCaption("% Comletion"));

                if "% Comletion" > 100 then
                    Error(
                        '%1 cannot be greater than 100.',
                        FieldCaption("% Comletion"));

                CalculateMilestoneAmount();
            end;
        }

        field(5; "Milestone Amount"; Decimal)
        {
            Caption = 'Milestone Amount';
            DecimalPlaces = 0 : 2;
            Editable = false;
        }

        field(6; "Payment Receive Applicable"; Boolean)
        {
            Caption = 'Payment Receive Applicable';
        }

        field(7; "Commission Level Applicable"; Boolean)
        {
            Caption = 'Commission Level Applicable';
            //  Visible = false;

            trigger OnValidate()
            begin
                if not "Commission Level Applicable" then begin
                    Clear("Commission Level");
                    Clear("Commission Level %");
                    Clear("Commission Amount");
                end;
            end;
        }

        field(8; "Commission Level"; Code[20])
        {
            Caption = 'Commission Level';

            TableRelation = "Project Commission"."Commission Level";

            trigger OnValidate()
            begin
                CalculateCommissionAmount();
            end;
        }

        field(9; "Commission Level %"; Decimal)
        {
            Caption = 'Commission Level %';
            DecimalPlaces = 0 : 2;

            trigger OnValidate()
            begin
                if "Commission Level %" < 0 then
                    Error(
                        '%1 cannot be less than 0.',
                        FieldCaption("Commission Level %"));

                if "Commission Level %" > 100 then
                    Error(
                        '%1 cannot be greater than 100.',
                        FieldCaption("Commission Level %"));

                CalculateCommissionAmount();
            end;
        }

        field(10; "Commission Amount"; Decimal)
        {
            Caption = 'Commission Amount';
            DecimalPlaces = 0 : 2;
            Editable = false;
        }

        field(11; "Payable To Type"; Option)
        {
            Caption = 'Payable To Type';
            OptionCaption = 'Employee,Vendor';
            OptionMembers = Employee,Vendor;

            trigger OnValidate()
            begin
                Clear("No.");
            end;
        }

        field(12; "No."; Text[100])
        {
            Caption = 'No.';

            TableRelation =
                if ("Payable To Type" = const(Employee))
                    Employee."No."
            else
            if ("Payable To Type" = const(Vendor))
                        Vendor."No.";
        }
    }

    keys
    {
        key(PK; "Project No.", Milestone, "Commission Level")
        {
            Clustered = true;
        }
    }

    local procedure CalculateMilestoneAmount()
    var
        JobPlanningLine: Record "Job Planning Line";
        TotalBillableAmount: Decimal;
    begin
        TotalBillableAmount := 0;

        if "Project No." = '' then begin
            "Milestone Amount" := 0;
            "Commission Amount" := 0;
            exit;
        end;

        JobPlanningLine.Reset();
        JobPlanningLine.SetRange("Job No.", "Project No.");
        JobPlanningLine.SetRange("Contract Line", true);

        if JobPlanningLine.FindSet() then
            repeat
                TotalBillableAmount += JobPlanningLine."Line Amount";
            until JobPlanningLine.Next() = 0;

        "Milestone Amount" :=
            Round(
                TotalBillableAmount * "% Comletion" / 100,
                0.01);

        CalculateCommissionAmount();
    end;

    local procedure CalculateCommissionAmount()
    begin
        if ("Milestone Amount" = 0) or
           ("Commission Level %" = 0)
        then begin
            "Commission Amount" := 0;
            exit;
        end;

        "Commission Amount" :=
            Round(
                "Milestone Amount" * "Commission Level %" / 100,
                0.01);
    end;
}