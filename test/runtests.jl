using Base.Test, Compat

addprocs(1)

import NBInclude; @everywhere using NBInclude

@test include(joinpath("includes", "test1.jl")) == 314159
@test f(5) == 6
@test normpath(myfile) == abspath("test.ipynb") * ":In[6]"
@test normpath(myfile2) == abspath("test.ipynb") * ":In[+7]"

@test remotecall_fetch(nbinclude, 2, "test.ipynb") == 314159


x=[]; nbinclude("test2.ipynb")
@test x == [1, 2, 3, 4, 5, 6]

x=[]; nbinclude("test2.ipynb"; counters = [1, 4, 5])
@test x == [1, 4, 5]

x=[]; nbinclude("test2.ipynb"; regexp=r"#.*executeme")
@test x == [2, 4]

x=[]; nbinclude("test2.ipynb"; cellnums = ["9", "10", "12"])
@test x == [1, 2, 4]

x=[]; nbinclude("test2.ipynb"; counters = [1, 4, 5], regexp=r"#.*executeme")
@test x == [4]

x=[]; nbinclude("test2.ipynb"; counters = [2, 1], regexp=r"exec", cellnums = ["9", "10"])
@test x == [2]
