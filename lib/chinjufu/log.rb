module Chinjufu
  class Log
    def initialize(path: nil)
      @pastel = Pastel.new
    end

    def write_line(text, is_cfn: false)
      puts fix_text(text, is_cfn)
    end

    private 
    def fix_text(text, is_cfn)
      prefix = is_cfn ? "CloudFormation" : "Chinjufu"
      return @pastel.yellow("#{prefix}: ") + text
    end
  end
end
