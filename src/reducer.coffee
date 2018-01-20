defineError = require 'node-define-error'
NodeParsingError = defineError('NodeParsingError')
UnimplementedRule = defineError('UnimplementedRule')
ReduceError = defineError('ReduceError', ['reducer', 'path', 'state', 'current', 'input'])

copyObj = (obj) ->
	r = {}
	for k in Object.keys(obj)
		r[k] = obj[k]
	return r

defineReducer = (opts) ->
	reducerName = opts?.name ? '?'
	parseNode = opts?.parseNode ? (x) -> {rule: x[0], arg: x[1..]}
	register = opts?.register ? {}
	defaultRule = opts?.defaultRule ? (arg, context, rule) -> throw new UnimplementedRule(rule)
	init = (register) ->
		impl = (rule) -> (body) ->
			register[rule] = body

		reduce = (root, context_ = {}) ->
			{env, initState} = context_
			context = {env, state: initState?()}
			path = []
			rec = (root) ->
				rec.current = root
				try
					{rule, arg} = parseNode(root)
				catch e
					throw new NodeParsingError('', e)
				body = register[rule] ? defaultRule
				path.push(rule)
				#log -> state
				r = body.call(rec, arg, context, rule)
				path.pop()
				return r
			rec.path = path
			try
				rst = rec(root)
				return {result: rst, state: context.state}
			catch e
				throw new ReduceError({reducer: reducerName, path, state: context.state, current: rec.current, input: root}, e)

		return (ruleDescripter) ->
			ruleDescripter(impl)
			reducer = {
				runState: (t, context) -> reduce(t, context)
				evalState: (t, context) -> reduce(t, context).result
				execState: (t, context) -> reduce(t, context).state
				eval: (t) -> reduce(t).result
				derive: (opts2) -> defineReducer({
					name: opts2.name
					parseNode: opts2.parseNode ? parseNode
					register: copyObj(register)
					defaultRule: opts2.defaultRule ? defaultRule
				})
			}
			return reducer

	return init(register)

module.exports = {
	defineReducer
	ReduceError
}

if module.parent is null
	require 'coffee-mate/global'

	evalExpr = defineReducer({name: 'ArithCalc'}) (def) ->
		def('+') ([a, b]) -> @(a) + @(b)
		def('-') ([a, b]) -> @(a) - @(b)
		def('const') ([a]) -> parseFloat(a)

	evalExpr1 = defineReducer({name: 'ArithCalc0'}) (def) ->
		def('+') ([a, b], {env, state}) -> state.cnt += 1; @(a) + @(b)
		def('-') ([a, b], {env, state}) -> state.cnt += 1; @(a) - @(b)
		def('const') ([a]) -> parseFloat(a)

	evalExpr2 = evalExpr1.derive({name: 'ArithCalc1'}) (def) ->
		def('*') ([a, b], {env, state}) -> state.cnt += 1; @(a) * @(b)

	context = {env: {}, initState: (-> {cnt: 0})}

	log -> evalExpr.eval(['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]])
	log -> evalExpr1.runState(['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]], context)
	log -> evalExpr1.runState(['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]], context)
	log -> evalExpr2.runState(['+', ['-', ['const', 1], ['const', 2]], ['*', ['const', '4'], ['const', '8']]], context)
	log -> evalExpr1.runState(['+', ['-', ['const', 1], ['const', 2]], ['*', ['const', '4'], ['const', '8']]], context)

