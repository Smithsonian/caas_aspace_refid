# frozen_string_literal: true

def filepath_from_plugin_root
  if ENV['REFID_SEED_FILE']
    user_input = ENV['REFID_SEED_FILE']
  else
    $stderr.puts "********* What is the path to your csv file (relative to the `caas_aspace_refid/migrations/csvs` directory)? *********"

    user_input = $stdin.gets.chomp
  end

  File.join(File.dirname('../plugins/caas_aspace_refid/migrations/csvs/.'), user_input).to_s
end

def user_feedback
  $stderr.puts "********* What would you like to do? *********"
  $stderr.puts "(c)ontinue anyway (the above error will have to be addressed separately in a future migration, db update, etc.)"
  $stderr.puts "(q)uit migration without making any changes"

  $stdin.gets.chomp
end
