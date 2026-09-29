pageextension 50605 "Webtel Posted Sales Cr Memo" extends "Posted Sales Credit Memo"
{
    //ModifyAllowed = true;

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
            // ====================================================
            // PROD E-INVOICE GROUP
            // ====================================================
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
                        Message(
                            EInvMgt.GetInvoiceJSON(Rec));
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
                        SalesCrMemoHeader:
                            Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader.Reset();
                        SalesCrMemoHeader.SetRange(
                            "No.",
                            Rec."No.");

                        Page.RunModal(
                            Page::"Posted Sales Credit Memos List",
                            SalesCrMemoHeader);

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
                        EInvoiceMgt:
                            Codeunit "E-Invoice Cancel CR Prod";
                    begin
                        if Rec."IRN No." = '' then
                            Error(
                                'IRN is not generated.');

                        if Rec."IRN Status" =
                           Rec."IRN Status"::Cancelled
                        then
                            Error(
                                'IRN already cancelled.');

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


            // group("GST Credit Debit API")
            // {
            //     Caption = 'GST Credit/Debit API';

            //     // ------------------------------------------------
            //     // Convert Credit Note to JSON
            //     // ------------------------------------------------
            //     action(ConvertCreditNoteToJSON)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Convert Credit Note to JSON';
            //         Image = ExportMessage;
            //         ToolTip =
            //             'Generate GST Credit Note JSON for the selected posted sales credit memo.';

            //         trigger OnAction()
            //         var
            //             GSTCreditDebitAPI:
            //                 Codeunit "GST Credit Debit Sale API";
            //             JsonText: Text;
            //         begin
            //             JsonText :=
            //                 GSTCreditDebitAPI.GetCreditDebitJSON(
            //                     Rec,
            //                     'CR');

            //             Message(
            //                 'Credit Note JSON generated successfully:\%1',
            //                 JsonText);
            //         end;
            //     }

            //     // ------------------------------------------------
            //     // Upload Credit Note
            //     // ------------------------------------------------
            //     action(UploadCreditNoteGST)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Upload Credit Note GST Data';
            //         Image = Export;
            //         ToolTip =
            //             'Upload the selected Credit Note to the GST server.';

            //         trigger OnAction()
            //         var
            //             GSTCreditDebitAPI:
            //                 Codeunit "GST Credit Debit Sale API";
            //             ResponseText: Text;
            //         begin
            //             if Rec."Sell-to Customer No." = '' then
            //                 Error(
            //                     'Customer is not specified for Credit Note %1.',
            //                     Rec."No.");

            //             if not Confirm(
            //                 'Do you want to upload Credit Note %1 to the GST server?',
            //                 false,
            //                 Rec."No.")
            //             then
            //                 exit;

            //             ResponseText :=
            //                 GSTCreditDebitAPI.UploadCreditDebit(
            //                     Rec,
            //                     'CR');

            //             Message(
            //                 'GST Credit Note API Response:\%1',
            //                 ResponseText);
            //         end;
            //     }

            //     // ------------------------------------------------
            //     // Convert as Debit Note JSON
            //     // ------------------------------------------------
            //     action(ConvertDebitNoteToJSON)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Convert Debit Note to JSON';
            //         Image = ExportMessage;
            //         ToolTip =
            //             'Generate GST Debit Note JSON for the selected document.';

            //         trigger OnAction()
            //         var
            //             GSTCreditDebitAPI:
            //                 Codeunit "GST Credit Debit Sale API";
            //             JsonText: Text;
            //         begin
            //             JsonText :=
            //                 GSTCreditDebitAPI.GetCreditDebitJSON(
            //                     Rec,
            //                     'DR');

            //             Message(
            //                 'Debit Note JSON generated successfully:\%1',
            //                 JsonText);
            //         end;
            //     }

            //     // ------------------------------------------------
            //     // Upload Debit Note
            //     // ------------------------------------------------
            //     action(UploadDebitNoteGST)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Upload Debit Note GST Data';
            //         Image = Export;
            //         ToolTip =
            //             'Upload the selected Debit Note to the GST server.';

            //         trigger OnAction()
            //         var
            //             GSTCreditDebitAPI:
            //                 Codeunit "GST Credit Debit Sale API";
            //             ResponseText: Text;
            //         begin
            //             if Rec."Sell-to Customer No." = '' then
            //                 Error(
            //                     'Customer is not specified for Debit Note %1.',
            //                     Rec."No.");

            //             if not Confirm(
            //                 'Do you want to upload document %1 as a Debit Note to the GST server?',
            //                 false,
            //                 Rec."No.")
            //             then
            //                 exit;

            //             ResponseText :=
            //                 GSTCreditDebitAPI.UploadCreditDebit(Rec,'DR');

            //             Message(
            //                 'GST Debit Note API Response:\%1',
            //                 ResponseText);
            //         end;
            //     }
            // }
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