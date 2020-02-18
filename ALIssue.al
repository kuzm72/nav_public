table 50115 ALIssue
{
    DataClassification = ToBeClassified;
    LookupPageId = ALIssueList;

    fields
    {
        field(1; ID; Integer)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'ID';

        }
        field(2; Number; Integer)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Number';
        }
        field(3; Title; Text[250])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Title';
        }
        field(4; Created_at; DateTime)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'Created At';
        }
        field(5; User; Text[50])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'User';
        }
        field(6; State; Text[30])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'State';
        }
        field(7; Html_url; Text[250])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'URL';
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    procedure RefreshIssue()
      var RefreshALIssue: Codeunit RefreshALIssueCode;
    begin
      RefreshALIssue.Refresh();
    end;
}