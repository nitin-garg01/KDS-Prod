
pageextension 50655 "Job Planing Line Page Ext" extends "Job Planning Lines"
{
    layout
    {
        addafter("Document No.")
        {
            field("Attach To Milestone"; Rec."Attach To Milestone")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Specifies the milestone.';
            }

            field("Is Commission ?"; Rec."Is Commission ?")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Specifies whether this is a commission line.';
            }

            field("Comm Level"; Rec."Comm Level")
            {
                ApplicationArea = All;
                Visible = true;
                ToolTip = 'Specifies the commission level.';

                trigger OnValidate()
                var
                    ProjectCommissionCalc: Record "Project Commission Calculation";
                begin
                    // Standard process for non-commission lines
                    if not Rec."Is Commission ?" then
                        exit;

                    // Clear Unit Cost when level is removed
                    if Rec."Comm Level" = '' then begin
                        Rec.Validate("Unit Cost", 0);
                        CurrPage.Update(false);
                        exit;
                    end;

                    // Quantity must be entered first
                    if Rec.Quantity = 0 then
                        Error('Quantity must not be zero before selecting Commission Level.');

                    // UOM must be entered first
                    if Rec."Unit of Measure Code" = '' then
                        Error('Unit of Measure Code must not be blank before selecting Commission Level.');

                    // Find commission calculation
                    if ProjectCommissionCalc.Get(
                        Rec."Job No.",
                        Rec."Attach To Milestone",
                        Rec."Comm Level")
                    then
                        Rec.Validate(
                            "Unit Cost",
                            ProjectCommissionCalc."Commission Amount")
                    else begin
                        Rec.Validate("Unit Cost", 0);
                        Error(
                            'Commission calculation not found for Project %1, Milestone %2 and Level %3.',
                            Rec."Job No.",
                            Rec."Attach To Milestone",
                            Rec."Comm Level");
                    end;

                    CurrPage.Update(false);
                end;
            }
        }

        addafter("Invoiced Amount (LCY)")
        {
            field(PaymentReceivedCalc; Rec.CalculatePaymentReceived())
            {
                ApplicationArea = All;
                Caption = 'Payment Received';
                Visible = true;
                Editable = false;
                ToolTip = 'Specifies payment received against the posted invoice.';
            }
        }

        modify("Unit Cost")
        {
            Editable = not Rec."Is Commission ?";
            ToolTip = 'Specifies the unit cost.';
        }

        modify("Quantity")
        {
            Editable = not (Rec."Is Commission ?" and (Rec."Comm Level" <> ''));
        }

        modify("Unit of Measure Code")
        {
            ApplicationArea = All;
            Visible = true;
            Editable = not (Rec."Is Commission ?" and (Rec."Comm Level" <> ''));
            ToolTip = 'Specifies the unit of measure.';
        }

        modify("Line Amount")
        {
            ApplicationArea = All;
            Visible = true;
            Editable = false;
            ToolTip = 'Specifies the line amount.';
        }
    }
}
