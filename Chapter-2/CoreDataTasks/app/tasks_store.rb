class TasksStore
  def self.shared
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize
    # Initialise the Core Data stack

    model = NSManagedObjectModel.alloc.init
    model.entities = [ Task.entity ]

    store = NSPersistentStoreCoordinator\
            .alloc.initWithManagedObjectModel(model)
    store_path = File.join(NSHomeDirectory(),
                           'Documents',
                           'CoreDataTasks.sqlite')
    store_url = NSURL.fileURLWithPath(store_path)

    puts "[INFO] Database file path: #{store_path}"

    error_ptr = Pointer.new(:object)

    unless store.addPersistentStoreWithType(NSSQLiteStoreType,
                                            configuration: nil,
                                            URL: store_url,
                                            options: nil,
                                            error: error_ptr)
      raise "[ERROR] Failed to create persistent store: " +
            error_ptr[0].description
    end

    context = NSManagedObjectContext.alloc.init
    context.persistentStoreCoordinator = store

    # Store the context as an instance variable of TasksStore
    @context = context
  end

  def create_task(task_description,
                  withPriority:priority,
                  andCompleted:completed)
    task = NSEntityDescription\
      .insertNewObjectForEntityForName('Task',
                                       inManagedObjectContext: @context)
    task.task_description = task_description
    task.priority = priority
    task.completed = completed
    task
  end

  def create_task(task_description)
    create_task(task_description, withPriority: 5, andCompleted: false)
  end

  def delete_task(task)
    @context.deleteObject(task)
  end

  def save_context
    error_ptr = Pointer.new(:object)

    unless @context.save(error_ptr)
      raise "[ERROR] Error saving the context: #{error_ptr[0].description}"
    end

    true
  end

  def get_tasks(opts = {})
    defaults = {priority: nil, completed: nil, task_description: nil}
    opts = defaults.merge(opts)

    request = NSFetchRequest.alloc.init
    request.entity = NSEntityDescription\
                             .entityForName('Task',
                                            inManagedObjectContext: @context)

    predicates = []

    unless opts[:completed].nil?
      completed = NSNumber.numberWithBool(opts[:completed])
      completed_predicate = NSPredicate.predicateWithFormat("completed == %@",
                                                            completed)
      predicates << completed_predicate
    end

    unless opts[:priority].nil?
      priority = NSNumber.numberWithInt(opts[:priority])
      priority_predicate = NSPredicate.predicateWithFormat("priority == %@",
                                                           priority)
      predicates << priority_predicate
    end

    unless opts[:task_description].nil?
      task_description = opts[:task_description]
      task_description_predicate = NSPredicate\
                      .predicateWithFormat("task_description CONTAINS[cd] %@",
                                           task_description)
      predicates << task_description_predicate
    end

    if predicates.count > 0
      # Create a compound predicate by ANDing together any predicates specified
      # thus far.
      compound_predicate = NSCompoundPredicate.andPredicateWithSubpredicates(predicates)
      request.setPredicate(compound_predicate)
    end

    completed_sort = NSSortDescriptor.alloc.initWithKey("completed",
                                                        ascending: true)
    priority_sort = NSSortDescriptor.alloc.initWithKey("priority",
                                                       ascending: true)
    description_sort = NSSortDescriptor.alloc.initWithKey("task_description",
                                                          ascending: true)

    request.setSortDescriptors([ completed_sort,
                                 priority_sort,
                                 description_sort ])

    error_ptr = Pointer.new(:object)

    data = @context.executeFetchRequest(request, error: error_ptr)

    if data == nil
      raise "[ERROR] Error fetching taskss: #{error_ptr[0].description}"
    end

    data
  end

  # A simpler version of `get_tasks` that appears earlier in the book,
  # demonstrating the minimum required to fetch records from Core Data.
  def get_tasks__simple
    request = NSFetchRequest.alloc.init
    request.entity = NSEntityDescription\
                             .entityForName('Task',
                                            inManagedObjectContext: @context)

    error_ptr = Pointer.new(:object)

    data = @context.executeFetchRequest(request, error: error_ptr)

    if data == nil
      raise "[ERROR] Error fetching tasks: #{error_ptr[0].description}"
    end

    data
  end
end
