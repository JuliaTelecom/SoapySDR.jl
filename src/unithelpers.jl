####################################################################################################
#    Unit Printing
####################################################################################################


# Express everything in (kHz, MHz, GHz)
function pick_freq_unit(val::Quantity)
    iszero(val.val) && return val
    abs(val) >= 1.0u"GHz" ? uconvert(u"GHz", val) :
    abs(val) >= 1.0u"MHz" ? uconvert(u"MHz", val) :
                            uconvert(u"kHz", val)
end

# Print to 3 digits of precision, no decimal point
print_3_digit(io::IO, val::Quantity) =  print(io, Base.Ryu.writeshortest(round(val.val, sigdigits=3),
    #= plus =# false,
    #= space =# false,
    #= hash =# false,
    ))

function print_unit(io::IO, val::Quantity)
    print_3_digit(io, val)
    print(io, " ", unit(val))
end

function print_unit_interval(io::IO, min, max)
    if unit(min) == unit(max) || iszero(min.val)
        print_3_digit(io, min)
        print(io, "..")
        print_3_digit(io, max)
        print(io, " ", unit(max))
    else
        print_unit(io, min)
        print(io, " .. ")
        print_unit(io, max)
    end
end

function print_unit_steprange(io::IO, min, max, step)
    print_unit(io, min)
    print(io, ":")
    print_unit(io, step)
    print(io, ":")
    print_unit(io, max)
end

print_unit_interval(io::IO, x::Interval{<:Any, Closed, Closed}) =
    print_unit_interval(io, minimum(x), maximum(x))

using Intervals: Closed
function print_hz_range(io::IO, x::Interval{<:Any, Closed, Closed})
    min, max = pick_freq_unit(minimum(x)), pick_freq_unit(maximum(x))
    print_unit_interval(io, min, max)
end

function print_hz_range(io::IO, x::AbstractRange)
    min, step, max = pick_freq_unit(first(x)), pick_freq_unit(Base.step(x)), pick_freq_unit(last(x))
    print_unit_steprange(io, min, max, step)
end
