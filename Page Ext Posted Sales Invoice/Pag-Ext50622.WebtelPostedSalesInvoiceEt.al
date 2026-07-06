pageextension 50622 "Webtel Posted sales invoice" extends "Posted sales Invoice"
{

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
                    Visible = true;
                    Editable = false;
                }

                field("Ack Date"; Rec."Ack Date")
                {
                    ApplicationArea = All;
                    Visible = true;
                    Editable = false;
                }

                field("Ack No."; Rec."Ack No.")
                {
                    ApplicationArea = All;
                    Visible = true;
                    Editable = false;
                }

                field("IRN Status"; Rec."IRN Status")
                {
                    ApplicationArea = All;
                    Visible = true;
                    Editable = false;
                }
                field("Cancel Date"; Rec."Cancel Date")
                {
                    ApplicationArea = All;
                    Visible = true;
                    Editable = false;
                }

                field("IRN Cancel Remarks"; Rec."IRN Cancel Remarks")
                {
                    ApplicationArea = All;
                    Visible = true;
                    Editable = false;

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
        modify("Cancel E-Invoice")
        {
            Visible = false;
        }
        addfirst(processing)
        {
            // group("E-Invoice Group")
            // {
            //     Caption = 'Test E-Invoice Group';
            //     action(ConvertToJSON)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Convert to JSON';
            //         Image = ExportMessage;

            //         trigger OnAction()
            //         var
            //             EInvMgt: Codeunit "E-Invoice Mgt Sandbox";
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
            //             EInvMgt: Codeunit "E-Invoice Mgt Sandbox";
            //         begin

            //             if Rec."IRN No." <> '' then
            //                 Error('IRN is already generated for Invoice No. %1', Rec."No.");

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
            //             SalesInvHeader: Record "Sales Invoice Header";
            //         begin
            //             SalesInvHeader.Reset();
            //             SalesInvHeader.SetRange("No.", Rec."No.");
            //             Page.RunModal(Page::"Posted Sales Invoices Edit", SalesInvHeader);
            //             CurrPage.Update();
            //         end;
            //     }


            //     action(CancelIRN)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'IRN Cancel';
            //         Image = Cancel;
            //         trigger OnAction()
            //         var
            //             EInvoiceCancelMgt: Codeunit "E-Invoice Cancel IRN";
            //             JsonText: Text;
            //             EInvMgt: Codeunit "E-Invoice Mgt Sandbox";
            //         begin
            //             if Rec."IRN No." = '' then
            //                 Error('IRN is not generated.');

            //             if Rec."IRN Status" = Rec."IRN Status"::Cancelled then
            //                 Error('IRN already cancelled.');


            //             if not Confirm('Do you want to cancel IRN %1 ', false, Rec."IRN No.")
            //             then
            //                 exit;

            //             EInvoiceCancelMgt.CancelIRN(Rec);

            //             CurrPage.Update(false);
            //         end;
            //     }

            // }
            group("E-Invoive Prod Group")
            {
                Caption = 'Prod. E-Invoice Group';
                action(ConvertToJsonProd)
                {
                    ApplicationArea = All;
                    Caption = 'Convert to JSON (Prod)';
                    Image = ExportMessage;
                    // Promoted = true;
                    // PromotedCategory = Process;
                    trigger OnAction()
                    var
                        EInvMgt: Codeunit "E-Invoice Mgt Production";
                    begin
                        Message(EInvMgt.GetInvoiceJSON(Rec));
                    end;
                }
                action(GenerateIRNWebtelProd)
                {
                    ApplicationArea = All;
                    Caption = 'Generate IRN Prod`';
                    Image = ElectronicDoc;

                    trigger OnAction()
                    var
                        EInvMgt: Codeunit "E-Invoice Mgt Production";
                    begin

                        // if Rec."IRN No." <> '' then
                        //     Error('IRN is already generated for Invoice No. %1', Rec."No.");

                        EInvMgt.GenerateIRN(Rec);

                        CurrPage.Update(true);
                    end;
                }



                action(OpenCancelDetailsProd)
                {
                    ApplicationArea = All;
                    Caption = 'IRN Cancel Details Prod';
                    Image = Cancel;
                    // Promoted = true;
                    // PromotedCategory = Process;
                    trigger OnAction()
                    var
                        SalesInvHeader: Record "Sales Invoice Header";
                    begin
                        SalesInvHeader.Reset();
                        SalesInvHeader.SetRange("No.", Rec."No.");
                        Page.RunModal(Page::"Posted Sales Invoices Edit", SalesInvHeader);
                        CurrPage.Update();
                    end;
                }


                action(CancelIRNProd)
                {
                    ApplicationArea = All;
                    Caption = 'IRN Cancel Prod';
                    Image = Cancel;
                    trigger OnAction()
                    var
                        EInvoiceCancelMgt: Codeunit "E-Invoice Cancel IRN Prod";
                        JsonText: Text;
                        EInvMgt: Codeunit "E-Invoice Mgt Production";
                        GSTRegNos: record "GST Registration Nos.";
                    begin


                        if Rec."IRN No." = '' then
                            Error('IRN is not generated.');

                        if Rec."IRN Status" = Rec."IRN Status"::Cancelled then
                            Error('IRN already cancelled.');

                        if not Confirm('Do you want to cancel IRN %1 ', false, Rec."IRN No.")
                        then
                            exit;

                        EInvoiceCancelMgt.CancelIRN(Rec);

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