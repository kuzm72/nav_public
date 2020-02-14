codeunit 50101 MyCodeunit
{
    [EventSubscriber(ObjectType::Table, 18, 'OnAfterInsertEvent', '', true, true)]
    local procedure CustomerOnAfterInsert(var Rec: Record Customer; RunTrigger : Boolean)
    begin
        Message('CustomerOnAfterInsert message success')
    end;
}