import Base.getindex, Base.vec, Base.dot, Base.cross, Base.-, Base.+
import GeometryTypes.Point
export Point
export HRepElement, HalfSpace, HyperPlane
export VRepElement, AbstractPoint, SymPoint, AbstractRay, Ray, Line
export islin, isray, ispoint, ispoint, coord, lift

const MyPoint{N,T} = Union{Point{N,T},AbstractArray{T}}
mypoint{T}(::Type{T}, a::AbstractArray) = AbstractArray{T}(a)
mypoint{T}(::Type{T}, a::AbstractArray{T}) = a
mypoint{N,T}(::Type{T}, a::Point{N}) = Point{N,T}(a)
mypoint{N,T}(::Type{T}, a::Point{N,T}) = a
const MyVec{N,T} = Union{Vec{N,T},AbstractArray{T}}
myvec{T}(::Type{T}, a::AbstractArray) = AbstractArray{T}(a)
myvec{T}(::Type{T}, a::AbstractArray{T}) = a
myvec{N,T}(::Type{T}, a::Vec{N}) = Vec{N,T}(a)
myvec{N,T}(::Type{T}, a::Vec{N,T}) = a

mydot(a, b) = sum(a .* b)
mydot(a::AbstractVector, b::AbstractVector) = dot(a, b)
mydot(f::FixedVector, v::FixedVector) = dot(f, v)
#mydot{T<:Union{Ray,Line}}(a::T, b::T) = mydot(a.r, b.r)
#mydot{T<:Union{Ray,Line}}(a, b::T) = mydot(a, b.r)
#mydot{T<:Union{Ray,Line}}(a::T, b) = mydot(a.r, b)

vecconv{T}(::Type{T}, a::AbstractVector) = AbstractVector{T}(a)
vecconv{T}(::Type{T}, a::FixedVector) = FixedVector{T}(a)

abstract type HRepElement{N,T} end

# ⟨a, x⟩ <= β
struct HalfSpace{N,T} <: HRepElement{N,T}
    a::MyVec{N,T}
    β::T
    function HalfSpace{N, T}(a::MyVec{N,T}, β::T) where {N, T}
        new{N, T}(a, β)
    end
end

(::Type{HalfSpace{N,T}}){N,T}(a::MyVec, β) = HalfSpace{N,T}(myvec(T, a), T(β))

struct HyperPlane{N,T} <: HRepElement{N,T}
    a::MyVec{N,T}
    β::T
    function HyperPlane{N, T}(a::MyVec{N,T}, β::T) where {N, T}
        new{N, T}(a, β)
    end
end

(::Type{HyperPlane{N,T}}){N,T}(a::MyVec, β) = HyperPlane{N,T}(myvec(T, a), T(β))

# FIXME should promote between a and β
HalfSpace(a, β) = HalfSpace{fulldim(a), eltype(a)}(a, eltype(a)(β))
HyperPlane(a, β) = HyperPlane{fulldim(a), eltype(a)}(a, eltype(a)(β))

Base.convert{N,Tin,Tout}(::Type{HalfSpace{N,Tout}}, h::HalfSpace{N,Tin}) = HalfSpace{N,Tout}(vecconv(Tout, h.a), Tout(h.β))
Base.convert{N,Tin,Tout}(::Type{HyperPlane{N,Tout}}, h::HyperPlane{N,Tin}) = HyperPlane{N,Tout}(vecconv(Tout, h.a), Tout(h.β))
Base.convert{N,T}(::Type{HalfSpace{N,T}}, h::HalfSpace{N,T}) = h
Base.convert{N,T}(::Type{HyperPlane{N,T}}, h::HyperPlane{N,T}) = h

islin(v::HalfSpace) = false
islin(v::HyperPlane) = true

(-)(h1::HRepElement, h2::HRepElement) = HalfSpace(h1.a - h2.a, h1.β - h2.β)
(-)(h1::HyperPlane, h2::HyperPlane) = HyperPlane(h1.a - h2.a, h1.β - h2.β)

(*)(h::HyperPlane, α::Real) = HyperPlane(h.a * α, h.β * α)
(*)(α::Real, h::HyperPlane) = HyperPlane(α * h.a, α * h.β)
(*)(h::HalfSpace, α::Real) = HalfSpace(h.a * α, h.β * α)
(*)(α::Real, h::HalfSpace) = HalfSpace(α * h.a, α * h.β)

