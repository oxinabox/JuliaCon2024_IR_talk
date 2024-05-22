### A Pluto.jl notebook ###
# v0.19.42

using Markdown
using InteractiveUtils

# ╔═╡ e37297c2-2b54-4d3c-ba9e-42d6a3a4e838
using Core.Compiler

# ╔═╡ 9f8402bc-cdf3-4276-bdeb-4b7d48f681e2
using ExprTools: splitdef, combinedef

# ╔═╡ 9785f7a0-be8c-4281-bcf7-b0428c0891e0
const CC = Core.Compiler

# ╔═╡ 30764e4e-1803-4684-95b9-3cd6edae1faa
"Given some IR generates a MethodInstance suitable for passing to infer_ir!, if you don't already have one with the right argument types"
function get_toplevel_mi_from_ir(ir, _module::Module)
    mi = ccall(:jl_new_method_instance_uninit, Ref{Core.MethodInstance}, ());
    mi.specTypes = Tuple{map(CC.widenconst, ir.argtypes)...}
    mi.def = _module
    return mi
end

# ╔═╡ 53dfacae-81b5-4770-97d9-f03f0f2a2681
"run type inference and constant propagation on the ir"
function infer_ir!(ir, interp::CC.AbstractInterpreter, mi::CC.MethodInstance)
    method_info = CC.MethodInfo(#=propagate_inbounds=#true, nothing)
    min_world = world = CC.get_world_counter(interp)
    max_world = Base.get_world_counter()
    irsv = CC.IRInterpretationState(interp, method_info, ir, mi, ir.argtypes, world, min_world, max_world)
    rt = CC._ir_abstract_constant_propagation(interp, irsv)
    return ir
end

# ╔═╡ 4e63f0ef-0a11-49b7-a225-79a7f1cabb4a
Base.iterate(compact::Core.Compiler.IncrementalCompact, state) = CC.iterate(compact, state)

# ╔═╡ ec74cc3f-2bb1-4af6-857d-908f99e1feaa
Base.iterate(compact::Core.Compiler.IncrementalCompact) = CC.iterate(compact)

# ╔═╡ ecb40511-60e4-45ae-ae0e-da97c7246e9d
Base.getindex(c::Core.Compiler.IncrementalCompact, args...) = CC.getindex(c, args...)

# ╔═╡ 4c6aa8b2-0d0a-462d-996e-2a012466e29c
md"""
see this [gist](https://gist.github.com/oxinabox/cdcffc1392f91a2f6d80b2524726d802)
https://discourse.julialang.org/t/upper-boundary-for-dispatch-in-julia/109405/13?u=oxinabox
"""

# ╔═╡ 92e3966e-e286-401d-aebc-3234f5887cea
Base.setindex!(c::Core.Compiler.IncrementalCompact, args...) = CC.setindex!(c, args...)

# ╔═╡ cfca566f-a0ba-4e6d-9497-23b81cef79e3
Base.setindex!(i::Core.Compiler.Instruction, args...) = CC.setindex!(i, args...)

# ╔═╡ 295c616f-e671-4385-9857-eb14a9ade1e9
if VERSION < v"1.11"
	function typeinf_ir_code(interp::CC.AbstractInterpreter, match::CC.MethodMatch, optimize_until::Union{Integer,AbstractString,Nothing})
		CC.typeinf_ircode(interp, match.method, match.spec_types, match.sparams, optimize_until)
	end
else
	function typeinf_ir_code(interp::CC.AbstractInterpreter, match::CC.MethodMatch, optimize_until::Union{Integer,AbstractString,Nothing})
		CC.typeinf_ir_code(interp, match)
	end
end


# ╔═╡ 3b804335-43f0-48e6-a5d7-e93f4267ab73


# ╔═╡ 501cd502-127a-484f-9609-25e9934dac8d


# ╔═╡ dd5a48d3-c937-4048-9647-5f6a3782bf5a
macro my_opt(func)
	func_parts = splitdef(func)
	temp_func_parts = copy(func_parts)
	temp_func_parts[:name] = gensym(func_parts[:name])
	
	quote
		meth = only(methods($(esc(combinedef(temp_func_parts)))))
		world = Base.get_world_counter()
		matches = Base._methods_by_ftype(meth.sig, #=lim=#-1, world)  # compiled without concrete type specializeation. fine for out purposes
		interp = CC.NativeInterpreter(world)
		ir = typeinf_ir_code(interp, only(matches), nothing)[1]
		
				

		mi = get_toplevel_mi_from_ir(ir, @__MODULE__);
		ir = infer_ir!(ir, interp, mi)
		
		# Optional: run some optimization passes (these have docstrings)
		inline_state = Core.Compiler.InliningState(interp)
		ir = Core.Compiler.ssa_inlining_pass!(ir, inline_state, #=propagate_inbounds=#true)
		ir = Core.Compiler.compact!(ir)
		
		ir = Core.Compiler.sroa_pass!(ir, inline_state)
		ir = Core.Compiler.adce_pass!(ir, inline_state)
		ir = Core.Compiler.compact!(ir)
		
		
		# optional but without checking you get segfaults easily.
		Core.Compiler.verify_ir(ir)
		
		# Bundle this up into something that can be executed
		
		const ($(esc(func_parts[:name]))) = Core.OpaqueClosure(ir; do_compile=true)  
	end
end

# ╔═╡ 8412f6a2-6629-4b14-95ef-02e352f5a8ac


# ╔═╡ c8519ac3-5f6e-469b-81b8-f3767fa02341
@my_opt function fib(n)
	out = Int[1, 1]
	for ii in 1:n-2
		push!(out, out[end] + out[end-1])
	end
	return out
end

# ╔═╡ 5561f206-6639-44ca-bd10-45324cf70f89
fib(5)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
ExprTools = "e2ba6199-217a-4e67-a87a-7c52f15ade04"

[compat]
ExprTools = "~0.1.10"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.3"
manifest_format = "2.0"
project_hash = "91ccfba74bb692842acd81d2d4919a390bd5b5a7"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"
"""

# ╔═╡ Cell order:
# ╠═4c6aa8b2-0d0a-462d-996e-2a012466e29c
# ╠═e37297c2-2b54-4d3c-ba9e-42d6a3a4e838
# ╠═9785f7a0-be8c-4281-bcf7-b0428c0891e0
# ╠═30764e4e-1803-4684-95b9-3cd6edae1faa
# ╠═53dfacae-81b5-4770-97d9-f03f0f2a2681
# ╠═4e63f0ef-0a11-49b7-a225-79a7f1cabb4a
# ╠═ec74cc3f-2bb1-4af6-857d-908f99e1feaa
# ╠═ecb40511-60e4-45ae-ae0e-da97c7246e9d
# ╠═92e3966e-e286-401d-aebc-3234f5887cea
# ╠═cfca566f-a0ba-4e6d-9497-23b81cef79e3
# ╠═295c616f-e671-4385-9857-eb14a9ade1e9
# ╠═9f8402bc-cdf3-4276-bdeb-4b7d48f681e2
# ╠═3b804335-43f0-48e6-a5d7-e93f4267ab73
# ╠═501cd502-127a-484f-9609-25e9934dac8d
# ╠═dd5a48d3-c937-4048-9647-5f6a3782bf5a
# ╠═8412f6a2-6629-4b14-95ef-02e352f5a8ac
# ╠═c8519ac3-5f6e-469b-81b8-f3767fa02341
# ╠═5561f206-6639-44ca-bd10-45324cf70f89
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
