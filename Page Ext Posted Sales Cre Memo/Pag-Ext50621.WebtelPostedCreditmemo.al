pageextension 50621 "Webtel Posted Sales Cr Memo" extends "Posted Sales Credit Memo"
{
    ModifyAllowed = true;

    layout
    {
        addlast(General)
        {
            group("E-Invoice Details")
            {
                Caption = 'E-Invoice Details';

                field("IRN No."; Rec."IRN No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Ack Date"; Rec."Ack Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = true;
                    Caption = 'Ack Date';
                }

                field("Ack No."; Rec."Ack No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = true;
                    Caption = 'AcK No';

                }

                field("IRN Status"; Rec."IRN Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = true;
                    Caption = 'IRN Status';
                }

                field("Cancel Date"; Rec."Cancel Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = true;
                    Caption = 'Cancel Date';

                }

                field("IRN Cancel Reason"; Rec."IRN Cancel Reason")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    Caption = 'IRN Cancel Reason';
                }

                field("IRN Cancel Remarks"; Rec."IRN Cancel Remarks")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = true;
                    Caption = 'IRN Cancel Remarks';
                }
                // field("QR Signed Code Image"; Rec."QR Signed Code Image")
                // {
                //     ApplicationArea = All;
                //     Editable = false;
                //     Caption = 'QR Code';
                // }
            }
        }
    }

    actions
    {
        modify("Generate IRN")
        {
            Visible = false;
        }
        addfirst(processing)
        {
            // group("Test E-invoice group")
            // {
            //     Caption = 'Test E-Invoice Group';
            //     action(ConvertToJSON)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Convert to JSON';
            //         Image = ExportMessage;

            //         trigger OnAction()
            //         var
            //             EInvMgt: Codeunit "E-Invoice Mgt Cr Memo";
            //         begin
            //             Message(EInvMgt.GetInvoiceJSON(Rec));
            //         end;
            //     }


            //     action(GenerateIRNWebtel)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Generate IRN';
            //         Image = ElectronicDoc;

            //         trigger OnAction()
            //         var
            //             EInvMgt: Codeunit "E-Invoice Mgt Cr Memo";
            //         begin
            //             if Rec."IRN No." <> '' then
            //                 if not Confirm(
            //                     'IRN is already registered.')
            //                 then
            //                     exit;

            //             EInvMgt.GenerateIRN(Rec);

            //             CurrPage.Update(true);
            //         end;
            //     }

            //     action(OpenCancelDetails)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'IRN Cancel Details';
            //         Image = Cancel;

            //         trigger OnAction()
            //         var
            //             SalesCrMemoHeader: Record "Sales Cr.Memo Header";
            //         begin
            //             SalesCrMemoHeader.Reset();
            //             SalesCrMemoHeader.SetRange("No.", Rec."No.");

            //             Page.RunModal(Page::"Posted Sales Credit Memos List", SalesCrMemoHeader);

            //             CurrPage.Update();
            //         end;
            //     }


            //     action(CancelIRN)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Cancel IRN';
            //         Image = Cancel;

            //         trigger OnAction()
            //         var
            //             EInvoiceMgt: Codeunit "E-Invoice Cancel Credit Memo";
            //         begin
            //             if Rec."IRN No." = '' then
            //                 Error('IRN is not generated.');

            //             if Rec."IRN Status" = Rec."IRN Status"::Cancelled then
            //                 Error('IRN already cancelled.');

            //             if not Confirm(
            //                 'Do you want to cancel IRN %1 ?',
            //                 false,
            //                 Rec."IRN No.")
            //             then
            //                 exit;

            //             EInvoiceMgt.CancelIRN(Rec);

            //             CurrPage.Update(false);
            //         end;
            //     }
            // }
            group("Prod E-Invoice Group")
            {
                Caption = 'Prod E-Invoice Group';

                action(ConvertToJSONProd)
                {
                    ApplicationArea = All;
                    Caption = 'Convert to JSON Prod';
                    Image = ExportMessage;
                    trigger OnAction()
                    var
                        EInvMgt: Codeunit "E-Invoice Mgt Cr Prod";
                    begin
                        Message(EInvMgt.GetInvoiceJSON(Rec));
                    end;
                }


                action(GenerateIRNWebtelProd)
                {
                    ApplicationArea = All;
                    Caption = 'Generate IRN Prod';
                    Image = ElectronicDoc;

                    trigger OnAction()
                    var
                        EInvMgt: Codeunit "E-Invoice Mgt Cr Prod";
                    begin
                        if Rec."IRN No." <> '' then
                            if not Confirm(
                                'IRN is already registered.')
                            then
                                exit;

                        EInvMgt.GenerateIRN(Rec);

                        CurrPage.Update(true);
                    end;
                }

                action(OpenCancelDetailsProd)
                {
                    ApplicationArea = All;
                    Caption = 'IRN Cancel Details Prod';
                    Image = Cancel;

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader.Reset();
                        SalesCrMemoHeader.SetRange("No.", Rec."No.");

                        Page.RunModal(Page::"Posted Sales Credit Memos List", SalesCrMemoHeader);

                        CurrPage.Update();
                    end;
                }


                action(CancelIRNProd)
                {
                    ApplicationArea = All;
                    Caption = 'Cancel IRN Prod';
                    Image = Cancel;

                    trigger OnAction()
                    var
                        EInvoiceMgt: Codeunit "E-Invoice Cancel CR Prod";
                    begin
                        if Rec."IRN No." = '' then
                            Error('IRN is not generated.');

                        if Rec."IRN Status" = Rec."IRN Status"::Cancelled then
                            Error('IRN already cancelled.');

                        if not Confirm(
                            'Do you want to cancel IRN %1 ?',
                            false,
                            Rec."IRN No.")
                        then
                            exit;

                        EInvoiceMgt.CancelIRN(Rec);

                        CurrPage.Update(false);
                    end;
                }
            }

        }
    }

    local procedure GetJSONResponseText(): Text
    var
        InStream: InStream;
        Result: Text;
    begin
        if Rec.JSONResponse.HasValue then begin
            Rec.JSONResponse.CreateInStream(InStream);
            InStream.ReadText(Result);
        end;

        exit(Result);
    end;


}