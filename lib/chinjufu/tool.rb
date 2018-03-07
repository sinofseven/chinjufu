module Chinjufu
  module Tool
    def opt_validate(opt, logger)
      if opt[:is_err] then
        pastel = Pastel.new
        logger.write_line pastel.red("Error: #{opt[:value]}")
        return false
      end
      return true
    end
    
    def exec_deploy(opt, logger)
      init(opt, logger)
      opt_deploy = exec_deploy_option
      return if exec_deploy_faild_not_exist_template_file(opt_deploy)
      stack = stack_info
      is_update = true
      if stack[:is_err] then
        str = stack[:value].message
        return if stack_info_failure(str)
        is_update = false
      end
      deploy_output = exec_deploy_stack(opt_deploy, is_update)
      return if exec_deploy_stack_failure(deploy_output)
      listen_result = exec_listen_events(false)
      exec_listen_events_failure(listen_result, false)
    end
    
    def exec_remove(opt, logger)
      init(opt, logger)
      stack = stack_info
      if stack[:is_err] then
        str = stack[:value].message
        return if stack_info_failure(str)
      end
    end
    
    private
    def init(opt, logger)
      @log ||= logger
      @cfn ||= Aws::CloudFormation::Client.new(region: opt[:region])
      @pastel ||= Pastel.new
      @stack_name ||= opt[:stack_name]
      @template_file ||= opt[:template_file]
      @request_token ||= SecureRandom.uuid
      @interval ||= 1
      @verbose ||= opt[:verbose]
    end
    
    def exec_deploy_option
      return nil unless File.exists?(@template_file)
      template = File.read(@template_file)
      result = {
        stack_name: @stack_name,
        template_body: template,
        client_request_token: @request_token
      }
      return result
    end
    
    def exec_deploy_faild_not_exist_template_file(opt)
      return false unless opt.nil?
      text = @pastel.red("error: template file does not exist.")
      @log.write_line(text)
    end
    
    def is_bottom_text_not_exist(str)
      return (str =~ /does not exist$/) != nil
    end
    
    def stack_info
      resp = {
        is_err: false,
        value: nil
      }
      begin
        resp[:value] = @cfn.describe_stacks({
          stack_name: @stack_name
        })
      rescue => e
        resp[:is_err] = true
        resp[:value] = e
      end
      return resp
    end
    
    def stack_info_failure(message)
      return false if is_bottom_text_not_exist(message)
      @log.write_line(@pastel.red("error: describe_stacks was failure."))
      @log.write_line(@pastel.yellow("  #{message}"))
      return true
    end
    
    def exec_deploy_stack(param, is_update)
      result = nil
      begin
        @cfn.create_stack(param) unless is_update
        @cfn.update_stack(param) if is_update
      rescue => e
        result = e
      end
      return result
    end
    
    def exec_deploy_stack_failure(output)
      return false if output.nil?
      @log.write_line(@pastel.red("error: create/update stack was failure."))
      @log.write_line(@pastel.yellow("  #{output.message}"))
      return true
    end
    
    def print_event(event)
      return unless @verbose
      @log.write_line("#{event.resource_status} #{event.resource_type} #{event.logical_resource_id}", is_cfn: true)
    end
    
    def is_finish_event(event)
      return false unless event.resource_type == "AWS::CloudFormation::Stack"
      return (event.resource_status =~ /(FAILED|COMPLETE)$/) != nil
    end
    
    def exec_listen_events(is_delete)
      err = nil
      list_failure = []
      list_event_ids = []
      param = {
        stack_name: @stack_name
      }
      flag_stop = false
      loop do
        break if flag_stop
        begin
          resp = @cfn.describe_stack_events(param)
          resp.stack_events.reverse().each do |event|
            next unless event.client_request_token == @request_token
            next if list_event_ids.include?(event.event_id)
            list_event_ids << event.event_id
            list_failure << event if event.resource_type != 'AWS::CloudFormation::Stack' && (event.resource_status =~ /FAILED$/)
            print_event(event)
            flag_stop = true if is_finish_event(event)
          end
          sleep @interval unless flag_stop
        rescue => e
          err = e unless is_delete && is_bottom_text_not_exist(e.message)
          flag_stop = true
        end
      end
      result = {
        err: !err.nil? ? err : nil,
        failure: err.nil? && list_failure.length > 0 ? list_failure : nil
      }
      return result
    end
    
    def print_failure_event(event)
    end
    
    def exec_listen_events_failure(output, is_delete)
      unless output[:err].nil? then
        @log.write_line(@pastel.red("error: happen error at listening stack events"))
        @log.write_line(@pastel.yellow("  #{output[:err].message}"))
        return
      end
      unless output[:failure].nil? then
        @log.write_line(@pastel.red("error: faild at deploying stack"))
        output[:failure].each do |event|
          print_failure_event(event)
        end
        return
      end
      @log.write_line(@pastel.yellow("#{is_delete ? "delete" : "deploy"} stack is success !!!"))
    end
  end
end
