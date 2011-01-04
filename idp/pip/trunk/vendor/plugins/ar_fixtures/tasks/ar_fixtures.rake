
desc "Dump current data to file. Use TABLE=ModelName"
task :dump_table_to_file => :environment do
  if ENV['TABLE'].blank?
    raise "No TABLE value given. Set TABLE=ModelName"
  else
    eval "#{ENV['TABLE']}.dump_to_file"
  end
end
