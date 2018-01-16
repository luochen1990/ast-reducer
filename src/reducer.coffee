CustomErrorType = require 'custom-error-type'
UndefinedReduceRule = CustomErrorType('UndefinedReduceRule', (rule) -> "Unimplemented Rule: #{rule}")
NodeParsingError = CustomErrorType('NodeParsingError', (parentError) -> "parseNode Failed:\n#{parentError.stack}")
ReduceError = CustomErrorType('ReduceError', ({reducer, path, state, current, input, parentError}) -> "#{parentError.name}\n Reducer: #{reducer}\n Rule: #{path[path.length-1]}\n Path: #{path.map((p) -> JSON.stringify(p)).join(' -> ')}\n State: #{JSON.stringify state}\n Current: #{JSON.stringify current}\n Input: #{JSON.stringify input}\n")

copyObj = (obj) ->
	r = {}
	for k in Object.keys(obj)
		r[k] = obj[k]
	return r

simpl = (lit) ->
	lit = lit.replace(/^\s*\(\s*function\s*\(\s*\)\s*{\s*return\s*([^]*?);?\s*}\s*\)\s*\(\s*\)\s*$/, '$1')
	return lit

literal = (thunk) ->
	s0 = "(#{thunk.toString()})()"
	s1 = simpl(s0)
	until s1 == s0
		s0 = s1
		s1 = simpl(s1)
	s2 = s0.replace(/[\r\n]{1,2}\s*/g, '') #inline
	r = if s2.length <= 60 then s2 else s0
	return r

log = (thunk) -> console.log(literal(thunk), '===>', thunk())

defineReducer = (opts) ->
	reducerName = opts?.name ? '?'
	parseNode = opts?.parseNode ? (x) -> {rule: x[0], arg: x[1..]}
	register = opts?.register ? {}
	defaultRule = opts?.defaultRule ? (arg, env, state, rule) -> throw new UndefinedReduceRule(rule)
	init = (register) ->
		impl = (rule) -> (body) ->
			register[rule] = body

		reduce = (root, {env, initState}) ->
			context = {env, state: initState()}
			path = []
			rec = (root) ->
				rec.current = root
				try
					{rule, arg} = parseNode(root)
				catch e
					throw new NodeParsingError(e)
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
				if (e instanceof NodeParsingError) or (e instanceof UndefinedReduceRule)
					throw new ReduceError({reducer: reducerName, path, state: context.state, current: rec.current, input: root, parentError: e})
				else
					throw e

		return (ruleDescripter) ->
			ruleDescripter(impl)
			reducer = {
				runState: (t, context) -> reduce(t, context)
				evalState: (t, context) -> reduce(t, context).result
				execState: (t, context) -> reduce(t, context).state
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
	evalExpr = defineReducer({name: 'ArithCalc0'}) (def) ->
		def('+') ([a, b], {env, state}) -> state.cnt += 1; @(a) + @(b)
		def('-') ([a, b], {env, state}) -> state.cnt += 1; @(a) - @(b)
		def('const') ([a]) -> parseFloat(a)

	evalExpr2 = evalExpr.derive({name: 'ArithCalc1'}) (def) ->
		def('*') ([a, b], {env, state}) -> state.cnt += 1; @(a) * @(b)

	context = {env: {}, initState: (-> {cnt: 0})}
	try
		log -> evalExpr
		log -> evalExpr.runState(['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]], context)
		log -> evalExpr.runState(['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]], context)
		log -> evalExpr2.runState(['+', ['-', ['const', 1], ['const', 2]], ['*', ['const', '4'], ['const', '8']]], context)
		log -> evalExpr.runState(['+', ['-', ['const', 1], ['const', 2]], ['*', ['const', '4'], ['const', '8']]], context)
	catch e
		log -> e.message

