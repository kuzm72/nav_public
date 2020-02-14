page 50102 "Book List"
{
    PageType = List;
    SourceTable = Book;
    CardPageId = "Book Card";

    layout
    {
        area(content)
        {
            repeater(books)
            {
                field("No.";"No.")
                {
                    ApplicationArea = all;
                }
                field(Tite;Title)
                {
                    ApplicationArea = all;
                }
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