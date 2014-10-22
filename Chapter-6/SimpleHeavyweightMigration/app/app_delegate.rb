class AppDelegate
  include CDQ

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    self.perform_migrations
    cdq.init
    true
  end

  def perform_migrations
    model = NSManagedObjectModel.mergedModelFromBundles(nil)
    latest_model_version_string = model.versionIdentifiers.anyObject
    puts "[INFO] Latest model version is #{latest_model_version_string}"

    app_name = NSBundle.mainBundle.objectForInfoDictionaryKey("CFBundleExecutable")
    store_path = File.join(NSHomeDirectory(), 'Documents', "#{app_name}.sqlite")
    store_url = NSURL.fileURLWithPath(store_path)

    puts "[INFO] Database file path: \"#{store_path}\""

    error_ptr = Pointer.new(:object)

    # Fetch the metadata for the current data store.
    metadata = NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(NSSQLiteStoreType, URL: store_url, error: error_ptr)

    # Check whether the metadata matches the current schema version or not.
    # Metadata will be nil if this is the first run of the app.
    if not metadata.nil?
      store_schema_version_string = metadata["NSStoreModelVersionIdentifiers"].first

      if store_schema_version_string.isEqualToString(latest_model_version_string)
        puts "[INFO] Store schema version matches latest schema version"
      end

      # Fetch all managed object models
      # NOTE: Result will be properly ordered if a suitable naming convention has been used
      #       e.g. 001, 002 etc. for the schema version identifier.
      mom_paths = NSBundle.mainBundle.pathsForResourcesOfType(".mom", inDirectory: "#{app_name}.momd")

      moms = []

      mom_paths.each do |path|
        moms << NSManagedObjectModel.alloc.initWithContentsOfURL(NSURL.fileURLWithPath(path))
      end

      puts "[INFO] #{moms.count} managed object model(s) found"

      # Find the managed object model for the current datastore
      mom_index_for_current_datastore = -1

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

      # 4. Working forwards one migration at a time, migrate from that version to the latest version.
      moms.slice(mom_index_for_current_datastore + 1, moms.count - 1).each do |model_version|
        destination_model = model_version
        destination_model_version_name = destination_model.versionIdentifiers.allObjects.first
        destination_model_version_identifier = destination_model_version_name.split(" ")[0]

        puts "[INFO] Examining model version '#{destination_model_version_name}'"

        if not source_model.entityVersionHashesByName.isEqualToDictionary(destination_model.entityVersionHashesByName)
          # The models have different version information, so we migrate

          # CHECK: Do we have a custom migration policy for this migration?
          #        Take the version identiier for the destination model and check
          #        whether a migration policy class exists for it.
          mapping_model = nil

          if Object.const_defined?("Migration_#{destination_model_version_identifier}")
            puts "[INFO] Migrating forwards to model version '#{destination_model_version_name}' (Custom)"
            # TODO
          else
            puts "[INFO] Migrating forwards to model version '#{destination_model_version_name}' (Automatic/Inferred)"

            error_ptr = Pointer.new(:object)

            # The migration policy does not exist, so we will perform an automatic migration,
            # where Core Data will infer automatically how to bring the schema up to date.
            mapping_model = NSMappingModel.inferredMappingModelForSourceModel(source_model,
                                                                              destinationModel: destination_model,
                                                                              error: error_ptr)

            puts "[INFO] Inferred Mapping Model: #{mapping_model}"

            unless mapping_model
              raise "[ERROR] Failed to infer mapping: #{error_ptr[0].description}"
            end
          end

          manager = NSMigrationManager.alloc.initWithSourceModel(source_model, destinationModel: destination_model)

          destination_store_url = store_url.URLByAppendingPathExtension('tmp')
          puts "[INFO] Migrating store at #{store_url} to destination store at #{destination_store_url}"

          file_manager = NSFileManager.defaultManager

          error_ptr = Pointer.new(:object)

          # Remove the temporary destination store if it already exists from a previous migration.
          # If the file exists, the copying process which occurs later will fail (it won't overwrite
          # files).
          if file_manager.fileExistsAtPath(destination_store_url.path)
            error_ptr = Pointer.new(:object)
            file_manager.removeItemAtPath(destination_store_url.path, error: error_ptr)
          end

          error_ptr = Pointer.new(:object)

          result = manager.migrateStoreFromURL(store_url,
                                               type: NSSQLiteStoreType,
                                               options: { NSSQLitePragmasOption: {"journal_mode" => "DELETE"} },
                                               withMappingModel: mapping_model,
                                               toDestinationURL: destination_store_url,
                                               destinationType: NSSQLiteStoreType,
                                               destinationOptions: nil,
                                               error: error_ptr)

          if result
            # Migration complete, we can now move the new store in place of the original

            coordinator = NSPersistentStoreCoordinator.alloc.initWithManagedObjectModel(moms.last)

            store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: destination_store_url, options: nil, error: error_ptr)

            file_manager.removeItemAtPath(store_url.path, error: error_ptr)

            coordinator.migratePersistentStore(store, toURL:store_url, options:nil, withType:NSSQLiteStoreType, error:error_ptr)
          else
            raise "[ERROR] Failed to migrate store: #{error_ptr[0].description}"
          end
        end

        # On the next run through this loop (if there is one) we will migrate _from_
        # the version that we have just migrated _to_, and continue until there are
        # no more versions left; we are then at the latest version.
        source_model = model_version
      end
    end
  end
end
