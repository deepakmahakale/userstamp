module Ddb
  module Userstamp
    module MigrationHelper
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        def userstamps(options = {})
          # add backwards compatibility support
          options = {include_deleted_by: options} if (options === true || options === false)

          append_id_suffix = options[:include_id] ? '_id' : ''

          column(Ddb::Userstamp.compatibility_mode ? "created_by#{append_id_suffix}".to_sym : :creator_id, :integer)
          column(Ddb::Userstamp.compatibility_mode ? "updated_by#{append_id_suffix}".to_sym : :updater_id, :integer)
          column(Ddb::Userstamp.compatibility_mode ? "deleted_by#{append_id_suffix}".to_sym : :deleter_id, :integer) if options[:include_deleted_by]
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::Table.send(:include, Ddb::Userstamp::MigrationHelper)
