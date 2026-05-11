class GoalStatusCheckJob < ApplicationJob
  queue_as :default

  def perform
    Goal.where(status: "active").find_each do |goal|
      if goal.deadline && goal.deadline < Date.today
        goal.update!(status: "paused")
        Rails.logger.info "[GOAL] User##{goal.user_id} — Meta##{goal.id} (#{goal.name}) " \
                          "pausada por prazo expirado (#{goal.deadline})"
      end
    end
  end
end
