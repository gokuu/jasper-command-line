# encoding: utf-8
#
# Copyright (C) 2012 Marlus Saraiva, Rodrigo Maia
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module JasperCommandLine
  module Jasper
    def self.render_pdf(jasper_file, datasource, parameters, options)
      initialize_engine

      options ||= {}
      parameters ||= {}
      jrxml_file  = jasper_file.sub(/\.jasper$/, ".jrxml")

      sign_options = options.delete(:signature)
      locale_options = options.delete(:locale)

      # begin
        # Convert the ruby parameters' hash to a java HashMap.
        # Pay attention that, for now, all parameters are converted to string!
        jasper_params = @hashMap.new
        parameters.each do |k,v|
          jasper_params.put(@javaString.new(k.to_s), @javaString.new(v.to_s))
        end

        # Compile it, if needed
        if !File.exist?(jasper_file) || (File.exist?(jrxml_file) && File.mtime(jrxml_file) > File.mtime(jasper_file))
          @jasperCompileManager.compileReportToFile(jrxml_file, jasper_file)
        end

        datasource = datasource.to_xml(options).to_s unless datasource.is_a?(String)

        # Fill the report
        input_source = @inputSource.new
        input_source.setCharacterStream(@stringReader.new(datasource))
        data_document = silence_warnings do
          # This is here to avoid the "already initialized constant DOCUMENT_POSITION_*" warnings.
          @jRXmlUtils._invoke('parse', 'Lorg.xml.sax.InputSource;', input_source)
        end

        jasper_params.put(@jRXPathQueryExecuterFactory.PARAMETER_XML_DATA_DOCUMENT, data_document)

        jasper_params.put(@jRParameter.REPORT_LOCALE, @locale.new(locale_options[:language], locale_options[:sub_language])) if locale_options

        temp_file = Tempfile.new(['pdf-', '.pdf'])
        file = temp_file.path
        temp_file.close!

        created_files = [file]
        merge_pdf_command_line = "gs -q -dBATCH -dPDFSETTINGS=/prepress -dNOPAUSE -sDEVICE=pdfwrite -dEmbedAllFonts=true -sOutputFile=#{file}"

        # Export n copies and merge them into one file
        options[:copies] ||= 1

        copy_file = nil

        (1..options[:copies]).each do |copy|
          copy_temp_file = Tempfile.new(["pdf-#{copy}-", '.pdf'])
          copy_file = copy_temp_file.path
          copy_temp_file.close!

          jasper_params.put @javaString.new('copy_number'), @javaString.new(copy.to_s)
          jasper_print = @jasperFillManager.fillReport(jasper_file, jasper_params)

          File.open(copy_file, 'wb') { |f| f.write @jasperExportManager._invoke('exportReportToPdf', 'Lnet.sf.jasperreports.engine.JasperPrint;', jasper_print) }

          merge_pdf_command_line << " #{copy_file}"

          created_files << copy_file
        end

        if options[:copies] > 1
          # Use GhostScript to create a single page
          `#{merge_pdf_command_line}`
        else
          file = copy_file
        end

        if options[:print] || options[:print_silent]
          temp_file = Tempfile.new(['pdf-', '.pdf'])
          file2 = temp_file.path
          temp_file.close!

          ::Prawn::Document.generate(file2, template: file) do |pdf|
            pdf.print if options[:print]
            pdf.print_silent if options[:print_silent]
          end

          file = file2
        end

        # Digitally sign the file, if necessary
        if sign_options
          temp_signed_file = Tempfile.new(['signed-pdf-', '.pdf'])
          signed_file = temp_signed_file.path

          temp_file.close!
          temp_signed_file.close!

          call_options = [
            '-n',
            '-t', file,
            '-s', sign_options[:key_file],
            '-p', %Q["#{sign_options[:password]}"],
            '-o', signed_file
          ]
          call_options.push '-l', %Q["#{sign_options[:location]}"] if sign_options[:location]
          call_options.push '-r', %Q["#{sign_options[:reason]}"] if sign_options[:reason]

          `java -jar #{File.dirname(__FILE__)}/java/PortableSigner/PortableSigner.jar #{call_options.join(' ')}`
        else
          signed_file = file
        end

        begin
          file_contents = File.read(signed_file)
          raise 'Invalid PDF file' unless file_contents[0..file_contents.index("\n")].chomp =~ /^%PDF-.*?$/

          puts file_contents
        ensure
          created_files.each { |file| File.unlink file if File.exists?(file) }
        end

      # rescue Exception => e
      #   JasperCommandLine.logger.error e.message + "\n " + e.backtrace.join("\n ")

      #   abort e.message
      # end
    end

    private

      def self.initialize_engine
        classpath = '.'
        Dir["#{File.dirname(__FILE__)}/java/*.jar"].each do |jar|
          classpath << File::PATH_SEPARATOR + File.expand_path(jar)
        end

        Dir["lib/*.jar"].each do |jar|
          classpath << File::PATH_SEPARATOR + File.expand_path(jar)
        end

        Rjb::load( classpath, ['-Djava.awt.headless=true','-Xms128M', '-Xmx256M'] )

        @jRException                 = Rjb::import 'net.sf.jasperreports.engine.JRException'
        @jasperCompileManager        = Rjb::import 'net.sf.jasperreports.engine.JasperCompileManager'
        @jasperExportManager         = Rjb::import 'net.sf.jasperreports.engine.JasperExportManager'
        @jasperFillManager           = Rjb::import 'net.sf.jasperreports.engine.JasperFillManager'
        @jasperPrint                 = Rjb::import 'net.sf.jasperreports.engine.JasperPrint'
        @jRXmlUtils                  = Rjb::import 'net.sf.jasperreports.engine.util.JRXmlUtils'
        @jRParameter                 = Rjb::import 'net.sf.jasperreports.engine.JRParameter'
        # This is here to avoid the "already initialized constant QUERY_EXECUTER_FACTORY_PREFIX" warnings.
        @jRXPathQueryExecuterFactory = silence_warnings{Rjb::import 'net.sf.jasperreports.engine.query.JRXPathQueryExecuterFactory'}
        @inputSource                 = Rjb::import 'org.xml.sax.InputSource'
        @stringReader                = Rjb::import 'java.io.StringReader'
        @hashMap                     = Rjb::import 'java.util.HashMap'
        @locale                      = Rjb::import 'java.util.Locale'
        @byteArrayInputStream        = Rjb::import 'java.io.ByteArrayInputStream'
        @javaString                  = Rjb::import 'java.lang.String'
        @jFreeChart                  = Rjb::import 'org.jfree.chart.JFreeChart'
      end
  end
end