require 'rspec/testrail/version'
require 'rspec/testrail/client'

module RSpec
  module Testrail
    class << self
      attr_reader :options

      def init(hash = {})
        @options = {
          url: hash[:url],
          user: hash[:user],
          password: hash[:password],
          project_id: hash[:project_id],
          suite_id: hash[:suite_id],
          run_name: hash[:run_name],
          run_description: hash[:run_description]
        }
      end

      def client
        @client ||= Client.new(@options[:url], @options[:user], @options[:password])
      end

      def process(example)
        if example.exception
          status = 5
          message = example.exception.message
        else
          status = 1
          message = ''
        end
        client.send_post("add_result_for_case/#{testrun['id']}/#{example.metadata[:testrail_id]}",
                         status_id: status,
                         comment: message)
      end

      def reset
        @options = nil
        @client = nil
        @testrun = nil
        @testruns = nil
      end

      protected

      def testrun
        @testrun ||=
          if testruns.empty?
            client.send_post("add_run/#{@options[:project_id]}",
                             suite_id: @options[:suite_id],
                             name: @options[:run_name],
                             description: @options[:run_description])
          else
            client.send_post("update_run/#{testruns[0]['id']}",
                             description: @options[:run_description])
          end
      end

      def testruns
        @testruns ||= client.send_get("get_runs/#{@options[:project_id]}?suite_id=#{URI.encode_www_form(@options[:suite_id])}")
                            .select do |run|
                              run['name'].include?(@options[:run_name])
                            end
      end
    end
  end
end
