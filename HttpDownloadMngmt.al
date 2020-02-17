codeunit 50140 HttpDownloadMngmnt
{
    procedure DownloadPicture(url: Text;var TempBlob : Record TempBlob temporary)
    var
        client: HttpClient;
        responce: HttpResponseMessage;
        request: HttpRequestMessage;
        inStr: InStream;
        outStr: OutStream;
    begin
        client.Get(url, responce);
        responce.Content.ReadAs(inStr);
        TempBlob.Blob.CreateOutStream(outStr);
        CopyStream(outStr, inStr);
    end;
}