using Base.Test

addprocs(1)

import NBInclude; @everywhere using NBInclude

@test nbinclude("test.ipynb") == 314159
@test f(5) == 6
@test myfile == abspath("test.ipynb") * ":In[4]"
@test myfile2 == abspath("test.ipynb") * ":In[+5]"

@test remotecall_fetch(nbinclude, 2, "test.ipynb") == 314159
