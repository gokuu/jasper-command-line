# encoding: utf-8
#
# js.rb : Implements embeddable Javascript support for PDF
#
# Copyright March 2009, James Healy. All Rights Reserved.
#
# This is free software. Please see the LICENSE file for details.

module JasperCommandLine
  module Prawn
    module JS
      # The maximum number of children to fit into a single node in the JavaScript tree.
      NAME_TREE_CHILDREN_LIMIT = 20 #:nodoc:

      # add a Javascript fragment that will execute when the document is opened.
      #
      # There can only be as many fragments as required. Calling this function
      # multiple times will append the new fragment to the list.
      #
      def add_docopen_js(name, script)
        obj = ref!(:S => :JavaScript, :JS => script)
        javascript.data.add(name, obj)
      end

      def print
        print_with_auto_to_printer false, nil
      end

      def print_silent
        print_with_auto_to_printer true, nil
      end

      def print_with_auto_to_printer(auto, printer)
        js = [
          'var pp = this.getPrintParams();',
          interactive_js(auto),
          select_printer_js(printer),
          'this.print(pp);'
        ]

        add_docopen_js "print", js.join(' ')
      end

      def interactive_js(auto)
        "pp.interactive = pp.constants.interactionLevel.silent;" if auto
      end

      def select_printer_js(printer)
        if printer
          escaped_printer = printer.gsub('"') { "\\#$0" }

          [
            'var names = app.printerNames;',
            'var regex = new RegExp("#{escaped_printer}", "i");',
            'for (var i = 0; i < names.length; i++) {',
              'if (names[i].match(regex)) {',
                'pp.printerName = names[i];',
                'break;',
              '}',
            '}'
          ].join(' ')
        else
          'pp.printerName = "";'
        end
      end

      # create or access the Javascript Name Tree in the document names dict.
      # See section 3.6.3 and table 3.28 in the PDF spec.
      #
      def javascript
        names.data[:JavaScript] ||= ref!(::Prawn::Core::NameTree::Node.new(self, NAME_TREE_CHILDREN_LIMIT))
      end
    end
  end
end

require 'prawn/document'
::Prawn::Document.send(:include, JasperCommandLine::Prawn::JS)