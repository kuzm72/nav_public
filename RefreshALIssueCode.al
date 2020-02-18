codeunit 50115 RefreshALIssueCode
{
    trigger OnRun()
    begin

    end;

    procedure Refresh()
    var
        tALIssue: Record ALIssue;
        client: HttpClient;
        responce: HttpResponseMessage;
        myJsonToken: JsonToken;
        myJsonValue: JsonValue;
        myJsonObject: JsonObject;
        myJsonArray: JsonArray;
        myJsonText: Text;
        i: Integer;
    begin
        tALIssue.DeleteAll(false);

        client.DefaultRequestHeaders.Add('User-Agent', 'Dynamics 365');
        if not client.Get('https://api.github.com/repos/Microsoft/AL/issues', responce) then
            Error('Cal of the webservice failed');

        // client.UseWindowsAuthentication()

        if not responce.IsSuccessStatusCode then
            error('The web service returned an error message:\\' + 'Status code: %1\' + 'Description: %2',
                responce.HttpStatusCode, responce.ReasonPhrase);

        responce.Content.ReadAs(myJsonText);
        if not myJsonArray.ReadFrom(myJsonText) then
            Error('Invalid response, expected an JSON array as root object');

        foreach myJsonToken in myJsonArray do begin
            myJsonObject := myJsonToken.AsObject;

            tALIssue.init;
            tALIssue.Validate(ID, GetJsonToken(myJsonObject, 'id').AsValue.AsInteger);
            tALIssue.number := GetJsonToken(myJsonObject, 'number').AsValue.AsInteger;
            tALIssue.title := GetJsonToken(myJsonObject, 'title').AsValue.AsText;
            tALIssue.created_at := GetJsonToken(myJsonObject, 'created_at').AsValue.AsDateTime;
            tALIssue.state := GetJsonToken(myJsonObject, 'state').AsValue.AsText;
            tALIssue.html_url := GetJsonToken(myJsonObject, 'html_url').AsValue.AsText;
            tALIssue.user := SelectJsonToken(myJsonObject, '$.user.login').AsValue.AsText;
            tALIssue.Insert(true);
        end;

    end;

    procedure GetJsonToken(JsonObject: JsonObject; TokenKey: text) JsonToken: JsonToken
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    procedure SelectJsonToken(JsonObject: JsonObject; Path: text) JsonToken: JsonToken
    begin
        if not JsonObject.SelectToken(Path, JsonToken) then
            Error('Could not find a token with path %1', Path);
    end;
}