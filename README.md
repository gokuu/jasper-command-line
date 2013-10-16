jasper-command-line
===================

Print a jasper document via the command line

### Disclaimer:
This is almost completely based on the great work by [Fortes Informática](https://github.com/fortesinformatica), with the gem [jasper-rails](https://github.com/fortesinformatica/jasper-rails). I built this out of  necessity for a project that wouldn't run [jasper-rails](https://github.com/fortesinformatica/jasper-rails) on top of Ubuntu + nginx + Passenger.

This gem embeds the .jar files provided by [jasper-rails](https://github.com/fortesinformatica/jasper-rails), so you don't need to include the gem ([jasper-rails](https://github.com/fortesinformatica/jasper-rails) requires the whole Ruby on Rails framework, which isn't necessary in this case).

It also embeds the .jar files needed to digitally sign the PDF, if necessary. The PDF files are signed using [PortableSigner](http://portablesigner.sourceforge.net) by [Peter Pfläging](peter.pflaeging@wien.gv.at). All credit for the digital signature code goes to him.

### Other acknowledgements:

* [Prawn](http://prawn.majesticseacreature.com), a "Fast, Nimble PDF Writer for Ruby"
* [Henrik Nyh](http://henrik.nyh.se/) for the auto-print addition to Prawn, [prawn-print](https://github.com/barsoom/prawn-print).

## Dependencies

* You need a Java Virtual Machine installed and set up in order to use this gem.
* [Ghostscript](http://www.ghostscript.com) to merge PDFs into a single document
* [rjb](http://rjb.rubyforge.org/) >= 1.4.0
* [builder](https://rubygems.org/gems/builder) >= 3.0.3
* [activesupport](https://rubygems.org/gems/activesupport) >= 3.2.0

## Install

```
gem install jasper-command-line
```

## Configure

If invoking jasper-command-line via a Rails project, you might need to add `jasper-command-line` to your Gemfile:

```ruby
gem "jasper-command-line"
```

## Using jasper-command-line

```
Usage: jasper-command-line [options]

Options:
    -j, --jasper file                The .jasper file to load (if one doesn't exist, it is compiled from the .jrxml file with the same name and on the same location)
    -d, --data-file file             The .xml file or url to load the data from
    -c, --copies number              The number of copies to generate
    -l, --locale locale              The locale to use in the report (in the format xx-YY)
        --param name=value           Adds the parameter with name key with the value value (can be defined multiple times)

Printing options:
    -p, --print                      Whether to generate a PDF file that automatically opens the print dialog when opened in Acrobat Reader
    -P, --print-silent               Whether to generate a PDF file that automatically prints to the default printer when opened in Acrobat Reader

Digital signature options:
        --sign-key-file file         The location of the PKCS12 file to digitally sign the PDF with
        --sign-location location     The location data for the signature
        --sign-password password     The password for the PKCS12 file
        --sign-reason reason         The reason for signing the PDF

Common options:
    -h, --help                       Show this message
        --version                    Show version
```

## LICENSE

Copyright (C) 2012 Pedro Rodrigues

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.