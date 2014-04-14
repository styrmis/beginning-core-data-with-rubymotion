class RootViewController < UITableViewController
  def viewDidLoad
    super

    # Set up the edit and add buttons
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = UIBarButtonItem.alloc\
                      .initWithBarButtonSystemItem(UIBarButtonSystemItemAdd,
                                                   target:self,
                                                   action:'addNewBook:')
    error_ptr = Pointer.new(:object)

    if not self.fetchedResultsController.performFetch(error_ptr)
      # NOTE: We will need to replace this with proper error handling
      #       code.
      #       abort() causes the application to generate a crash log
      #       and terminate; useful during development but should not
      #       appear in a production application.
      NSLog("Unresolved error %@, %@", error_ptr, error_ptr.userInfo)
      abort
    end
  end

  def viewWillAppear(animated)
    super

    self.tableView.reloadData
  end

  def viewDidUnload
    @fetched_results_controller = nil
  end

  def addNewBook(sender)
    addVC = DetailViewController.alloc.init
    self.navigationController.pushViewController(addVC, animated:true)
  end

  # UITableView data source methods

  def numberOfSectionsInTableView(tableView)
    self.fetchedResultsController.sections.count
  end

  # To check how to write delegate/data source methods such as
  # this one, you can check them here:
  # http://www.rubymotion.com/developer-center/api/UITableViewDataSource.html
  def tableView(tableView, numberOfRowsInSection:section)
    section_info = self.fetchedResultsController.sections.objectAtIndex(section)
    section_info.numberOfObjects
  end

  def configureCell(cell, atIndexPath: indexPath)
    book = self.fetchedResultsController.objectAtIndexPath(indexPath)

    cell.textLabel.text = book.title
    cell
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cell = tableView.dequeueReusableCellWithIdentifier("CELL")

    cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault,
                                                 reuseIdentifier: "CELL")
    self.configureCell(cell, atIndexPath: indexPath)

    return cell
  end

  def tableView(tableView, titleForHeaderInSection:section)
    self.fetchedResultsController.sections.objectAtIndex(section).name
  end

  def tableView(tableView, commitEditingStyle:editingStyle, forRowAtIndexPath:indexPath)
    if editingStyle == UITableViewCellEditingStyleDelete
      cdq.contexts.current.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath))
      cdq.save
    end
  end

  # Table view delegate

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)
    selected_book = self.fetchedResultsController.objectAtIndexPath(indexPath)

    detailVC = DetailViewController.alloc.init
    detailVC.book = selected_book

    self.navigationController.pushViewController(detailVC, animated:true)

    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  end

  # Table view editing

  def tableView(tableView, canMoveRowAtIndexPath:indexPath)
    # No rows in the table are re-orderable
    false
  end

  def setEditing(editing, animated: animated)
    super

    # If editing, remove the 'add' button
    # If not editing, reinstate it
    if editing
      @rightBarButtonItem = self.navigationItem.rightBarButtonItem;
      self.navigationItem.rightBarButtonItem = nil
    else
      self.navigationItem.rightBarButtonItem = @rightBarButtonItem
      @rightBarButtonItem = nil;
    end
  end

  # Methods related to NSFetchedResultsController

  def fetchedResultsController
    if not @fetched_results_controller.nil?
      return @fetched_results_controller
    end

    fetch_request = NSFetchRequest.alloc.init
    fetch_request.setEntity(Book.entity_description)

    author_sort_descriptor = NSSortDescriptor.alloc.initWithKey("author",
                                                                ascending: true)
    title_sort_descriptor = NSSortDescriptor.alloc.initWithKey("title",
                                                                ascending: true)

    fetch_request.setSortDescriptors([ author_sort_descriptor,
                                       title_sort_descriptor ])

    @fetched_results_controller = NSFetchedResultsController.alloc.initWithFetchRequest(fetch_request,
                                                                                        managedObjectContext: cdq.contexts.current,
                                                                                        sectionNameKeyPath: "author",
                                                                                        cacheName: "Root")

    # TODO: Implement delegate methods
    @fetched_results_controller.delegate = self

    @fetched_results_controller
  end

  # NSFetchedResultsController delegate methods to respond to additions, removals and so on.

  def controllerWillChangeContent(controller)
    self.tableView.beginUpdates
  end

  def controller(controller,
                 didChangeObject:anObject,
                 atIndexPath:indexPath,
                 forChangeType:type,
                 newIndexPath:newIndexPath)
    case type
    when NSFetchedResultsChangeInsert
      self.tableView.insertRowsAtIndexPaths([newIndexPath],
                                            withRowAnimation:UITableViewRowAnimationAutomatic)
    when NSFetchedResultsChangeDelete
      self.tableView.deleteRowsAtIndexPaths([indexPath],
                                            withRowAnimation:UITableViewRowAnimationAutomatic)
    when NSFetchedResultsChangeUpdate
      self.configureCell(self.tableView.cellForRowAtIndexPath(indexPath), atIndexPath:indexPath)
    when NSFetchedResultsChangeMove
      self.tableView.deleteRowsAtIndexPaths([indexPath],
                                            withRowAnimation:UITableViewRowAnimationAutomatic)
      self.tableView.insertRowsAtIndexPaths([newIndexPath],
                                            withRowAnimation:UITableViewRowAnimationAutomatic)
    end
  end

  def controller(controller,
                 didChangeSection:sectionInfo,
                 atIndex:sectionIndex,
                 forChangeType:type)
    case type
    when NSFetchedResultsChangeInsert
      self.tableView.insertSections(NSIndexSet.indexSetWithIndex(sectionIndex),
                                    withRowAnimation:UITableViewRowAnimationAutomatic)
    when NSFetchedResultsChangeDelete
      self.tableView.deleteSections(NSIndexSet.indexSetWithIndex(sectionIndex),
                                    withRowAnimation:UITableViewRowAnimationAutomatic)
    end
  end

  def controllerDidChangeContent(controller)
    self.tableView.endUpdates
  end
end
