require 'csv'
require_relative 'plugin_migration_utils'

Sequel.migration do

  up do
    modified_records = []
    CSV.foreach(filepath_from_plugin_root, headers: true) do |csv_row|
      if (existing = self[:caas_aspace_refid].where(resource_id: csv_row[0])).any?
        if (existing_refid = existing.get(:next_refid)) > csv_row[1].to_i
          $stderr.puts "ERROR: Cannot update next refid for resource #{csv_row[0]}. Current stored refid (#{existing_refid}) is greater than the refid provided in the csv (#{csv_row[1]})."

          raise Exception.new('Migration halted by user') unless user_feedback == 'c'
        else
          $stderr.puts "INFO: Preparing to update next refid for resource #{existing.get(:resource_id)}."
          existing.update(next_refid: csv_row[1],
                          create_time: Time.now,
                          system_mtime: Time.now,
                          user_mtime: Time.now)
          modified_records << existing.first
        end
      else
        resource = self[:resource].where(id: csv_row[0])
        if resource.none?
          $stderr.puts "ERROR: Cannot create next refid record for resource #{csv_row[0]}. No resource record with that id exists."

          raise Exception.new('Migration halted by user') unless user_feedback == 'c'
        else
          $stderr.puts "INFO: Preparing to create new next refid for resource #{resource.get(:id)}."
          new_record_id = self[:caas_aspace_refid].insert(resource_id: csv_row[0],
                                                       next_refid: csv_row[1],
                                                       json_schema_version: 1,
                                                       create_time: Time.now,
                                                       system_mtime: Time.now,
                                                       user_mtime: Time.now)
          modified_records << self[:caas_aspace_refid].where(id: new_record_id).first
        end
      end
    end
    $stderr.puts "INFO: The following #{modified_records.count} records were successfully created/updated:"
    modified_records.each { |r| $stderr.puts(r)}
  end


  down do
    # The `caas_aspace_refid` table should have been empty before, so we'll just empty it.
    self[:caas_aspace_refid].delete
  end

end
