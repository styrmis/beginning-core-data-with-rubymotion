class Task < NSManagedObject
  def self.entity
    @entity ||= begin
      # A task has a description field, a numeric priority (where 5 will
      # signify 'no priority' and will otherwise be set between 1 and 4,
      # with 1 being the highest priority and 4 the lowest.
      # A boolean field `completed` tracks whether the task has been
      # completed or not
      entity = NSEntityDescription.alloc.init
      entity.name = 'Task'
      entity.managedObjectClassName = 'Task'
      entity.properties =
              [ 'task_description', NSStringAttributeType,
                'priority', NSInteger32AttributeType,
                'completed', NSBooleanAttributeType ]\
              .each_slice(2).map do |name, type, optional|
        property = NSAttributeDescription.alloc.init
        property.name = name
        property.attributeType = type
        property.optional = false
        property
      end

      # Return the entity
      entity
    end
  end

  def to_s
    "Priority: #{self.priority} " +
    "Completed: #{self.completed} " +
    "Description: '#{self.task_description}'"
  end
end
