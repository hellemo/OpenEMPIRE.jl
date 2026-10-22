function test_solve()

	data_folder = joinpath(pkgdir(OpenEMPIRE), "data", "test")
	config_file = joinpath(pkgdir(OpenEMPIRE), "config", "testrun.yaml")

	emp, periods, sets, params = OpenEMPIRE.create_model(config_file, data_folder; optimizer = HiGHS.Optimizer)

	optimize!(emp)

	@test termination_status(emp) == MOI.OPTIMAL
	@test primal_status(emp) == MOI.FEASIBLE_POINT
	@test isfinite(objective_value(emp))
end

# `model_factory` builds into the model it returns, given the model's periods.
function test_model_factory()
	data_folder = joinpath(pkgdir(OpenEMPIRE), "data", "test")
	config_file = joinpath(pkgdir(OpenEMPIRE), "config", "testrun.yaml")

	reference, = OpenEMPIRE.create_model(config_file, data_folder; optimizer = HiGHS.Optimizer,
		scenario_rng = Random.MersenneTwister(1))
	optimize!(reference)

	factory_periods = Ref{Any}(nothing)
	factory = periods -> (factory_periods[] = periods; JuMP.Model(HiGHS.Optimizer))
	emp, periods, = OpenEMPIRE.create_model(config_file, data_folder; model_factory = factory,
		scenario_rng = Random.MersenneTwister(1))
	@test factory_periods[] === periods
	set_silent(emp)
	optimize!(emp)

	@test termination_status(emp) == MOI.OPTIMAL
	@test objective_value(emp) ≈ objective_value(reference) rtol = 1e-6
end
