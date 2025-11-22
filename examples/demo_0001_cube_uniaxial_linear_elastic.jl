using AbaqusTools

using Comodo
using Comodo.GLMakie
using Comodo.GeometryBasics
using Comodo.Rotations
using Comodo.Statistics
using Comodo.LinearAlgebra

#=
This demo shows the creation of an INP file for Abaqus based analysis
a hexahedral mesh for a 3D cube is created and the cube is subjected
to uniaxial compression.  
=#

GLMakie.closeall()

# Material parameter set
E_youngs = 1.0
v_poisson = 0.4

prescribedDisplacement_Z = -3.0

pointSpacing = 3.0
boxDim = [10.0, 10.0, 10.0] # Dimensionsions for the box in each direction
boxEl = ceil.(Int,boxDim./pointSpacing) # Number of elements to use in each direction 

E, V, F, Fb, Cb = hexbox(boxDim,boxEl)

bcSupportList_X = elements2indices(Fb[Cb.==1])
bcSupportList_Y = elements2indices(Fb[Cb.==4])
bcSupportList_Z = elements2indices(Fb[Cb.==5])
bcPrescribeList = elements2indices(Fb[Cb.==2])

# Visualisation
cmap = Makie.Categorical(:Spectral) 

Fbs,Vbs = separate_vertices(Fb,V)
Cbs_V = simplex2vertexdata(Fbs,Cb)
M = GeometryBasics.Mesh(Vbs,Fbs)

fig = Figure(size=(1600,800))

ax1 = AxisGeom(fig[1, 1], title = "Boundary faces with boundary markers for the hexahedral mesh")
hp2 = meshplot!(ax1, Fbs, Vbs; strokewidth=3, color=Cbs_V, colormap=cmap)
Colorbar(fig[1, 2], hp2)

ax2 = AxisGeom(fig[1, 3], title = "Boundary faces with boundary markers for the hexahedral mesh")
hp3 = meshplot!(ax2, Fbs, Vbs; strokewidth=1.0, color=(:white, 0.5), transparency=true)
scatter!(ax2, V[bcSupportList_X], color=:red, markersize=25)
scatter!(ax2, V[bcSupportList_Y], color=:green, markersize=25)
scatter!(ax2, V[bcSupportList_Z], color=:blue, markersize=25)
scatter!(ax2, V[bcPrescribeList], color=:black, markersize=25)

screen = display(GLMakie.Screen(), fig)

##############

# --------------------------------
jobName = "Demo uniaxial"
partName_1 = "Cube"
elementType_1 = "C3D8"
elementIds_1 = 1:length(E)
nodeIds_1  = 1:length(V)

nodeSetName_1 = "NodeSet-1"
elementSetName_1 = "ElementSet-1"
materialName_1 = "Material-1"
instanceName_1  = "Cube-assembly-1"
nodeSetName_1 ="all"
nodeSetName_bcSupportList_X = "bcSupportList_X"
nodeSetName_bcSupportList_Y = "bcSupportList_Y"
nodeSetName_bcSupportList_Z = "bcSupportList_Z"
nodeSetName_bcPrescribeList = "bcPrescribeList"

tempDir = joinpath(abaqustoolsdir(),"assets", "temp")
if !isdir(tempDir)
    mkdir(tempDir)
end
inp_filename = joinpath(tempDir, "cube_uniaxial.inp")

file_io = open(inp_filename, "w")
addHeader(file_io, jobName)
addPart(file_io, partName_1; firstTime = true)
    addNodes(file_io, V)
    addElements(file_io, E, elementType_1; indexOffset=0)
    addIndexSet(file_io, elementSetName_1, elementIds_1; type=:elements)
    addSolidSection(file_io, elementSetName_1, materialName_1)
endPart(file_io)

startAssembly(file_io; name="Assembly-1")
    addInstance(file_io; name=instanceName_1, part=partName_1)
    addIndexSet(file_io, nodeSetName_1, nodeIds_1; instance=instanceName_1, type=:nodes, indexOffset=0)
    addIndexSet(file_io, nodeSetName_bcSupportList_X, bcSupportList_X; instance=instanceName_1, type=:nodes, indexOffset=0)
    addIndexSet(file_io, nodeSetName_bcSupportList_Y, bcSupportList_Y; instance=instanceName_1, type=:nodes, indexOffset=0)
    addIndexSet(file_io, nodeSetName_bcSupportList_Z, bcSupportList_Z; instance=instanceName_1, type=:nodes, indexOffset=0)
    addIndexSet(file_io, nodeSetName_bcPrescribeList, bcPrescribeList; instance=instanceName_1, type=:nodes, indexOffset=0)
endAssembly(file_io)

addMaterial(file_io; name=materialName_1, type="Elastic", parameters=[E_youngs, v_poisson])

startStep(file_io; name="Step-1", nlgeom="YES", type="Static", parameters=[0.1, 1.0, 1e-5, 0.1])
    addBoundary(file_io; setName=nodeSetName_bcSupportList_X, vals=[1, 1])
    addBoundary(file_io; setName=nodeSetName_bcSupportList_Y, vals=[2, 2])
    addBoundary(file_io; setName=nodeSetName_bcSupportList_Z, vals=[3, 3])
    addBoundary(file_io; setName=nodeSetName_bcPrescribeList, vals=[3, 3], parameters=[prescribedDisplacement_Z])

    S = ["* Restart, write, frequency=0", 
         "* Output, field, variable=PRESELECT",
         "* Output, history, variable=PRESELECT", 
         "* Node print, nset=all, frequency=1", 
         "COORD", 
         "* El print", 
         "S", 
         "* El print", 
         "E "]
    addFree(file_io, S)
endStep(file_io)
close(file_io)

# run_abaqus(inp_filename; ABAQUS_EXEC="abaqus", job="job-1")  