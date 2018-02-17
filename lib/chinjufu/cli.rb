module Chinjufu
  class CLI < Thor
    include Chinjufu::OptLoader
    include Chinjufu::Tool
    class_option '--stack-name', type: :string
    class_option '--region', type: :string
    class_option '--setting-file', type: :string, aliases: '-f'
    class_option '--verbose', type: :boolean, aliases: '-v'

    desc 'deploy', 'create/update stack'
    option '--template-file', type: :string
    def deploy
      opt = load(options, true)
      return unless opt_validate(opt)
      puts 'exec deploy'

    end

    desc 'remove', 'delete stack'
    def remove
      opt = load(options, false)
      return unless opt_validate(opt)
      puts "exec remove"
    end
  end
end
