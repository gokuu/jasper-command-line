jasper-command-line
===================

Print a jasper document via the command line

**Disclaimer**: This is almost completely based on the great work by [Fortes Informática](https://github.com/fortesinformatica), with the gem [jasper-rails](https://github.com/fortesinformatica/jasper-rails). I built this out of  necessity for a project that wouldn't run [jasper-rails](https://github.com/fortesinformatica/jasper-rails) on top of Ubuntu + nginx + Passenger.

This gem embeds the .jar files provided by [jasper-rails](https://github.com/fortesinformatica/jasper-rails), so you don't need to include the gem ([jasper-rails](https://github.com/fortesinformatica/jasper-rails) requires the whole Ruby on Rails framework, which isn't necessary in this case).

## Dependencies

* You need a Java Virtual Machine installed and set up in order to use this gem.
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
jasper-command-line [options]

Options:
--jasper /path/to/file     The .jasper file to load (if one doesn't exist, it is
                           compiled from the .jrxml file with the same name and
                           on the same location)
--data-file /path/to/file  The .xml file to load the data from
--param key=value          Adds the parameter with name key with the value value
                           (can be defined multiple times)
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