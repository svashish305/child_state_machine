FROM hexpm/elixir:1.16.1-erlang-26.2.2-alpine-3.19.1 AS base

WORKDIR /child_state_machine

RUN mix do local.hex --force, local.rebar --force

RUN apk add npm inotify-tools git