class Migration_0003 < NSEntityMigrationPolicy
  def beginEntityMapping(mapping, manager: manager, error: error)
    puts "Initialise custom migration"

    super

    true
  end

  def createDestinationInstancesForSourceInstance(source,
                                                  entityMapping: mapping,
                                                  manager: manager,
                                                  error: error)
    puts "For entity: #{source}"

    super

    true
  end

  def method_missing(method_id)
    puts method_id.id2name
  end
end
