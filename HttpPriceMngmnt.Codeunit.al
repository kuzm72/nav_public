codeunit 50120 HttpPriceMngmnt
{
    procedure RefreshPrices(pSH: Record "Sales Header");
    var
        SH: Record "Sales Header";
        SL: Record "Sales Line";
        jHeader: JsonObject;
        jLine: JsonObject;
        jLines: JsonArray;
        jRequest: JsonArray;
        jResponce: JsonArray;
        jToken: JsonToken;
        jTokenLine: JsonToken;
        locHeader: Code[20];
        locLine: Integer;
        locItemNo: Code[30];
        locUnitCost: Decimal;
    begin
        Clear(jRequest);
        Clear(jResponce);

        SH.Reset;
        SH.Get(pSH."Document Type", pSH."No.");

        SL.Reset;
        SL.SetRange("Document Type", SH."Document Type");
        SL.SetRange("Document No.", SH."No.");
        SL.SetRange(Type, SL.Type::Item);
        if not SL.FindSet() then
            Error('Sales Order does no have item lines');

        jHeader.Add('order number', SH."No.");
        jHeader.Add('location code', SH."Location Code");
        jHeader.Add('customer code', SH."Sell-to Customer No.");
        jRequest.Add(jHeader);

        jLine.Add('line no', '');
        jLine.Add('item no', '');
        jLine.Add('quantity', '');

        repeat
            jLine.Replace('line no', SL."Line No.");
            jLine.Replace('item no', SL."No.");
            jLine.Replace('quantity', SL.Quantity); //Qty base would be better option here
            jLines.Add(jLine);
        until SL.next = 0;

        jRequest.Add(jLines);
        ProcessJsonRequest(jRequest, jResponce);
        if jResponce.Count = 0 then
            Error('No valid responce received from the server');

        SL.Reset;
        Clear(jHeader);
        Clear(jLines);
        locHeader := '';
        locLine := 0;
        locItemNo := '';
        foreach jToken in jResponce do begin
            if locLine = 0 then begin
                jHeader := jToken.AsObject;
                locHeader := GetJsonToken(jHeader, 'order no').AsValue.AsCode;
                if SH."No." <> locHeader then
                    Error('Invalid responce from the server - order mismatch - expected: %1 received %2', SH."No.", locHeader);
            end
            else begin
                jLines := jToken.AsArray;
                foreach jTokenLine in jLines do begin
                    jLine := jTokenLine.AsObject;
                    locLine := GetJsonToken(jLine, 'line no').AsValue.AsInteger;

                    SL.Get(SH."Document Type", locHeader, locLine);
                    locItemNo := GetJsonToken(jLine, 'item no').AsValue.AsCode;
                    if (SL.Type = SL.Type::Item) AND (SL."No." = locItemNo) then begin
                        if SL.Quantity <> 0 then
                            locUnitCost := GetJsonToken(jLine, 'calculated line amount').AsValue.AsDecimal / SL.Quantity //TODO should use GLsetup."unit amount round. precision"
                        else
                            locUnitCost := 0;
                        SL.Validate("Unit Cost", locUnitCost);
                        SL.Modify(true);
                    end
                    else
                        Error('Invalid responce from the server - item/type mismatch - expected: %1 received %2', SL."No.", locItemNo);
                end;
            end;
        end;
    end;

    local procedure ProcessJsonRequest(JsonRequest: JsonArray; var JsonResponce: JsonArray)
    var
        Client: HttpClient;
        Headers: HttpHeaders;
        Responce: HttpResponseMessage;
        Content: HttpContent;
        locJsonText: Text;
    begin
        JsonRequest.WriteTo(locJsonText); //TODO check boolean
        Content.WriteFrom(locJsonText);
        Content.GetHeaders(Headers);
        Headers.Remove('Content-Type');
        Headers.Add('Content-Type', 'text/xml;charset=utf-8');
        Client.SetBaseAddress('http://localhost/'); //TODO remove harcoding
        Client.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365');

        if not Client.Post('http://localhost/', Content, Responce) then
            Error('Cal of the webservice failed'); //TODO remove harcoding

        if not Responce.IsSuccessStatusCode then
            Error('The web service returned an error message:\\' + 'Status code: %1\' + 'Description: %2',
                Responce.HttpStatusCode, Responce.ReasonPhrase);

        Responce.Content.ReadAs(locJsonText);
        Message(locJsonText);

        if not JsonResponce.ReadFrom(locJsonText) then
            Error('Invalid response, expected an JSON array as root object');
    end;

    local procedure GetJsonToken(JsonObject: JsonObject; TokenKey: text) JsonToken: JsonToken
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;
}