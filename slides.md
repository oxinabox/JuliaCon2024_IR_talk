
# Adventures in IR: Plundering Core.Compiler

Dr Frames White (she/her)

JuliaHub

---

## This conference is much easier to get to than on in the US
Only 20 hours in transit,
not 40.

---

## What is this talk?

This is about writing custom omptimization passes that work using the tools that are built into the compiler itself.

Incontrast to say IRTools.jl which reimplements analysis and motification utilities itself

It is the core behind DAECompiler used in Cedar,
and behind Diffractor's demand driven AD.
It's also used for Will Tebbut's Tapir.jl reverse mode AD.

---

## A warning: this is unstable internals

This is so far away from a public API.
We are in the deep intercontinential ocean.
The light of god can not reach you here.

If see Valentin Churavy's talk for some parts of stablizing some of this.
But it will likely remain not fully public.

In particular, the trick of giving typed IR to an OpaqueCloure is likely to change.
It's not what they were really made for, it just happens to be convienent.

But the general content and conception of this talk should remain useful.


---

## Why would I want to do this?

 - Run different optimization pipeline 
    - Disable inlining
    - Allow union splitting with more than 4 elements in the union
    - etc.
 - Generate multiple functions from 1 definition
    - DAECompile generates about a dozen different things like Jacobians and callbacks from a signle function definition.
    - This kinda thing generally requires custom intrinsics.
 
---

## The compiler pipeline
You are likely familar with the compilation pipeline of:

1. Source code
2. Parsing -> AST
     - Macros run here
3. Lowering -> Untyped IR
     - Cassette, Zygote and JuliaInterpetter run here
4. Type Inference -> Typed IR 
     - loop here running julia optimization passes
     - This stage is what this talk is about
5. Code Generation -> LLVM IR
     - loop here running LLVM optimization passes
     - Enzyme, and GPU Compiler run here.
6. Assembling -> Machine Code

---

## Let's soom in on step 4: the Typed IR
If you have used `@code_typed` you get back typed IR, as a `CodeInfo` object.
It's not quiet SSA because it has slots (basically variables).

You want a `IRCode` object, which you can get from `Base.code_ircode`.
This is the representation that is used with in the optimizer.
it is a true SSA, and it is also enriched with the CFG.
For display purposes it can be converted back to a `CodeInfo` object.

This is what is actually created and manipulated during this step,
and what almost all Julia's own optimization passes are running on.

---

## How do I get instructions out of a `IRCode`

```julia
if VERSION < v"1.11.0-DEV.258"
    Base.getindex(ir::IRCode, ssa::SSAValue) = CC.getindex(ir, ssa)
end
```

---
## A lot of the utilities are not in the Base namespace
When you do `for` that lowers to calls to `iterate` in the current namespace.
Similar for `getindex` and `setindex` (and several other special forms).
But `Core` is a different namespace to `Base`.
So some things are broken if you are using from normal julia code which is in main with Base exporting them.
But you can do a manual method merge across the namespaces.


---


