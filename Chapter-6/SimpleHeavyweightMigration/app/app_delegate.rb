class AppDelegate
  include CDQ

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    self.perform_migrations
    cdq.init
    true
  end

  def perform_migrations
    # Load the latest model version, as found in the main app bundle
    model = NSManagedObjectModel.mergedModelFromBundles(nil)
    latest_model_version_string = model.versionIdentifiers.anyObject
    puts "[INFO] Latest model version is #{latest_model_version_string}"

    # Core Data Query by default sets the filename of the data store based on
    # the name of the app; we follow this convention so that our migration
    # process can work transparently alongside CDQ's initialisation process.
    app_name = NSBundle.mainBundle.objectForInfoDictionaryKey("CFBundleExecutable")
    store_path = File.join(NSHomeDirectory(), 'Documents', "#{app_name}.sqlite")
    store_url = NSURL.fileURLWithPath(store_path)

    puts "[INFO] Database file path: \"#{store_path}\""

    error_ptr = Pointer.new(:object)

    # Fetch the metadata for the current data store.
    metadata = NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL:store_url, error:error_ptr)

    # Check whether the metadata matches the current schema version or not.
    # Metadata will be nil if this is the first run of the app.
    if not metadata.nil?
      store_schema_version_string = metadata["NSStoreModelVersionIdentifiers"].first

      if store_schema_version_string.isEqualToString(latest_model_version_string)
        puts "[INFO] Store schema version matches latest schema version"
      end

      # Fetch all managed object models
      # NOTE: Result will be properly ordered if a suitable naming convention has been used
      #       e.g. 0001, 0002 etc. for the schema version identifier.
      mom_paths = NSBundle.mainBundle.pathsForResourcesOfType(".mom", inDirectory:"#{app_name}.momd")

      moms = []

      mom_paths.each do |path|
        moms << NSManagedObjectModel.alloc.initWithContentsOfURL(NSURL.fileURLWithPath(path))
      end

      puts "[INFO] #{moms.count} managed object model(s) found"

      mom_index_for_current_datastore = -1

      # Find the managed object model for the current datastore
      moms.each_with_index do |mom, index|
        mom_version_identifier = mom.versionIdentifiers.allObjects.first

        if mom_version_identifier == store_schema_version_string
          mom_index_for_current_datastore = index
        end
      end

      source_model = nil

      if mom_index_for_current_datastore == -1
        puts "[ERROR] Failed to find managed object model for current version of datastore"
        return
      else
        puts "[INFO] Current datastore version is managed object model #{mom_index_for_current_datastore+1} of #{moms.count}"
        source_model = moms[mom_index_for_current_datastore]
      end

      # All data migrations will appear here in the form
      # [ "000X schema description" => :migration_handler_method ]
      data_migrations = {
        "0003 migrate name data" => :migration_0003_migrate_name_data
      }

      # Working forwards one version at a time, migrate from that version to the next-latest version.
      moms.slice(mom_index_for_current_datastore + 1, moms.count - 1).each do |model_version|
        destination_model = model_version
        destination_model_version_name = destination_model.versionIdentifiers.allObjects.first

        puts "[INFO] Examining model version '#{destination_model_version_name}'"

        # The goal here is to get a mapping model for our migration, which will either be
        # programmatically configured via a data migration or will be inferred automatically
        # for a schema migration.
        mapping_model = nil

        error_ptr = Pointer.new(:object)

        if data_migrations.keys.include? destination_model_version_name
          puts "[INFO] Migrating forwards to model version '#{destination_model_version_name}' (Custom)"

          # Take the name of the handler method for the current migration and
          # 'send' it to this class, the app delegate. The send method will
          # cause the handler to be invoked, which we expect to return a mapping
          # model which should contain all the necessary information that Core
          # Data needs in order to execute it.
          mapping_model = self.send(data_migrations[destination_model_version_name])
        else
          puts "[INFO] Migrating forwards to model version '#{destination_model_version_name}' (Automatic/Inferred)"


          # The migration policy does not exist, so we will perform an automatic migration,
          # where Core Data will infer automatically how to bring the schema up to date.
          mapping_model = NSMappingModel.inferredMappingModelForSourceModel(source_model,
                                                                            destinationModel:destination_model,
                                                                            error:error_ptr)
        end

        unless mapping_model
          raise "[ERROR] Failed to infer mapping: #{error_ptr[0] and error_ptr[0].description}"
        end

        manager = NSMigrationManager.alloc.initWithSourceModel(source_model, destinationModel:destination_model)

        destination_store_url = store_url.URLByAppendingPathExtension('tmp')

        file_manager = NSFileManager.defaultManager

        error_ptr = Pointer.new(:object)

        # Remove the temporary destination store if it already exists from a previous migration.
        # If the file exists, the copying process which occurs later will fail (it won't overwrite
        # files).
        if file_manager.fileExistsAtPath(destination_store_url.path)
          error_ptr = Pointer.new(:object)
          file_manager.removeItemAtPath(destination_store_url.path, error:error_ptr)
        end

        error_ptr = Pointer.new(:object)

        # Migrate the data store, passing in a mapping model which has either
        # been automatically inferred (and is therefore equivalent to asking
        # Core Data to handle the migration automatically), or has been created
        # by a migration handler method which we have written.
        result = manager.migrateStoreFromURL(store_url,
                                             type:NSSQLiteStoreType,
                                             options:nil,
                                             withMappingModel:mapping_model,
                                             toDestinationURL:destination_store_url,
                                             destinationType:NSSQLiteStoreType,
                                             destinationOptions:nil,
                                             error:error_ptr)

        if result
          # Migration complete, we can now move the new store in place of the original

          coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(moms.last)

          store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration:nil, URL:destination_store_url, options:nil, error:error_ptr)

          file_manager.removeItemAtPath(store_url.path, error:error_ptr)

          coordinator.migratePersistentStore(store, toURL:store_url, options:nil, withType:NSSQLiteStoreType, error:error_ptr)
        else
          raise "[ERROR] Failed to migrate store: #{error_ptr[0].description}"
        end

        # On the next run through this loop (if there is one) we will migrate _from_
        # the version that we have just migrated _to_, and continue until there are
        # no more versions left; we are then at the latest version.
        source_model = destination_model
      end
    end
  end

  private

  def migration_0003_migrate_name_data
    # We will create our own mapping model from scratch
    mapping_model = NSMappingModel.alloc.init

    # Create an entity mapping which will map from the Person
    # entity in the source datastore to the Person entity
    # in the destination store, i.e. this is an operation
    # to transform the Person entity.
    entity_mapping = NSEntityMapping.alloc.init
    entity_mapping.setName("PersonToPerson")
    entity_mapping.setSourceEntityName("Person")
    entity_mapping.setDestinationEntityName("Person")

    # The source expression should evaluate to a fetch request
    # which returns all of the source records that should be
    # migrated. In our case we wish to migrate all of them,
    # but we could modify this to return only certain Person
    # records based on whatever criteria we like.
    source_expression = NSExpression.expressionWithFormat("FETCH(FUNCTION($manager, \"fetchRequestForSourceEntityNamed:predicateString:\" , \"Person\", \"TRUEPREDICATE\"), $manager.sourceContext, NO)")
    entity_mapping.setSourceExpression(source_expression)

    # We do not perform the actual data transformation here in
    # this migration method, instead we delegate this to a
    # dedicated class which we will provide. Core Data will
    # instantiate the class and delegate the task of
    # creating all Person entities in the destination store
    # to it.
    entity_mapping.setEntityMigrationPolicyClassName("Migration_0003")

    # The custom entity mapping type is for a mapping which
    # delegates the mapping procedure to a custom class, as
    # specified above.
    entity_mapping.setMappingType(NSCustomEntityMappingType)

    mapping_model.setEntityMappings([ entity_mapping ])

    mapping_model
  end
end
