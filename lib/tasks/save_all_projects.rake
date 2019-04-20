
require 'active_record'
require 'pp'

namespace :save_all_projects do
  desc "Save all projects"
  task :save => :environment do
    messages = []
    errors = []

    Project.all.each do |project|
      begin
        project.save!
        messages << "Computed fields for project #{project.name} has been successfully calculated"
      rescue Exception => e
        errors << e.message
      end
    end

    messages.each(&method(:puts)) if messages.any?
    errors.each(&method(:puts)) if errors.any?

  end
end