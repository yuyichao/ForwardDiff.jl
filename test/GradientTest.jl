module GradientTest

include(joinpath(Pkg.dir("ForwardDiff"), "test", "TestFuncs.jl"))

import Calculus

using Base.Test
using ForwardDiff
using ForwardDiff: default_value, KWARG_DEFAULTS

########################
# @gradient/@gradient! #
########################

const ALL = :(Val{$(default_value(KWARG_DEFAULTS, :allresults))})
const CHUNK = :(Val{$(default_value(KWARG_DEFAULTS, :chunk))})
const LEN = :(Val{$(default_value(KWARG_DEFAULTS, :input_length))})
const MULTITHREAD = :(Val{$(default_value(KWARG_DEFAULTS, :multithread))})
const MUTATES = :(Val{$(default_value(KWARG_DEFAULTS, :mutates))})

@test macroexpand(:(ForwardDiff.@gradient(sin))) == :(ForwardDiff._gradient(sin, $ALL, $CHUNK, $LEN, $MULTITHREAD, $MUTATES))
@test macroexpand(:(ForwardDiff.@gradient(sin; mutates=1, allresults=2, multithread=3, chunk=4, input_length=5))) == :(ForwardDiff._gradient(sin, Val{2}, Val{4}, Val{5}, Val{3}, Val{1}))
@test macroexpand(:(ForwardDiff.@gradient(sin, chunk=1, mutates=2))) == :(ForwardDiff._gradient(sin, $ALL, Val{1}, $LEN, $MULTITHREAD, Val{2}))

@test macroexpand(:(ForwardDiff.@gradient(sin, x))) == :(ForwardDiff._gradient(sin, x, $ALL, $CHUNK, $LEN, $MULTITHREAD))
@test macroexpand(:(ForwardDiff.@gradient(sin, x, input_length=1, allresults=2, multithread=3, chunk=4))) == :(ForwardDiff._gradient(sin, x, Val{2}, Val{4}, Val{1}, Val{3}))
@test macroexpand(:(ForwardDiff.@gradient(sin, x; chunk=1, multithread=2))) == :(ForwardDiff._gradient(sin, x, $ALL, Val{1}, $LEN, Val{2}))

@test macroexpand(:(ForwardDiff.@gradient!(sin, output, x))) == :(ForwardDiff._gradient!(sin, output, x, $ALL, $CHUNK, $LEN, $MULTITHREAD))
@test macroexpand(:(ForwardDiff.@gradient!(sin, output, x, input_length=1, allresults=2, multithread=3, chunk=4))) == :(ForwardDiff._gradient!(sin, output, x, Val{2}, Val{4}, Val{1}, Val{3}))
@test macroexpand(:(ForwardDiff.@gradient!(sin, output, x; chunk=1, multithread=2))) == :(ForwardDiff._gradient!(sin, output, x, $ALL, Val{1}, $LEN, Val{2}))

##################
# Test Functions #
##################

const XLEN = 10
const X = rand(XLEN)
const GRADEPS = 1e-6

# There's going to be some approximation error, since we're testing
# against a result calculated via finite difference.
test_approx_grad(a::Array, b::Array) = @test_approx_eq_eps a b GRADEPS
test_approx_grad(a::Number, b::Number) = @test_approx_eq_eps a b GRADEPS

function test_approx_grad(a::ForwardDiff.GradientResult, b::ForwardDiff.GradientResult)
    test_approx_grad(ForwardDiff.value(a), ForwardDiff.value(b))
    test_approx_grad(ForwardDiff.gradient(a), ForwardDiff.gradient(b))
end

output() = similar(X)

for f in TestFuncs.VECTOR_TO_SCALAR_FUNCS
    valresult = f(X)
    gradresult = Calculus.gradient(f, X)
    fullresult = ForwardDiff.GradientResult(valresult, gradresult)
    for c in (default_value(KWARG_DEFAULTS, :chunk), div(XLEN, 2), div(XLEN, 2) + 1, XLEN)
        ###################
        # single-threaded #
        ###################
        # @gradient(f)
        g1 = ForwardDiff.@gradient(f; chunk = c, input_length = XLEN)
        g1! = ForwardDiff.@gradient(f; chunk = c, mutates = true)
        g2 = ForwardDiff.@gradient(f; chunk = c, allresults = true)
        g2! = ForwardDiff.@gradient(f; chunk = c, input_length = XLEN, allresults = true, mutates = true)
        out1 = output()
        out2 = output()
        test_approx_grad(gradresult, g1(X))
        test_approx_grad(gradresult, g1!(out1, X))
        test_approx_grad(gradresult, out1)
        test_approx_grad(fullresult, g2(X))
        test_approx_grad(fullresult, g2!(out2, X))
        test_approx_grad(gradresult, out2)
        # @gradient(f, x)
        test_approx_grad(gradresult, ForwardDiff.@gradient(f, X; chunk = c, input_length = XLEN))
        test_approx_grad(fullresult, ForwardDiff.@gradient(f, X; chunk = c, allresults = true))
        # @gradient!(f, out, x)
        out3 = output()
        out4 = output()
        test_approx_grad(gradresult, ForwardDiff.@gradient!(f, out3, X; chunk = c, input_length = XLEN))
        test_approx_grad(gradresult, out3)
        test_approx_grad(fullresult, ForwardDiff.@gradient!(f, out4, X; chunk = c, allresults = true))
        test_approx_grad(gradresult, out4)
        if ForwardDiff.IS_MULTITHREADED_JULIA
            #################
            # multithreaded #
            #################
            # @gradient(f)
            g1 = ForwardDiff.@gradient(f; multithread = true, chunk = c, input_length = XLEN)
            g1! = ForwardDiff.@gradient(f; multithread = true, chunk = c, mutates = true)
            g2 = ForwardDiff.@gradient(f; multithread = true, chunk = c, allresults = true)
            g2! = ForwardDiff.@gradient(f; multithread = true, chunk = c, input_length = XLEN, allresults = true, mutates = true)
            out1 = output()
            out2 = output()
            test_approx_grad(gradresult, g1(X))
            test_approx_grad(gradresult, g1!(out1, X))
            test_approx_grad(gradresult, out1)
            test_approx_grad(fullresult, g2(X))
            test_approx_grad(fullresult, g2!(out2, X))
            test_approx_grad(gradresult, out2)
            # @gradient(f, x)
            test_approx_grad(gradresult, ForwardDiff.@gradient(f, X; multithread = true, chunk = c, input_length = XLEN))
            test_approx_grad(fullresult, ForwardDiff.@gradient(f, X; multithread = true, chunk = c, allresults = true))
            # @gradient!(f, out, x)
            out3 = output()
            out4 = output()
            test_approx_grad(gradresult, ForwardDiff.@gradient!(f, out3, X; multithread = true, chunk = c, input_length = XLEN))
            test_approx_grad(gradresult, out3)
            test_approx_grad(fullresult, ForwardDiff.@gradient!(f, out4, X; multithread = true, chunk = c, allresults = true))
            test_approx_grad(gradresult, out4)
        end
    end
end

end # module
