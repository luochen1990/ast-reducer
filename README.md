AST Reducer
===========

A Tool to process AST or any other recursive data structure in JavaScript.

Feature
-------

- An EDSL to define reduce rules
- Pure functional:
  - state is managed via simulating a state monad (the `state` field in context)
  - global constants is managed via simulating a reader monad (the `env` field in context)
- Derivable Reducer
- Pretty and helpful error message
- Configuable node parsing logic (the `parseNode` field in opts)
- Configuable default rule (the `defaultRule` field in opts)

Install
-------

```
npm install ast-reducer
```

Usage
-----

In CoffeeScript

```coffeescript
###------- Import Package -------###

{defineReducer} = require('ast-reducer')

###------- Simple Usage -------###

evalExpr = defineReducer({name: 'ArithCalc'}) (def) ->
  def('+') ([a, b]) -> @(a) + @(b)
  def('-') ([a, b]) -> @(a) - @(b)
  def('const') ([a]) -> parseFloat(a)

ast = ['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]]
console.log evalExpr.eval(ast)
# output: 11

###------- Use State -------###

evalExpr = defineReducer({name: 'ArithCalc0'}) (def) ->
  def('+') ([a, b], {env, state}) -> state.cnt += 1; @(a) + @(b)
  def('-') ([a, b], {env, state}) -> state.cnt += 1; @(a) - @(b)
  def('const') ([a]) -> parseFloat(a)

context = {env: {}, initState: (-> {cnt: 0})}
console.log evalExpr.runState(ast, context)
# output: { result: 11, state: { cnt: 3 } }

###------- Derive Reducer -------###

evalExpr2 = evalExpr.derive({name: 'ArithCalc1'}) (def) ->
  def('*') ([a, b], {env, state}) -> state.cnt += 1; @(a) * @(b)

ast2 = ['+', ['-', ['const', 1], ['const', 2]], ['*', ['const', '4'], ['const', '8']]]
console.log evalExpr2.runState(ast2, context)
# output: { result: 31, state: { cnt: 3 } }

###------- Error Report -------###

console.log evalExpr.runState(ast2, context)
# error message:
###
ReduceError:
  [reducer]: "ArithCalc0"
  [path]: ["+","*"]
  [state]: {"cnt":2}
  [current]: ["*",["const","4"],["const","8"]]
  [input]: ["+",["-",["const",1],["const",2]],["*",["const","4"],["const","8"]]]

  Caused By: UnimplementedRule: *
      at Function.defaultRule (the/long/long/path/to/reducer.coffee:34:13)

    at reduce (the/long/long/path/to/reducer.coffee:42:11)
    at Object.runState (the/long/long/path/to/reducer.coffee:47:31)
    ...
###
```

