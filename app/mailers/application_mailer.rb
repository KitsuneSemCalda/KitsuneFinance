class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_SENDER", "Kitsune Finance <noreply@kitsune.finance>")
  layout "mailer"
end
