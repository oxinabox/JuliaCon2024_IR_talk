### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ e2274fde-ac8a-11ee-2da5-07759d5f3838
using IntervalArithmetic


# ╔═╡ 9f8402bc-cdf3-4276-bdeb-4b7d48f681e2
using ExprTools: splitdef, combinedef

# ╔═╡ 30764e4e-1803-4684-95b9-3cd6edae1faa
"Given some IR generates a MethodInstance suitable for passing to infer_ir!, if you don't already have one with the right argument types"
function get_toplevel_mi_from_ir(ir, _module::Module)
    mi = ccall(:jl_new_method_instance_uninit, Ref{Core.MethodInstance}, ());
    mi.specTypes = Tuple{map(Core.Compiler.widenconst, ir.argtypes)...}
    mi.def = _module
    return mi
end

# ╔═╡ 53dfacae-81b5-4770-97d9-f03f0f2a2681
"run type inference and constant propagation on the ir"
function infer_ir!(ir, interp::Core.Compiler.AbstractInterpreter, mi::Core.Compiler.MethodInstance)
    method_info = Core.Compiler.MethodInfo(#=propagate_inbounds=#true, nothing)
    min_world = world = Core.Compiler.get_world_counter(interp)
    max_world = Base.get_world_counter()
    irsv = Core.Compiler.IRInterpretationState(interp, method_info, ir, mi, ir.argtypes, world, min_world, max_world)
    rt = Core.Compiler._ir_abstract_constant_propagation(interp, irsv)
    return ir
end

# ╔═╡ 4e63f0ef-0a11-49b7-a225-79a7f1cabb4a
Base.iterate(compact::Core.Compiler.IncrementalCompact, state) = Core.Compiler.iterate(compact, state)

# ╔═╡ ec74cc3f-2bb1-4af6-857d-908f99e1feaa
Base.iterate(compact::Core.Compiler.IncrementalCompact) = Core.Compiler.iterate(compact)

# ╔═╡ ecb40511-60e4-45ae-ae0e-da97c7246e9d
Base.getindex(c::Core.Compiler.IncrementalCompact, args...) = Core.Compiler.getindex(c, args...)

# ╔═╡ 4c6aa8b2-0d0a-462d-996e-2a012466e29c
md"""
see this [gist](https://gist.github.com/oxinabox/cdcffc1392f91a2f6d80b2524726d802)
"""

# ╔═╡ 92e3966e-e286-401d-aebc-3234f5887cea
Base.setindex!(c::Core.Compiler.IncrementalCompact, args...) = Core.Compiler.setindex!(c, args...)

# ╔═╡ cfca566f-a0ba-4e6d-9497-23b81cef79e3
Base.setindex!(i::Core.Compiler.Instruction, args...) = Core.Compiler.setindex!(i, args...)

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
		interp = Core.Compiler.Core.Compiler.NativeInterpreter(world)
		ir = Core.Compiler.typeinf_ircode(interp, only(matches), nothing)[1]


		mi = get_toplevel_mi_from_ir(ir, @__MODULE__);
		ir = infer_ir!(ir, interp, mi)
		
		# Optional: run some optimization passes (these have docstrings)
		inline_state = Core.Compiler.InliningState(interp)
		ir = Core.Compiler.ssa_inlining_pass!(ir, inline_state, #=propagate_inbounds=#true)
		ir = Core.Compiler.compact!(ir)
		
		ir = Core.Compiler.sroa_pass!(ir, inline_state)
		ir, = Core.Compiler.adce_pass!(ir, inline_state)
		ir = Core.Compiler.compact!(ir)
		
		
		# optional but without checking you get segfaults easily.
		Core.Compiler.verify_ir(ir)
		
		# Bundle this up into something that can be executed
		
		const ($(esc(func_parts[:name]))) = Core.OpaqueClosure(ir; do_compile=true)  
	end
end

# ╔═╡ c8519ac3-5f6e-469b-81b8-f3767fa02341
@my_opt function biased_flip2()
	if 2*rand()>2.0
		:heads
	else
		:tails
	end
end

# ╔═╡ 5561f206-6639-44ca-bd10-45324cf70f89
biased_flip2()

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
ExprTools = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
IntervalArithmetic = "d1acc4aa-44c8-5952-acd4-ba5d80a2a253"

[compat]
ExprTools = "~0.1.10"
IntervalArithmetic = "~0.22.5"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.0-DEV"
manifest_format = "2.0"
project_hash = "60c8570d280992127ffbb17971fdbf7b4a798ef3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.CRlibm]]
deps = ["CRlibm_jll"]
git-tree-sha1 = "32abd86e3c2025db5172aa182b982debed519834"
uuid = "96374032-68de-5a5b-8d9e-752f78720389"
version = "1.0.1"

[[deps.CRlibm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e329286945d0cfc04456972ea732551869af1cfc"
uuid = "4e9b3aee-d8a1-5a3d-ad8b-7d824db253f0"
version = "1.0.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.IntervalArithmetic]]
deps = ["CRlibm", "RoundingEmulator"]
git-tree-sha1 = "c274ec586ea58eb7b42afd0c5d67e50ff50229b5"
uuid = "d1acc4aa-44c8-5952-acd4-ba5d80a2a253"
version = "0.22.5"

    [deps.IntervalArithmetic.extensions]
    IntervalArithmeticDiffRulesExt = "DiffRules"
    IntervalArithmeticRecipesBaseExt = "RecipesBase"

    [deps.IntervalArithmetic.weakdeps]
    DiffRules = "b552c78f-8df3-52c6-915a-8e097449b14b"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.5.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.1+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00805cd429dcb4870060ff49ef443486c262e38e"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.RoundingEmulator]]
git-tree-sha1 = "40b9edad2e5287e05bd413a38f61a8ff55b9557b"
uuid = "5eaf0fd0-dfba-4ccb-bf02-d820a40db705"
version = "0.2.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.58.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╠═4c6aa8b2-0d0a-462d-996e-2a012466e29c
# ╠═30764e4e-1803-4684-95b9-3cd6edae1faa
# ╠═53dfacae-81b5-4770-97d9-f03f0f2a2681
# ╠═4e63f0ef-0a11-49b7-a225-79a7f1cabb4a
# ╠═ec74cc3f-2bb1-4af6-857d-908f99e1feaa
# ╠═ecb40511-60e4-45ae-ae0e-da97c7246e9d
# ╠═92e3966e-e286-401d-aebc-3234f5887cea
# ╠═cfca566f-a0ba-4e6d-9497-23b81cef79e3
# ╠═e2274fde-ac8a-11ee-2da5-07759d5f3838
# ╠═9f8402bc-cdf3-4276-bdeb-4b7d48f681e2
# ╠═3b804335-43f0-48e6-a5d7-e93f4267ab73
# ╠═501cd502-127a-484f-9609-25e9934dac8d
# ╠═dd5a48d3-c937-4048-9647-5f6a3782bf5a
# ╠═c8519ac3-5f6e-469b-81b8-f3767fa02341
# ╠═5561f206-6639-44ca-bd10-45324cf70f89
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
