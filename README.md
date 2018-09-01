# NBInclude

[![Build Status](https://travis-ci.org/stevengj/NBInclude.jl.svg?branch=master)](https://travis-ci.org/stevengj/NBInclude.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/8kixdblpw5oi8nd3?svg=true)](https://ci.appveyor.com/project/StevenGJohnson/nbinclude-jl)

NBInclude is a package for the [Julia language](http://julialang.org/) which allows you to include and execute [IJulia](https://github.com/JuliaLang/IJulia.jl) (Julia-language [Jupyter](https://jupyter.org/)) notebook files just as you would include an ordinary Julia file.  That is, analogous to doing [`include("myfile.jl")`](http://docs.julialang.org/en/latest/stdlib/base/#Base.include) in Julia to execute `myfile.jl`, you can do
```jl
using NBInclude
@nbinclude("myfile.ipynb")
```
to execute all of the code cells in the IJulia notebook `myfile.ipynb`. Similar to `include`, the value of the last evaluated expression in the last evaluated code cell is returned.

The goal of this package is to make notebook files just as easy to incorporate into Julia programs as ordinary Julia (`.jl`) files, giving you the advantages of a notebook (integrated code, formatted text, equations, graphics, and other results) while retaining the modularity and re-usability of `.jl` files.

Note: Scoping rules have changed between Julia 0.6 and Julia 1.0. Running a notebook as `@nbinclude(foo.ipynb, softscope=true)` will load notebooks as they work for interactive use in the IJulia kernel ("soft" global scoping, or 0.6-style). That flag's default value, `false`, will load notebooks with the "hard" scoping rule of Julia 1.0 (e.g. in `include`); see the [SoftGlobalScope package](https://github.com/stevengj/SoftGlobalScope.jl) for more details.

Key features of NBInclude are:

* The path of the notebook is relative to the path of the current file (if any),
and nested inclusions can use paths relative to the notebook, just as for `include`.
* In a module, included notebooks work fine with [precompilation](http://docs.julialang.org/en/latest/manual/modules/#module-initialization-and-precompilation) in Julia 0.4 (and re-compilation is automatically triggered if the notebook changes).
* Code is associated with accurate line numbers (e.g. for backtraces when exceptions are thrown), in the form of `myfile.ipynb:In[N]:M` for line `M` in input cell `N` of the `myfile.ipynb` notebook.  Un-numbered cells (e.g. unevaluated cells) are given a number
`+N` for the `N`-th nonempty cell in the notebook.  You can use `@nbinclude("myfile.ipynb", renumber=true)` to automatically renumber the cells in sequence (as if you had selected *Run All* from the Jupyter *Cell* menu), without altering the file.
* The Julia `@__FILE__` macro returns `/path/to/myfile.ipynb:In[N]` for input cell `N`.
* In IJulia, cells beginning with `;` or `?` are interpreted as shell commands or help requests, respectively.  Such cells are ignored by `@nbinclude`.
* `counters` and `regex` keywords can be used to include a subset of notebook cells to those for which `counter ∈ counters` and the cell text matches `regex`. For example, `@nbinclude("notebook.ipynb"; counters=1:10, regex=r"#\s*EXECUTE")`
would include cells 1 to 10 from `notebook.ipynb` that contain comments like `# EXECUTE`.
* A keyword `anshook` can be used to run a passed function on the return value of all the cells.
* No Python or Jupyter dependency.
* The `softscope` flag mentioned above. 

To install it, simply do `Pkg.add("NBInclude")` as usual for Julia packages.

## Contact

NBInclude was written by [Steven G. Johnson](http://math.mit.edu/~stevenj/) and is free/open-source software under the [MIT/Expat license](LICENSE.md).  Please file bug reports and feature requests at the [NBInclude github page](https://github.com/stevengj/NBInclude.jl).
