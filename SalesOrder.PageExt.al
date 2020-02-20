pageextension 50120 SalesOrderExt extends "Sales Order"
{
    actions
    {
        addfirst("F&unctions")
        {
            action(RetrivePrices)
            {
                CaptionML = ENU = 'Retrieve Prices';
                Image = LineReserve;
                Promoted = true;

                trigger OnAction()
                var 
                    DownloadManager: Codeunit HttpPriceMngmnt;
                begin
                    DownloadManager.RefreshPrices(Rec);
                    CurrPage.Update(true);
                end;
            }
        }
    }
}