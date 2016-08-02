VERSION >= v"0.4.0-dev+6521" && __precompile__()

"""
The NBInclude module allow you to include and execute Julia code from
IJulia Jupyter notebooks.  Analogous to `include("myfile.jl")`, just do

    using NBInclude
    nbinclude("myfile.ipynb")

to include the Julia code from the notebook `myfile.ipynb`.  Like `include`,
the value of the last evaluated expression is returned.
"""
module NBInclude

using Compat, JSON
export nbinclude

"""
    my_include_string(s::AbstractString, path::AbstractString, prev)

Like include_string, but also change the current source path just
as `include(filename)` would do.   We are hacking undocumented internals
of Julia here (see `base/loading.jl:include_from_node1`), but it hasn't
changed from Julia 0.2 to Julia 0.4 so it's not too crazy.  `prev`
should be the previous path returned by `Base.source_path`.
"""
function my_include_string(s::AbstractString, path::AbstractString, prev)
    tls = task_local_storage()
    tls[:SOURCE_PATH] = path
    try
        return include_string(s, path)
    finally
        if prev === nothing
            delete!(tls, :SOURCE_PATH)
        else
            tls[:SOURCE_PATH] = prev
        end
    end
end

"""
    nbinclude(path::AbstractString; renumber::Bool=false)

Include the IJulia Jupyter notebook at `path` and execute the code
cells (in the order that they appear in the file), returning the
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
"""
function nbinclude(path::AbstractString; renumber::Bool=false)
    # act like include(path), in that path is relative to current file:
    prev = Base.source_path(nothing)
    path = (prev == nothing) ? abspath(path) : joinpath(dirname(prev),path)

    # for precompilation, invalidate the cache if the notebook changes:
    include_dependency(path)

    # similar to base/loading.jl, handle nbinclude calls from worker
    # nodes that may not have filesystem access by fetching the file
    # contents from node 1.
    nb = if myid() == 1
        # sleep a bit to process file requests from other nodes
        nprocs()>1 && sleep(0.005)
        open(JSON.parse, path, "r")
    else
        JSON.parse(remotecall_fetch(readstring, 1, path))
    end

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
            ismatch(shell_or_help, s) && continue
            cellnum = renumber ? string(counter) :
                      cell["execution_count"] == nothing ? string('+',counter) :
                      string(cell["execution_count"])
            ret = my_include_string(s, string(path, ":In[", cellnum, "]"), prev)
        end
    end
    return ret
end

end # module
