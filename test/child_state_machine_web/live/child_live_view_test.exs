defmodule ChildStateMachineWeb.ChildLiveViewTest do
  use ChildStateMachineWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias ChildStateMachineWeb.ChildLiveView

  # Reset the state before each test
  setup do
    ChildStateMachine.reset_state()

    receive do
      :reset_complete ->
        :ok
    after
      1_000 -> raise "State reset timed out"
    end

    :ok
  end

  test "mounts with initial state", %{conn: conn} do
    {:ok, live_view, _html} = live_isolated(conn, ChildLiveView)

    html = render(live_view)
    assert String.contains?(html, "State: playing")
    assert String.contains?(html, "Mood: 0")
    assert String.contains?(html, "Snacks: 0")
  end

  test "transition from playing to hiding and back to playing", %{conn: conn} do
    {:ok, live_view, _html} = live_isolated(conn, ChildLiveView)

    # Simulate clicking the button to transition to hiding
    html_view =
      live_view
      # Find the button by its ID
      |> element("#to-hiding-btn")
      # Use render_click with the appropriate phx_trigger and phx_value
      |> render_click(phx_trigger: "send_event", phx_value: %{"event" => "call_to_kindergarten"})

    assert html_view =~ "State: hiding"

    # Simulate clicking the button to transition back to playing
    # Use the original live_view, as render_click returns HTML
    html_view_after =
      live_view
      # Find the button by its ID
      |> element("#to-playing-btn")
      # Use render_click with the appropriate phx_trigger and phx_value
      |> render_click(phx_trigger: "send_event", phx_value: %{"event" => "call_to_play"})

    assert html_view_after =~ "State: playing"
  end

  test "give a snack in playing state", %{conn: conn} do
    {:ok, live_view, _html} = live_isolated(conn, ChildLiveView)

    # Trigger the event to give a snack
    html_view =
      live_view
      # Find the button by its ID
      |> element("#give-snack-btn")
      # Use render_click with the appropriate phx_trigger and phx_value
      |> render_click(phx_trigger: "send_event", phx_value: %{"event" => "give_snack"})

    assert String.contains?(html_view, "Snacks: 1")
  end

  test "attempt to give a snack in hiding state shows error", %{conn: conn} do
    {:ok, live_view, _html} = live_isolated(conn, ChildLiveView)

    # Transition to hiding state first
    live_view
    # Find the button by its ID
    |> element("#to-hiding-btn")
    # Use render_click with the appropriate phx_trigger and phx_value
    |> render_click(phx_trigger: "send_event", phx_value: %{"event" => "call_to_kindergarten"})

    # Attempt to give a snack in hiding state
    # Use the original live_view as the base for the next action
    html_view_after =
      live_view
      # Find the button by its ID
      |> element("#give-snack-btn")
      # Use render_click with the appropriate phx_trigger and phx_value
      |> render_click(phx_trigger: "send_event", phx_value: %{"event" => "give_snack"})

    assert String.contains?(
             html_view_after,
             "Snacks can only be given in playing or eating states"
           )
  end
end
