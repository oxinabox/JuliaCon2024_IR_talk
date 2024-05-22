

Title: Adventures in Julia IR: Plundering Core.Compiler


Abstract:
This is a tutorial on how to use the tools shipped with Julia in Core.Compiler to manipulate the Julia IR and thus change how the program is compiled.
It includes running custom code transforms (like for autodiff), custom optimization passes, and introducing custom intrinsics.
This talk is for advanced Julia users, who want to understand and (ab)use the internals.


Description:
Julia uses several intermediate representations (IR) during the compilation process.
The abstract syntax tree (AST), untyped IR, typed IR, LLVM IR.
Different transforms happen as these different stages, and they can be extended by you.
In contrast to previous talks presented at JuliaCon, the focus of this talk is on typed-IR, rather than the untyped IR commonly manipulated with Cassette or IRTools.jl.

This talk will cover in detail how passes transform the code, showing how to implement and deploy custom passes for optimization.
This will allow you to control how your code is optimised, or even introduce new semantics beyond what is possible at the lexical/syntax level via conventional metaprogramming.

The exact content and methods presented in this talk are likely to break without warning, as they use extensively the internals of the language which are subject to change without regards to SemVer.
However, the general learning and approach will remain relevant.
