page 50115 ALIssueList
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = ALIssue;
    Editable = false;
    SourceTableView=order(descending);
    
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(ID; ID)
                {
                    ApplicationArea = All;
                }
                field(Number; Number)
                {
                    ApplicationArea = All;
                }
                field(Title; Title)
                {
                    ApplicationArea = All;
                }
                field(Created_at; Created_at)
                {
                    ApplicationArea = All;
                }
                field(User; User)
                {
                    ApplicationArea = All;
                }
                field(State; State)
                {
                    ApplicationArea = All;
                }
                field(URL; Html_url)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = URL;
                }
            }
        }
    }
    actions
    {
        area(Processing){
            action(RefreshALIssueList) {
                CaptionML = ENU = 'Refresh Issues';
                Promoted = true;
                PromotedCategory = Process;
                Image = RefreshLines;
                trigger onAction()
                begin
                    Rec.RefreshIssue;
                    CurrPage.Update;
                    if Rec.FindFirst then;
                end;
            }
        }
    }
}