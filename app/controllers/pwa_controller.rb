class PwaController < ApplicationController
  protect_from_forgery except: :service_worker
  layout false

  def manifest
    respond_to do |format|
      format.json
    end
  end

  def service_worker
    respond_to do |format|
      format.js
    end
  end
end
