module Monetizable
  extend ActiveSupport::Concern

  private

  def cents_from_string(value)
    return nil if value.blank?
    (value.to_f * 100).to_i
  end

  def convert_to_cents(*fields)
    resource_params = params[resource_name]
    return unless resource_params
    fields.each do |field|
      next if resource_params[field].blank?
      resource_params[field] = cents_from_string(resource_params[field])
    end
  end

  def resource_name
    controller_name.singularize
  end
end
