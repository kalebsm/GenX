using CSV
using DataFrames


subfolders = [    
              "Thermal_Base",
              "2_Hr_BESS", 
              "2_Hr_BESS_Fuelx2",
              "4_Hr_BESS",
              "4_Hr_BESS_Fuelx2",
              "4_Hr_BESS_Fuelx3",
              "4_Hr_BESS_Fuelx4",
              "6_Hr_BESS",
              "6_Hr_BESS_Fuelx2",
              "8_Hr_BESS",
              "8_Hr_BESS_Fuelx2",
              "10_Hr_BESS",
              "10_Hr_BESS_Fuelx2",
              ]
#


inpath = pwd()


for folder in subfolders

  # get runpath
  cem_path = inpath * "\\" * "research_systems" * "\\" * folder
  cem_resources_path = cem_path * "\\" * "resources"
  cem_results_path = cem_path * "\\" * "results"
  # cem_loc = "C:/Users/ks885/Documents/aa_research/Modeling/GenX_original/Research_Systems/"


  lac_path = inpath * "\\..\\" * "SPCM\\research_systems\\" * folder * "\\"
  # XXX could be updated with utils or Dr.watson 
  lac_resources_path = lac_path * "\\" *  "resources\\"

  # cem_path_name = "CEM_" * folder * "_ABB/"
  # cem_path = cem_loc * cem_path_name

  # cp(base_lac_path, lac_path; force=true)

  # load capacity.csv file from Results folder as dataframe
  capacity_df = CSV.read(joinpath(cem_results_path, "capacity.csv"), DataFrame)


  # load resources data from storage, thermal, vre
  cem_storage_gen_data = CSV.read(joinpath(cem_resources_path, "Storage.csv"), DataFrame)
  cem_thermal_gen_data = CSV.read(joinpath(cem_resources_path, "Thermal.csv"), DataFrame)
  cem_vre_gen_data = CSV.read(joinpath(cem_resources_path, "VRE.csv"), DataFrame)
  # outadated Generators all in same place
  # generator_data_df = CSV.read(joinpath(cem_path, "Generators_data.csv"), DataFrame)

  # get dataframe of capacity_df that are only non-zero in the NewCap and EndCap columns
  nontrivial_df = capacity_df[capacity_df.NewCap .> 1, :]
  # remove the resource for 'Total'
  nontrivial_df_upd = nontrivial_df[nontrivial_df.Resource .!= "Total", :]

  nontrivial_storage_data = filter(row -> row.Resource in nontrivial_df_upd.Resource, cem_storage_gen_data)
  nontrivial_thermal_data = filter(row -> row.Resource in nontrivial_df_upd.Resource, cem_thermal_gen_data)
  nontrivial_vre_data = filter(row -> row.Resource in nontrivial_df_upd.Resource, cem_vre_gen_data)

  ### get the capacities of the nontrivial resources in storage, thermal, vre
  # get the resources in capacity_df that are in cem_storage_gen_data
  storage_resources = nontrivial_storage_data.Resource
  thermal_resources = nontrivial_thermal_data.Resource
  vre_resources = nontrivial_vre_data.Resource

  # get the resources in capacity_df that are in resources
  storage_resource_only_capacity_df = filter(row -> row.Resource in storage_resources, capacity_df)
  thermal_resource_only_capacity_df = filter(row -> row.Resource in thermal_resources, capacity_df)
  vre_resource_only_capacity_df = filter(row -> row.Resource in vre_resources, capacity_df)

  # get the capacities from capacity_df
  storage_capacities = storage_resource_only_capacity_df.NewCap
  thermal_capacities = thermal_resource_only_capacity_df.NewCap
  vre_capacities = vre_resource_only_capacity_df.NewCap

  # get the energies from capacity_df
  storage_energies = storage_resource_only_capacity_df.NewEnergyCap

  # make copies of storage, thermal, vre dataframes for lacs
  lac_storage_data = copy(nontrivial_storage_data)
  lac_thermal_data = copy(nontrivial_thermal_data)
  lac_vre_data = copy(nontrivial_vre_data)

  # update Existing_Cap_MW in lac_storage_data with capacity_df.NewCap
  lac_storage_data.Existing_Cap_MW = storage_capacities
  lac_storage_data.Existing_Cap_MWh = storage_energies

  # update Existing_Cap_MW in lac_thermal_data with capacity_df.NewCap
  lac_thermal_data.Existing_Cap_MW = thermal_capacities

  # update Existing_Cap_MW in lac_vre_data with capacity_df.NewCap
  lac_vre_data.Existing_Cap_MW = vre_capacities
  # add columns for solar if reserouce has 'solar', 'pv', or 'photovoltaic' in the name
  lac_vre_data.Solar = ifelse.(occursin.(r"(?i)solar", lac_vre_data.Resource) .| 
    occursin.(r"(?i)pv", lac_vre_data.Resource) .| 
    occursin.(r"(?i)photovoltaic", lac_vre_data.Resource), 1, 0)
  # add columns for wind if resource has 'wind' in the name
  lac_vre_data.Wind = ifelse.(occursin.(r"(?i)wind", lac_vre_data.Resource), 1, 0)

  ### write the updated dataframes to the lac_resources_path
  # save the updated lac_storage_data to Storage.csv
  CSV.write(joinpath(lac_resources_path, "Storage.csv"), lac_storage_data)
  # save the updated lac_thermal_data to Thermal.csv
  CSV.write(joinpath(lac_resources_path, "Thermal.csv"), lac_thermal_data)
  # save the updated lac_vre_data to VRE.csv
  CSV.write(joinpath(lac_resources_path, "VRE.csv"), lac_vre_data)


  ### load Resource_minimum_capacity_requirement.csv in policy_assignments in lac_resources_path
  resource_minimum_capacity_requirement_df = CSV.read(joinpath(lac_resources_path, 
    "policy_assignments", "Resource_minimum_capacity_requirement.csv"), DataFrame)

  # filter out the resources that are not in the nontrivial_df
  resource_minimum_capacity_requirement_df = filter(row -> row.Resource in nontrivial_df.Resource, 
    resource_minimum_capacity_requirement_df)

  # save the updated resource_minimum_capacity_requirement_df to the lac_resources_path
  CSV.write(joinpath(lac_resources_path, "policy_assignments", 
    "Resource_minimum_capacity_requirement.csv"), resource_minimum_capacity_requirement_df)

  # lac_generator_data = filter(row -> row.Resource in capacity_df.Resource, generator_data_df)

  # resources = lac_generator_data.Resource

  # # get the resources in capacity_df that are in resources
  # resource_only_capacity_df = filter(row -> row.Resource in resources, capacity_df)

  # # get capacitieis from capacity_df
  # capacities = resource_only_capacity_df.NewCap
  # energies = resource_only_capacity_df.NewEnergyCap

  # # update Existing_Cap_MW in lac_generator_data with capacity_df.NewCap
  # lac_generator_data.Existing_Cap_MW = capacities
  # lac_generator_data.Existing_Cap_MWh = energies

  # # save the updated lac_generator_data to Generators_data.csv
  # CSV.write(joinpath(lac_path, "Generators_data.csv"), lac_generator_data)


  # load in the Generators_variability.csv
  # generator_variability_df = CSV.read(joinpath(cem_path, "Generators_variability.csv"), DataFrame)

  # load in the Fuels_data.csv
  # fuels_data_df = CSV.read(joinpath(cem_path, "Fuels_data.csv"), DataFrame)

  # load in the load_data.csv
  # load_data_df = CSV.read(joinpath(cem_path, "Load_data.csv"), DataFrame)

  # save the the generator_variability_df to the lac_path
  # CSV.write(joinpath(lac_path, "Generators_variability.csv"), generator_variability_df)

  # save the fuels_data_df to the lac_path
  # CSV.write(joinpath(lac_path, "Fuels_data.csv"), fuels_data_df)

  # save the load_data to the lac_path
  # CSV.write(joinpath(lac_path, "Load_data.csv"), load_data_df)


  print("Done with ", folder, "\n")
end

print("Done with all folders")