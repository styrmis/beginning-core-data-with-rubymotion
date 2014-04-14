class DetailViewController < UITableViewController
  FormFields = [ 'Title', 'Author', 'Copyright' ]

  attr_accessor :book

  def viewDidLoad
    super

    if self.class == DetailViewController.class
      self.navigationItem.rightBarButtonItem = self.editButtonItem;
    end

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

  def tableView(tableView, numberOfRowsInSection:section)
    3
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cell = tableView.dequeueReusableCellWithIdentifier("CELL")

    cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleValue2,
                                                 reuseIdentifier: "CELL")

    cell.textLabel.text = FormFields[indexPath.row]

    cell.detailTextLabel.text = @values[indexPath.row]

    return cell
  end

  # UITableView delegate methods

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    editingVC = EditingViewController.alloc.init

    editingVC.editedObject = self.book

    case indexPath.row
    when 0
      editingVC.editedFieldKey = "title"
    when 1
      editingVC.editedFieldKey = "author"
    when 2
      editingVC.editedFieldKey = "copyright"
    end

    # NOTE: The original CoreDataBooks example uses localised strings
    #       for the field name (editedFieldName) but we just
    #       capitalise the key (e.g. "author" becomes "Author" as that
    #       is sufficient, unless we want to localise the app.
    editingVC.editedFieldName = editingVC.editedFieldKey.capitalize

    self.navigationController.pushViewController(editingVC, animated: true)

    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  end
end
