module Chinjufu
  class Log
    def initialize(is_verbose, path: nil)
      @is_verbose = is_verbose.nil? ? false : is_verbose
      @pastel = Pastel.new
    end

    def write_line(text, is_cfn: false)
      puts fix_text(text, is_cfn)
    end

    private 
    def fix_text(text, is_cfn)
      prefix = is_cfn ? "CloudFormation" : "Chinjufu"
      return @is_verbose ? @pastel.yellow("#{prefix}: ") + text : text
    end
  end
end
