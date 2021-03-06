import ForwardDiff
using ForwardDiff.CHUNK_THRESHOLD
using Base.Test

# seed RNG, thus making result inaccuracies deterministic
# so we don't have to retune EPS for arbitrary inputs
srand(1)

const XLEN = CHUNK_THRESHOLD + 1
const YLEN = div(CHUNK_THRESHOLD, 2) + 1
const X, Y = rand(XLEN), rand(YLEN)
const CHUNK_SIZES = (1, div(CHUNK_THRESHOLD, 3), div(CHUNK_THRESHOLD, 2), CHUNK_THRESHOLD, CHUNK_THRESHOLD + 1)
const FINITEDIFF_ERROR = 1.5e-5

# used to test against results calculated via finite difference
test_approx_eps(a::Array, b::Array) = @test_approx_eq_eps a b EPS
