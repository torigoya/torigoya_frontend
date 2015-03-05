require 'torigoya_kit'
require 'mongoid/grid_fs'
require 'tempfile'
require 'digest/md5'
require 'securerandom'

module Api
  class PostSourceV1
    include ExecutionTaskWorker
    include Cages

    def self.execute(params)
      # ========================================
      # value
      # ========================================
      value = ApiUtil.extract_value(params)
      if value.nil?
        raise "value was not given"
      end
      #    Rails.logger.info "VALUE => " + value.to_s


      ### ========================================
      ### description
      ### ========================================
      description = ApiUtil.validate_type(value, "description", String)

      ### ========================================
      ### visibility
      ### ========================================
      visibility = ApiUtil.validate_type(value, "visibility", Integer)

      # ========================================
      # user id
      # ========================================
      #user_id = if user_signed_in? then current_user.id.to_s then nil end
      user_id = nil

      ### ========================================
      ### source code
      ### ========================================
      source_data = ApiUtil.validate_array(value, "source_codes", 1, 1)    # currently only one file is accepted
      source_codes = source_data.map do |code|
        # no filename => nil
        next TorigoyaKit::SourceData.new(nil, code)
      end

      entry = Entry.new(:owner_user_id => user_id,
                        :revision => "",
                        :visibility => visibility,
                        )

      grid_fs = Mongoid::GridFs
      source_data.each do |code|
        begin
          # TODO: support multi files
          file = Tempfile.new('procgarden_frontend')
          file.write(code)
          file.close

          f = grid_fs.put(file.path)
          code = entry.codes.build(:file_id => f.id,
                                   :file_name => "source",
                                   :type => :native,
                                   )
          code.save!

        ensure
          file.unlink unless file.nil?
        end
      end


      ### ========================================
      ### tickets
      ### ========================================
      tickets_info = load_tickets_info(value, source_codes)

      #
      proc_table = Cages.get_proc_table()

      # validate
      tickets_info.each do |t|
        unless proc_table.has_key?(t.proc_id)
          raise "proc_id: #{t.proc_id} is not registered in this system."
        end
        unless proc_table[t.proc_id]['Versioned'].has_key?(t.proc_version)
          raise "proc_version #{t.proc_version} is not registered in this system."
        end
      end

      #
      language_tags = tickets_info.map do |t|
        if proc_table.has_key?(t.proc_id)
          next "#{proc_table[t.proc_id]['Description']['Name']}[#{t.proc_version}]"
        else
          next nil
        end
      end
      entry.language_tags = language_tags.compact.uniq

      #
      tickets_info.each do |t|
        # create label string
        label = "#{proc_table[t.proc_id]['Description']['Name']}[#{t.proc_version}]"

        if t.is_a?(ExecutableTicketInfo)
          # do execution
          model = entry.tickets.build(:index => t.index,
                                      :is_running => true,
                                      :processed => false,
                                      :do_execute => true,
                                      :proc_id => t.proc_id,
                                      :proc_version => t.proc_version,
                                      :proc_label => label,
                                      :phase => Phase::Waiting
                                     )
          self.set_initial_record(model, t)
          model.save!

          # execute!
          ExecutionTaskWorker.execute_and_update_ticket(t.kit, model)

        else
          # do NOT execution
          model = entry.tickets.build(:index => t.index,
                                      :is_running => false,
                                      :processed => true,
                                      :do_execute => false,
                                      :proc_id => t.proc_id,
                                      :proc_version => t.proc_version,
                                      :proc_label => label,
                                      :phase => Phase::NotExecuted
                                     )
          self.set_initial_record(model, t)
          model.save!
        end
      end # tickets.each

      entry.save!

      return {
        :entry_id => entry.id.to_s,
        :is_error => false
      }
    end


    def self.set_initial_record(model, ticket)
      # set compile information
      unless ticket.compile_setting.nil?
        st = ticket.compile_setting
        sc = st.structured_command.map &:to_tuple
        cmd = st.command_line

        model.compile_state = CompileState.new(:index => 0,
                                               :structured_command_line => sc,
                                               :cpu_time_sec_limit => st.cpu_limit,
                                               :memory_bytes_limit => st.memory_limit,
                                               :free_command_line => cmd
                                              )
      end

      # set link information
      unless ticket.link_setting.nil?
        st = ticket.link_setting
        sc = st.structured_command.map &:to_tuple
        cmd = st.command_line

        model.link_state = LinkState.new(:index => 0,
                                         :structured_command_line => sc,
                                         :cpu_time_sec_limit => st.cpu_limit,
                                         :memory_bytes_limit => st.memory_limit,
                                         :free_command_line => cmd
                                        )
      end

      # set inputs information
      ticket.inputs.each.with_index do |input, index|
        st = input.run_setting
        sc = st.structured_command.map &:to_tuple
        cmd = st.command_line
        stdin_bin = BSON::Binary.new(input.stdin.code.force_encoding("ASCII-8BIT"))

        model.run_states << RunState.new(:index => index,
                                         :structured_command_line => sc,
                                         :cpu_time_sec_limit => st.cpu_limit,
                                         :memory_bytes_limit => st.memory_limit,
                                         :free_command_line => cmd,
                                         :stdin => stdin_bin
                                        )
      end
    end

    ###
    def self.parse_execution_settings(base, tag)
      command_line = if base.has_key?("command_line")
                       ApiUtil.validate_type(base, "command_line", String)
                     else
                       ""
                     end
      structured_command_line = ApiUtil.validate_type(base, "structured_command_line", Array)

      return TorigoyaKit::ExecutionSetting.new(command_line,
                                               structured_command_line,
                                               5,   # 5sec
                                               2 * 1024 * 1024 * 1024 # 2GB
                                               )
    end


    class ExecutableTicketInfo
      def initialize(index, kit)
        @index = index    # int
        @kit = kit        # TorigoyaKit::Ticket
      end
      attr_reader :index, :kit

      def proc_id
        return @kit.proc_id
      end

      def proc_version
        return @kit.proc_version
      end

      def compile_setting
        return @kit.build_inst.compile_setting
      end

      def link_setting
        return @kit.build_inst.link_setting
      end

      def inputs
        return @kit.run_inst.inputs
      end
    end

    class NoExecutableTicketInfo
      def initialize(index, proc_id, proc_version, compile_s, link_s, inputs)
        @index = index
        @proc_id = proc_id
        @proc_version = proc_version
        @compile_setting = compile_s
        @link_setting = link_s
        @inputs = inputs
      end
      attr_reader :index, :proc_id, :proc_version
      attr_reader :compile_setting, :link_setting, :inputs
    end

    # @return [ExecutableTicketInfo or NoExecutableTicketInfo]
    def self.load_tickets_info(value, source_codes)
      tickets_data = ApiUtil.validate_array(value, "tickets", 1, 10)
      tickets = tickets_data.map.with_index do |ticket, index|
        proc_id = ApiUtil.validate_type(ticket, "proc_id", Integer)
        proc_version = ApiUtil.validate_type(ticket, "proc_version", String)
        do_execution = ApiUtil.validate_type(ticket, "do_execution", Boolean)

        ##### ========================================
        ##### compile
        ##### ========================================
        compile = if ticket.has_key?("compile")
                    parse_execution_settings(ticket["compile"], :compile)
                  else
                    nil
                  end

        ##### ========================================
        ##### link
        ##### ========================================
        link = if ticket.has_key?("link")
                 parse_execution_settings(ticket["link"], :link)
               else
                 nil
               end

        ##### ========================================
        ##### build inst
        ##### ========================================
        build_inst = unless compile.nil? && link.nil?
                       TorigoyaKit::BuildInstruction.new(compile, link)
                     else
                       nil
                     end

        ##### ========================================
        ##### inputs [1, 10]
        ##### ========================================
        inputs_data = ApiUtil.validate_array(ticket, "inputs", 1, 10)
        inputs = inputs_data.map.with_index do |input, index|
          stdin = TorigoyaKit::SourceData.new(index.to_s,
                                              ApiUtil.validate_type(input, "stdin", String)
                                              )
          run = parse_execution_settings(input, :run)
          next TorigoyaKit::Input.new(stdin, run)
        end

        #
        if do_execution
          ##### ========================================
          ##### run inst
          ##### ========================================
          run_inst = TorigoyaKit::RunInstruction.new(inputs)

          base_name = Digest::MD5.hexdigest("#{proc_id}/#{proc_version}/#{source_codes}/#{Time.now}") + SecureRandom.hex(16)

          #
          kit = TorigoyaKit::Ticket.new(base_name, proc_id, proc_version, source_codes, build_inst, run_inst)
          next ExecutableTicketInfo.new(index, kit)

        else
          next NoExecutableTicketInfo.new(index, proc_id,  proc_version, compile, link, inputs)
        end
      end # tickets_data.map

      return tickets
    end


  end # clsss PostSourceV1
end # module Api
