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


`logger` Defaults to recording to neo4j. You can supply an object that responds to `debug` and receives the following objects : `(arguments, call_site, called_code)`

Where:
  * `arguments` has the following methods defined:
   * `args` An array of classes referencing the type of the argument (if the argument is an instance - it refers to the class of that instance)
   * `keyword_args` as above but for the keyword arguments in the method call
  * `call_site` & `called_code` have the following methods defined:
    * `file`
    * `line_number`
    * `object` - refers to the self defined at that line during runtime
    * `class_method` - boolean - true if the 


`application_directories` A glob of application directories. Defaults to `app/**/*.rb` and `lib/**/*.rb`

NEO4J connection related options

`neo4j_url`

`neo4j_username`

`neo4j_password`


# Recorded data
As well as recording the execution chains, call sites, file and line number,
Delfos also records the distance across the file system.  The distance is
defined as basically the visual distance in an ordinary filesystem tree view
like vim's NERDTree view.

This means files that traverse a large number of directories to call other
files end up with a 'worse' score than files which call files which are
alphabetically next to each other in the same directory.

There is also a score recorded for number of possible files traversed. So
projects which have large numbers of files per directory are also penalised.

This scoring system is quite likely to change as it is used against more
systems to record sample data sets.

```
▾ lib/
  ▾ delfos/
    ▸ distance/
    ▾ method_logging/
        args.rb
        args_spec.rb
        code_location.rb
        code_location_spec.rb
        klass_determination.rb
    ▾ neo4j/
        distance_update.rb
        distance_update_spec.rb
        execution_persistence.rb
        informer.rb
        informer_spec.rb
        query_execution.rb
    ▸ patching/
      common_path.rb
      common_path_spec.rb
      execution_chain.rb
      execution_chain_spec.rb
      integration_spec.rb
      method_logging.rb
      method_logging_spec.rb
      patching.rb
      patching_spec.rb
      patching_unstubbing_spec_helper.rb
      perform_patching.rb
      perform_patching_spec.rb
      remove_patching.rb
      version.rb
    delfos.rb
    delfos_spec.rb
```

## Examples
In the example above, if a call site in `remove_patching.rb` were to call a
site in `common_path.rb` in the same directory it would receives 'penalty'
points for crossing the 11 files in between, but no penalty points for
traversing directories. It would also get penalty points for the 11 possible
file traversals in the directory.

If `code_location.rb` were to call neo4j `query_execution.rb` it would receive
 * penalty points for traversing `args.rb` and `args_spec.rb`
 * penalty points for the 4 possible file traversals in the directory

  Then it would receive
 * penalty points for moving up one directory,
 * and more penalty points for traversing into the `neo4j` directory
 * plus penalty points for possible traversals across the 4 directories

Finally it would receive 
  * penalty points for traversing across the 6 files
  * penalty points for the 6 possible traversals

The ordinary points and points for possible traversals are recorded separately.
The algorithm is likely to change once analysis is done on the effectiveness of the data.

# Future work

Following are some ideas of where to take this project next:

## Analysis

### UI
I would like to create a UI for visualizing execution chains with their respective file system traversals.

### Command line tool
I want to detect common software design mistakes in a way which is useful/actionable like rubocop.

### Cope with Metaprogramming
It would be nice if Delfos were able to handle code which defines/re-defines
the 3 metaprogramming methods it uses.


# Development

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


