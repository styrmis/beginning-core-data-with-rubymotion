class Migration_0003 < NSEntityMigrationPolicy
  def beginEntityMapping(mapping, manager:manager, error:error)
    puts "[INFO] Initialise custom migration"

    true
  end

  def createDestinationInstancesForSourceInstance(source,
                                                  entityMapping:mapping,
                                                  manager:manager,
                                                  error:error)
    puts "[INFO] Migrating entity: #{source}"

    source_keys = source.entity.attributesByName.allKeys.mutableCopy
    source_values = source.dictionaryWithValuesForKeys(source_keys)
    destination = NSEntityDescription.insertNewObjectForEntityForName(mapping.destinationEntityName,
                                                                      inManagedObjectContext:manager.destinationContext)

    destination_keys = destination.entity.attributesByName.allKeys

    # Populate destination instance with data from source instance
    destination_keys.each do |key|
      value = source_values.valueForKey(key)
      # Avoid NULL values
      if (value and !value.isEqual(NSNull.null))
        destination.setValue(value, forKey:key)
      end
    end

    # Perform the migration, which is to populate the first_name and
    # last_name fields from the contents of the name field
    name = source.valueForKey("name")
    name_parts = name.split(" ")
    if name_parts.count > 1
      destination.setValue(name_parts[0], forKey:"first_name")
      destination.setValue(name_parts.slice(1, name_parts.count).join(" "), forKey:"last_name")
    else
      destination.setValue(name, forKey:"first_name")
    end

    true
  end
end