function (*){ElemT<:HRepElement}(h::ElemT, P::Matrix)
    Tout = mypromote_type(eltype(ElemT), eltype(P))
    ElemTout = changeboth(ElemT, size(P, 2), Tout)
    ElemTout(P' * h.a, h.β)
end
function zeropad{ElemT<:HRepElement}(h::ElemT, n::Integer)
    if n == 0
        h
    else
        ElemTout = changefulldim(ElemT, fulldim(h) + abs(n))
        T = eltype(ElemT)
        if n < 0
            aout = [spzeros(T, -n); h.a]
        else
            aout = [h.a; spzeros(T, n)]
        end
        ElemTout(aout, h.β)
    end
end

# Point: -> A same Rep should always return the same of the two types so that when points and sympoints will have different accessors it will be type stable
# Point{N, T} or AbstractVector{T}
# Linear Point:
# SymPoint{N,T}
# Ray:
# Ray{N, T}
# Linear Ray:
# Line{N, T}

struct SymPoint{N, T}
    a::MyPoint{N, T}
    function SymPoint{N, T}(a::MyPoint{N, T}) where {N, T}
        new{N, T}(a)
    end
end

(::Type{SymPoint{N,T}}){N,T}(a::MyPoint) = SymPoint{N,T}(mypoint(T, a))

struct Ray{N, T}
    a::MyVec{N, T}
    function Ray{N, T}(a::MyVec{N, T}) where {N, T}
        new{N, T}(a)
    end
end

(::Type{Ray{N,T}}){N,T}(a::MyVec) = Ray{N,T}(myvec(T, a))

struct Line{N,T}
    a::MyVec{N, T}
    function Line{N, T}(a::MyVec{N, T}) where {N, T}
        new{N, T}(a)
    end
end

getindex(x::Union{SymPoint,Ray,Line}, i) = x.a[i]
vec(x::Union{SymPoint,Ray,Line}) = vec(x.a)

(-){ElemT<:Union{HyperPlane, HalfSpace}}(h::ElemT) = ElemT(-h.a, -h.β)
(-){ElemT<:Union{SymPoint,Ray,Line}}(elem::ElemT) = ElemT(-coord(elem))
# Used in remproj
(-)(p::AbstractArray, l::Line) = p - coord(l)
# Ray - Line is done in remproj
(-)(r::Ray, s::Union{Ray, Line}) = Ray(r.a - s.a)
(+)(r::Ray, s::Ray) = Ray(r.a + s.a)
(+)(p::Union{AbstractArray,Point}, r::Ray) = p + coord(r)

for op in [:dot, :cross]
    @eval begin
        $op(x::Union{SymPoint,Ray,Line}, y) = $op(x.a, y)
        $op(x, y::Union{SymPoint,Ray,Line}) = $op(x, y.a)
        $op(x::Union{SymPoint,Ray,Line}, y::Union{SymPoint,Ray,Line}) = $op(x.a, y.a)
    end
end

(*){T<:Union{SymPoint,Ray,Line}}(x, y::T) = T(x * y.a)
(*){T<:Union{SymPoint,Ray,Line}}(y::T, x) = T(y.a * x)

Base.convert{T}(::Type{Vector{T}}, x::Union{SymPoint,Ray,Line}) = convert(Vector{T}, x.a)

(::Type{Line{N,T}}){N,T}(a::MyVec) = Line{N,T}(myvec(T, a))

SymPoint(a::Union{Point,AbstractVector}) = SymPoint{fulldim(a), eltype(a)}(a)
Ray(a::Union{Vec,AbstractVector}) = Ray{fulldim(a), eltype(a)}(a)
Line(a::Union{Vec,AbstractVector}) = Line{fulldim(a), eltype(a)}(a)

Base.convert{N,Tin,Tout}(::Type{SymPoint{N,Tout}}, v::SymPoint{N,Tin}) = SymPoint{N,Tout}(vecconv(Tout, v.a))
Base.convert{N,Tin,Tout}(::Type{Ray{N,Tout}}, v::Ray{N,Tin}) = Ray{N,Tout}(vecconv(Tout, v.a))
Base.convert{N,Tin,Tout}(::Type{Line{N,Tout}}, v::Line{N,Tin}) = Line{N,Tout}(vecconv(Tout, v.a))
Base.convert{N,T}(::Type{SymPoint{N,T}}, v::SymPoint{N,T}) = v
Base.convert{N,T}(::Type{Ray{N,T}}, v::Ray{N,T}) = v
Base.convert{N,T}(::Type{Line{N,T}}, v::Line{N,T}) = v

const AbstractPoint{N, T} = Union{Point{N, T}, AbstractVector{T}, SymPoint{N, T}}
const AbstractRay{N, T} = Union{Ray{N, T}, Line{N, T}}
const FixedVRepElement{N,T} = Union{Point{N,T}, Ray{N,T}, Line{N,T}, SymPoint{N,T}}
const VRepElement{N,T} = Union{FixedVRepElement{N,T}, AbstractVector{T}}
const RepElement{N,T} = Union{HRepElement{N,T}, VRepElement{N,T}}
const FixedRepElement{N,T} = Union{HRepElement{N,T}, FixedVRepElement{N,T}}

fulldim{N}(e::FixedRepElement{N}) = N
eltype{N,T}(e::FixedRepElement{N, T}) = T
fulldim{T<:FixedRepElement}(::Type{T}) = T.parameters[1]
eltype{T<:FixedRepElement}(::Type{T}) = T.parameters[2]

fulldim(v::AbstractVector) = length(v)
fulldim{T<:AbstractVector}(::Type{T}) = T.parameters[1]

islin{T<:Union{Point,AbstractVector,Ray}}(v::T) = false
islin{T<:Union{SymPoint,Line}}(v::T) = true
isray{T<:Union{Point,AbstractVector,SymPoint}}(v::T) = false
isray{T<:Union{Ray,Line}}(v::T) = true
ispoint{T<:Union{Point,AbstractVector,SymPoint}}(v::T) = true
ispoint{T<:Union{Ray,Line}}(v::T) = false

coord{ElemT<:Union{Point,AbstractVector}}(v::ElemT) = v
coord{ElemT<:Union{HRepElement,SymPoint,Ray,Line}}(v::ElemT) = v.a

const VRepElementContainer = Union{SymPoint, Ray, Line}

function (*){ElemT<:FixedVRepElement}(P::Matrix, v::ElemT)
    if ElemT <: VRepElementContainer
        Tout = mypromote_type(eltype(ElemT), eltype(P))
        ElemTout = changeboth(ElemT, size(P, 1), Tout)
        return ElemTout(P * v.a)
    else
        return P * v.a
    end
end
function zeropad{ElemT<:VRepElement}(v::ElemT, n::Integer)
    if n == 0
        v
    else
        ElemTout = changefulldim(ElemT, fulldim(v) + abs(n))
        T = eltype(ElemT)
        if n < 0
            aout = [spzeros(T, -n); coord(v)]
        else
            aout = [coord(v); spzeros(T, n)]
        end
        ElemTout(aout)
    end
end

for ElemT in [:HalfSpace, :HyperPlane, :Point, :SymPoint, :Vec, :Ray, :Line]
    @eval begin
        changeeltype{N,T,Tout}(::Type{$ElemT{N,T}}, ::Type{Tout}) = $ElemT{N,Tout}
        changefulldim{N,T}(::Type{$ElemT{N,T}}, Nout) = $ElemT{Nout,T}
        changeboth{N,T,Tout}(::Type{$ElemT{N,T}}, Nout, ::Type{Tout}) = $ElemT{Nout,Tout}
    end
end

changeeltype{VecT<:AbstractVector,Tout}(::Type{VecT}, ::Type{Tout}) = AbstractVector{Tout}
changefulldim{VecT<:AbstractVector}(::Type{VecT}, Nout) = VecT
changeboth{VecT<:AbstractVector,Tout}(::Type{VecT}, Nout, ::Type{Tout}) = AbstractVector{Tout}

mydot(a::AbstractVector, r::Ray) = mydot(a, r.a)
mydot(a::AbstractVector, l::Line) = mydot(a, l.a)

Base.in{N}(r::Ray{N}, h::HalfSpace{N}) = mynonpos(mydot(h.a, r))
Base.in{N}(l::Line{N}, h::HalfSpace{N}) = mynonpos(mydot(h.a, l))
Base.in{N}(p::Point{N}, h::HalfSpace{N}) = myleq(mydot(h.a, p), h.β)
Base.in{N}(p::AbstractVector, h::HalfSpace{N}) = myleq(mydot(h.a, p), h.β)
Base.in{N}(p::SymPoint{N}, h::HalfSpace{N}) = myleq(mydot(h.a, p.p), h.β)

Base.in{N}(r::Ray{N}, h::HyperPlane{N}) = myeqzero(mydot(h.a, r))
Base.in{N}(l::Line{N}, h::HyperPlane{N}) = myeqzero(mydot(h.a, l))
Base.in{N}(p::Point{N}, h::HyperPlane{N}) = myeq(mydot(h.a, p), h.β)
Base.in{N}(p::AbstractVector, h::HyperPlane{N}) = myeq(mydot(h.a, p), h.β)
Base.in{N}(p::SymPoint{N}, h::HyperPlane{N}) = myeq(mydot(h.a, p.p), h.β)

import Base.vec
function Base.vec{N,T}(x::FixedVector{N,T})
    y = Vector{T}(N)
    for i in 1:N
        y[i] = x[i]
    end
    y
end
#Base.vec{ElemT::VRepElementContainer}(x::ElemT) = ElemT(vec(x.a))

pushbefore(a::AbstractVector, β) = [β; a]
function pushbefore{ElemT<:FixedVector}(a::ElemT, β, ElemTout = changefulldim(ElemT, fulldim(ElemT)+1))
    ElemTout([β; vec(a)])
end

function lift{ElemT <: HRepElement}(h::ElemT)
    ElemT(pushbefore(h.a, -h.β), zero(eltype(ElemT)))
end
lift{N,T}(h::Ray{N,T}) = Ray{N+1,T}(pushbefore(h.a, zero(T)))
lift{N,T}(h::Line{N,T}) = Line{N+1,T}(pushbefore(h.a, zero(T)))
lift{N,T}(h::Point{N,T}) = pushbefore(h, one(T))
lift{T}(h::AbstractVector{T}) = Ray{length(h)+1,T}(pushbefore(h, one(T)))
lift{N,T}(h::SymPoint{N,T}) = Line{N+1,T}(pushbefore(h.a, one(T)))

translate{ElemT<:HRepElement}(h::ElemT, p) = ElemT(h.a, h.β + mydot(h.a, p))
