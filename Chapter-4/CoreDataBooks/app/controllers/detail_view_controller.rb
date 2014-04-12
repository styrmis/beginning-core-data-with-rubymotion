class DetailViewController < UITableViewController
  FormFields = [ 'Title', 'Author', 'Copyright' ]

  attr_accessor :book

  def viewDidLoad
    super

    if self.book.nil?
      @values = [ 'Title', 'Author', '' ]
    else
      @values = [ self.book.title,
                  self.book.author,
                  self.book.copyright ]
    end
  end

  # UITableView data source methods

  def numberOfSectionsInTableView(tableView)
    1
  end

  def tableView(tableView, numberOfRowsInSection: section)
    3
  end

  def tableView(tableView, cellForRowAtIndexPath: indexPath)
    cell = tableView.dequeueReusableCellWithIdentifier("CELL")

    cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleValue2,
                                                 reuseIdentifier: "CELL")

    cell.textLabel.text = FormFields[indexPath.row]

    cell.detailTextLabel.text = @values[indexPath.row]

    return cell
  end
end
