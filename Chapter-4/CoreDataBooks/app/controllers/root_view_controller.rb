class RootViewController < UITableViewController
  def viewDidLoad
    super

    # Set up the edit and add buttons
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = UIBarButtonItem.alloc\
                      .initWithBarButtonSystemItem(UIBarButtonSystemItemAdd,
                                                   target:self,
                                                   action:'addNewBook')
    # TODO: Add button

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

  def addNewBook
    # TODO: Show add book view controller
  end

  # UITableView delegate methods

  def numberOfSectionsInTableView(tableView)
    self.fetchedResultsController.sections.count
  end

  # To check how to write delegate/data source methods such as
  # this one, you can check them here:
  # http://www.rubymotion.com/developer-center/api/UITableViewDataSource.html
  def tableView(tableView, numberOfRowsInSection: section)
    section_info = self.fetchedResultsController.sections.objectAtIndex(section)
    section_info.numberOfObjects
  end

  def tableView(tableView, cellForRowAtIndexPath: indexPath)
    cell = tableView.dequeueReusableCellWithIdentifier("CELL")

    cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault,
                                                 reuseIdentifier: "CELL")

    book = self.fetchedResultsController.objectAtIndexPath(indexPath)

    cell.textLabel.text = book.title
    cell
  end

  def tableView(tableView, titleForHeaderInSection: section)
    self.fetchedResultsController.sections.objectAtIndex(section).name
  end

  # TODO: commitEditingStyle

  # Methods related to NSFetchedResultsController

  protected

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
    # @fetched_results_controller.delegate = self

    @fetched_results_controller
  end
end
