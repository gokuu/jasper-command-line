module JasperCommandLine
  class CommandLine
    def initialize(*args)
      begin
        options = parse_arguments(args)

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
      rescue OptionParser::InvalidOption => e
        puts "Error: #{e.message}"
      rescue => e
        puts "Error: #{e.message}"
        puts e.backtrace
      end
    end

    private

      def parse_arguments(arguments)
        require 'optparse'
        require 'optparse/time'
        require 'ostruct'

        data = {
          :params => {}
        }

        # Default to the help message
        arguments << '--help' if arguments.empty?

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: jasper-command-line [options]"
        end

        opts.separator ""
        opts.separator "Options:"

        opts.on('-j', '--jasper file', "The .jasper file to load (if one doesn't exist, it is compiled from the .jrxml file with the same name and on the same location)") do |file|
          raise ArgumentError.new("File not found: #{file}") unless File.exists?(file) || File.exists?(file.gsub(/\.jasper$/, '.jrxml'))
          data[:jasper_file] = file
        end

        opts.on('-d', '--data-file file', "The .xml file to load the data from") do |file|
          raise ArgumentError.new("Data file not found: #{file}") unless File.exists?(file)
          data[:data] = File.read file
        end

        opts.on('-c', '--copies number', Integer, "The number of copies to generate") do |i|
          data[:copies] = i
          raise ArgumentError.new("Ghostscript isn't available. Merging is not possible") if data[:copies] > 1 && !JasperCommandLine.ghostscript_available?
        end

        opts.on('-l', '--locale locale', "The locale to use in the report (in the format xx-YY)") do |locale|
          raise ArgumentError.new("Invalid locale format: #{locale}") unless locale =~ /([a-z]{2})-([A-Z]{2})/
          data[:locale] = { language: $1, sub_language: $2 }
        end

        opts.on('--param name=value', "Adds the parameter with name key with the value value (can be defined multiple times)") do |parameter|
          raise ArgumentError.new("Invalid param format: #{parameter}") unless parameter =~ /([^\s]+)=(.*)/
          data[:params][$1] = $2
        end

        opts.separator ""
        opts.separator "Digital signature options:"

        opts.on('--sign-key-file file', "The location of the PKCS12 file to digitally sign the PDF with") do |file|
          # Sign document with file
          raise ArgumentError.new("Signature key file not found: #{file}") unless File.exists?(file)
          data[:signature] ||= {}
          data[:signature][:key_file] = file
        end

        opts.on('--sign-location location', "The location data for the signature") do |location|
          # Location to set on the signature
          data[:signature] ||= {}
          data[:signature][:location] = location
        end

        opts.on('--sign-password password', "The password for the PKCS12 file") do |password|
          # Password to open the signature key file
          data[:signature] ||= {}
          data[:signature][:password] = password
        end

        opts.on('--sign-reason reason', "The reason for signing the PDF") do |reason|
          # Reason to set on the signature
          data[:signature] ||= {}
          data[:signature][:reason] = reason
        end

        opts.separator ""
        opts.separator "Common options:"

        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end

        # Another typical switch to print the version.
        opts.on_tail("--version", "Show version") do
          puts JasperCommandLine::VERSION
          exit
        end

        opts.parse! arguments

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