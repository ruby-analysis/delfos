# Why is this here?
This exists as a result of trying to get the bundler test suite to pass with `Delfos` enabled.

I wanted to get a popular, yet sufficiently complex gem's whole test suite to run.

There is a spec which sets a class level expectation, using old RSpec `should` style syntax on `Pathname`.

At the time of writing there was no way to inject the logging code but allow this spec to pass unchanged.

# How can we get rid of this?

If we find a way to make `Delfos` work unintrusively.
