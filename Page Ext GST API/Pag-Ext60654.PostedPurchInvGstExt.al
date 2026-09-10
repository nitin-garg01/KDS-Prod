pageextension 50654 "Posted Purch Inv GST Ext" extends "Posted Purchase Invoice"
{
    layout
    {
        addafter("Document Date")
        {
            group("GST API GROUP")
            {
                Caption = 'GST API GROUP';

                field("GST Upload Status"; Rec."GST Upload Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Status of GST upload to compliance server';
                }

                field("GST Upload Error"; Rec."GST Upload Error")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Error message from GST upload attempt';
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            // ====================================================
            // GST PURCHASE API
            // ====================================================

            action(ConvertToJSON)
            {
                ApplicationArea = All;
                Caption = 'Convert to JSON';
                Image = Export;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Convert the posted purchase invoice data into GST JSON.';

                trigger OnAction()
                var
                    GSTPurchaseAPI: Codeunit "GST Purchase API";
                    JsonText: Text;
                begin
                    JsonText :=
                        GSTPurchaseAPI.GetPurchaseJSON(
                            Rec);

                    Message(
                        '%1',
                        JsonText);
                end;
            }

            action(UploadGSTData)
            {
                ApplicationArea = All;
                Caption = 'Upload GST Data';
                Image = ExportToExcel;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Upload the purchase invoice GST data to the GST API.';

                trigger OnAction()
                var
                    GSTPurchaseAPI: Codeunit "GST Purchase API";
                    ResponseText: Text;
                begin
                    ResponseText :=
                        GSTPurchaseAPI.UploadPurchase(
                            Rec);

                    Message(
                        ResponseText);
                end;
            }


            // ====================================================
            // ADVANCE TAX PURCHASE API
            // ====================================================

            group("Advance Tax Purchase API")
            {
                Caption = 'Advance Tax Purchase API';

                action(ConvertAdvanceTaxPurchaseToJSON)
                {
                    ApplicationArea = All;
                    Caption = 'Convert Advance Tax Purchase to JSON';
                    Image = ExportMessage;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Convert the posted purchase invoice data into Advance Tax Purchase JSON.';

                    trigger OnAction()
                    var
                        GSTAdvanceTaxPurchase:
                            Codeunit "GST Advance Tax Purchase";
                    begin
                        GSTAdvanceTaxPurchase.PreviewAdvanceTaxPurchaseJSON(
                            Rec);
                    end;
                }

                action(UploadAdvanceTaxPurchaseData)
                {
                    ApplicationArea = All;
                    Caption = 'Upload Advance Tax Purchase Data';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Upload the purchase invoice Advance Tax data to the GST server.';

                    trigger OnAction()
                    var
                        GSTAdvanceTaxPurchase:
                            Codeunit "GST Advance Tax Purchase";
                    begin
                        GSTAdvanceTaxPurchase.UploadPurchaseInvoice(
                            Rec);

                        CurrPage.Update(true);
                    end;
                }
            }


            // ====================================================
            // ADVANCE ADJUSTMENT PURCHASE API
            // ====================================================

            group("Advance Adjustment Purchase API")
            {
                Caption = 'Advance Adjustment Purchase API';

                action(ConvertAdvanceAdjustmentPurchaseToJSON)
                {
                    ApplicationArea = All;
                    Caption = 'Convert Advance Adjustment Purchase to JSON';
                    Image = ExportMessage;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Convert the posted purchase invoice data into Advance Adjustment Purchase JSON.';

                    trigger OnAction()
                    var
                        GSTAdvanceAdjustmentPurchase:
                            Codeunit "GST Advance Adjust. Purchase";
                    begin
                        GSTAdvanceAdjustmentPurchase.PreviewAdvanceAdjustmentPurchaseJSON(
                            Rec);
                    end;
                }

                action(UploadAdvanceAdjustmentPurchaseData)
                {
                    ApplicationArea = All;
                    Caption = 'Upload Advance Adjustment Purchase Data';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Upload the purchase invoice Advance Adjustment data to the GST server.';

                    trigger OnAction()
                    var
                        GSTAdvanceAdjustmentPurchase:
                            Codeunit "GST Advance Adjust. Purchase";
                    begin
                        GSTAdvanceAdjustmentPurchase.UploadPurchaseInvoice(
                            Rec);

                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }
}