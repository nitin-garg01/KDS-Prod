page 50323 "Posted Sales Invoices Edit"
{


    Editable = true;
    InsertAllowed = false;
    PageType = List;
    ModifyAllowed = true;
    DeleteAllowed = false;
    SourceTable = "Sales Invoice Header";
    SourceTableView = sorting("Posting Date")
                      order(descending);
    UsageCategory = History;
    Permissions = TableData "Sales Invoice Header" = Rimd;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    AboutTitle = 'The final invoice number (No.)';
                    AboutText = 'This is the invoice number uniquely identifying each posted sale. Your customers see this number on the invoices they receive from you.';
                    ToolTip = 'Specifies the posted sales invoice number. Each posted sales invoice gets a unique number. Typically, the number is generated based on a number series.';
                }

                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    editable = false;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the name of the customer that you shipped the items on the invoice to.';
                }

                field("IRN Cancel Reason"; Rec."IRN Cancel Reason")
                {
                    caption = 'IRN Cancel Reason';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason why the invoice was canceled. This field is filled in when you cancel a posted sales invoice.';

                    visible = true;
                    Editable = IsCancelEditable;

                    trigger OnValidate()
                    begin
                        if Rec."IRN Status" = Rec."IRN Status"::Cancelled then
                            Error('IRN Cancel Reason cannot be changed after IRN cancellation.');
                    end;
                }
                field("IRN Cancel Remarks"; Rec."IRN Cancel Remarks")
                {
                    caption = 'IRN Cancel Remarks';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment status of the invoice.';

                    visible = true;
                    Editable = IsCancelEditable;

                    trigger OnValidate()
                    begin
                        if Rec."IRN Status" = Rec."IRN Status"::Cancelled then
                            Error('IRN Cancel Remarks cannot be changed after IRN cancellation.');
                    end;
                }
            }
        }
    }
    var
        IsCancelEditable: Boolean;

    trigger OnAfterGetRecord()
    begin
        // Editable only when IRN is NOT yet cancelled
        IsCancelEditable := Rec."IRN Status" <> Rec."IRN Status"::Cancelled;
    end;
}