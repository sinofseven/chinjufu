module Chinjufu
  module Tool
    def opt_validate(opt)
      if opt[:is_err] then
        pastel = Pastel.new
        puts pastel.red("Error: #{opt[:value]}")
        return false
      end
      return true
    end
    def deploy(opt)
    end
    
    private
    def init(opt)
      @log ||= Chinjufu::Log.new(opt[:value][:log_file])
    end
  end
end
