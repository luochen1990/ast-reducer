{copy, log, json} = require 'coffee-mate'
CustomErrorType = require 'custom-error-type'
UndefinedReduceRule = CustomErrorType('UndefinedReduceRule', (rule) -> "Unimplemented Rule: #{rule}")
NodeParsingError = CustomErrorType('NodeParsingError', (parentError) -> "parseNode Failed:\n#{parentError.stack}")
ReduceError = CustomErrorType('ReduceError', ({path, state, current, input, parentError}) -> "#{parentError.name}\n Rule: #{path[path.length-1]}\n Path: #{path.map((p) -> json(p)).join(' -> ')}\n State: #{JSON.stringify state}\n Current: #{JSON.stringify current}\n Input: #{JSON.stringify input}\n")

defineReducer = (opts) ->
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
					throw new ReduceError({path, state: context.state, current: rec.current, input: root, parentError: e})
				else
					throw e

		return (ruleDescripter) ->
			ruleDescripter(impl)
			reducer = (t, context) -> reduce(t, context).result
			reducer.runState = (t, context) -> reduce(t, context)
			reducer.evalState = (t, context) -> reduce(t, context).result
			reducer.execState = (t, context) -> reduce(t, context).state
			reducer.derive = (moreRuleDescripter) -> init(copy(register))(moreRuleDescripter)
			return reducer

	return init(register)

module.exports = {
	defineReducer
	ReduceError
}

if module.parent is null
	evalExpr = defineReducer() (def) ->
		def('+') ([a, b], {env, state}) -> state.cnt += 1; @(a) + @(b)
		def('-') ([a, b], {env, state}) -> state.cnt += 1; @(a) - @(b)
		def('const') ([a]) -> parseFloat(a)

	evalExpr2 = evalExpr.derive (def) ->
		def('*') ([a, b], {env, state}) -> state.cnt += 1; @(a) * @(b)

	context = {env: {}, initState: (-> {cnt: 0})}
	try
		log -> evalExpr.runState(['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]], context)
		log -> evalExpr.runState(['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]], context)
		log -> evalExpr2.runState(['+', ['-', ['const', 1], ['const', 2]], ['*', ['const', '4'], ['const', '8']]], context)
		log -> evalExpr.runState(['+', ['-', ['const', 1], ['const', 2]], ['*', ['const', '4'], ['const', '8']]], context)
	catch e
		log -> e.message

