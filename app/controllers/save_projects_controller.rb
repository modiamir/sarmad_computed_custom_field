class SaveProjectsController < ApplicationController

  def save_all
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

    flash[:notice] = messages.join('<br/>') if messages.any?
    flash[:error] = errors.join('<br/>') if errors.any?

    redirect_back_or_default home_path
  end
end
