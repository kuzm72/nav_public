pageextension 50140 ItemPageExtension extends "Item Card"
{
    actions
    {
        addfirst(ItemActionGroup) 
        {
            action(DownloadPicture)
            {
                CaptionML=ENU='Download Picture';
                Image = Picture;

                trigger OnAction()
                var 
                    DownloadManager: Codeunit HttpDownloadMngmnt;
                    TempBlob: Record TempBlob temporary;
                    InStr: InStream;
                begin
                    DownloadManager.DownloadPicture('https://upload.wikimedia.org/wikipedia/commons/6/60/Lotus_Type_108_-_LotusSport_bicycle.jpg', TempBlob);
                    TempBlob.Blob.CreateInStream(InStr); 
                    rec.Picture.ImportStream(InStr,'Default image'); 
                    CurrPage.Update(true);
                end;
            }

        }
    }    
}