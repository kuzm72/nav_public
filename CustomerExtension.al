tableextension 50101 CustomerExtention extends Customer
{
    fields
    {
        field(50101; "Favorite Book"; Code[10])
        {
            TableRelation = Book."No.";
            CaptionML=ENU='Favorite Book';
            DataClassification = ToBeClassified;
        }
    }
}
pageextension 50101 CustomerCardExtension extends "Customer Card"
{
    layout
    {
        addlast(General){
            field("favorite Book";"Favorite Book")
            {
              ApplicationArea = All;
            }
        }
    }
}