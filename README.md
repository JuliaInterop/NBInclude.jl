# NBInclude

[![CI](https://github.com/JuliaInterop/NBInclude.jl/workflows/CI/badge.svg)](https://github.com/JuliaInterop/NBInclude.jl/actions?query=workflow%3ACI)

NBInclude is a package for the [Julia language](http://julialang.org/) which allows you to include and execute [IJulia](https://github.com/JuliaLang/IJulia.jl) (Julia-language [Jupyter](https://jupyter.org/)) notebook files just as you would include an ordinary Julia file.

The goal of this package is to make notebook files just as easy to incorporate into Julia programs as ordinary Julia (`.jl`) files, giving you the advantages of a notebook (integrated code, formatted text, equations, graphics, and other results) while retaining the modularity and re-usability of `.jl` files.

## Basic usage

Analogous to [`include("myfile.jl")`](https://docs.julialang.org/en/v1/base/base/#Base.include) in Julia to execute `myfile.jl`, you can do
```jl
using NBInclude
@nbinclude("myfile.ipynb")
```
to execute all of the code cells in the IJulia notebook `myfile.ipynb`. Similar to `include`, the value of the last evaluated expression in the last evaluated code cell is returned.

We also export an `in_nbinclude()` function, which returns `true` only when it is
executed in code run via `@nbinclude`.  Using this, you can selectively run code
in a notebook only interactively or only via `@nbinclude`.

There is also a function
```jl
nbexport("myfile.jl", "myfile.ipynb")
```
that can be used to convert an IJulia notebook file to an ordinary Julia file, with
Markdown text in the notebook converted to formatted comments in the Julia file.

## Detailed features

Key features of `@nbinclude` are:

* The path of the notebook is relative to the path of the current file (if any),
and nested inclusions can use paths relative to the notebook, just as for `include`.
* In a module, included notebooks work fine with [precompilation](https://docs.julialang.org/en/v1/manual/modules/#Module-initialization-and-precompilation) in Julia (and re-compilation is automatically triggered if the notebook changes).
* Code is associated with accurate line numbers (e.g. for backtraces when exceptions are thrown), in the form of `myfile.ipynb:In[N]:M` for line `M` in input cell `N` of the `myfile.ipynb` notebook.  Un-numbered cells (e.g. unevaluated cells) are given a number
`+N` for the `N`-th nonempty cell in the notebook.  You can use `@nbinclude("myfile.ipynb", renumber=true)` to automatically renumber the cells in sequence (as if you had selected *Run All* from the Jupyter *Cell* menu), without altering the file.
* The Julia `@__FILE__` macro returns `/path/to/myfile.ipynb:In[N]` for input cell `N`.
* In IJulia, cells beginning with `;` or `?` are interpreted as shell commands or help requests, respectively.  Such cells are ignored by `@nbinclude`.
* `counters` and `regex` keywords can be used to include a subset of notebook cells to those for which `counter ∈ counters` and the cell text matches `regex`. For example, `@nbinclude("notebook.ipynb"; counters=1:10, regex=r"#\s*EXECUTE")`
would include cells 1 to 10 from `notebook.ipynb` that contain comments like `# EXECUTE`.
* A keyword `anshook` can be used to run a passed function on the return value of all the cells.
* No Python or Jupyter dependency.
* The `softscope` flag mentioned below.

Note: Scoping rules differ between interactive (IJulia, REPL) and non-interactive Julia code. Running a notebook as `@nbinclude("foo.ipynb"; softscope=true)` will load notebooks using "soft" global scoping similar to interactive (REPL) code in Julia 1.5+ or for IJulia with any Julia version. That flag's default value, `false`, will load notebooks with the "hard" scoping rule that Julia uses for non-interactive code (e.g. in `include`); see also the [SoftGlobalScope package](https://github.com/stevengj/SoftGlobalScope.jl) for more details.

Key features of `nbexport` are:

* You can either call `nbexport(filename, notebookfile)` to export to a file, or
  `nbexport(io, notebookfile)` to write to an `IO` stream (e.g. `stdout` or a buffer).
* To export to a string, use `sprint(nbexport, notebookfile)`.
* Like `@nbinclude`, you can pass a `regex` keyword to specify a subset of the notebook
  code cells to export.
* Markdown cells in the notebook are parsed and formatted as pretty-printed text comments
  with the help of Julia's [Markdown](https://docs.julialang.org/en/v1/stdlib/Markdown/)
  standard library.
* Markdown cells can be ignored by passing `markdown=false` to `nbexport`.

## Contact

NBInclude was written by [Steven G. Johnson](http://math.mit.edu/~stevenj/) and is free/open-source software under the [MIT/Expat license](LICENSE.md).  Please file bug reports and feature requests at the [NBInclude github page](https://github.com/stevengj/NBInclude.jl).
