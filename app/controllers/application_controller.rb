class ApplicationController < ActionController::Base
  include Monetizable
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Redirect to dashboard after sign in
  def after_sign_in_path_for(resource)
    dashboard_path
  end
end
