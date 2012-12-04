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
  classpath = '.'
  Dir["#{File.dirname(__FILE__)}/java/*.jar"].each do |jar|
    classpath << File::PATH_SEPARATOR + File.expand_path(jar)
  end

  Dir["lib/*.jar"].each do |jar|
    classpath << File::PATH_SEPARATOR + File.expand_path(jar)
  end

  Rjb::load( classpath, ['-Djava.awt.headless=true','-Xms128M', '-Xmx256M'] )

  JRException                 = Rjb::import 'net.sf.jasperreports.engine.JRException'
  JasperCompileManager        = Rjb::import 'net.sf.jasperreports.engine.JasperCompileManager'
  JasperExportManager         = Rjb::import 'net.sf.jasperreports.engine.JasperExportManager'
  JasperFillManager           = Rjb::import 'net.sf.jasperreports.engine.JasperFillManager'
  JasperPrint                 = Rjb::import 'net.sf.jasperreports.engine.JasperPrint'
  JRXmlUtils                  = Rjb::import 'net.sf.jasperreports.engine.util.JRXmlUtils'
  # This is here to avoid the "already initialized constant QUERY_EXECUTER_FACTORY_PREFIX" warnings.
  JRXPathQueryExecuterFactory = silence_warnings{Rjb::import 'net.sf.jasperreports.engine.query.JRXPathQueryExecuterFactory'}
  InputSource                 = Rjb::import 'org.xml.sax.InputSource'
  StringReader                = Rjb::import 'java.io.StringReader'
  HashMap                     = Rjb::import 'java.util.HashMap'
  ByteArrayInputStream        = Rjb::import 'java.io.ByteArrayInputStream'
  JavaString                  = Rjb::import 'java.lang.String'
  JFreeChart                  = Rjb::import 'org.jfree.chart.JFreeChart'

  module Jasper
    def self.render_pdf(jasper_file, datasource, parameters, options)
      options ||= {}
      parameters ||= {}
      jrxml_file  = jasper_file.sub(/\.jasper$/, ".jrxml")

      sign_options = options.delete(:signature)

      begin
        # Convert the ruby parameters' hash to a java HashMap.
        # Pay attention that, for now, all parameters are converted to string!
        jasper_params = HashMap.new
        parameters.each do |k,v|
          jasper_params.put(JavaString.new(k.to_s), JavaString.new(v.to_s))
        end

        # Compile it, if needed
        if !File.exist?(jasper_file) || (File.exist?(jrxml_file) && File.mtime(jrxml_file) > File.mtime(jasper_file))
          JasperCompileManager.compileReportToFile(jrxml_file, jasper_file)
        end

        datasource = datasource.to_xml(options).to_s unless datasource.is_a?(String)

        # Fill the report
        input_source = InputSource.new
        input_source.setCharacterStream(StringReader.new(datasource))
        data_document = silence_warnings do
          # This is here to avoid the "already initialized constant DOCUMENT_POSITION_*" warnings.
          JRXmlUtils._invoke('parse', 'Lorg.xml.sax.InputSource;', input_source)
        end

        jasper_params.put(JRXPathQueryExecuterFactory.PARAMETER_XML_DATA_DOCUMENT, data_document)
        jasper_print = JasperFillManager.fillReport(jasper_file, jasper_params)

        # Export it!

        if sign_options
          file = Tempfile.new(['pdf-', '.pdf'])
          signed_file = Tempfile.new(['signed-pdf-', '.pdf'])
          begin
            file.write JasperExportManager._invoke('exportReportToPdf', 'Lnet.sf.jasperreports.engine.JasperPrint;', jasper_print)

            call_options = [
              '-n',
              '-t', file.path,
              '-s', sign_options[:key_file],
              '-p', %Q["#{sign_options[:password]}"],
              '-o', signed_file.path
            ]
            call_options.push '-l', %Q["#{sign_options[:location]}"] if sign_options[:location]
            call_options.push '-r', %Q["#{sign_options[:reason]}"] if sign_options[:reason]

            `java -jar #{File.dirname(__FILE__)}/java/PortableSigner/PortableSigner.jar #{call_options.join(' ')}`

            return File.read(signed_file.path)
          ensure
            file.close!
            signed_file.close!
          end
        else
          JasperExportManager._invoke('exportReportToPdf', 'Lnet.sf.jasperreports.engine.JasperPrint;', jasper_print)
        end

      rescue Exception=>e
        if e.respond_to? 'printStackTrace'
          JasperCommandLine.logger.error e.message
          e.printStackTrace
        else
          JasperCommandLine.logger.error e.message + "\n " + e.backtrace.join("\n ")
        end
        raise e
      end
    end
  end
end