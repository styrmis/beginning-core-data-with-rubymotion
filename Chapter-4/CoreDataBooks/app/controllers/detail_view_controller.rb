class DetailViewController < UITableViewController
  FormFields = [ 'Title', 'Author', 'Copyright' ]

  attr_accessor :book

  def viewDidLoad
    super

    if self.class == DetailViewController
      self.navigationItem.rightBarButtonItem = self.editButtonItem
    end

    self.tableView.allowsSelectionDuringEditing = true

    if self.book.nil?
      @values = [ 'Title', 'Author', '' ]
    else
      # Load the values from the book object and update interface
      self.updateInterface
    end
  end

  def viewWillAppear(animated)
    super

    self.updateInterface

    # Every time the view appears we want to check whether the current
    # values will result in a valid Book record.
    # This works because in order to edit an attribute the user is taken
    # to the separate editing view and returns to this view, thus ensuring
    # that this will be called whenever the field values change.
    self.updateRightBarButtonItemState
  end

  # Override setEditing so that we can manage the saving of the context
  # when we finish editing, and later so that we can add in undo handling.
  def setEditing(editing, animated:animated)
    super

    # Hide the back button when editing starts,
    # show it again when editing finishes.
    self.navigationItem.setHidesBackButton(editing, animated:animated)

    # TODO: Add in undo management

    if not editing
      # We have finished editing, so we persist any changes to the database
      cdq.save
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

  # Catch taps before they are handled by didSelectRowAtIndexPath
  # and if the table view is not in editing mode, do not process
  # the selection.
  def tableView(tableView, willSelectRowAtIndexPath:indexPath)
    if self.isEditing
      indexPath
    else
      nil
    end
  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    # Only show the EditingViewController is the table view is in
    # editing mode (the Edit button has been tapped).
    if self.isEditing
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

  # Disable row deletion completely (we always want to show the same three
  # options)
  def tableView(tableView, editingStyleForRowAtIndexPath:indexPath)
    UITableViewCellEditingStyleNone
  end

  # Disable indentation of table view when editing (usually done to make space
  # for deletion control.
  def tableView(tableView, shouldIndentWhileEditingRowAtIndexPath:indexPath)
    false
  end

  def updateInterface
    @values = [ self.book.title,
                self.book.author,
                self.dateFormatter.stringFromDate(book.copyright) ]
    self.tableView.reloadData
  end

  def updateRightBarButtonItemState
    # Conditionally enable the right bar button item
    # it should only be enabled if the book is in a valid state for saving.
    self.navigationItem.rightBarButtonItem.enabled = self.book.validateForUpdate(nil)
  end

  def dateFormatter
    @dateFormatter ||= NSDateFormatter.alloc.init.tap {|df|
      df.setDateStyle NSDateFormatterMediumStyle
      df.setTimeStyle NSDateFormatterNoStyle
    }

    @dateFormatter
  end
end
