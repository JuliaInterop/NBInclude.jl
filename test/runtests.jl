using NBInclude
using Base.Test

@test nbinclude("test.ipynb") == 314159
@test f(5) == 6
@test myfile == abspath("test.ipynb") * ":In[4]"
@test myfile2 == abspath("test.ipynb") * ":In[+5]"
