
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
    write(file_io, ", \n") 

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
# when adding *elset, there should NOT be instance
# for example, *Elset, elset=ElementSet-1
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
    if m == 1 
        s = @sprintf("%i", ind[1])* ", "
        write(file_io, s*"\n")
    else
        for i = 1:nRow:m
            j = i + nRow - 1 
            if j>m
                j = m 
            end
            s = join([@sprintf("%i", x+indexOffset) for x ∈ ind[i:j]],", ")
            write(file_io, s*"\n")
        end
    end
end

function addMaterial(file_io; name="Material_1", category="Elastic", parameters=[1.0, 0.4], kwargs...)
    
    # Add Material and name line 
    write(file_io, "* Material, name=$name \n")

    # Parse and add category, type, etc.  
    s = "*" * category
    if haskey(kwargs, :user)
        v = kwargs[:user]        
        if isempty(v)
            s *= ", user"    
        else
            s *= ", user="*v    
        end
    end
       
    if haskey(kwargs, :type)
        v = kwargs[:type]        
        if !isempty(v)
            s *= ", type="*v    
        end
    end

    if haskey(kwargs, :properties)
        v = kwargs[:properties]        
        if !isempty(v)
            s *= ", properties=$v"    
        end
    end
    write(file_io, s * " \n")    

    # Add parameter line 
    write(file_io, join([@sprintf("%.16e", x) for x ∈ parameters], ", ") *" \n")
end

function equation(file_io; n=3, node_sets=["set1", "set2"], vals=[[1,1], [1, -1]])
    write(file_io, "* Equation \n")
    write(file_io, "$n \n")    
    for (i, nodeSetNow) in enumerate(node_sets)        
        write(file_io, nodeSetNow *", "* join([@sprintf("%i", x) for x ∈ vals[i]], ", ") *" \n")    
    end    
end

function constraint(file_io; constraintname="")
    write(file_io, "** Constraints" * ": " * constraintname * " \n")    
end

function startStep(file_io; name="Step-1", nlgeom="YES", type="Static", parameters=[0.1, 1.0, 1e-5, 0.1], kwargs...)
    s = "* Step, name=$name, nlgeom=$nlgeom"
    if haskey(kwargs, :inc)
        v = kwargs[:inc]        
        if !isempty(v)
            s *= ", inc=$v"
        end
    end

    if haskey(kwargs, :perturbation)
        v = kwargs[:perturbation]        
        if isempty(v)
            s *= ", perturbation"    
        else
            s *= ", perturbation="*v    
        end
    end

    write(file_io, s * " \n")    

    write(file_io, "* $type \n")
    s=""
    for (i,p) in enumerate(parameters)
        if !isnothing(p)
            if i==1
                s *= @sprintf("%i", p)
            else
                s *= ", " * @sprintf("%i", p)
            end
        else
            s *= ", "
        end
    end
    write(file_io, s * " \n")
    # write(file_io, join([@sprintf("%.16e", x) for x ∈ parameters], ", ") *" \n")
end

function addBoundary(file_io; setName="Nodeset-1", skipHeading=false, kwargs...)    
    if skipHeading == false
        s = "* Boundary"
        # write(file_io, "* Boundary \n")    
        if haskey(kwargs, :op)
            v = kwargs[:op]
            if !isempty(v)
                s *= ", op=" * v
            end
        end

        if haskey(kwargs, :load_case)
            v = kwargs[:load_case]
            if !isempty(v)
                s *= ", load case=$v"
            end
        end
        write(file_io, s * " \n")
    end

    s="$setName"    
    if haskey(kwargs, :flag)
        v = kwargs[:flag]
        if !isempty(v)
            s *= ", " * v
        end
    end

    if haskey(kwargs, :vals)
        v = kwargs[:vals]
        if !isempty(v)
            if length(v) == 3
                s *= ", " * join([@sprintf("%i", x) for x ∈ v[1:end-1]], ", ") * ", " * @sprintf("%.16e", v[end])
            else length(v) == 2
                s *= ", " * join([@sprintf("%i", x) for x ∈ v], ", ")
            end
        end
    end

    if haskey(kwargs, :parameters)
        v = kwargs[:parameters]
        if !isempty(v)
            s *= ", " * join([@sprintf("%.16e", x) for x ∈ v], ", ")
        end
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