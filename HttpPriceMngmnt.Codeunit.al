codeunit 50120 HttpPriceMngmnt
{
    var
        rSRSetup: Record "Sales & Receivables Setup";
        rSH: Record "Sales Header";
        rSL: Record "Sales Line";
        IsReleased: Boolean;
        BaseUrl: Text;
        Url: Text;
        IsInitialized: Boolean;
        Text001: label 'Sales Order does no have item lines';
        Text002: label 'Could not find a token with key %1';
        Text003: label 'Not initialized';
        Text004: label 'Invalid responce from the server - order mismatch - expected: %1 received %2';
        Text005: label 'Invalid responce from the server - no lines for order %1';
        Text006: label 'Expecting array of sales lines here %1';
        Text007: label 'Expecting individual sale line here %1';
        Text008: label 'Invalid responce from the server - item/type mismatch - expected: %1 received %2';
        Text009: label 'Prices for Sales Order %1 received';
        Text010: label 'Call to the webservice failed';
        Text011: label 'The web service returned an error message:\\Status code: %1\Description: %2';
        Text012: label 'Invalid response, expected an JSON object as root';

    procedure RefreshPrices(pSH: Record "Sales Header");
    var
        jRequest: JsonObject;
        jResponce: JsonObject;
    begin
        //prepare request
        Init(pSH, jRequest);

        //get responce
        Clear(jResponce);
        ProcessJsonRequest(jRequest, jResponce);

        //process prices
        UpdateSalesOrder(jResponce);
    end;

    local procedure Init(pSH: Record "Sales Header"; var jRequest: JsonObject);
    var
        jLine: JsonObject;
        jLines: JsonArray;

    begin
        rSRSetup.Get;

        /*******/
        //TODO Extend S&R setup table and page with required URL
        BaseUrl := 'http://localhost:3000/';
        Url := 'prices';
        /*******/

        rSH.Reset;
        rSH.Get(pSH."Document Type", pSH."No.");
        IsReleased := (rSH.Status = rSH.Status::Released);

        rSL.Reset;
        rSL.SetRange("Document Type", rSH."Document Type");
        rSL.SetRange("Document No.", rSH."No.");
        rSL.SetRange(Type, rSL.Type::Item);
        if not rSL.FindSet() then
            Error(Text001);

        IsInitialized := true;

        Clear(jRequest);
        jRequest.Add('order number', rSH."No.");
        jRequest.Add('location code', rSH."Location Code");
        jRequest.Add('customer code', rSH."Sell-to Customer No.");

        jLine.Add('line no', '');
        jLine.Add('item no', '');
        jLine.Add('quantity', '');

        repeat
            jLine.Replace('line no', rSL."Line No.");
            jLine.Replace('item no', rSL."No.");
            jLine.Replace('quantity', rSL.Quantity); //Qty base?
            jLines.Add(jLine);
        until rSL.next = 0;

        jRequest.Add('lines', jLines);
    end;

    local procedure UpdateSalesOrder(JResponce: JsonObject);
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        jToken: JsonToken;
        jTokenLine: JsonToken;
        jLine: JsonObject;
        jLines: JsonArray;
        locHeader: Code[20];
        locLine: Integer;
        locItemNo: Code[30];
        locUnitCost: Decimal;
        locLineAmount: Decimal;
    begin
        if not IsInitialized then
            Error(Text003);

        Clear(jLines);
        locHeader := '';
        locLine := 0;
        locItemNo := '';

        locHeader := GetJsonToken(jResponce, 'order number').AsValue.AsCode;
        if rSH."No." <> locHeader then
            Error(Text004, rSH."No.", locHeader);

        if not jResponce.SelectToken('lines', jToken) then
            Error(Text005, locHeader);

        if jToken.IsArray then
            jLines := jToken.AsArray
        else
            Error(Text006, jToken);

        foreach jTokenLine in jLines do begin
            if jTokenLine.IsObject then
                jLine := jTokenLine.AsObject
            else
                Error(Text007, jTokenLine);

            locLine := GetJsonToken(jLine, 'line number').AsValue.AsInteger;

            rSL.Get(rSH."Document Type", locHeader, locLine);
            locItemNo := GetJsonToken(jLine, 'item number').AsValue.AsCode;
            if (rSL.Type = rSL.Type::Item) AND (rSL."No." = locItemNo) then begin
                if rSL.Quantity <> 0 then begin
                    locLineAmount := GetJsonToken(jLine, 'calculated line amount').AsValue.AsDecimal;
                    locUnitCost := locLineAmount / rSL.Quantity //TODO should use GLsetup."unit amount round. precision"
                end
                else
                    locUnitCost := 0; //TODO proper divide by 0 handling

                if IsReleased then begin
                    ReleaseSalesDoc.Reopen(rSH);
                    IsReleased := false;
                end;

                rSL.Validate("Line Discount Amount", 0); //TODO handle discount ?
                rSL.Validate("Unit Price", locUnitCost);
                rSL.Validate("Line Amount", locLineAmount);
                rSL.Modify(true);
            end
            else
                Error(Text008, rSL."No.", locItemNo);
        end;

        if not IsReleased then
            ReleaseSalesDoc.PerformManualRelease(rSH);

        if GuiAllowed then
            Message(Text009, rSH."No.");
    end;

    local procedure ProcessJsonRequest(JsonRequest: JsonObject; var JsonResponce: JsonObject)
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
        Client.SetBaseAddress(BaseUrl);
        Client.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365');

        if not Client.Post(Url, Content, Responce) then
            Error(Text010);

        if not Responce.IsSuccessStatusCode then
            Error(Text011, Responce.HttpStatusCode, Responce.ReasonPhrase);

        Responce.Content.ReadAs(locJsonText);

        if not JsonResponce.ReadFrom(locJsonText) then
            Error(Text012);
    end;

    local procedure GetJsonToken(JsonObject: JsonObject; TokenKey: text) JsonToken: JsonToken
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error(Text002, TokenKey);
    end;
}