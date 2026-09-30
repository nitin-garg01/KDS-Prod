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

            trigger OnValidate()
            var
                JobRec: Record Job;
            begin
                Clear("Project Descritpion");

                if "Project No." = '' then
                    exit;

                if JobRec.Get("Project No.") then
                    "Project Descritpion" := JobRec.Description;
            end;

        }
        field(2; "Project Descritpion"; Text[100])
        {
            Caption = 'Project Descritpion ';
            editable = false;
        }
        field(3; Milestone; Code[50])
        {

            Caption = 'Milestone';
            TableRelation = "Project Milestone"."Code";
        }
        field(4; "% Comletion"; Decimal)
        {
            Caption = '% Comletion';
            DecimalPlaces = 0 : 2;
            trigger OnValidate()
            begin
                if "% Comletion" < 0 then
                    Error('%1 cannot be less than 0.', FieldCaption("% Comletion"));

                if "% Comletion" > 100 then
                    Error('%1 cannot be greater than 100.', FieldCaption("% Comletion"));
            end;
        }
        field(5; "Milestone Amount"; Decimal)
        {
            Caption = 'Milestone Amount';
            DecimalPlaces = 0 : 2;
        }
        field(6; "Payment Receive Applicable"; Boolean)
        {
            Caption = 'Payment Receive Applicable';
        }
        field(7; "Commission Level Applicable"; Boolean)
        {
            Caption = 'Commission Level Applicable';
        }
        field(8; "Commission Level"; Code[20])
        {
            Caption = 'Commission Level';
            TableRelation = "Project Commission"."Commission Level";
        }
        field(9; "Payable To Type"; option)
        {
            Caption = 'Payable To Type';
            OptionCaption = 'Employee,Vendor';
            optionMembers = Employee,Vendor;
            trigger OnValidate()
            begin
                clear("No.");
            end;
        }
        field(10; "No."; Text[100])
        {
            Caption = 'No.';
            TableRelation =
        if ("Payable To Type" = const(Employee)) Employee."No."
            else if ("Payable To Type" = const(Vendor)) Vendor."No.";
        }
    }
    keys
    {
        key(PK; "Project No.", Milestone, "Commission Level")
        {
            Clustered = true;
        }
    }
}
