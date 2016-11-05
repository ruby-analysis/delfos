# Delfos

[![Build Status](http://img.shields.io/travis/markburns/delfos.svg?style=flat-square)](https://travis-ci.org/markburns/delfos)
[![Dependency Status](http://img.shields.io/gemnasium/markburns/delfos.svg?style=flat-square)](https://gemnasium.com/markburns/delfos)
[![Code Climate](http://img.shields.io/codeclimate/github/markburns/delfos3.svg?style=flat-square)](https://codeclimate.com/github/markburns/delfos)
[![Gem Version](http://img.shields.io/gem/v/delfos.svg?style=flat-square)](https://rubygems.org/gems/delfos)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delfos'
```

## External Dependencies
Delfos depends upon Neo4j for recording data.

## Usage

### With Rails 

```ruby
#e.g.  in config/initializers/delfos.rb

#Delfos is very slow, so we recommend only setting up when required
if defined?(Delfos) && ENV["DELFOS_ENABLED"]
  Delfos.setup!
end

# Any code defined in the app or lib directories executed after this point will
# automatically have execution chains with type information recorded.

# You could click around the app or run integration tests
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

#A `SOLID CASE` for application architecture

## In one simple question:
> How can I fit more related things together on screen?

## The problem

> When editing this massive Rails project,
> I find myself scrolling up and down the file browser and forgetting where I
> am in the codebase or what I was trying to find.
>
> It's OK when I know the name
> of the file I'm looking for, but it's awful when I am not sure or can't
> remember what to look for.

> Also having tons of small objects is great. But
> understanding the dependencies between code that is many levels of
> directories away from other related code seems painful.


## The lesser known SOLID principles
The aim of this project is to aid ruby developers in spotting, understanding and
fixing violations of some of the 6 lesser known package-related SOLID principles.
These principles broadly correspond to:

* Cohesion
* Acyclic Dependencies
* Stability
* Equivalency of Release/Reuse

CASE is an easy to remember acronym, but the letters map to 6 principles

Specifically the principles are:

```
  * Cohesion -----> CCP - Common Closure Principle
  *           \---> CRP - Common Reuse Principle
  * Acyclicity ---> ADP - Acyclic Dependencies Principle
  * Stability  ---> SAP - Stable Abstractions Principle
  *           \---> SDP - Stable Dependencies Principle
  * Equivalence --> REP - Release Reuse Equivalency Principle
```

The `E` of `CASE` is a bit contrived and would be better as an `R`
but we were trying to make it easy to remember :)

You can read about them in the [Original Paper](http://web.archive.org/web/20020217194239/http://www.objectmentor.com/resources/articles/Principles_and_Patterns.PDF)


### Huh?!
### The less technical explanation
In less technical terms I want to be able to answer the following questions:

> What are the main domain concepts in my application?

> How can I refactor or organize my code to better match the domain?

> What are some specific examples of coupling between objects that are not located together?


# Hypothesis
I think that Rails is great, but I think that most large Rails apps built by
successful founded startups are likely to have considerable technical debt.

Often developers at startups are at the beginning of their careers and may cut
corners in order to get to market.

Rails helps you quickly build applications but doesn't provide much of a
helping hand for scaling the complexity of the codebase up.

Namespaced Engines are an example that helps, but I've rarely seen them used,
or when used, rarely seen them used properly.

So lots of developers tackle the complexity by introducing more design patterns like
`jobs`, `services`, `decorators`, `presenters`, `forms`, etc.
This helps with object complexity and size, but doesn't help with code organization
obeying the `CRP` and `CCP`.

Technical terms, but basically they mean keep related things together. Things
that change together should be located together.

When you start with a Rails app it _does_ feel like related things are together.
Models like `User` have many `Post`s and `Post`s belong to `User`s.
Views are grouped together, and you can go and change all the styles for the site in
one place.

But as the application grows and you have more and more design patterns it starts to
feel less like the concepts change together.

Does your `BurgerPresenter` belong with the `RestaurantPresenter`,
and `EmployeePresenter` and `ManagerPresenter`?

Or does it belongs with the `Burger`, `BurgerTopping`, `BurgerCreationService` and `BurgerSerializer`?

If you've read this far, I'm sure you can guess which one I think is the correct answer.

But I want to answer this with data.

I bet that @dhh and all the guys writing basecamp etc _do_ write well organized code.

I suspect that they know or feel exactly what and when is the right code and time to extract
a piece of functionality into an engine.

I also bet that organizing a really simple blog application based on domain concepts mapping to
domain folders is also overkill.

So the questions to answer are:

> Can I create a metric that gives a good feel for how coupled/cohesive/spaghetti-like a codebase is?

> Would the basecamp codebase score well?

> I think yes

> Would a small rails app with say 10 models score better than one organized by domain concept?

> I think yes

> Would a large app with 300 models and controllers and every design pattern directory under the sun score better
> in domain related folders (or in engines)

> I think yes

> Can I create a useful metric for this?

> I think yes I can.

