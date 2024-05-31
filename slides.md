
# Adventures in IR: Plundering Core.Compiler

Dr Frames White (she/her)

JuliaHub

---

## This conference is much easier to get to than on in the US
Only 20 hours in transit,
not 40.

---

## The compiler pipeline
You are likely familar with the compilation pipeline of
 - Source code
 - Parsing -> AST
     - Macros run here
 - Lowering -> Untyped IR
     - Cassette, Zygote and JuliaInterpetter run here
 - Type Inference -> Typed IR 
     - loop here running julia optimization passes
     - This stage is what this talk is about
 - Code Generation -> LLVM IR
     - loop here running LLVM optimization passes
     - Enzyme, and GPU compuler run here.
 - Assembling -> Machine Code

---

## That is not quiet detailed enough
If you have used `@code_typed` you get back typed IR.
A `CodeInfo` object.
It's not quiet SSA because it has slots (basically variables).

You want a `IRCode` object, which you can get from `Base.code_ircode`.
This is the representation that is used with in the optimizer.
it is a true SSA, and it is also enriched with the CFG.
For display purposes it can be converted back to a `CodeInfo` object

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
