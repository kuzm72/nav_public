page 50101 "Book Card"
{
    PageType = Card;
    SourceTable = Book;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No.";"No.")
                {
                    ApplicationArea = all;
                }
                field(Tite;Title)
                {
                    ApplicationArea = all;
                }
            }

            group(Details)
            {
                field(Author;Author)
                {
                    ApplicationArea = all;
                }
                field(Hardcover;Hardcover)
                {
                    ApplicationArea = all;
                }
                field("Page Count";"Page Count")
                {
                    ApplicationArea = all;
                }
            }
        }
    }
}