using NBInclude, Test


@testset "Scoping Tests" begin
    VERSION >= v"1.0.0" ? eval(:(@test_throws LoadError @nbinclude(joinpath("includes", "scoping.ipynb")))) : true
    @nbinclude(joinpath("includes", "scoping.ipynb"); softscope = true)
    @test a == 11
end

@test include(joinpath("includes", "test1.jl")) == 314159
@test f(5) == 6
@test normpath(myfile) == abspath("test.ipynb") * ":In[6]"
@test normpath(myfile2) == abspath("test.ipynb") * ":In[+7]"

x=[]; @nbinclude("test2.ipynb")
@test x == [1, 2, 3, 4, 5, 6]

x=[]; @nbinclude("test2.ipynb"; counters = [1, 4, 5])
@test x == [1, 4, 5]

x=[]; @nbinclude("test2.ipynb"; regex=r"#.*executeme")
@test x == [2, 4]

x=[]; @nbinclude("test2.ipynb"; counters = [1, 4, 5], regex=r"#.*executeme")
@test x == [4]

z = 0; @nbinclude("test2.ipynb"; anshook = x -> (global z += 1))
@test z == 7

@test !in_nbinclude()

let desired_output = "#   This is an example notebook:\n\nfunction f(x)\n    return x + 1\nend\n\nf(3)\n\n# comment\n\nconst myfile = @__FILE__\n\nconst myfile2 = @__FILE__\nf(314158)\n# comment",
    test_ipynb = joinpath(@__DIR__, "test.ipynb"), outfilename = tempname()
    @test sprint(nbexport, test_ipynb) == desired_output
    try
        # wrong arg order should not overwrite ipynb (#30):
        @test_throws Exception nbexport(test_ipynb, outfilename)

        nbexport(outfilename, test_ipynb)
        @test read(outfilename, String) == desired_output
    finally
        rm(outfilename, force=true)
    end
end
