# Brolly

## Why?

Existing tools for umbrella apps segregate test coverage stats per app,
operating under the assumption that apps should *only* be tested in isolation.
However, with the advent of Docker and the capability to create rapidly consistent test environments,
cross-app testing can be more productive.
It allows for higher-level coverage of modules that orchestrate side effects between apps.

## How?

Brolly captures coverage statistics of inter-app communication within an umbrella app.
This enables comprehensive integration tests that reduce unnecessary mocking,
which is often tightly coupled to specific library implementations.

## What?

Brolly compiles and executes all umbrella app code in the same :cover context using brolly.cover.
Results can be exported with a simple preview using brolly.inspect,
to a browser with brolly.html, or to an IDE with brolly.lcov.
