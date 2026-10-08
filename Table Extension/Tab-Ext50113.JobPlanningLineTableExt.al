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
                if not "Is Commission ?" then
                    Clear("Comm Level");
            end;
        }

        field(50101; "Attach To Milestone"; Code[50])
        {
            Caption = 'Attach To Milestone';
            DataClassification = ToBeClassified;
            Editable = false;
        }

        field(50102; "Comm Level"; Code[20])
        {
            Caption = 'Commission Level';
            DataClassification = ToBeClassified;

            TableRelation = "Project Commission Calculation"."Commission Level"
        where("Project No." = field("Job No."), Milestone = field("Attach To Milestone"));

            trigger OnValidate()
            var
                ProjectCommission: Record "Project Commission Calculation";
            begin
                if not "Is Commission ?" then begin
                    Clear("Comm Level");
                    exit;
                end;

                if "Comm Level" = '' then
                    exit;

                ProjectCommission.Reset();
                ProjectCommission.SetRange("Project No.", "Job No.");
                ProjectCommission.SetRange(Milestone, "Attach To Milestone");
                ProjectCommission.SetRange("Commission Level", "Comm Level");

                if ProjectCommission.FindFirst() then begin

                    Validate("Unit Price", ProjectCommission."Commission Amount");
                end;
            end;
        }

        field(50103; "Payment Received"; Decimal)
        {
            Caption = 'Payment Received';
            DataClassification = ToBeClassified;
        }

        modify("Job Task No.")
        {
            trigger OnAfterValidate()
            var
                JobTask: Record "Job Task";
            begin
                if ("Job No." = '') or ("Job Task No." = '') then
                    exit;

                if JobTask.Get("Job No.", "Job Task No.") then
                    "Attach To Milestone" := JobTask.Milestone;
            end;
        }
    }
    procedure CalculatePaymentReceived(): Decimal
    var
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PaymentReceived: Decimal;
    begin

        if Rec."Invoiced Amount (LCY)" = 0 then
            exit(0);

        JobPlanningLineInvoice.SetRange("Job No.", Rec."Job No.");
        JobPlanningLineInvoice.SetRange("Job Task No.", Rec."Job Task No.");
        JobPlanningLineInvoice.SetRange("Job Planning Line No.", Rec."Line No.");
        JobPlanningLineInvoice.SetRange("Document Type", JobPlanningLineInvoice."Document Type"::"Posted Invoice");

        if JobPlanningLineInvoice.FindSet() then
            repeat
                CustLedgEntry.Reset();
                CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
                CustLedgEntry.SetRange("Document No.", JobPlanningLineInvoice."Document No.");

                if CustLedgEntry.FindSet() then
                    repeat
                        DetailedCustLedgEntry.Reset();
                        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
                        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
                        DetailedCustLedgEntry.SetRange(Unapplied, false);

                        if DetailedCustLedgEntry.FindSet() then
                            repeat
                                PaymentReceived += Abs(DetailedCustLedgEntry.Amount);
                            until DetailedCustLedgEntry.Next() = 0;
                    until CustLedgEntry.Next() = 0;
            until JobPlanningLineInvoice.Next() = 0;
        exit(PaymentReceived);
    end;
}