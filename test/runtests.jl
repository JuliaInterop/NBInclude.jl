using Base.Test, Compat

addprocs(1)

import NBInclude; @everywhere using NBInclude

@test include(joinpath("includes", "test1.jl")) == 314159
@test f(5) == 6
@test normpath(myfile) == abspath("test.ipynb") * ":In[6]"
@test normpath(myfile2) == abspath("test.ipynb") * ":In[+7]"

@test remotecall_fetch(nbinclude, 2, "test.ipynb") == 314159
