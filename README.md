# Delfos

[![Build Status](http://img.shields.io/travis/markburns/delfos.svg?style=flat-square)](https://travis-ci.org/markburns/delfos)
[![Dependency Status](http://img.shields.io/gemnasium/markburns/delfos.svg?style=flat-square)](https://gemnasium.com/markburns/delfos)
[![Code Climate](http://img.shields.io/codeclimate/github/markburns/delfos3.svg?style=flat-square)](https://codeclimate.com/github/markburns/delfos)
[![Gem Version](http://img.shields.io/gem/v/delfos.svg?style=flat-square)](https://rubygems.org/gems/delfos)

# Background
For more on the background behind this project see [SOLID](solid.md)

# Functionality
  * Record runtime type information and call site file locations in every method call of your application for most ruby programs
  * Ignores library code - i.e. only records method calls defined in your application
  * [Not yet] Working with programs which redefine `BasicObject.inherited`, `.method_added`, `.singleton_method_added`
  * [Not yet] Analysis of type information in Neo4j to:
    * show cyclic dependencies
    * highlight dependency issues across large file system distances
    * suggest potential domain concept file system organisations to simplify app structure

## Dependencies
Zero gem dependencies.

Delfos by default depends upon a connection to a Neo4j instance for recording data.

## Usage

```ruby
#Gemfile
gem 'delfos'

#e.g.  in config/initializers/delfos.rb or equivalent

#Delfos is very slow, so we recommend only setting up when required
if defined?(Delfos) && ENV["DELFOS_ENABLED"]
  Delfos.setup!
end

# Any code defined in the app or lib directories executed after this point will
# automatically have execution chains with type information recorded.

# You could now click around the app or run integration tests to record type
# and callsite information
```

#### Delfos.setup! options

`logger` An object that responds to `debug(args, call_site, called_code)`
Where:
  * `args` contains argument type information and keyword args type information of the method call
  * `call_site` & `called_code` both respond to object, class_method, file, line_number to give call site information of the
  caller and calle

`application_directories` A glob of application directories. Defaults to `app/**/*.rb` and `lib/**/*.rb`

NEO4J connection related options
  `neo4j_url`
  `neo4j_username`
  `neo4j_password`
```


## Development

Delfos specs are organized in a similar fashion to `golang` tests and follow
the principles outlined by this README.  That is that code that changes
together lives together.

So there are no specs in the `spec` folder, unit specs live next to their implementation.
E.g.

```
lib/delfos/neo4j/
  distance_update.rb
  distance_update_spec.rb
```

The rake task is setup to handle this default and is equivalent to the following:

```
NEO4J_URL=http://localhost:7474 NEO4J_USERNAME=username NEO4J_PASSWORD=password bundle exec rspec lib
```


