
pageextension 50606 "Webtel Posted sales invoice" extends "Posted Sales Invoice"
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
            // group("GST API Group")
            // {
            //     Caption = 'GST API';

            //     action(ConvertToJSONGST)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Convert to JSON (GST)';
            //         Image = ExportMessage;

            //         trigger OnAction()
            //         var
            //             GSTSalesAPI: Codeunit "GST Sales API";
            //             JsonText: Text;
            //         begin
            //             JsonText := GSTSalesAPI.GetSalesJSON(Rec);
            //             Message('%1', JsonText);
            //         end;
            //     }

            //     action(UploadGSTData)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Upload GST Sales Data';
            //         Image = Export;

            //         trigger OnAction()
            //         var
            //             GSTSalesAPI: Codeunit "GST Sales API";
            //             ResponseText: Text;
            //         begin


            //             ResponseText := GSTSalesAPI.UploadSales(Rec);

            //             Message('Response: %1', ResponseText);

            //             CurrPage.Update(true);
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
                    Caption = 'Generate IRN Prod';
                    Image = ElectronicDoc;

                    trigger OnAction()
                    var
                        EInvMgt: Codeunit "E-Invoice Mgt Production";
                    begin
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
                    begin
                        if Rec."IRN No." = '' then
                            Error('IRN is not generated.');

                        if Rec."IRN Status" = Rec."IRN Status"::Cancelled then
                            Error('IRN already cancelled.');

                        if not Confirm('Do you want to cancel IRN %1?', false, Rec."IRN No.") then
                            exit;

                        EInvoiceCancelMgt.CancelIRN(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            // group("Advance Tax API")
            // {
            //     Caption = 'Advance Tax API';

            //     action(ConvertAdvanceTaxToJSON)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Convert Advance Tax to JSON';
            //         Image = ExportMessage;

            //         trigger OnAction()
            //         var
            //             AdvanceTaxAPI: Codeunit "GST Advance Tax Sales";
            //         begin
            //             AdvanceTaxAPI.PreviewAdvanceTaxJSON(Rec);
            //         end;
            //     }

            //     action(UploadAdvanceTaxData)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Upload Advance Tax Data';
            //         Image = Export;

            //         trigger OnAction()
            //         var
            //             AdvanceTaxAPI: Codeunit "GST Advance Tax Sales";
            //         begin
            //             AdvanceTaxAPI.UploadSalesInvoice(Rec);
            //             CurrPage.Update(true);
            //         end;
            //     }
            // }
            // group("Advance Adjustment Sale API")
            // {
            //     Caption = 'Advance Adjustment Sale API';

            //     action(ConvertAdvanceAdjustmentToJSON)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Convert Advance Adjustment to JSON';
            //         Image = ExportMessage;

            //         trigger OnAction()
            //         var
            //             AdvanceAdjustmentAPI: Codeunit "GST Advance Adjustment Sale";
            //         begin
            //             AdvanceAdjustmentAPI.PreviewAdvanceAdjustmentJSON(Rec);
            //         end;
            //     }

            //     action(UploadAdvanceAdjustmentData)
            //     {
            //         ApplicationArea = All;
            //         Caption = 'Upload Advance Adjustment Sale Data';
            //         Image = Export;

            //         trigger OnAction()
            //         var
            //             AdvanceAdjustmentAPI: Codeunit "GST Advance Adjustment Sale";
            //         begin
            //             AdvanceAdjustmentAPI.UploadSalesInvoice(Rec);
            //             CurrPage.Update(true);
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