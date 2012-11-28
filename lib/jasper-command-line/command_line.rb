module JasperCommandLine
  class CommandLine
    def initialize(*args)
      begin
        options = parse_arguments(args)

        if !options
          puts "Usage:"
          puts ""
          puts "jasper-command-line [options]"
          puts ""
          puts "Options:"
          puts ""
          puts "--jasper /path/to/file     The .jasper file to load (if one doesn't exist, it is"
          puts "                           compiled from the .jrxml file with the same name and"
          puts "                           on the same location)"
          puts "--data-file /path/to/file  The .xml file to load the data from"
          puts "--param key=value          Adds the parameter with name key with the value value"
          puts "                           (can be defined multiple times)"
        else
          if options[:jasper_file]
            puts JasperCommandLine::Jasper::render_pdf(options[:jasper_file], options[:data], options[:params], {})
          end
        end
      rescue ArgumentError => e
        puts "Error: #{e.message}"
      rescue => e
        puts "Error: #{e.message}"
        puts e.backtrace
      end
    end

    private

      def parse_arguments(arguments)
        data = {
          :params => {}
        }

        return false unless arguments.any?

        i = 0

        while i < arguments.length
          argument = arguments[i]

          case get_option(argument)
            when 'data'
              i = get_option_data(arguments, i) do |argument_data|
                raise ArgumentError.new("Data not found") if get_option(argument_data)
                data[:data] = argument_data
              end

            when 'data-file'
              i = get_option_data(arguments, i) do |argument_data|
                raise ArgumentError.new("Data file not found: #{argument_data}") unless File.exists?(argument_data)
                data[:data] = File.read argument_data
              end

            when 'param'
              i = get_option_data(arguments, i) do |argument_data|
                raise ArgumentError.new("Invalid param format: #{argument_data}") unless argument_data =~ /(.*?)=(.*)/
                data[:params][$1] = $2
              end

            when 'jasper'
              # Or a file
              i = get_option_data(arguments, i) do |argument_data|
                raise ArgumentError.new("File not found: #{argument_data}") unless File.exists?(argument_data)
                data[:jasper_file] = argument_data
              end

          end
        end

        return data
      end

      def get_option(argument)
        if argument.strip =~ /^--(.*?)$/
          return $1
        end

        nil
      end

      def get_option_data(arguments, index)
        index += 1
        data = ''

        while index < arguments.length && !get_option(arguments[index])
          data << arguments[index]
          index += 1
        end

        yield data

        return index
      end
  end
end