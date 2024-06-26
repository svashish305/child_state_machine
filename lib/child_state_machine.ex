defmodule ChildStateMachine do
  @moduledoc """
  ChildStateMachine keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use GenServer

  # Starting the GenServer with initial state
  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  # Initializing with default values
  def init(_initial_state) do
    {:ok, %{state: :playing, mood: 0, snacks: 0, total_snacks_consumed: 0}}
  end

  # Function to reset the state
  def reset_state do
    GenServer.cast(__MODULE__, {:reset_state, self()})
  end

  # Handling the :reset_state message
  def handle_cast({:reset_state, caller}, _current_state) do
    new_state = %{state: :playing, mood: 0, snacks: 0, total_snacks_consumed: 0}
    send(caller, :reset_complete)
    {:noreply, new_state}
  end

  # Public interface to send events
  def send_event(event) do
    GenServer.call(__MODULE__, {:handle_event, event})
  end

  # Special handling for the :get_state event
  def handle_call({:handle_event, :get_state}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:handle_event, :give_snack}, _from, state = %{state: current_state}) do
    case current_state do
      :playing ->
        new_state = Map.update!(state, :snacks, &(&1 + 1))
        {:reply, {:ok, new_state}, new_state}

      :eating_and_watching_cartoons ->
        new_state = Map.update!(state, :snacks, &(&1 + 1))
        {:reply, {:ok, new_state}, new_state}

      _ ->
        {:reply, {:error, "Snacks can only be given in playing or eating states"}, state}
    end
  end

  # Handling the calls/events
  def handle_call({:handle_event, event}, _from, state) do
    case determine_new_state(event, state) do
      {:ok, new_state} -> {:reply, {:ok, new_state}, new_state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  # Handling state and property updates
  defp determine_new_state(
         event,
         state = %{state: current_state, mood: mood, snacks: snacks, total_snacks_consumed: total}
       ) do
    case {event, current_state} do
      {:call_to_kindergarten, :playing} ->
        {:ok, %{state | state: :hiding, mood: 0, snacks: snacks}}

      {:call_to_play, :hiding} ->
        {:ok, %{state | state: :playing}}

      {:call_to_eat, :playing} ->
        {:ok, %{state | state: :eating_and_watching_cartoons}}

      {:call_to_play, :eating_and_watching_cartoons} when snacks > 0 ->
        {new_mood, new_total, _breakdown} =
          update_mood(mood, total, snacks)

        {:ok,
         %{
           state
           | state: :playing,
             mood: new_mood,
             snacks: 0,
             total_snacks_consumed: new_total
         }}

      {:call_to_play, :eating_and_watching_cartoons} ->
        {:ok, %{state | state: :playing, mood: 0}}

      _ ->
        {:error, "Cannot transition from #{current_state} with #{event}"}
    end
  end

  # Update the mood based on the snacks
  defp update_mood(mood, total_snacks_consumed, snacks_to_consume) do
    Enum.reduce(1..snacks_to_consume, {mood, total_snacks_consumed, []}, fn _,
                                                                            {acc_mood, acc_total,
                                                                             breakdown} ->
      new_total = acc_total + 1

      {additional_mood, reason} =
        case new_total do
          _ when rem(new_total, 15) == 0 -> {8, "15th snack"}
          _ when rem(new_total, 5) == 0 -> {4, "5th snack"}
          _ when rem(new_total, 3) == 0 -> {2, "3rd snack"}
          _ -> {1, "other snack"}
        end

      IO.inspect("Snack #{new_total}: #{reason} - Mood increase: #{additional_mood}")

      new_breakdown = [{new_total, reason, additional_mood} | breakdown]
      {acc_mood + additional_mood, new_total, new_breakdown}
    end)
  end
end
