defmodule Acquire.Query.Where.Function do
  use Definition, schema: Acquire.Query.Where.Function.Schema

  @type t :: %__MODULE__{
          function: String.t(),
          args: [term]
        }

  defstruct [:function, :args]

  defimpl Acquire.Queryable, for: __MODULE__ do
    @operators ["=", ">", "<", ">=", "<=", "!="]

    alias Acquire.Queryable
    alias Acquire.Query.Where.Parameter

    def parse_statement(fun) do
      arguments =
        Enum.map(fun.args, fn arg ->
          case Queryable.impl_for(arg) do
            nil -> parameterize(arg)
            _ -> Queryable.parse_statement(arg)
          end
        end)

      to_statement(fun.function, arguments)
    end

    def parse_input(fun) do
      Enum.map(fun.args, fn arg ->
        case Queryable.impl_for(arg) do
          nil -> Parameter.get_value(arg)
          _ -> Queryable.parse_input(arg)
        end
      end)
      |> List.flatten()
      |> Enum.filter(& &1)
    end

    defp to_statement(fun, [arg1, arg2 | _]) when fun in @operators do
      "#{arg1} #{fun} #{arg2}"
    end

    defp to_statement(fun, arguments) do
      "#{fun}(#{Enum.join(arguments, ", ")})"
    end

    defp parameterize(%Parameter{}), do: "?"
    defp parameterize(arg), do: arg
  end
end

defmodule Acquire.Query.Where.Function.Schema do
  use Definition.Schema

  @impl true
  def s do
    schema(%Acquire.Query.Where.Function{
      function: required_string(),
      args: spec(is_list())
    })
  end
end
