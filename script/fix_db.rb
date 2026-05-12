require_relative 'config/environment'
ActiveRecord::SchemaMigration.delete_all
ActiveRecord::InternalMetadata.delete_all
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS schema_migrations")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS ar_internal_metadata")
