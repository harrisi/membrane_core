defmodule Membrane.Core.Message do
  @moduledoc false
  # Record representing membrane internal message

  require Record

  Record.defrecord(:message, __MODULE__, type: nil, args: [], opts: [])

  @type t :: {__MODULE__, type_t, args_t}
  @type type_t :: atom
  @type args_t :: list | any
  @type opts_t :: Keyword.t()

  defmacro new(type, args \\ [], opts \\ []) do
    quote do
      unquote(__MODULE__).message(type: unquote(type), args: unquote(args), opts: unquote(opts))
    end
  end

  @spec send(pid, type_t, args_t, opts_t) :: t
  def send(pid, type, args \\ [], opts \\ []) do
    Kernel.send(pid, message(type: type, args: args, opts: opts))
  end

  @spec self(type_t, args_t, opts_t) :: t
  def self(type, args \\ [], opts \\ []) do
    __MODULE__.send(self(), type, args, opts)
  end

  @spec call(GenServer.server(), type_t, args_t, timeout()) :: term()
  def call(pid, type, args \\ [], opts \\ [], timeout \\ 5000) do
    GenServer.call(pid, message(type: type, args: args, opts: opts), timeout)
  end

  def from_pad(message(opts: opts)), do: Keyword.get(opts, :from_pad)
end
