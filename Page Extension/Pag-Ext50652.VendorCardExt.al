// pageextension 50652 "Vendor Card GST Ext" extends "Vendor Card"
// {

//     layout
//     {
//         addlast(general)
//         {
//             group("GST API")
//             {
//                 Caption = 'GST API';
//                 field("GST Upload Status"; Rec."GST Upload Status")
//                 {
//                     ApplicationArea = All;
//                     editable = false;
//                 }
//                 field("GST Upload Error"; Rec."GST Upload Error")
//                 {
//                     Editable = false;
//                     ApplicationArea = All;
//                     visible = false;
//                 }
//             }
//         }
//     }

//     actions
//     {
//         addlast(Processing)
//         {
//             action(ConvertToJson)
//             {
//                 Caption = 'Convert To JSON';
//                 Image = ExportFile;
//                 ApplicationArea = All;

//                 trigger OnAction()
//                 var
//                     GSTJson: Codeunit "GST Part Master API";
//                 begin
//                     GSTJson.ShowVendorJson(Rec."No.");
//                 end;
//             }

//             action(UploadGSTData)
//             {
//                 Caption = 'Upload GST Data';
//                 Image = SendTo;

//                 ApplicationArea = All;

//                 trigger OnAction()
//                 var
//                     GSTJson: Codeunit "GST Part Master API";
//                 begin
//                     GSTJson.UploadVendor(Rec."No.");
//                     CurrPage.Update(true);
//                 end;
//             }
//         }
//     }

// }
