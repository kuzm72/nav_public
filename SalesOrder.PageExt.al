pageextension 50120 SalesOrderExt extends "Sales Order"
{
    actions
    {
        addfirst("F&unctions")
        {
            action(RetrivePrices)
            {
                Caption = 'Retrieve Prices';
                Image = PriceWorksheet;
                PromotedCategory = Process;
                Promoted = true;

                trigger OnAction()
                var
                    DownloadManager: Codeunit HttpPriceMngmnt;
                begin
                    TestField(Status, Status::Released);
                    DownloadManager.RefreshPrices(Rec);
                    CurrPage.Update(true);
                end;
            }
        }
    }
}