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
    runpath = inpath * "\\" * "research_systems" * "\\" * folder

    if isdir(joinpath(runpath, "Results"))
        println("Results folder exists in ", runpath)
        println("Removing Results folder $folder")
        if isdir(runpath * "\\Results")
            rm(runpath * "\\Results"; force=true, recursive=true)
        else
            continue
        end
    else
        println("Results folder does not exist in ", runpath)
    end

    # could run full case here
    try
        # Run the command (subprocess)
        println("Running process in $folder")
        # run(command)
        include(joinpath(runpath, "Run.jl"))
    catch e
        # Handle any error that may occur during the subprocess execution
        println("Error in $folder: $e")
    end


end

