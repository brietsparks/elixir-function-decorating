defmodule ElixirLogflowTest do
  use ExUnit.Case
  doctest ElixirLogflow

  test "calc args - mix_envs - default" do
    assert ElixirLogflow.calc_args(quote do nil end) == {[:dev]}
  end

  test "do_using - simple - mix env = dev" do
    result_ast = ElixirLogflow.do_using(nil, :dev)
    assert result_ast == ElixirLogflow.generate_using_ast
  end

  test "do_using - simple - mix env = prod" do
    result_ast = ElixirLogflow.do_using(nil, current_env: :prod)
    assert result_ast == (quote do nil end)
  end

  test "do_using - with 'mix_envs: [:prod]', mix env = :prod" do
    result_ast = ElixirLogflow.do_using(quote do [mix_envs: [:prod]] end,
      :prod)
    assert result_ast == ElixirLogflow.generate_using_ast
  end

  test "decorate_function_def" do
    fn_call_ast = quote do beep(word) end
    fn_options_ast = [do: quote do word end]

    defmodule TestModuleDecorator do
      def decorate(%FnDef{} = fn_def, decorators) do
        {:ok, fn_def}
      end
    end

    result = ElixirLogflow.decorate_function_def(%FnDef{
        fn_call_ast: fn_call_ast, fn_options_ast: fn_options_ast},
        [TestModuleDecorator])

    assert result == {:ok, %FnDef{
        fn_call_ast: quote do beep(word) end,
        fn_options_ast: [do: quote do word end]
      }}
  end

  def tttt do
    call_ast = quote(unquote: false) do say_hello end
    body_ast = quote(unquote: false) do [do: :ok] end
    fun_name = ""
    expected_ast = quote context: ElixirLogflow do
      Kernel.def unquote({:say_hello, [], ElixirLogflowTest}) do
        module = __ENV__.module
        function_name = unquote(fun_name)

        ElixirLogflow.do_log_pre(module,
          unquote({:{}, [], [:say_hello, [], ElixirLogflowTest]}))
        result = :ok
        ElixirLogflow.do_log_pst(module,
          unquote({:{}, [], [:say_hello, [], ElixirLogflowTest]}),
          result)

        result
      end
    end

    result_ast = ElixirLogflow.do_def(call_ast, body_ast)
    assert ^expected_ast = result_ast
  end
end
