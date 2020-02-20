codeunit 50120 HttpPriceMngmnt
{
    procedure RefreshPrices(pSH: Record "Sales Header");
    var
        SH: Record "Sales Header";
        SL: Record "Sales Line";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        IsReleased: Boolean;
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
        locLineAmount: Decimal;
    begin
        Clear(jRequest);
        Clear(jResponce);

        SH.Reset;
        SH.Get(pSH."Document Type", pSH."No.");
        IsReleased := (SH.Status = SH.Status::Released);

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
            jLine.Replace('quantity', SL.Quantity); //Qty base?
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

        jResponce.Get(0, jToken); //expecting array of sales orders but process only the first one
        if jToken.IsObject then
            jHeader := jToken.AsObject
        else
            Error('Expecting top-level object here %1', jToken);

        locHeader := GetJsonToken(jHeader, 'order number').AsValue.AsCode;
        if SH."No." <> locHeader then
            Error('Invalid responce from the server - order mismatch - expected: %1 received %2', SH."No.", locHeader);

        if not jHeader.SelectToken('lines', jToken) then
            Error('Invalid responce from the server - no lines for order %1', locHeader);

        if jToken.IsArray then
            jLines := jToken.AsArray
        else
            Error('Expecting array of sales lines here %1', jToken);

        foreach jTokenLine in jLines do begin
            if jTokenLine.IsObject then
                jLine := jTokenLine.AsObject
            else
                Error('Expecting individual sale line here %1', jTokenLine);

            locLine := GetJsonToken(jLine, 'line number').AsValue.AsInteger;

            SL.Get(SH."Document Type", locHeader, locLine);
            locItemNo := GetJsonToken(jLine, 'item number').AsValue.AsCode;
            if (SL.Type = SL.Type::Item) AND (SL."No." = locItemNo) then begin
                if SL.Quantity <> 0 then begin
                    locLineAmount := GetJsonToken(jLine, 'calculated line amount').AsValue.AsDecimal;
                    locUnitCost := locLineAmount / SL.Quantity //TODO should use GLsetup."unit amount round. precision"
                end
                else
                    locUnitCost := 0; //TODO proper divide by 0 handling

                if IsReleased then begin
                    ReleaseSalesDoc.Reopen(SH);
                    IsReleased := false;
                end;

                SL.Validate("Line Discount Amount", 0); //TODO handle discount ?
                SL.Validate("Unit Price", locUnitCost);
                SL.Validate("Line Amount", locLineAmount);
                SL.Modify(true);
            end
            else
                Error('Invalid responce from the server - item/type mismatch - expected: %1 received %2', SL."No.", locItemNo);
        end;

        if not IsReleased then
            ReleaseSalesDoc.PerformManualRelease(SH);

        Message('Prices for Sales Order %1 received', SH."No.");
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
        Headers.Add('Content-Type', 'application/json; charset=utf-8');
        Client.SetBaseAddress('http://localhost:3000/'); //TODO remove harcoding
        Client.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365');

        if not Client.Post('prices', Content, Responce) then
            Error('Call to the webservice failed'); //TODO remove harcoding

        if not Responce.IsSuccessStatusCode then
            Error('The web service returned an error message:\\' + 'Status code: %1\' + 'Description: %2',
                Responce.HttpStatusCode, Responce.ReasonPhrase);

        Responce.Content.ReadAs(locJsonText);

        if not JsonResponce.ReadFrom(locJsonText) then
            Error('Invalid response, expected an JSON array as root object');
    end;

    local procedure GetJsonToken(JsonObject: JsonObject; TokenKey: text) JsonToken: JsonToken
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;
}