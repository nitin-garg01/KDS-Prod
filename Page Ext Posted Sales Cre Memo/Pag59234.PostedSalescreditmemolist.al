
page 59234 "Posted Sales Credit Memos List"
{
    Editable = true;
    PageType = List;
    InsertAllowed = false;
    SourceTable = "Sales Cr.Memo Header";
    SourceTableView = sorting("Posting Date") order(descending);
    UsageCategory = History;
    permissions = tabledata "Sales Cr.Memo Header" = rimd;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    editable = false;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the name of the customer that you shipped the items on the credit memo to.';
                }

                field("IRN Cancel Reason"; Rec."IRN Cancel Reason")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason for canceling the IRN.';
                    Visible = true;
                    Editable = IsCancelEditable;
                }
                field("IRN Cancel Remark"; Rec."IRN Cancel Remarks")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remarks for canceling the IRN.';
                    Visible = true;
                    Editable = IsCancelEditable;
                }

            }
        }
    }
    var
        IsCancelEditable: Boolean;

    trigger OnAfterGetRecord()
    begin
        IsCancelEditable := Rec."IRN Status" <> Rec."IRN Status"::Cancelled;
    end;

}