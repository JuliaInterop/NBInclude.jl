# NBInclude

[![Build Status](https://travis-ci.org/stevengj/NBInclude.jl.svg?branch=master)](https://travis-ci.org/stevengj/NBInclude.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/8kixdblpw5oi8nd3?svg=true)](https://ci.appveyor.com/project/StevenGJohnson/nbinclude-jl)

NBInclude is a package for the Julia language which allows you to
include and execute Julia-language Jupyter (IJulia) notebook files
just as you would include an ordinary Julia file.  That is, analogous
to doing `include("myfile.jl")` in Julia to execute `myfile.jl`, you can do
```jl
using NBInclude
nbinclude("myfile.ipynb")
```
to execute all of the code cells in the IJulia notebook `myfile.ipynb`.
Similar to `include`, the value of the last evaluated expression
in the last evaluated code cell is returned.

The goal of this package is to make notebook files just as easy to
incorporate into Julia programs as ordinary Julia (`.jl`) files, giving
you the advantages of a notebook (integrated code, formatted text, equations,
graphics, and other results) while retaining the modularity and re-usability
of `.jl` files.

Key features of NBInclude are:

* The path of the notebook is relative to the path of the current file (if any),
and nested inclusions can use paths relative to the notebook, just as for `include`.
* In a module, included notebooks work fine with precompilation in Julia 0.4 (and re-compilation is automatically triggered if the notebook changes).
* Code is associated with accurate line numbers (e.g. for backtraces when exceptions are thrown), in the form of `myfile.ipynb:In[N]:M` for line `M` in input cell `N` of the `myfile.ipynb` notebook.  Un-numbered cells (e.g. unevaluated cells) are given a number
`+N` for the `N`-th nonempty cell in the notebook.  You can use `nbinclude("myfile.ipynb", renumber=true)` to automatically renumber the cells in sequence (as if you had selected *Run All* from the Jupyter *Cell* menu), without altering the file.
* The Julia `@__FILE__` macro returns `/path/to/myfile.ipynb:In[N]` for input cell `N`.
* Like `include`, `nbinclude` works fine with parallel Julia processes, even for
worker processes (from Julia's `addprocs`) that may not have filesystem access.
(Do `import NBInclude; @everywhere using NBInclude` to use `nbinclude` on
all processes.)
* No Python or Jupyter dependency.

To install it, simply do `Pkg.add("NBInclude")` as usual for Julia packages.

## Contact

NBInclude was written by [Steven G. Johnson](http://math.mit.edu/~stevenj/) and is free/open-source software under the [MIT/Expat license](LICENSE.md).  Please file bug reports and feature requests at the [NBInclude github page](https://github.com/stevengj/NBInclude.jl).
