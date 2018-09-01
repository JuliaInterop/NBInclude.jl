VERSION < v"0.7.0-beta2.199" && __precompile__()

"""
The NBInclude module allow you to include and execute Julia code from
IJulia Jupyter notebooks.  Analogous to `include("myfile.jl")`, just do

    using NBInclude
    @nbinclude("myfile.ipynb")

to include the Julia code from the notebook `myfile.ipynb`.  Like `include`,
the value of the last evaluated expression is returned.
"""
module NBInclude
export nbinclude, @nbinclude

using Compat, JSON, SoftGlobalScope

"""
    my_include_string(m::Module, s::AbstractString, path::AbstractString, prev, softscope)

Like include_string (or softscope_include_string, depending on the `softscope` flag), but also change the current source path just as `include(filename)` would do.   We are hacking undocumented internals of Julia here (see `base/loading.jl:include_relative`), but it hasn't
changed from Julia 0.2 to Julia 0.7 so it's not too crazy.  `prev`
should be the previous path returned by `Base.source_path`.
"""
function my_include_string(m::Module, s::AbstractString, path::AbstractString, prev, softscope)
    tls = task_local_storage()
    tls[:SOURCE_PATH] = path
    try
        return softscope ? softscope_include_string(m, s, path) : include_string(m, s, path)
    finally
        if prev === nothing
            delete!(tls, :SOURCE_PATH)
        else
            tls[:SOURCE_PATH] = prev
        end
    end
end

"""
    nbinclude(m::Module, path; ...)

Like `@nbinclude(path; ...)` but allows you to specify a module
to evaluate in, similar to `include(m, path)`.
"""
function nbinclude(m::Module, path::AbstractString;
                   renumber::Bool=false,
                   counters = 1:typemax(Int),
                   regex::Regex = r"",
                   anshook = identity,
                   softscope::Bool=false)
   # act like include(path), in that path is relative to current file:
   # for precompilation, invalidate the cache if the notebook changes:
    path, prev = @static if VERSION >= v"0.7.0-DEV.3483" # julia#25455
        Base._include_dependency(m, path)
    else
        Base._include_dependency(path)
    end

    # similar to julia#22588, we assume that all nodes
    # where you are running nbinclude can access the filesystem
    nb = open(JSON.parse, path, "r")

    # check for an acceptable notebook:
    nb["nbformat"] == 4 || error("unrecognized notebook format ", nb["nbformat"])
    lang = lowercase(nb["metadata"]["language_info"]["name"])
    lang == "julia" || error("notebook is for unregognized language $lang")

    shell_or_help = r"^\s*[;?]" # pattern for shell command or help

    ret = nothing
    counter = 0 # keep our own cell counter to handle un-executed notebooks.
    for cell in nb["cells"]
        if cell["cell_type"] == "code" && !isempty(cell["source"])
            s = join(cell["source"])
            isempty(strip(s)) && continue # Jupyter doesn't number empty cells
            counter += 1
            occursin(shell_or_help, s) && continue
            cellnum = renumber ? string(counter) :
                      cell["execution_count"] == nothing ? string('+',counter) :
                      string(cell["execution_count"])
            counter in counters && occursin(regex, s) || continue
            ret = my_include_string(m, s, string(path, ":In[", cellnum, "]"), prev, softscope)
            anshook(ret)
        end
    end
    return ret
end

# nbinclude(path) must be a macro because of #22064 — in 1.0, current_module() is disappearing
# so there is no way to get the caller's module without being a macro.

@noinline function nbinclude(path::AbstractString; kws...)
    Base.depwarn("`nbinclude(path)` is deprecated, use `@nbinclude(path)` instead.", :nbinclude)
    return nbinclude(isdefined(Base, :_current_module) ? Base._current_module() : current_module(),
                     path; kws...)
end

const curmod_expr = VERSION >= v"0.7.0-DEV.481" ? :(@__MODULE__) : :(current_module())

"""
    @nbinclude(path::AbstractString; renumber::Bool=false, counters=1:typemax(Int), regex::Regex=r"", anshook = identity, softscope::Bool = false)

Include the IJulia Jupyter notebook at `path` and execute the code
cells (in the order that they appear in the file) in `m`, returning the
result of the last expression in the last code cell.

Similarly to `include(path)` for `.jl` files, the `path` is relative
to the path of the current file (if any), and nested calls to
`include` or `nbinclude` are relative to the path of the notebook file.

For code in the `N`-th input cell of the notebook, the `@__FILE__` macro
(and other code that uses the file name, e.g. exception backtraces)
returns `path:In[N]`, where `N` is the cell number saved in the notebook.
If the cell has no number (e.g. if it hasn't been evaluated yet), then
it is assigned a number `+N` for the `N`-th nonempty cell.  If `renumber`
is set to `true`, then the cell numbers saved in the notebook are ignored
and each cell is assigned a consecutive number `N`.

`counters` and `regex` can be used to include only a subset of notebook cells.
Only cells for which `counter ∈ counters` holds and the cell text matches `regex`
are executed. E.g.

    @nbinclude("notebook.ipynb"; counters = 1:10, regex=r"# *exec"i)

would include cells 1 to 10 from "notebook.ipynb" that contain comments like
`# exec` or `# ExecuteMe` in the cell text.

`anshook` can be used to execute a function on all the values returned in the cells.

`softscope` toggles between the "hard" and "soft" scoping rules described in the README.

See also `nbinclude(module, path; ...)` to include a notebook in a specified module.
"""
macro nbinclude(args...)
    args = collect(args) # need a mutable collection, not a tuple
    # (extracting keyword arguments in macro calls is a pain since we want to handle
    # the cases both with and without a semicolon.)
    if !isempty(args) && Meta.isexpr(args[1], :parameters)
        kws = map(esc, popfirst!(args).args)
    else
        kws = Any[]
    end
    while !isempty(args)
        if Meta.isexpr(args[end], :(=))
            pushfirst!(kws, esc(Expr(:kw, args[end].args)))
            pop!(args)
        else
            break
        end
    end
    # remaining args: path or module,path
    args = esc.(args)
    if length(args) == 1
        pushfirst!(args, curmod_expr) # use current module
    end
    return Expr(:call, :nbinclude, Expr(:parameters, kws...), args...)
end

end # module
