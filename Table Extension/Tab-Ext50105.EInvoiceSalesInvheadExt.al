tableextension 50105 "E-Invoice Sales Inv head Ext" extends "Sales Invoice Header"
{

    fields
    {
        field(60100; "IRN No."; Text[70])
        {
            Caption = 'IRN No.';
            DataClassification = CustomerContent;

        }
        field(60241; "Ack No."; Text[30])
        {
            Caption = 'Ack No.';

        }
        field(60242; "Ack Date"; DateTime)
        {
            Caption = 'Ack Date';

        }
        field(60245; "Cancel Date"; DateTime)
        {
            Caption = 'Cancel date';
        }
        field(60243; "IRN Status"; Option)
        {
            OptionMembers = " ",Generated,Failed,Cancelled;
            Caption = 'IRN Status';
        }

        field(60244; "JSONResponse"; Blob)
        {
            Caption = 'JSON Response';
        }
        field(60246; "QR Signed Code"; Text[2048])
        {
            Caption = 'QR Signed Code';
            DataClassification = CustomerContent;
        }
        field(60247; "QR Signed Code Image"; Blob)
        {
            Caption = 'QR Image';
            DataClassification = CustomerContent;
        }

        field(50600; "IRN Cancel Reason"; Option)
        {
            Caption = 'Cancel Reason';
            DataClassification = ToBeClassified;
            OptionMembers = Others,Duplicate,DataEntryMistake,OrderCancelled;
            OptionCaption = 'Others,Duplicate,Data Entry Mistake,Order Cancelled';
        }

        field(50601; "IRN Cancel Remarks"; Text[250])
        {
            Caption = 'Cancel Remarks';
            DataClassification = ToBeClassified;
            Editable = true;
        }

    }
}
