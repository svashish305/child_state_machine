defmodule ChildStateMachine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChildStateMachineWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:child_state_machine, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ChildStateMachine.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ChildStateMachine.Finch},
      # Start a worker by calling: ChildStateMachine.Worker.start_link(arg)
      # {ChildStateMachine.Worker, arg},
      # Start to serve requests, typically the last entry
      ChildStateMachineWeb.Endpoint,
      ChildStateMachine
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChildStateMachine.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChildStateMachineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
