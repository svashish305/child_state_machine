defmodule ChildStateMachineTest do
  use ExUnit.Case, async: true

  alias ChildStateMachine

  describe "ChildStateMachine functionality" do
    setup do
      {:ok, pid} = GenServer.start_link(ChildStateMachine, %{})
      {:ok, pid: pid}
    end

    test "initial state is playing", %{pid: pid} do
      assert {:ok, state} = GenServer.call(pid, {:handle_event, :get_state})
      assert state == %{state: :playing, mood: 0, snacks: 0, total_snacks_consumed: 0}
    end

    test "transitions from playing to eating_and_watching_cartoons", %{pid: pid} do
      GenServer.call(pid, {:handle_event, :call_to_eat})
      assert {:ok, state} = GenServer.call(pid, {:handle_event, :get_state})
      assert state.state == :eating_and_watching_cartoons
    end

    test "increments snacks when given in playing state", %{pid: pid} do
      # Ensure the state is playing
      GenServer.call(pid, {:handle_event, :call_to_play})
      GenServer.call(pid, {:handle_event, :give_snack})
      assert {:ok, state} = GenServer.call(pid, {:handle_event, :get_state})
      assert state.snacks == 1
    end

    test "every third snack raises mood by 2", %{pid: pid} do
      # Ensure the state is playing
      GenServer.call(pid, {:handle_event, :call_to_play})

      # Transition to eating state
      GenServer.call(pid, {:handle_event, :call_to_eat})

      # Give three snacks
      for _ <- 1..3, do: GenServer.call(pid, {:handle_event, :give_snack})

      # Transition back to playing to consume the snacks and update the mood
      GenServer.call(pid, {:handle_event, :call_to_play})

      # Check the mood
      assert {:ok, state} = GenServer.call(pid, {:handle_event, :get_state})
      assert state.mood >= 2
    end

    test "every fifth snack raises mood by 4", %{pid: pid} do
      # Ensure the state is playing
      GenServer.call(pid, {:handle_event, :call_to_play})

      # Transition to eating state
      GenServer.call(pid, {:handle_event, :call_to_eat})

      # Give five snacks
      for _ <- 1..5, do: GenServer.call(pid, {:handle_event, :give_snack})

      # Transition to playing to consume the snack and apply mood change
      GenServer.call(pid, {:handle_event, :call_to_play})

      # Check the mood
      assert {:ok, state} = GenServer.call(pid, {:handle_event, :get_state})
      assert state.mood >= 4
    end

    test "every fifteenth snack raises mood by 8", %{pid: pid} do
      # Ensure the state is playing
      GenServer.call(pid, {:handle_event, :call_to_play})

      # Transition to eating state
      GenServer.call(pid, {:handle_event, :call_to_eat})

      # Give fifteen snacks
      for _ <- 1..15, do: GenServer.call(pid, {:handle_event, :give_snack})

      # Transition to playing to consume the snack and apply mood change
      GenServer.call(pid, {:handle_event, :call_to_play})

      # Check the mood
      assert {:ok, state} = GenServer.call(pid, {:handle_event, :get_state})
      # The mood should be greater than just 8 due to previous incremental increases
      assert state.mood >= 8
    end

    test "resets mood to zero when transitioning to hiding", %{pid: pid} do
      # Ensure the state is playing
      GenServer.call(pid, {:handle_event, :call_to_play})
      # Give a snack to ensure the mood is increased
      GenServer.call(pid, {:handle_event, :give_snack})
      # Transition to hiding
      GenServer.call(pid, {:handle_event, :call_to_kindergarten})
      assert {:ok, state} = GenServer.call(pid, {:handle_event, :get_state})
      assert state.mood == 0
      assert state.state == :hiding
    end

    test "returns an error when giving a snack in hiding state", %{pid: pid} do
      # Transition to hiding state
      GenServer.call(pid, {:handle_event, :call_to_kindergarten})
      assert {:error, reason} = GenServer.call(pid, {:handle_event, :give_snack})
      assert reason == "Snacks can only be given in playing or eating states"
    end

    test "returns an error when there is invalid transition", %{pid: pid} do
      GenServer.call(pid, {:handle_event, :call_to_kindergarten})
      assert {:error, reason} = GenServer.call(pid, {:handle_event, :call_to_kindergarten})
      assert reason == "Cannot transition from hiding with call_to_kindergarten"
    end
  end
end
