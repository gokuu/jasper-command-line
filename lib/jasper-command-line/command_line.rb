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
          puts "--copies number            The number of copies to generate"
          puts "--param key=value          Adds the parameter with name key with the value value"
          puts "                           (can be defined multiple times)"
          puts ""
          puts "Digital signature options:"
          puts "--sign-key-file /path/to/file  The location of the PKCS12 file to"
          puts "                               digitally sign the PDF with"
          puts "--sign-password password       The password for the PKCS12 file"
          puts "--sign-location location       The location of the signature"
          puts "--sign-reason reason           The reason for signing the PDF"
        else
          if options[:jasper_file]
            jasper_file = options.delete :jasper_file
            data = options.delete :data
            params = options.delete :params

            if options[:signature]
              if options[:signature][:key_file] && !options[:signature][:password]
                raise ArgumentError.new("Password not supplied for certificate")
              end
            end

            puts JasperCommandLine::Jasper::render_pdf(jasper_file, data, params, options)
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
              i = get_option_data(arguments, i) do |argument_data|
                raise ArgumentError.new("File not found: #{argument_data}") unless File.exists?(argument_data) || File.exists?(argument_data.gsub(/\.jasper$/, '.jrxml'))
                data[:jasper_file] = argument_data
              end

            when 'copies'
              i = get_option_data(arguments, i) do |argument_data|
                raise ArgumentError.new("Invalid number of copies: #{argument_data}") unless argument_data =~ /^[1-9][0-9]*$/
                data[:copies] = argument_data.to_i
              end

            when 'sign-key-file'
              # Sign document with file
              i = get_option_data(arguments, i) do |argument_data|
                raise ArgumentError.new("Signature key file not found: #{argument_data}") unless File.exists?(argument_data)
                data[:signature] ||= {}
                data[:signature][:key_file] = argument_data
              end

            when 'sign-location'
              # Location to set on the signature
              i = get_option_data(arguments, i) do |argument_data|
                data[:signature] ||= {}
                data[:signature][:location] = argument_data
              end

            when 'sign-password'
              # Password to open the signature key file
              i = get_option_data(arguments, i) do |argument_data|
                data[:signature] ||= {}
                data[:signature][:password] = argument_data
              end

            when 'sign-reason'
              # Reason to set on the signature
              i = get_option_data(arguments, i) do |argument_data|
                data[:signature] ||= {}
                data[:signature][:reason] = argument_data
              end

            else
              i += 1
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