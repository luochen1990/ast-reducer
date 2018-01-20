defineReducer = require('../lib/reducer').defineReducer

evalExpr = defineReducer({name: 'ArithCalc'})((def) => {
    def('+')(([a, b]) => this(a) + this(b)) //not working, this is auto binded.
    def('-')(([a, b]) => this(a) - this(b))
    def('const')(([a]) => parseFloat(a))
})

console.log(evalExpr.eval(['+', ['-', ['const', 1], ['const', 2]], ['+', ['const', '4'], ['const', '8']]]))
