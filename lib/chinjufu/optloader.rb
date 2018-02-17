module Chinjufu
  module OptLoader
    def load(options, is_deploy)
      @input = options
      @option = {
        region: nil,
        stack_name: nil,
        template_file: nil,
        log_file: nil,
        verbose: nil
      }
      load_aws_cli_config(options)
      load_env
      load_file(options)
      load_cli(options)
      return validate_option(is_deploy)
    end

    def load_aws_cli_config(_options)
      profile_name = 'default'
      profile = AWSConfig[profile_name]
      return if profile.nil?
      region = profile.region
      @option[:region] = region unless region.nil?
    end

    def load_env
      region ||= ENV['AWS_REGION']
      region ||= ENV['AWS_DEFAULT_REGION']
      @option[:region] = region unless region.nil?
    end

    def load_file(options)
      default_file_name = 'chinjufu.yml'
      file = File.exist?(default_file_name) ? default_file_name : nil
      file = options['f'] unless options['f'].nil?
      return if file.nil?
      conf = YAML.load_file(file)
      @option[:region] = conf['region'] unless conf['region'].nil?
      @option[:stack_name] = conf['stack_name'] unless conf['stack_name'].nil?
      @option[:template_file] = conf["template_file"] unless conf['template_file'].nil?
    end

    def load_cli(options)
      key_region = 'region'
      key_stack_name = 'stack-name'
      key_template_file = 'template-file'
      key_verbose = 'verbose'
      @option[:region] = options[key_region] unless options[key_region].nil?
      @option[:stack_name] = options[key_stack_name] unless options[key_stack_name].nil?
      @option[:template_file] = options[key_template_file] unless options[key_template_file].nil?
      @option[:verbose] = options[key_verbose] unless options[key_verbose].nil?
    end

    def validate_option(is_deploy)
      result = {
        is_err: false,
        value: @option
      }
      if @option[:region].nil? || @option[:stack_name].nil? || (is_deploy && @option[:template_file].nil?) then
        result[:is_err] = true
        list = []
        list << "region" if @option[:region].nil?
        list << "stack-name" if @option[:stack_name].nil?
        list << "template-file" if is_deploy && @option[:template_file].nil?
        flag = false
        text = ""
        list.each do |key|
          text += ", " if flag
          flag = true unless flag
          text += key
        end
        text += " is necessary."
        result[:value] = text
      end
      return result
    end
  end
end
