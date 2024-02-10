// 8 Week SQL Challenge
// We just use Get from Folder as its easier and allow parameterization  for future proofing
let
    Source = Folder.Files("C:\Users\desktoppc\Desktop\m-Code SQL\8 Week SQL Challenge")
in
    Source

// Case 1 - Sales
let
  Source              = #"8 Week SQL Challenge", 
  #"Filtered Rows"    = Table.SelectRows(Source, each Text.Contains([Folder Path], "Case Study #1 - Danny's Diner")), 
  #"Filtered Rows1"   = Table.SelectRows(#"Filtered Rows", each ([Extension] = ".csv")), 
  #"Sales File"       = #"Filtered Rows1"{[Name = "sales.csv"]}[Content], 
  #"Imported CSV"     = Csv.Document(#"Sales File", [Delimiter = ",", Columns = 3, Encoding = 65001, QuoteStyle = QuoteStyle.None]), 
  #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]), 
  #"Changed Type"     = Table.TransformColumnTypes(#"Promoted Headers", {{"customer_id", type text}, {"product_id", Int64.Type}}), 
  #"Parsed Date"      = Table.TransformColumns(#"Changed Type", {{"order_date", each Date.From(DateTimeZone.From(_)), type date}})
in
  #"Parsed Date"

// Case 1 - Menu
let
  Source              = #"8 Week SQL Challenge", 
  #"Filtered Rows"    = Table.SelectRows(Source, each Text.Contains([Folder Path], "Case Study #1 - Danny's Diner")), 
  #"Filtered Rows1"   = Table.SelectRows(#"Filtered Rows", each ([Extension] = ".csv")), 
  #"Menu File"        = #"Filtered Rows1"{[Name = "menu.csv"]}[Content], 
  #"Imported CSV"     = Csv.Document(#"Menu File", [Delimiter = ",", Columns = 3, Encoding = 65001, QuoteStyle = QuoteStyle.None]), 
  #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]), 
  #"Changed Type"     = Table.TransformColumnTypes(#"Promoted Headers", {{"product_id", Int64.Type}, {"product_name", type text}, {"price", Int64.Type}})
in
  #"Changed Type"

// Case 1 - Members
let
  Source              = #"8 Week SQL Challenge", 
  #"Filtered Rows"    = Table.SelectRows(Source, each Text.Contains([Folder Path], "Case Study #1 - Danny's Diner")), 
  #"Filtered Rows1"   = Table.SelectRows(#"Filtered Rows", each ([Extension] = ".csv")), 
  #"Members File"     = #"Filtered Rows1"{[Name = "members.csv"]}[Content], 
  #"Imported CSV"     = Csv.Document(#"Members File", [Delimiter = ",", Columns = 2, Encoding = 65001, QuoteStyle = QuoteStyle.None]), 
  #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]), 
  #"Changed Type"     = Table.TransformColumnTypes(#"Promoted Headers", {{"customer_id", type text}}), 
  #"Parsed Date"      = Table.TransformColumns(#"Changed Type", {{"join_date", each Date.From(DateTimeZone.From(_)), type date}})
in
  #"Parsed Date"

