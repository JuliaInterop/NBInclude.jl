@testset "Scoping Tests" begin
    @test_throws ErrorException @nbinclude("scoping.ipynb")
    @nbinclude("scoping.ipynb"; softscope = true)
    @test a == 11
end 