{defineReducer} = require('./reducer')

### Simple Usage ###

evalExpr = defineReducer({name: 'ArithCalc'}) (def) ->
  def('+') ([a, b]) -> @(a) + @(b)
  def('-') ([a, b]) -> @(a) - @(b)
  def('const') ([a]) -> parseFloat(a)

ast = ['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]]
console.log evalExpr.eval(ast)

### Use State ###

evalExpr = defineReducer({name: 'ArithCalc0'}) (def) ->
  def('+') ([a, b], {env, state}) -> state.cnt += 1; @(a) + @(b)
  def('-') ([a, b], {env, state}) -> state.cnt += 1; @(a) - @(b)
  def('const') ([a]) -> parseFloat(a)

context = {env: {}, initState: (-> {cnt: 0})}
console.log evalExpr.runState(ast, context)

### Derive Reducer ###

evalExpr2 = evalExpr.derive({name: 'ArithCalc1'}) (def) ->
  def('*') ([a, b], {env, state}) -> state.cnt += 1; @(a) * @(b)

ast2 = ['+', ['-', ['const', 1], ['const', 2]], ['*', ['const', '4'], ['const', '8']]]
console.log evalExpr2.runState(ast2, context)

### Error Report ###

console.log evalExpr.runState(ast2, context)

