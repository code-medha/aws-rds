# Scope of Observability Project

The scope of this project is to learn the observability skills by configuring Honeycomb and Rollbar with a Python Flask backend.

In this project I will document the process involved in configuring Honeycomb and Rollbar.

First, let's start with Observability basics.

## What is Observability?

As we know for programming languages we have debuggers, which helps us to find the errors in the program syntax, logic etc.
Similarly for large software systems we need some means to capture what's going on in this system. To capture the overall health of the software system we make use of observability.

observability is the ability to understand the internal state of a system based on the data through logs, metrics, and traces. It helps to debug, monitor, and optimize systems in distributed and microservices environments.


## Why you should configure observability in your applications?

Observability helps you understand what’s happening inside your application when it’s running in real-world environments. When users experience slow responses, errors, or unexpected behavior, observability tools can show you exactly where the problem is such as a slow database query, failed API call, or spike in traffic.

By configuring observability, you gain real-time visibility into your application's health and performance, which helps you detect issues faster.


## Observability Terms

While instrumenting any observability tool, we come across the following terms quite often. Let's understand the definition of each term.

Traces: It represents the journey of a single request through various components, such as microservices, within a distributed system. Traces can be thought of as a detailed timeline of what happens behind the scenes when a user clicks a button or an API is called.

Span: Each part of this story is told by a span. A span is a single piece of instrumentation from a single location in your code. It represents a single unit of work done by a service.

Instrumentation: It is the code that send data to make the trace.


Refer to the following links to learn the steps involved in instrumenting Honeycomb and Rollbar:
- [Honeycomb Instrumentation](https://github.com/devops-champ/observability-project/blob/main/_docs/honeycomb.md#honeycomb)
- [Rollbar Instrumentation](https://github.com/devops-champ/observability-project/blob/main/_docs/rollbar.md#configuring-rollbar)


CREDITS - The source code of this project belongs to AWS Bootcamp by Andrew Brown.
