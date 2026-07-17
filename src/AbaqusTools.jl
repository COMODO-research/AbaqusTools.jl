module AbaqusTools

using FileIO
using Printf 

include("functions.jl")

export abaqustoolsdir
export addHeader, addPart, addNodes, addElements, addIndexSet, addMaterial
export addSolidSection, startAssembly, endAssembly, addInstance, endPart, equation
export startStep, endStep, addBoundary, addFree, run_abaqus, constraint

end # module AbaqusTools
