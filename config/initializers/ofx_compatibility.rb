Rails.application.reloader.to_prepare do
  require "bigdecimal"

  unless BigDecimal.respond_to?(:new)
    class BigDecimal
      def self.new(*args, **kwargs)
        BigDecimal(args.first)
      end
    end
  end
end
