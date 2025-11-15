
"""
    comododir()

# Description 

This function simply returns the string for the Comodo path. This is helpful for 
instance to load items, such as meshes, from the `assets` folder. 
"""
function abaqustoolsdir()
    pkgdir(@__MODULE__)
end

function addHeader(file_io,jobName; echo="NO", model="NO", history="NO", contact="NO", comment="** Generated using AbaqusTools.jl")
    S = [
        "* Heading ", 
        "** Job name: $jobName", 
        comment, 
        "**----------------",
        "* Preprint, echo="*echo*", model="*model*", history="*history*", contact="*contact,       
        "**----------------",
        ]
    for s in S
        write(file_io, s*"\n")
    end
end

function addPart(file_io, partName; firstTime = true)
    if firstTime
        write(file_io, "** PARTS \n")    
    end
    write(file_io, "* Part, name=$partName \n")
    write(file_io, "** This section defines the part geometry in terms of nodes and elements \n")
end 

function addNodes(file_io, V)
    write(file_io, "* Node \n")    
    for (i,v) in enumerate(V)
        s = @sprintf("%i, ",i) * join([@sprintf("%.16e",x) for x ∈ v],", ")
        write(file_io, s*"\n")
    end
end 

function addElements(file_io, E, elementType; indexOffset=0)
    write(file_io, "* Element, type=$elementType \n")
    for (i,e) in enumerate(E)        
        s = @sprintf("%i, ", i+indexOffset) * join([@sprintf("%i",x) for x ∈ e],", ")
        write(file_io, s*"\n")
    end
end

function addSolidSection(file_io, elementSetName, materialName)
    write(file_io, "*Solid Section, elset=$elementSetName, material=$materialName \n")
    write(file_io, "*, \n")    
end

function endPart(file_io)
    write(file_io, "*End Part \n")        
end

function startAssembly(file_io; name="Assembly-1")
    write(file_io, "* Assembly, name=$name \n")
end

function endAssembly(file_io)
    write(file_io, "* End Assembly \n")
end

function addInstance(file_io; name="Part-1-assembly", part="Part-1")
    write(file_io, "* Instance, name=$name, part=$part \n")
    write(file_io, "* End Instance \n")
end

function addIndexSet(file_io, setName, ind; type=:nodes, instance="", nRow=16, indexOffset=0)
    if type == :nodes
        if !isempty(instance)
            write(file_io, "*Nset, nset=$setName, instance=$instance\n")    
        else
            write(file_io, "*Nset, nset=$setName \n")    
        end
    elseif type == :elements
        if !isempty(instance)
            write(file_io, "*Elset, elset=$setName, instance=$instance\n")     
        else
            write(file_io, "*Elset, elset=$setName \n")    
        end
    end
    
    m = length(ind)
    for i = 1:nRow:m
        j = i + nRow - 1 
        if j>m
            j = m 
        end
        s = join([@sprintf("%i",x+indexOffset) for x ∈ ind[i:j]],", ")
        write(file_io, s*"\n")
    end
end

function addMaterial(file_io; name="Elastic", type="Elastic", parameters=[1.0, 0.4])
    write(file_io, "* Material, name=$name \n")
    write(file_io, "* $type \n")
    write(file_io, join([@sprintf("%.16e", x) for x ∈ parameters], ", ") *" \n")
end

function startStep(file_io; name="Step-1", nlgeom="YES", type="Static", parameters=[0.1, 1.0, 1e-5, 0.1])
    write(file_io, "* Step, name=$name, nlgeom=$nlgeom \n")
    write(file_io, "* $type \n")
    write(file_io, join([@sprintf("%.16e", x) for x ∈ parameters], ", ") *" \n")
end

function addBoundary(file_io; setName="Nodeset-1", vals=[1, 1], parameters=Vector{Float64}())
    write(file_io, "* Boundary \n")
    s = "$setName, " * join([@sprintf("%i", x) for x ∈ vals], ", ")
    if !isempty(parameters)
        s *= ", " * join([@sprintf("%.16e", x) for x ∈ parameters], ", ")
    end
    write(file_io, s * " \n")
end

function endStep(file_io)
    write(file_io, "* End Step \n")
end

function addFree(file_io, S)
    for s in S
        write(file_io, s*"\n")
    end
end

function run_abaqus(run_filename; ABAQUS_EXEC="abaqus", job="job-1")   
    @static if Sys.islinux()
        runCommand = `nice "$ABAQUS_EXEC" inp="$run_filename"  job=$job interactive ask_delete=OFF`    
    elseif Sys.isapple()
        runCommand = `nice "$ABAQUS_EXEC" inp="$run_filename"  job=$job interactive ask_delete=OFF`
    else
        runCommand = `"$ABAQUS_EXEC" inp="$run_filename"  job=$job interactive ask_delete=OFF`
    end
    # println(runCommand)
    run(runCommand)
end