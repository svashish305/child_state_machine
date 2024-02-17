defmodule ChildStateMachineWeb.ChildLiveView do
  use Phoenix.LiveView
  alias ChildStateMachine

  # When LiveView mounts, subscribe to GenServer updates
  def mount(_params, _session, socket) do
    case ChildStateMachine.send_event(:get_state) do
      {:ok, state} ->
        {:ok, assign(socket, state: state, error: nil)}

      _error ->
        {:ok,
         assign(socket,
           state: %{
             state: :error,
             mood: 0,
             snacks: 0,
             total_snacks_consumed: 0,
             error: "Failed to get initial state"
           }
         )}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="relative">
      <%= if @error do %>
        <div
          role="alert"
          class="absolute inset-x-0 top-0 transform -translate-y-full transition-transform duration-300"
        >
          <div class="bg-red-500 text-white font-bold rounded-t px-4 py-2">
            Danger
          </div>
          
          <div class="border border-t-0 border-red-400 rounded-b bg-red-100 px-4 py-3 text-red-700">
            <p><%= @error %></p>
          </div>
        </div>
      <% end %>
      
      <div class="mt-24 p-4 max-w-sm mx-auto bg-white rounded-xl shadow-md flex items-center space-x-4">
        <div>
          <div class="text-xl font-medium text-black">State: <%= @state.state %></div>
          
          <p class="text-gray-500">Mood: <%= @state.mood %></p>
          
          <p class="text-gray-500">Snacks: <%= @state.snacks %></p>
        </div>
      </div>
      
      <div class="flex space-x-2 justify-center py-2">
        <button
          phx-click="send_event"
          phx-value-event="call_to_kindergarten"
          class="px-4 py-2 bg-brand text-black rounded hover:bg-brand-dark"
          id="to-hiding-btn"
        >
          Go to Kindergarten
        </button>
        
        <button
          phx-click="send_event"
          phx-value-event="call_to_play"
          class="px-4 py-2 bg-green-500 text-black rounded hover:bg-green-700"
          id="to-playing-btn"
        >
          Play
        </button>
        
        <button
          phx-click="send_event"
          phx-value-event="call_to_eat"
          class="px-4 py-2 bg-blue-500 text-black rounded hover:bg-blue-700"
          id="to-eating-btn"
        >
          Eat
        </button>
        
        <button
          phx-click="send_event"
          phx-value-event="give_snack"
          class="px-4 py-2 bg-yellow-500 text-black rounded hover:bg-yellow-600"
          id="give-snack-btn"
        >
          Give Snack
        </button>
      </div>
    </div>
    """
  end

  # Handling events from the user
  def handle_event("send_event", %{"event" => event}, socket) do
    case ChildStateMachine.send_event(String.to_atom(event)) do
      {:ok, new_state} ->
        IO.inspect(new_state, label: "New State")
        {:noreply, assign(socket, state: new_state, error: nil)}

      {:error, reason} ->
        {:noreply, assign(socket, error: reason)}
    end
  end
end