// Case 1 Joined
// Since most of the questions require joining tables, lets just do it all in one query then refrence it in the other queries.
let
  Source                       = Table.NestedJoin(#"Case 1 - Sales", {"customer_id"}, #"Case 1 - Members", {"customer_id"}, "Case 1 - Members", JoinKind.LeftOuter),
  #"Merged Queries"            = Table.NestedJoin(Source, {"product_id"}, #"Case 1 - Menu", {"product_id"}, "Case 1 - Menu", JoinKind.LeftOuter),
  #"Expanded Case 1 - Members" = Table.ExpandTableColumn(#"Merged Queries", "Case 1 - Members", {"join_date"}, {"join_date"}),
  #"Expanded Case 1 - Menu"    = Table.ExpandTableColumn(#"Expanded Case 1 - Members", "Case 1 - Menu", {"product_name", "price"}, {"product_name", "price"})
in
  #"Expanded Case 1 - Menu"

// Case 1 Q1 - What is the total amount each customer spent at the restaurant?
let
  Source          = #"Case 1 Joined", 
  #"Grouped Rows" = Table.Group(Source, {"customer_id"}, {{"Total Amount Spent", each List.Sum([price]), type nullable number}})
in
  #"Grouped Rows"

// Case 1 Q2 - How many days has each customer visited the restaurant?
let
  Source                   = #"Case 1 Joined", 
  #"Removed Other Columns" = Table.SelectColumns(Source, {"customer_id", "order_date"}), 
  #"Grouped Rows"          = Table.Group(#"Removed Other Columns", {"customer_id"}, {{"Number of Days Visited", each Table.RowCount(Table.Distinct(_)), Int64.Type}})
in
  #"Grouped Rows"

// Case 1 Q3 - What was the first item from the menu purchased by each customer?
let
  Source          = #"Case 1 Joined", 
  #"Grouped Rows" = Table.Group(Source, {"customer_id"}, {{"First Item Purchased", each List.First([product_name]), type nullable text}, {"Purchased On", each List.Min([order_date]), type date}})
in
  #"Grouped Rows"

// Case 1 Q4 - What is the most purchased item on the menu and how many times was it purchased by all customers?
let
    Source             = #"Case 1 Joined", 
    #"Grouped Rows"    = Table.Group(Source, {"product_name"}, {{"Number of Times Purchased", each Table.RowCount(_), Int64.Type}}), 
    #"Sorted Rows"     = Table.Sort(#"Grouped Rows", {{"Number of Times Purchased", Order.Descending}}), 
    #"Kept First Rows" = Table.FirstN(#"Sorted Rows", 1)
in
    #"Kept First Rows"

// Case 1 Q5 - Which item was the most popular for each customer?
let
    Source                   = #"Case 1 Joined", 
    #"Removed Other Columns" = Table.SelectColumns(Source, {"customer_id", "product_name"}), 
    #"Grouped Rows"          = Table.Group(#"Removed Other Columns", {"customer_id"}, {{"Count", each _, type table [customer_id = nullable text, product_name = nullable text]}}), 
    #"Added Nested Count"    = Table.TransformColumns(#"Grouped Rows", {"Count", each Table.Group(_, {"product_name"}, {{"Nested Count", Table.RowCount, type number}}), type table}), 
    // Define a separate function for filtering the nested tables
    FilterNestedTables       = (nestedTable as table) as table =>
        let
            maxCount      = List.Max(Table.Column(nestedTable, "Nested Count")), 
            filteredTable = Table.SelectRows(nestedTable, each [Nested Count] = maxCount)
        in
            filteredTable, 
    #"Added Custom"          = Table.TransformColumns(#"Added Nested Count", {"Count", FilterNestedTables}), 
    #"Expanded Count"        = Table.ExpandTableColumn(#"Added Custom", "Count", {"product_name", "Nested Count"}, {"product_name", "Nested Count"}), 
    #"Renamed Columns"       = Table.RenameColumns(#"Expanded Count", {{"Nested Count", "purchase_count"}})
in
    #"Renamed Columns"

// Case 1 Q6 - Which item was purchased first by the customer after they became a member?
let
    Source       = #"Case 1 Joined", 
    FilteredRows = Table.SelectRows(Source, each [order_date] > [join_date]), 
    GroupedRows  = Table.Group(FilteredRows, {"customer_id"}, {{"first_purchase after membership", each _[product_name]{0}, type text}})
in
    GroupedRows

// Case 1 Q7 - Which item was purchased just before the customer became a member?
let
	Source       = #"Case 1 Joined",
	FilterRows   = Table.SelectRows(Source, each ([order_date] < [join_date])),
	GroupRows    = Table.Group(FilterRows, {"customer_id"}, {{"LastPurchase", each List.Max([order_date]), type date}}),
	JoinBack     = Table.NestedJoin(GroupRows, {"customer_id", "LastPurchase"}, FilterRows, {"customer_id", "order_date"}, "NewColumn", JoinKind.Inner),
	ExpandColumn = Table.ExpandTableColumn(JoinBack, "NewColumn", {"product_name"}, {"purchase_before_membership"})
in
	ExpandColumn

// Case 1 Q8 - What is the total items and amount spent for each member before they became a member?
let
    Source     = #"Case 1 Joined", 
    FilterRows = Table.SelectRows(Source, each ([order_date] < [join_date])), 
    GroupRows  = Table.Group(FilterRows, {"customer_id"}, {{"Total Items", each Table.RowCount(_), type number}, {"Total Amount Spent", each List.Sum([price]), type number}})
in
    GroupRows

// Case 1 Q9 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
let
    Source    = #"Case 1 Joined", 
    AddPoints = Table.AddColumn(Source, "Points", each if [product_name] = "sushi" then [price] * 20 else [price] * 10), 
    GroupRows = Table.Group(AddPoints, {"customer_id"}, {{"Total Points", each List.Sum([Points]), type number}})
in
    GroupRows

// Case 1 Q10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
let
    Source           = #"Case 1 Joined", 
    AddPointsColumn  = Table.AddColumn(Source, "Points", each try if [order_date] - [join_date] >= #duration(0, 0, 0, 0) and [order_date] - [join_date] <= #duration(6, 0, 0, 0) then [price] * 10 * 2 else if [product_name] = "sushi" then [price] * 10 * 2 else [price] * 10 otherwise null), 
    FilterJanuary    = Table.SelectRows(AddPointsColumn, each Date.Month([order_date]) = 1 and Date.Year([order_date]) = 2021), 
    GroupByCustomer  = Table.Group(FilterJanuary, {"customer_id"}, {{"Total Points", each List.Sum([Points]), type number}}), 
    #"Filtered Rows" = Table.SelectRows(GroupByCustomer, each [Total Points] <> null and [Total Points] <> "")
in
    #"Filtered Rows"

// Bonus 1 - Join All The Things
let
    sales                    = #"Case 1 Joined", 
    AddMemberColumn          = Table.AddColumn(sales, "MEMBER", each try if [join_date] <= [order_date] then "Y" else "N" otherwise "N"), 
    #"Removed Other Columns" = Table.SelectColumns(AddMemberColumn, {"customer_id", "order_date", "product_name", "price", "MEMBER"})
in
    #"Removed Other Columns"

// Bonus 2 - Rank All The Things
let
    Source           = #"Case 1 Joined", 
    AddMemberColumn  = Table.AddColumn(Source, "member", each if [order_date] < [join_date] or [join_date] = null then "N" else "Y"), 
    SortRows         = Table.Sort(AddMemberColumn, {{"customer_id", Order.Ascending}, {"member", Order.Ascending}, {"order_date", Order.Ascending}}), 
    GroupRows        = Table.Group(SortRows, {"customer_id", "member"}, {{"all", each _, type table}}), 
    AddRankingColumn = Table.TransformColumns(GroupRows, {"all", each if _[member]{0} = "N" then Table.AddColumn(_, "ranking", each null) else Table.AddIndexColumn(_, "ranking", 1, 1)}), 
    RemoveOldColumns = Table.RemoveColumns(AddRankingColumn, {"customer_id", "member"}), 
    #"Expanded all"  = Table.ExpandTableColumn(RemoveOldColumns, "all", {"customer_id", "order_date", "product_id", "join_date", "product_name", "price", "member", "ranking"}, {"customer_id", "order_date", "product_id", "join_date", "product_name", "price", "member", "ranking"}),
    #"Removed Other Columns" = Table.SelectColumns(#"Expanded all",{"customer_id", "order_date", "product_name", "price", "member", "ranking"})
in
    #"Removed Other Columns"