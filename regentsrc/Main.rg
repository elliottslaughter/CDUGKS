import "regent"

-- Helper modules to handle command line arguments
local Config = require("config")
Config.methods.initialize_from_command.replicable = true

-- This is simlifies the coloring syntax a bit
local coloring   = require("coloring_util")

-- Some C APIs
local c     = regentlib.c
local sqrt  = regentlib.sqrt(double)
local cmath = terralib.includec("math.h")
local PI = cmath.M_PI
local isnan = regentlib.isnan(double)

-- Replicable
cmath.fmax.replicable = true

-- Field space for Simulation Parameters
fspace params{

  -- Simulation Parameters
  N  : int32[3],
  NV : int32[3],
  Nc : int64,
  Nv : int64,
  R : double,
  K : double,
  g : double,
  w : double,
  Cv : double,
  ur : double,
  Tr : double,
  Pr : double,
  effD : int32,
  BCs : int32[6],
  Vmin : double[3],
  Vmax : double[3],
  Tf : double,
  dtdump: double,
  thermal_bath : bool,
  thermal_T : double

}

-- Field space for reduced distribution functions and their gradients
fspace grid{

  -- Reduced Distribution Functions  
  g : double,
  b : double,
}

-- Field space for rectangular mesh
fspace mesh{

  -- Cell Position
  x    : double,
  y    : double,
  z    : double,
  
  -- Cell Size
  dx   : double,
  dy   : double,
  dz   : double,

}

-- Field space for conserved variables at cell center and interfaces
fspace W{

    -- Conserved Variables
    rho  : double,
    rhov : double[3],
    rhoE : double

}

-- Field space for velocity mesh
fspace vmesh
{

  -- Velocity and Weight
  v : double,
  w : double

}


-- This task updates r_params given a value of testProblem
task TestProblem(r_params : region(ispace(int1d), params), testProblem : int32)
where
  reads writes(r_params)
do
  for e in r_params do

    -- Some Default Settings
    r_params[e].thermal_bath = false
    r_params[e].thermal_T = 0

    -- Sod Shock
    if testProblem == 1 then

      -- Dimensionality
      r_params[e].effD = 1

      var num : int32 = 128
      -- Spatial Resolution
      r_params[e].N[0]  = num
      r_params[e].N[1]  = 1
      r_params[e].N[2]  = 1
                
      -- Velocity Resolution
      r_params[e].NV[0] = num+1
      r_params[e].NV[1] = 1
      r_params[e].NV[2] = 1
                
      -- Velocity Grid (Min and Max)
      r_params[e].Vmin[0] = -8
      r_params[e].Vmin[1] = 0
      r_params[e].Vmin[2] = 0
                
      r_params[e].Vmax[0] = 8
      r_params[e].Vmax[1] = 0
      r_params[e].Vmax[2] = 0
                
      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]

      -- Boundary Conditions
      r_params[e].BCs[0] = 2 
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0
      r_params[e].BCs[3] = 2 
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0


      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-6                                  -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 1.0                                   -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 0.15                                   -- Stop Time
      r_params[e].dtdump = r_params[e].Tf/200                 -- Time Between Dumps
 
    -- Kelvin-Helmholtz
    elseif testProblem == 2 then 

      -- Dimensionality
      r_params[e].effD = 2

      var num : int32 = 100
      -- Spatial Resolution
      r_params[e].N[0]  = num
      r_params[e].N[1]  = num
      r_params[e].N[2]  = 1
                
      -- Velocity Resolution
      r_params[e].NV[0] = num+1
      r_params[e].NV[1] = num+1
      r_params[e].NV[2] = 1
             
      -- Velocity Grid (Min and Max)   
      r_params[e].Vmin[0] = -10
      r_params[e].Vmin[1] = -10
      r_params[e].Vmin[2] = 0
                
      r_params[e].Vmax[0] = 10
      r_params[e].Vmax[1] = 10
      r_params[e].Vmax[2] = 0
                
      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]


      -- Boundary Conditions
      r_params[e].BCs[0] = 0
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0
      r_params[e].BCs[3] = 0
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0

      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-4                                  -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 2.0/3.0                               -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 1.6                                    -- Stop Time
      r_params[e].dtdump = r_params[e].Tf/400                 -- Time Between Dumps

    -- Uniform Density Shear
    elseif testProblem == 3 then 

      -- Dimensionality
      r_params[e].effD = 2

      var num : int32 = 64
      -- Spatial Resolution
      r_params[e].N[0]  = 1
      r_params[e].N[1]  = num
      r_params[e].N[2]  = 1
                
      -- Velocity Resolution
      r_params[e].NV[0] = num+1
      r_params[e].NV[1] = num+1
      r_params[e].NV[2] = 1

      -- Velocity Grid (Min and Max)
      r_params[e].Vmin[0] = -10
      r_params[e].Vmin[1] = -10
      r_params[e].Vmin[2] = 0
                
      r_params[e].Vmax[0] = 10
      r_params[e].Vmax[1] = 10
      r_params[e].Vmax[2] = 0
                
      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]


      -- Boundary Conditions
      r_params[e].BCs[0] = 0
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0
      r_params[e].BCs[3] = 0
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0


      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.0                                   -- Viscosity Exponent
      r_params[e].ur  = 1e2                                   -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 1.0                                   -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 4.0                                    -- Stop Time
      r_params[e].dtdump = r_params[e].Tf/400                 -- Time Between Dumps

    -- Ramped Kelvin-Helmholtz
    elseif testProblem == 4 then 

      -- Dimensionality
      r_params[e].effD = 2

      var num : int32 = 128
      -- Spatial Resolution
      r_params[e].N[0]  = num
      r_params[e].N[1]  = num
      r_params[e].N[2]  = 1
                
      -- Velocity Resolution
      r_params[e].NV[0] = 128+1
      r_params[e].NV[1] = 128+1
      r_params[e].NV[2] = 1
                
      -- Velocity Grid (Min and Max)
      r_params[e].Vmin[0] = -10
      r_params[e].Vmin[1] = -10
      r_params[e].Vmin[2] = 0
                
      r_params[e].Vmax[0] = 10
      r_params[e].Vmax[1] = 10
      r_params[e].Vmax[2] = 0
                
      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]


      -- Boundary Conditions
      r_params[e].BCs[0] = 0
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0
      r_params[e].BCs[3] = 0
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0


      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-4                                  -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 2.0/3.0                               -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 2.0                                    -- Stop Time
      r_params[e].dtdump = r_params[e].Tf/400                 -- Time Between Dumps

    -- Nonuniform Density Shear
    -- Adds a sinusoidal temperature/density profile which preserves isobaricity
    elseif testProblem == 5 then 

      -- Dimensionality
      r_params[e].effD = 2

      var num : int32 = 64
      -- Spatial Resolution
      r_params[e].N[0]  = 2
      r_params[e].N[1]  = num
      r_params[e].N[2]  = 1
                
      -- Velocity Resolution
      r_params[e].NV[0] = num+1
      r_params[e].NV[1] = num+1
      r_params[e].NV[2] = 1

      -- Velocity Grid (Min and Max)       
      r_params[e].Vmin[0] = -10
      r_params[e].Vmin[1] = -10
      r_params[e].Vmin[2] = 0
              
      r_params[e].Vmax[0] = 10
      r_params[e].Vmax[1] = 10
      r_params[e].Vmax[2] = 0
                
      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]


      -- Boundary Conditions
      r_params[e].BCs[0] = 0
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0
      r_params[e].BCs[3] = 0
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0


      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-4                                  -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 2.0/3.0                               -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 4.0                                    -- Stop Time
      r_params[e].dtdump = r_params[e].Tf/400                 -- Time Between Dumps

    -- Maxwellian Relaxation
    elseif testProblem == 6 then 

      -- Dimensionality
      r_params[e].effD = 1

      var num : int32 = 128
      -- Spatial Resolution
      r_params[e].N[0]  = num
      r_params[e].N[1]  = 1
      r_params[e].N[2]  = 1
                
      -- Velocity Resolution
      r_params[e].NV[0] = num+1
      r_params[e].NV[1] = 1
      r_params[e].NV[2] = 1
                
      -- Velocity Grid (Min and Max)
      r_params[e].Vmin[0] = -10
      r_params[e].Vmin[1] = 0
      r_params[e].Vmin[2] = 0
                
      r_params[e].Vmax[0] = 10
      r_params[e].Vmax[1] = 0
      r_params[e].Vmax[2] = 0
                
      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]


      -- Boundary Conditions
      r_params[e].BCs[0] = 1
      r_params[e].BCs[1] = 1
      r_params[e].BCs[2] = 1
      r_params[e].BCs[3] = 1
      r_params[e].BCs[4] = 1
      r_params[e].BCs[5] = 1


      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 0.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-4                                  -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 2.0/3.0                               -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 2.0                                    -- Stop Time
      r_params[e].dtdump = r_params[e].Tf/400                 -- Time Between Dumps
    
    -- Blob Test
    elseif testProblem == 7 then 

      -- Dimensionality
      r_params[e].effD = 2

      var num : int32 = 100
      -- Spatial Resolution
      r_params[e].N[0]  = num
      r_params[e].N[1]  = num
      r_params[e].N[2]  = 1
                
      -- Velocity Resolution
      r_params[e].NV[0] = num+1
      r_params[e].NV[1] = num+1
      r_params[e].NV[2] = 1
                
      -- Velocity Grid (Min and Max)
      r_params[e].Vmin[0] = -20
      r_params[e].Vmin[1] = -20
      r_params[e].Vmin[2] = 0
                
      r_params[e].Vmax[0] = 20
      r_params[e].Vmax[1] = 20
      r_params[e].Vmax[2] = 0
                
      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]


      -- Boundary Conditions
      r_params[e].BCs[0] = 0
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0
      r_params[e].BCs[3] = 0
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0


      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-6                                  -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 2.0/3.0                               -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 2.0                    -- Stop Time
      r_params[e].dtdump = r_params[e].Tf/400            -- Time Between Dumps
      
    -- Thermoacoustic
    elseif testProblem == 8 then

      -- Dimensionality
      r_params[e].effD = 1

      var num : int32 = 512
      -- Spatial Resolution
      r_params[e].N[0]  = num
      r_params[e].N[1]  = 1
      r_params[e].N[2]  = 1

      -- Velocity Resolution
      r_params[e].NV[0] = num+1
      r_params[e].NV[1] = 1
      r_params[e].NV[2] = 1

      -- Velocity Grid (Min and Max)
      r_params[e].Vmin[0] = -10
      r_params[e].Vmin[1] = 0
      r_params[e].Vmin[2] = 0

      r_params[e].Vmax[0] = 10
      r_params[e].Vmax[1] = 0
      r_params[e].Vmax[2] = 0

      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]


      -- Boundary Conditions
      r_params[e].BCs[0] = 0
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0

      -- Boundary Conditions
      r_params[e].BCs[3] = 0
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0


      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-3                                  -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 2.0/3.0                               -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 4.0                                    -- Stop Time
      r_params[e].dtdump = r_params[e].Tf/400                 -- Time Between Dumps
        
    -- Gresho Vortex (also known as Triangular Vortex)
    -- Refer to Fabian Miczek 2013
    elseif testProblem == 9 then

      -- Dimensionality
      r_params[e].effD = 2

      var num : int32 = 100
      -- Spatial Resolution
      r_params[e].N[0]  = num
      r_params[e].N[1]  = num
      r_params[e].N[2]  = 1

      -- Velocity Resolution
      r_params[e].NV[0] = num+1
      r_params[e].NV[1] = num+1
      r_params[e].NV[2] = 1

      -- Velocity Grid (Min and Max)
      var dv : double = 9/(2*PI/5) -- Number of passes through box divided by max ring speed
      r_params[e].Vmin[0] = -10 + dv
      r_params[e].Vmin[1] = -10 + dv
      r_params[e].Vmin[2] = 0

      r_params[e].Vmax[0] = 10 + dv
      r_params[e].Vmax[1] = 10 + dv
      r_params[e].Vmax[2] = 0

      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]


      -- Boundary Conditions
      r_params[e].BCs[0] = 0
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0

      -- Boundary Conditions
      r_params[e].BCs[3] = 0
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0


      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-6                                  -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 2.0/3.0                               -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 2.0*PI/5.0                             -- Stop Time
      r_params[e].dtdump = r_params[e].Tf/200                 -- Time Between Dumps

    -- Sine Wave Collapse
    -- Sinusoidal Velocity Profile
    elseif testProblem == 10 then

      -- Dimensionality
      r_params[e].effD = 1

      -- Spatial Resolution
      r_params[e].N[0]  = 128
      r_params[e].N[1]  = 1
      r_params[e].N[2]  = 1

      -- Velocity Resolution
      r_params[e].NV[0] = 16385
      r_params[e].NV[1] = 1
      r_params[e].NV[2] = 1

      -- Velocity Grid (Min and Max)
      r_params[e].Vmin[0] = -6
      r_params[e].Vmin[1] = 0
      r_params[e].Vmin[2] = 0

      r_params[e].Vmax[0] = 6
      r_params[e].Vmax[1] = 0
      r_params[e].Vmax[2] = 0

      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]

      -- Boundary Conditions
      r_params[e].BCs[0] = 0
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0

      r_params[e].BCs[3] = 0
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0

      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-2                                   -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 2.0/3.0                               -- Prandtl Number

      -- Simulation Parameters
      r_params[e].Tf = 1.0                            	-- Stop Time
      r_params[e].dtdump = r_params[e].Tf/200          	-- Time Between Dumps

    -- Isothermal Shock
    elseif testProblem == 11 then

      -- Dimensionality
      r_params[e].effD = 1

      -- Spatial Resolution
      r_params[e].N[0]  = 128
      r_params[e].N[1]  = 1
      r_params[e].N[2]  = 1

      -- Velocity Resolution
      r_params[e].NV[0] = 128+1
      r_params[e].NV[1] = 1
      r_params[e].NV[2] = 1

      -- Velocity Grid (Min and Max)
      r_params[e].Vmin[0] = -6
      r_params[e].Vmin[1] = 0
      r_params[e].Vmin[2] = 0

      r_params[e].Vmax[0] = 8
      r_params[e].Vmax[1] = 0
      r_params[e].Vmax[2] = 0

      -- Number of Cells
      r_params[e].Nc = r_params[e].N[0]*r_params[e].N[1]*r_params[e].N[2]
      r_params[e].Nv = r_params[e].NV[0]*r_params[e].NV[1]*r_params[e].NV[2]

      -- Boundary Conditions
      r_params[e].BCs[0] = 2
      r_params[e].BCs[1] = 0
      r_params[e].BCs[2] = 0

      r_params[e].BCs[3] = 2
      r_params[e].BCs[4] = 0
      r_params[e].BCs[5] = 0

      -- Physical Parameters
      r_params[e].R   = 0.5                                   -- Gas Constant
      r_params[e].K   = 2.0                                   -- Internal DOF
      r_params[e].Cv  = (3+r_params[e].K)*r_params[e].R/2.0   -- Specific Heat
      r_params[e].g   = (r_params[e].K+5)/(r_params[e].K+3.0) -- Adiabatic Index
      r_params[e].w   = 0.5                                   -- Viscosity Exponent
      r_params[e].ur  = 1e-4                                  -- Reference Visc
      r_params[e].Tr  = 1.0                                   -- Reference Temp
      r_params[e].Pr  = 2./3                                   -- Prandtl Number

      -- Thermal Bath
      r_params[e].thermal_bath = true
      r_params[e].thermal_T = 0.8

      -- Simulation Parameters
      r_params[e].Tf = 0.4                             	-- Stop Time
      r_params[e].dtdump = r_params[e].Tf/200          	-- Time Between Dumps

    end
  end
end

task NewtonCotes(vxmesh : region(ispace(int1d), vmesh), vymesh : region(ispace(int1d), vmesh),
                 vzmesh : region(ispace(int1d), vmesh),
                 NV : int32[3], Vmin : double[3], Vmax : double[3])
where
  reads writes(vxmesh, vymesh, vzmesh)
do
  -- Newton-Cotes Weights
  var k : int32
  var n : int32
  var b : double
  var a : double
  var dh : double

  regentlib.assert((NV[0]%4 == 1 and NV[1]%4 == 1 and NV[2]%4 == 1), "4th Order Newton-Cotes weights require 4n+1 grid cells\n")


  -- First Dimension
  a = Vmin[0]
  b = Vmax[0]
  n = (NV[0])/4  
  dh = (b-a)/(NV[0]-1)*4 

  for kx = 0, NV[0] do
    vxmesh[kx].v = Vmin[0] + kx*dh/4
  end 

  for kx = 0, n do

    vxmesh[4*kx].w   = 14.0
    vxmesh[4*kx+1].w = 32.0
    vxmesh[4*kx+2].w = 12.0
    vxmesh[4*kx+3].w = 32.0

  end

  vxmesh[0].w = 7.0
  vxmesh[NV[0]-1].w = 7.0



  for kx = 0, NV[0] do
    vxmesh[kx].w = vxmesh[kx].w*dh/90. -- TODO Trying Lower Order Integration old factor was /90.}
  end

  -- Check Weights
  --for kx = 0, NV[0] do
  --  c.printf("Main.hh vxmesh[%d].v = %f\n", kx, vxmesh[kx].v)
  --end
  --for kx = 0, NV[0] do
  --  c.printf("Main.hh vxmesh[%d].w = %f\n", kx, vxmesh[kx].w)
  --end
  

  -- Second Dimension
  if NV[1] >= 5 then
    a = Vmin[1]
    b = Vmax[1]
    n = (NV[1])/4  
    dh = (b-a)/(NV[1]-1)*4 

    for ky = 0, NV[1] do
      vymesh[ky].v = Vmin[1] + ky*dh/4
    end 

    for ky = 0, n do

      vymesh[4*ky].w   = 14.0
      vymesh[4*ky+1].w = 32.0
      vymesh[4*ky+2].w = 12.0
      vymesh[4*ky+3].w = 32.0

    end

    vymesh[0].w = 7.0
    vymesh[NV[1]-1].w = 7.0

    for ky = 0, NV[1] do
      vymesh[ky].w = vymesh[ky].w*dh/90. -- TODO Trying Lower Order Integration old factor was /90.}
    end 

  elseif NV[1] == 1 then

    -- i.e. if 1-Dimensional Problem
    vymesh[0].v = 0
    vymesh[0].w = 1

  else
    c.printf("Error with Newton Cotes (number of vy points)\n")
  end 

  -- Check Weights
  --for ky = 0, NV[1] do
  --  c.printf("Main.hh vymesh[%d].v = %f\n", ky, vymesh[ky].v)
  --end
  --for ky = 0, NV[1] do
  --  c.printf("Main.hh vymesh[%d].w = %f\n", ky, vymesh[ky].w)
  --end

  -- Third Dimension
  if NV[2] >= 5 then
    a = Vmin[2]
    b = Vmax[2]
    n = (NV[2])/4
    dh = (b-a)/(NV[2]-1)*4 

    for kz = 0, NV[2] do
      vzmesh[kz].v = Vmin[2] + k*dh/4
    end 

    for kz = 0, n do
      vzmesh[4*kz].w   = 14.0
      vzmesh[4*kz+1].w = 32.0
      vzmesh[4*kz+2].w = 12.0
      vzmesh[4*kz+3].w = 32.0

    end

    vzmesh[0].w = 7.0
    vzmesh[NV[2]-1].w = 7.0


    for kz = 0, NV[2] do
      vzmesh[kz].w = vzmesh[kz].w*dh/90. -- TODO Trying Lower Order Integration old factor was /90.}
    end
  elseif NV[2] == 1 then

    -- i.e. if 2-Dimensional Problem
    vzmesh[0].v = 0
    vzmesh[0].w = 1

  else
    c.printf("Error with Newton Cotes (number of vz points)\n")
  end 

  -- Check Weights
  --for kz = 0, NV[2] do
  --  c.printf("Main.hh vzmesh[%d].v = %f\n", kz, vzmesh[kz].v)
  --end
  --for kz = 0, NV[2] do
  --  c.printf("Main.hh vzmesh[%d].w = %f\n", kz, vzmesh[kz].w)
  --end

end

task InitializeMesh(r_mesh : region(ispace(int8d), mesh), N : int32[3], MeshType : int32)
where
  reads writes(r_mesh)
do
  -- User-Specified Mesh
  if MeshType == 0 then
    -- TODO
  
  -- Rectangular Mesh
  elseif MeshType == 1 then
    
    c.printf("Initializing Uniform Grid\n")
    
    for e in r_mesh do

      var Nx : int32 = N[0]
      var Ny : int32 = N[1]
      var Nz : int32 = N[2]

      var dX : double = 1.0/Nx
      var dY : double = 1.0/Ny
      var dZ : double = 1.0/Nz

      r_mesh[e].x = dX*(e.x + 1.0/2.0)
      r_mesh[e].y = dY*(e.y + 1.0/2.0)
      r_mesh[e].z = dZ*(e.z + 1.0/2.0)

      r_mesh[e].dx = dX
      r_mesh[e].dy = dY
      r_mesh[e].dz = dZ

    end
  -- Nested Rectangular 
  elseif MeshType == 2 then 
    -- TODO  
  end
end

task InitializeW(r_W : region(ispace(int8d), W), 
                 r_mesh : region(ispace(int8d), mesh),
                 N : int32[3], NV : int32[3], testProblem : int32, R : double, Cv : double, g : double)
where
  reads writes(r_W),
  reads(r_mesh)
do

  -- Sod Shock Tube
  if testProblem == 1 then
    
    -- Left and Right Density
    var pL : double = 1.0
    var pR : double = 1.0/8.0

    -- Left and Right Pressure
    var PL : double = 1.0
    var PR : double = 1.0/10.0

    for e in r_W do

      -- Left Side
      if r_mesh[e].x <= 0.5 then
        r_W[e].rho = pL
        r_W[e].rhov[0] = 0
        r_W[e].rhov[1] = 0
        r_W[e].rhov[2] = 0
        r_W[e].rhoE = Cv*PL/R + 0.5*r_W[e].rhov[0]*r_W[e].rhov[0]/r_W[e].rho

      -- Right Side
      else
        r_W[e].rho = pR
        r_W[e].rhov[0] = 0
        r_W[e].rhov[1] = 0
        r_W[e].rhov[2] = 0
        r_W[e].rhoE = Cv*PR/R + 0.5*r_W[e].rhov[0]*r_W[e].rhov[0]/r_W[e].rho
      end

      --c.printf("W[%d] = {%f, %f, %f}\n", e.x, r_W[e].rho, r_W[e].rhov[1], r_W[e].rhoE)
    end

  -- Kelvin Helmholtz Problem
  -- Sharp Interface (No Ramp)
  elseif testProblem == 2 then
    
    -- Densities
    var rho1 : double = 2.0
    var rho2 : double = 1.0
    
    -- Pressures 
    var P1 : double = 2.0
    var P2 : double = 2.0
    
    var vrel : double = 2.0    -- Relative Velocity
    var amp : double = 0.04    -- Perturbation Amplitude

    for e in r_W do

      -- Right-Moving Denser Fluid
      if (0.25 <= r_mesh[e].y) and (r_mesh[e].y <= 0.75) then
        r_W[e].rho = rho1
        r_W[e].rhov[0] = r_W[e].rho*(vrel/2.0)
        r_W[e].rhov[1] = amp*cmath.sin(2*PI*r_mesh[e].x)*r_W[e].rho
        r_W[e].rhov[2] = 0
        r_W[e].rhoE = Cv*P1/R + 0.5*(r_W[e].rhov[0]*r_W[e].rhov[0] + r_W[e].rhov[1]*r_W[e].rhov[1])/r_W[e].rho
      
      -- Left-Moving Lighter Fluid
      else
        r_W[e].rho = rho2
        r_W[e].rhov[0] = r_W[e].rho*(-vrel/2.0)
        r_W[e].rhov[1] = amp*cmath.sin(2*PI*r_mesh[e].x)*r_W[e].rho
        r_W[e].rhov[2] = 0
        r_W[e].rhoE = Cv*P2/R + 0.5*(r_W[e].rhov[0]*r_W[e].rhov[0] + r_W[e].rhov[1]*r_W[e].rhov[1])/r_W[e].rho
        
      end      

      --c.printf("W[{%d, %d}] = {%f, {%f, %f}, %f}\n", e.x, e.y, r_W[e].rho, r_W[e].rhov[0], r_W[e].rhov[1], r_W[e].rhoE)
    end

  -- Uniform Shear Problem
  elseif testProblem == 3 then
    
    var rho : double = 1.0    -- Denisty
    var P : double = rho/1.4  -- Pressure gamma = 1.4 
    var v : double = 0.0      -- Bulk Velocity
    var amp : double = 0.5    -- Sinsoidal Amplitude

    for e in r_W do
      r_W[e].rho = rho
      r_W[e].rhov[0] = r_W[e].rho*(v + amp*cmath.cos(2*PI*r_mesh[e].y))
      r_W[e].rhov[1] = 0
      r_W[e].rhov[2] = 0
      r_W[e].rhoE = Cv*P/R + 0.5*(r_W[e].rhov[0]*r_W[e].rhov[0] + r_W[e].rhov[1]*r_W[e].rhov[1])/r_W[e].rho
        
      --c.printf("W[{%d, %d}] = {%f, {%f, %f}, %f}\n", e.x, e.y, r_W[e].rho, r_W[e].rhov[0], r_W[e].rhov[1], r_W[e].rhoE)
    end

  -- Ramped Kelvin Helmholtz Problem
  -- Refer to Brant E. Robertson et. al 2009
  elseif testProblem == 4 then
    
    -- Densities
    var rho1 : double = 2.0
    var rho2 : double = 1.0
    
    var P : double = 2.0      -- Pressure 
    var vrel : double = 2.0   -- Velocity Difference
    var amp : double = 0.04   -- Perturbation Amplitude
    var vb : double = 0.0     -- Bulk Velocity

    var delta : double = 0.05

    for e in r_W do
      var Ramp : double = 1/(1 + cmath.exp(-2*(r_mesh[e].y - 0.25)/delta)) * 1/(1 + cmath.exp(-2*(0.75 - r_mesh[e].y)/delta))
      var vx : double = vb - vrel/2 + Ramp*(vrel)
      var rho : double = rho2 + Ramp*(rho1 - rho2) 
      var vy : double = amp*cmath.sin(2*PI*r_mesh[e].x)

      r_W[e].rho = rho
      r_W[e].rhov[0] = rho*vx
      r_W[e].rhov[1] = rho*vy
      r_W[e].rhov[2] = 0
      r_W[e].rhoE = Cv*P/R + 0.5*(r_W[e].rhov[0]*r_W[e].rhov[0] + r_W[e].rhov[1]*r_W[e].rhov[1])/r_W[e].rho

      c.printf("W[{%d, %d}] = {%f, {%f, %f}, %f}\n", e.x, e.y, r_W[e].rho, r_W[e].rhov[0], r_W[e].rhov[1], r_W[e].rhoE)
    end

  -- Nonuniform Shear Problem
  -- Adds a sinusoidal temperature/density profile which preserves isobaricity
  elseif testProblem == 5 then
    
    var P : double = 2.0     -- Pressure   
    var v : double = 0.0     -- Bulk Velocity
    var amp : double = 0.25  -- Sinsoidal Amplitude 

    for e in r_W do
      
      var Temp : double = 1 + amp*cmath.cos(2*PI*r_mesh[e].y) 

      r_W[e].rho = P/Temp -- (Ideal Gas: P \propto rho T)
      r_W[e].rhov[0] = r_W[e].rho*(v + amp*cmath.cos(2*PI*r_mesh[e].y))
      r_W[e].rhov[1] = 0
      r_W[e].rhov[2] = 0
      r_W[e].rhoE = Cv*P/R + 0.5*(r_W[e].rhov[0]*r_W[e].rhov[0] + r_W[e].rhov[1]*r_W[e].rhov[1])/r_W[e].rho
        
      --c.printf("W[{%d, %d}] = {%f, {%f, %f}, %f}\n", e.x, e.y, r_W[e].rho, r_W[e].rhov[0], r_W[e].rhov[1], r_W[e].rhoE)
    end

  -- Maxwellian Relaxation 
  -- This one was a (sort of) failed experiment
  -- Sine Wave Collapse does a much better job illustrating the effects that this intended to show
  elseif testProblem == 6 then
    
    var T : double = 0.5  -- Temperature
    var a : double = 0.2  -- Linear factor between const and nonlinear IC
    var n : double = 5    -- exponent, i.e. steepness

    for e in r_W do

      r_W[e].rho = a + (1-a)*cmath.pow(cmath.cos(2*PI*r_mesh[e].x - PI/2), 2*n)
      r_W[e].rhov[0] = 2*r_W[e].rho*(2/(1 + cmath.exp(100*(r_mesh[e].x-1.0/2))) -1)
      r_W[e].rhov[1] = 0
      r_W[e].rhov[2] = 0

      var P : double = R*r_W[e].rho*T
      r_W[e].rhoE = Cv*P/R + 0.5*r_W[e].rhov[0]*r_W[e].rhov[0]/r_W[e].rho
        
      --c.printf("W[{%d, %d}] = {%f, {%f, %f}, %f}\n", e.x, e.y, r_W[e].rho, r_W[e].rhov[0], r_W[e].rhov[1], r_W[e].rhoE)
    end

  -- Blob Test
  elseif testProblem == 7 then
    
    -- Blob Parameters
    var rhoB : double = 10.0   -- Density
    var PB : double = 1.0      -- Pressure
    var r : double = 1/10.     -- Radius

    -- Surrounding Medium Parameters
    var rhoS : double = 1.0                  -- Density
    var PS : double = 1.0                    -- Pressure
    var cS : double = cmath.sqrt(g*PS/rhoS)  -- Speed of Sound
    var vS : double = 2.7*cS                 -- Bulk Motion (M = 2.7)

    for e in r_W do

      var x : double = r_mesh[e].x - 1/2
      var y : double = r_mesh[e].y - 1/2

      -- Blob
      if (x*x + y*y) < r*r then

        r_W[e].rho = rhoB
        r_W[e].rhov[0] = 0
        r_W[e].rhov[1] = 0
        r_W[e].rhov[2] = 0        
        r_W[e].rhoE = Cv*PB/R

      -- Background
      else
        r_W[e].rho = rhoS
        r_W[e].rhov[0] = r_W[e].rho*vS
        r_W[e].rhov[1] = 0
        r_W[e].rhov[2] = 0        
        r_W[e].rhoE = Cv*PS/R + 0.5*r_W[e].rhov[0]*r_W[e].rhov[0]/r_W[e].rho
      end 

    end

  -- Thermoacoustic Wave
  elseif testProblem == 8 then

    var rho : double = 1    -- Density
    var dv : double = 0.05  -- Perturbation Amplitude
    var c : double = 1.0    -- Speed of Sound


    for e in r_W do

      var v : double = dv*cmath.sin(4*PI*r_mesh[e].x)

      r_W[e].rho = rho * (1 - v/c)
      
      var P : double = 1.0 -- It's in here in case a sinusoidal pressure profile is wanted 

      r_W[e].rhov[0] = 0 --r_W[e].rho*v -- If you want a pressure wave then also uncomment this
      r_W[e].rhov[1] = 0
      r_W[e].rhov[2] = 0
      r_W[e].rhoE = Cv*P/R + 0.5*r_W[e].rhov[0]*r_W[e].rhov[0]/r_W[e].rho
    end

  -- Gresho Vortex (also known as Triangular Vortex)
  -- Refer to Fabian Miczek 2013
  elseif testProblem == 9 then

    var um : double = 1.0                         -- Velocity Max
    var rho0 : double = 1                         -- Density
    var M : double = cmath.sqrt(rho0*um*um/5/g)   -- Mach Number
    var P0 : double = rho0*um*um/g/M/M            -- Pressure 

    -- Declarations for Velocity, Pressure
    var uphi : double
    var P : double

    
    var dv : double = 0 * 9/(2*PI/5/um) -- Bulk velocity if desired (number of rotations / rotation rate)

    for e in r_W do

      -- Reshift Center to Origin
      var x : double = r_mesh[e].x - 0.5
      var y : double = r_mesh[e].y - 0.5

      -- Transform to Polar Coordinates
      var r : double = cmath.sqrt(x*x + y*y)
      var phi : double = cmath.atan2(y, x)

      -- Piecewise Function 
      -- Refer to Fabian Miczek 2013
      if r < 0.2 then
        P = P0 + 25.0/2.0*r*r
        uphi = 5*r
      elseif ((0.2 <= r) and (r < 0.4)) then
        P = P0 + 25.0/2.0*r*r + 4*(1 - 5*r - cmath.log(0.2) + cmath.log(r))
        uphi = 2.0 - 5.0*r
      elseif r >= 0.4 then
        P = P0 - 2.0 + 4.0*cmath.log(2)
        uphi = 0
      end

      r_W[e].rho = rho0
      r_W[e].rhov[0] = rho0 * (-cmath.sin(phi) * uphi + dv)
      r_W[e].rhov[1] = rho0 * ( cmath.cos(phi) * uphi + dv)
      r_W[e].rhov[2] = 0
      r_W[e].rhoE = Cv*P/R + 0.5*(r_W[e].rhov[0]*r_W[e].rhov[0] + r_W[e].rhov[1]*r_W[e].rhov[1])/r_W[e].rho

    end

   -- Sine Wave Collapse
  elseif testProblem == 10 then

    -- Uniform Density
    var rho0 : double = 1

    -- Nonzero Width
    var T : double = 0.1
    var P : double = rho0 * R * T

    for e in r_W do

      r_W[e].rho = rho0
      r_W[e].rhov[0] = rho0 * cmath.sin(2*PI*r_mesh[e].x)
      r_W[e].rhov[1] = 0
      r_W[e].rhov[2] = 0
      r_W[e].rhoE = Cv*P/R + 0.5*(r_W[e].rhov[0]*r_W[e].rhov[0])/r_W[e].rho

    end

  -- Isothermal Shock
  elseif testProblem == 11 then

    -- Left and Right Density
    var pL : double = 1.0
    var pR : double = 1.0/2.0

    -- Left and Right Pressure
    var temp : double = 1.2
    var PL : double = pL * R * temp
    var PR : double = pR * R * temp

    for e in r_W do

      -- Left Side
      if r_mesh[e].x <= 0.3 then
        r_W[e].rho = pL
        r_W[e].rhov[0] = pL*2
        r_W[e].rhov[1] = 0
        r_W[e].rhov[2] = 0
        r_W[e].rhoE = Cv*PL/R + 0.5*r_W[e].rhov[0]*r_W[e].rhov[0]/r_W[e].rho

      -- Right Side
      else
        r_W[e].rho = pR
        r_W[e].rhov[0] = pR*0
        r_W[e].rhov[1] = 0
        r_W[e].rhov[2] = 0
        r_W[e].rhoE = Cv*PR/R + 0.5*r_W[e].rhov[0]*r_W[e].rhov[0]/r_W[e].rho
      end
    end

  -- Thermal Bath
  elseif testProblem == 12 then

    -- Density 
    var rho : double = 1.0

    -- Pressure
    var temp : double = 1.2
    var P : double = rho * R * temp

    for e in r_W do

      r_W[e].rho = rho
      r_W[e].rhov[0] = 0
      r_W[e].rhov[1] = 0
      r_W[e].rhov[2] = 0
      r_W[e].rhoE = Cv*P/R + 0.5*r_W[e].rhov[0]*r_W[e].rhov[0]/r_W[e].rho
      
    end

  end
end

-- Helper terra functions to simplify inline representations:

terra Temperature(E : double, u : double, g : double, R : double)
 
  -- Temperature computes temperatue given total energy E, bulk/mean velocity, adiabatic index g, gas constant R

  return (g - 1)/R*(E - 0.5*u*u)
end

terra geq(c2 : double, rho : double, T : double, R : double, effD : int32)

  -- geq computes the equilibrium distribution for g given squared peculiar velocity c2, density rho, temperature T, gas constnat R, and dimensionality effD
  
  var x : double = rho*cmath.exp(-c2/(2*R*T))*cmath.pow(2*PI*R*T, -double(effD)/2.0)

  return x
end

terra visc(T : double, ur : double, Tr : double, w : double)

  -- visc computes viscosity according to exponent model given temperature T, reference values ur (mu_r) and Tr, and exponent w.

  return ur*cmath.pow(T/Tr,w)
end

terra sgn(x : double)

  -- sgn returns the sign of x

  var sx : double = double(0 < x) - double(x < 0)
  return sx
end

terra abs(x : double)

  -- abs returns the absolute value of x
  
  return x*sgn(x)
end


terra VanLeer(L : double, C : double, R : double, xL : double, xC : double, xR : double)

  -- The Van Leer Limiter
  -- Input: left, middle (center) and right values (L, C, R), and respective cell positions (xL, xC, xR)
  -- Intermediate values: left and right slopes, s1 and s2
  -- Output: Van Leer limited slope.
  
  -- Periodic Boundary Adjustment
  if xR < xC then xR = xR + 1.0 end
  if xL > xC then xL = xL - 1.0 end


  var s1 : double = (C - L)/(xC - xL)
  var s2 : double = (R - C)/(xR - xC)

  if (C == L and C == R) then

    -- If one of the slopes is zero, then return zero.
    -- To be completely honest, I forgot why I included this case but I'm too afraid to remove it and it doesnt hurt keeping it.
    -- It's actually more efficient than multiplying zero by a few factors and then returning the value so...

    return 0.
  elseif (xC == xL or xC == xR) then

    -- xC == xL or xC == xR if and only if at the boundary and BC not periodic.
    -- If Dirichlet, slope doesn't matter since cell is not updated. Return zero.
    -- If Outflow, slope should be zero (in the constant approximation). Return zero.

    return 0.
  else 

    -- if s1 and s2 have the same sign, then return harmonic mean. Otherwise, zero.

    return (sgn(s1) + sgn(s2))*(abs(s1) * abs(s2))/(abs(s1) + abs(s2))
  end  
end


terra BC(i : int32, j : int32, k : int32, Dim : int32, BCs : int32[6], N : int32[3])

  -- This function takes in a set of spatial indices (i, j, k)
  -- and grid size information N and computes the set of 
  -- left and right indices (IL, JL, KL) and (IR, JR, KR)
  -- along the dimension Dim, subject to boundary conditions BCs

  var IL : int32
  var JL : int32
  var KL : int32
  var IR : int32
  var JR : int32
  var KR : int32

  if Dim == 0 then
    IL = i - 1
    IR = i + 1
    JL = j
    JR = j
    KL = k
    KR = k
  end

  if Dim == 1 then
    IL = i
    IR = i
    JL = j - 1
    JR = j + 1
    KL = k
    KR = k
  end

  if Dim == 2 then
    IL = i
    IR = i
    JL = j
    JR = j
    KL = k - 1
    KR = k + 1
  end

  -- Periodic Boundary Conditions (Left and right must both be periodic -- only one if)
  -- The grid size is added and then modded out because of a weird (intended) bug with moduloing negative numbers. 
  if Dim == 0 and BCs[0] == 0 then
      IL = (IL + N[0])%N[0]
      IR =  IR % N[0]
  elseif Dim == 1 and BCs[1] == 0 then
      JL = (JL + N[1])%N[1]
      JR =  JR % N[1]
  elseif Dim == 2 and BCs[0] == 0 then
      KL = (KL + N[2])%N[2]
      KR =  KR % N[2]
  

  -- Dirichlet or Outflow Boundary Conditions
  elseif (Dim == 0 and i == 0 and (BCs[0] == 1 or BCs[0] == 2)) then
    IL = 0
  elseif (Dim == 0 and i == N[0]-1 and (BCs[3] == 1 or BCs[3] == 2)) then
    IR = i
  elseif (Dim == 1 and j == 0 and (BCs[1] == 1 or BCs[1] == 2)) then
    JL = 0
  elseif (Dim == 1 and j == N[1]-1 and (BCs[4] == 1 or BCs[4] == 2)) then
    JR = j
  elseif (Dim == 2 and k == 0 and (BCs[2] == 1 or BCs[2] == 2)) then
    KL = 0
  elseif (Dim == 2 and k == N[2]-1 and (BCs[5] == 1 or BCs[5] == 2)) then
    KR = k
  end
 
  -- Store indices in Left/Right struct LR 
  var LR : int32[6] 
  LR[0] = IL
  LR[1] = JL
  LR[2] = KL
  LR[3] = IR
  LR[4] = JR
  LR[5] = KR

  return LR
end
BC.replicable = true;


terra TimeStep(calcdt : double, dumptime : double, tend : double)

  -- This simple helper function computes the minimum of several timesteps
  -- calcdt is the usual (CFL * dx/umax) from the CFL criterion
  -- dumptime is the time until the next dump
  -- tend is the time until final simulation time

  var timestep : double = cmath.fmin(cmath.fmin(calcdt, dumptime), tend)
  return timestep
end 
TimeStep.replicable = true

-- Refer to original CDUGKS paper for steps
-- Hongtao Liu et. al. 2018
-- Step 1: Phibar at interface
-- Step 1a: Phibar at Cell Center.
task Step1a(r_grid : region(ispace(int8d), grid),
            r_gridbarp : region(ispace(int8d), grid),
            r_S : region(ispace(int8d), grid),
            r_W : region(ispace(int8d), W),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            dt : double, R : double, K : double, Cv : double,
            g : double, w : double, ur : double, Tr : double,
            Pr : double, effD : int32, thermal_bath : bool, thermal_T : double)
where
  reads(r_grid, r_W, vxmesh.v, vymesh.v, vzmesh.v), 
  reads writes(r_S),
  reads writes(r_gridbarp)
do

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_grid.bounds.lo.x, r_grid.bounds.lo.y, r_grid.bounds.lo.z}
  var shi : int3d = {r_grid.bounds.hi.x, r_grid.bounds.hi.y, r_grid.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)


  -- Relaxation Times
  var tg : double
  var tb : double
  var tgb : double

  var c2 : double    -- Peculiar Velocity squared
  var u : double     -- Bulk Velocity
  var T : double     -- Temperature
  var Xi : double[3] -- Discrete Velocity
  var Z : double     -- Auxilary energy term, see energy distribution PDE in paper

  -- Indices
  var e3 : int8d
  var e6 : int8d 

  -- Equilbrium Distributions
  var g_eq : double 
  var b_eq : double
  
  for s in s3 do

    -- Construct Spatial Index
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}

    -- Compute Bulk Speed
    u = 0
    for d = 0, effD do
      u += r_W[e3].rhov[d]/r_W[e3].rho*r_W[e3].rhov[d]/r_W[e3].rho
    end
    u = sqrt(u)

    -- Compute Temperature
    T = Temperature(r_W[e3].rhoE/r_W[e3].rho, u, g, R)

    -- Stop Simulation if Negative Temperature
    if T < 0 then
      c.printf("T < 0, r_W[e3].rhoE = %f, r_W[e3].rho = %f, u = %f, g = %f, R = %f\n", r_W[e3].rhoE, r_W[e3].rho, u, g, R)
      regentlib.assert(T >= 0, "Negative Temperature\n")
    end

    -- Compute Relaxation Times
    tg = visc(T, ur, Tr, w)/r_W[e3].rho/R/T
    tb = tg/Pr
    if (Pr == 1) then
      tgb = 0 -- Manually set to zero to avoid division by zero when Pr = 1
    else
      tgb = tb*tg/(tg-tb)
    end

    for v in v3 do
      e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z}

      -- Compute Peculiar Velocity squared
      c2 = 0
      Xi[0] = vxmesh[v.x].v
      Xi[1] = vymesh[v.y].v
      Xi[2] = vzmesh[v.z].v     
      for d = 0, effD do
        c2 += (Xi[d]-r_W[e3].rhov[d]/r_W[e3].rho)*(Xi[d]-r_W[e3].rhov[d]/r_W[e3].rho)
      end

      -- Compute Equilibrium Distributions
      if thermal_bath then
        g_eq = geq(c2, r_W[e3].rho, thermal_T, R, effD)
        b_eq = g_eq*(Xi[0]*Xi[0] + Xi[1]*Xi[1] + Xi[2]*Xi[2] + (3.0-effD+K)*R*thermal_T)/2.0
      else
        g_eq = geq(c2, r_W[e3].rho, T, R, effD)
        b_eq = g_eq*(Xi[0]*Xi[0] + Xi[1]*Xi[1] + Xi[2]*Xi[2] + (3.0-effD+K)*R*T)/2.0
      end

      -- Compute Auxilary Energy Term for b
      Z = 0
      for d = 0, effD do
        Z += Xi[d]*r_W[e3].rhov[d]/r_W[e3].rho
      end 
      Z += -u*u/2

      -- Compute Source Terms (Combined with Step 1 to save compute since u is already calculated)
      r_S[e6].g = -0 -- -a dot grad_xi g 
      if (Pr == 1) then
        -- Manually set to zero to avoid division by zero when Pr = 1
        r_S[e6].b = 0 + 0 --a dot grad stuff
      else 
        r_S[e6].b = Z/tgb*(r_grid[e6].g - g_eq) + 0 --a dot grad stuff
      end

      -- Step 1a: Compute phibarplus
      r_gridbarp[e6].g = (tg - dt/4.)/tg*r_grid[e6].g + dt/(4.*tg)*g_eq + dt/4.*r_S[e6].g
      r_gridbarp[e6].b = (tb - dt/4.)/tb*r_grid[e6].b + dt/(4.*tb)*b_eq + dt/4.*r_S[e6].b
  

      -- NaN checker
      if (isnan(r_gridbarp[e6].g) == 1 or isnan(r_gridbarp[e6].b) == 1) then

        c.printf("Step 1a: gp = %.12f, bp = %.12f, g = %.12f, b = %.12f, g_eq = %.12f, Sg = %.12f, Sb = %.12f, taus = {%.12f, %.12f}\n", r_gridbarp[e6].g, r_gridbarp[e6].b, r_grid[e6].g, r_grid[e6].b, g_eq, r_S[e6].g, r_S[e6].b, tg, tb)

        regentlib.assert(not [bool](isnan(r_gridbarp[e6].g)), "Step 1a\n")
        regentlib.assert(not [bool](isnan(r_gridbarp[e6].b)), "Step 1a\n")
    
      end

    end
  end
end

-- Step 1b
-- Compute gradients of phibarplus to compute phibarplus at interface. 
-- Compute phibar at interface from phibarplus.

-- x Gradient
task Step1b_sigx(r_gridbarp : region(ispace(int8d), grid),
            r_sig : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            plx_mesh : region(ispace(int8d), mesh),
            prx_mesh : region(ispace(int8d), mesh),
            plx_gridbarp : region(ispace(int8d), grid),
            prx_gridbarp : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),            
            vymesh : region(ispace(int1d), vmesh),            
            vzmesh : region(ispace(int1d), vmesh),            
            BCs : int32[6], N : int32[3], effD : int32)
where 
  reads(r_gridbarp, r_mesh, plx_mesh, prx_mesh, plx_gridbarp, prx_gridbarp),
  reads writes(r_sig)
do
  
  -- Gradient Axis
  var Dim : int32 = 0 

  -- Cell Centers 
  var xC : double
  var xL : double
  var xR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e6 : int8d 
  var e7 : int8d 
  var eL6 : int8d 
  var eR6  : int8d

  -- Left/Right values of g/b
  var gbpL : double
  var gbpR : double
  var bbpL : double
  var bbpR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    xC = r_mesh[e3].x
  
    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3] 
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do
      
      e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z}
      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      eL6 = {IL, JL, KL, 0, 0, v.x, v.y, v.z}
      eR6 = {IR, JR, KR, 0, 0, v.x, v.y, v.z}

      -- Gather Left Values 
      if r_gridbarp.bounds.lo.x == s.x then
        gbpL = plx_gridbarp[eL6].g 
        bbpL = plx_gridbarp[eL6].b 
        xL = plx_mesh[eL3].x
      else
        gbpL = r_gridbarp[eL6].g
        bbpL = r_gridbarp[eL6].b
        xL = r_mesh[eL3].x
      end

      -- Gather Right Values
      if r_gridbarp.bounds.hi.x == s.x then
        gbpR = prx_gridbarp[eR6].g 
        bbpR = prx_gridbarp[eR6].b 
        xR = prx_mesh[eR3].x
      else
        gbpR = r_gridbarp[eR6].g
        bbpR = r_gridbarp[eR6].b
        xR = r_mesh[eR3].x
      end

      -- Compute Gradients
      r_sig[e7].g = VanLeer(gbpL, r_gridbarp[e6].g, gbpR, xL, xC, xR)
      r_sig[e7].b = VanLeer(bbpL, r_gridbarp[e6].b, bbpR, xL, xC, xR)

      -- NaN checker
      if (isnan(r_sig[e7].g) == 1 or isnan(r_sig[e7].b) == 1) then

        c.printf("Step 1b_sigx: r_sig.g = %f, r_sig.b = %f\n", r_sig[e7].g, r_sig[e7].b)

        regentlib.assert(not [bool](isnan(r_sig[e7].g)), "Step 1b_sigx\n")
        regentlib.assert(not [bool](isnan(r_sig[e7].b)), "Step 1b_sigx\n")

      end
  
    end
  end
end

-- y Gradient
task Step1b_sigy(r_gridbarp : region(ispace(int8d), grid),
            r_sig : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            ply_mesh : region(ispace(int8d), mesh),
            pry_mesh : region(ispace(int8d), mesh),
            ply_gridbarp : region(ispace(int8d), grid),
            pry_gridbarp : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),            
            vymesh : region(ispace(int1d), vmesh),            
            vzmesh : region(ispace(int1d), vmesh),            
            BCs : int32[6], N : int32[3], effD : int32)
where 
  reads(r_gridbarp, r_mesh, ply_mesh, pry_mesh, ply_gridbarp, pry_gridbarp),
  reads writes(r_sig)
do
  -- Gradient Axis
  var Dim : int32 = 1

  -- Cell Centers 
  var yC : double
  var yL : double
  var yR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e6 : int8d 
  var e7 : int8d 
  var eL6 : int8d 
  var eR6  : int8d

  -- Left/Right values of g/b
  var gbpL : double
  var gbpR : double
  var bbpL : double
  var bbpR : double
  
  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    yC = r_mesh[e3].y
  
    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3] 
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do
      
      e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z}
      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      eL6 = {IL, JL, KL, 0, 0, v.x, v.y, v.z}
      eR6 = {IR, JR, KR, 0, 0, v.x, v.y, v.z}

      -- Gather Left Values
      if r_gridbarp.bounds.lo.y == s.y then
        gbpL = ply_gridbarp[eL6].g 
        bbpL = ply_gridbarp[eL6].b 
        yL = ply_mesh[eL3].y
      else
        gbpL = r_gridbarp[eL6].g
        bbpL = r_gridbarp[eL6].b
        yL = r_mesh[eL3].y
      end

      -- Gather Right Values
      if r_gridbarp.bounds.hi.y == s.y then
        gbpR = pry_gridbarp[eR6].g 
        bbpR = pry_gridbarp[eR6].b 
        yR = pry_mesh[eR3].y
      else
        gbpR = r_gridbarp[eR6].g
        bbpR = r_gridbarp[eR6].b
        yR = r_mesh[eR3].y
      end

      -- Compute Gradients
      r_sig[e7].g = VanLeer(gbpL, r_gridbarp[e6].g, gbpR, yL, yC, yR)
      r_sig[e7].b = VanLeer(bbpL, r_gridbarp[e6].b, bbpR, yL, yC, yR)

      -- NaN checker
      if (isnan(r_sig[e7].g) == 1 or isnan(r_sig[e7].b) == 1) then

        c.printf("Step 1b_sigy: r_sig.g = %f, r_sig.b = %f\n", r_sig[e7].g, r_sig[e7].b)

        regentlib.assert(not [bool](isnan(r_sig[e7].g)), "Step 1b_sigy\n")
        regentlib.assert(not [bool](isnan(r_sig[e7].b)), "Step 1b_sigy\n")

      end
  
    end
  end
end

-- z Gradient
task Step1b_sigz(r_gridbarp : region(ispace(int8d), grid),
            r_sig : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            plz_mesh : region(ispace(int8d), mesh),
            prz_mesh : region(ispace(int8d), mesh),
            plz_gridbarp : region(ispace(int8d), grid),
            prz_gridbarp : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),            
            vymesh : region(ispace(int1d), vmesh),            
            vzmesh : region(ispace(int1d), vmesh),            
            BCs : int32[6], N : int32[3], effD : int32)
where 
  reads(r_gridbarp, r_mesh, plz_mesh, prz_mesh, plz_gridbarp, prz_gridbarp),
  reads writes(r_sig)
do
  -- Gradient Axis
  var Dim : int32 = 2

  -- Cell Centers 
  var zC : double
  var zL : double
  var zR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e6 : int8d 
  var e7 : int8d 
  var eL6 : int8d 
  var eR6  : int8d

  -- Left/Right values of g/b
  var gbpL : double
  var gbpR : double
  var bbpL : double
  var bbpR : double
  
  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    zC = r_mesh[e3].z
  
    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3] 
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do
      
      e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z}
      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      eL6 = {IL, JL, KL, 0, 0, v.x, v.y, v.z}
      eR6 = {IR, JR, KR, 0, 0, v.x, v.y, v.z}

      -- Gather Left Values 
      if r_gridbarp.bounds.lo.z == s.z then
        gbpL = plz_gridbarp[eL6].g 
        bbpL = plz_gridbarp[eL6].b 
        zL = plz_mesh[eL3].z
      else
        gbpL = r_gridbarp[eL6].g
        bbpL = r_gridbarp[eL6].b
        zL = r_mesh[eL3].z
      end

      -- Gather Right Values
      if r_gridbarp.bounds.hi.z == s.z then
        gbpR = prz_gridbarp[eR6].g 
        bbpR = prz_gridbarp[eR6].b 
        zR = prz_mesh[eR3].z
      else
        gbpR = r_gridbarp[eR6].g
        bbpR = r_gridbarp[eR6].b
        zR = r_mesh[eR3].z
      end

      -- Compute Gradients
      r_sig[e7].g = VanLeer(gbpL, r_gridbarp[e6].g, gbpR, zL, zC, zR)
      r_sig[e7].b = VanLeer(bbpL, r_gridbarp[e6].b, bbpR, zL, zC, zR)

      -- NaN checker
      if (isnan(r_sig[e7].g) == 1 or isnan(r_sig[e7].b) == 1) then

        c.printf("Step 1b_sigz: r_sig.g = %f, r_sig.b = %f\n", r_sig[e7].g, r_sig[e7].b)

        regentlib.assert(not [bool](isnan(r_sig[e7].g)), "Step 1b_sigz\n")
        regentlib.assert(not [bool](isnan(r_sig[e7].b)), "Step 1b_sigz\n")

      end
  
    end
  end
end

-- Second Derivatives
-- Need Second Derivatives (Hessian) to be able to interpolate gradients.
-- Note: Hessian is asymmetric due to nonlinear limiter.
-- i.e. VL(d_y VL(d_x(field))) != VL(d_x VL(d_y(field))) if VL is nonlinear

-- x Gradient of sigx
task Step1b_sigx_x(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            plx_mesh : region(ispace(int8d), mesh),
            prx_mesh : region(ispace(int8d), mesh),
            plx_sig : region(ispace(int8d), grid),
            prx_sig : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_mesh, plx_mesh, prx_mesh, plx_sig, prx_sig),
  reads writes(r_sig2)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  -- VL(d_Dim2(VL(d_Dim(field))))
  var Dim : int32 = 0
  var Dim2 : int32 = 0

  -- Cell Centers
  var xC : double
  var xL : double
  var xR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e7 : int8d 
  var e8 : int8d 
  var eL7 : int8d 
  var eR7  : int8d

  -- Left/Right values of g/b
  var gsigL : double
  var gsigR : double
  var bsigL : double
  var bsigR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    xC = r_mesh[e3].x

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
     
      -- Gather Left Values
      if r_sig.bounds.lo.x == s.x then
        gsigL = plx_sig[eL7].g 
        bsigL = plx_sig[eL7].b 
        xL = plx_mesh[eL3].x
      else
        gsigL = r_sig[eL7].g
        bsigL = r_sig[eL7].b
        xL = r_mesh[eL3].x
      end

      -- Gather Right Values
      if r_sig.bounds.hi.x == s.x then
        gsigR = prx_sig[eR7].g
        bsigR = prx_sig[eR7].b
        xR = prx_mesh[eR3].x
      else
        gsigR = r_sig[eR7].g
        bsigR = r_sig[eR7].b
        xR = r_mesh[eR3].x
      end

      -- Compute Gradient of Gradient
      r_sig2[e8].g = VanLeer(gsigL, r_sig[e7].g, gsigR, xL, xC, xR)
      r_sig2[e8].b = VanLeer(bsigL, r_sig[e7].b, bsigR, xL, xC, xR)

    end
  end
end

-- x Gradient of sigy
task Step1b_sigy_x(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            plx_mesh : region(ispace(int8d), mesh),
            prx_mesh : region(ispace(int8d), mesh),
            plx_sig : region(ispace(int8d), grid),
            prx_sig : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_mesh, plx_mesh, prx_mesh, plx_sig, prx_sig),
  reads writes(r_sig2)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  -- VL(d_Dim2(VL(d_Dim(field))))
  var Dim : int32 = 1
  var Dim2 : int32 = 0

  -- Cell Centers
  var xC : double
  var xL : double
  var xR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e7 : int8d 
  var e8 : int8d 
  var eL7 : int8d 
  var eR7  : int8d

  -- Left/Right values of g/b
  var gsigL : double
  var gsigR : double
  var bsigL : double
  var bsigR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    xC = r_mesh[e3].x

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
     
      -- Gather Left Values
      if r_sig.bounds.lo.x == s.x then
        gsigL = plx_sig[eL7].g 
        bsigL = plx_sig[eL7].b 
        xL = plx_mesh[eL3].x
      else
        gsigL = r_sig[eL7].g
        bsigL = r_sig[eL7].b
        xL = r_mesh[eL3].x
      end

      -- Gather Right Values
      if r_sig.bounds.hi.x == s.x then
        gsigR = prx_sig[eR7].g
        bsigR = prx_sig[eR7].b
        xR = prx_mesh[eR3].x
      else
        gsigR = r_sig[eR7].g
        bsigR = r_sig[eR7].b
        xR = r_mesh[eR3].x
      end

      -- Compute Gradient of Gradient
      r_sig2[e8].g = VanLeer(gsigL, r_sig[e7].g, gsigR, xL, xC, xR)
      r_sig2[e8].b = VanLeer(bsigL, r_sig[e7].b, bsigR, xL, xC, xR)

    end
  end
end


-- x Gradient of sigz
task Step1b_sigz_x(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            plx_mesh : region(ispace(int8d), mesh),
            prx_mesh : region(ispace(int8d), mesh),
            plx_sig : region(ispace(int8d), grid),
            prx_sig : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_mesh, plx_mesh, prx_mesh, plx_sig, prx_sig),
  reads writes(r_sig2)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  -- VL(d_Dim2(VL(d_Dim(field))))
  var Dim : int32 = 2
  var Dim2 : int32 = 0

  -- Cell Centers
  var xC : double
  var xL : double
  var xR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e7 : int8d 
  var e8 : int8d 
  var eL7 : int8d 
  var eR7  : int8d

  -- Left/Right values of g/b
  var gsigL : double
  var gsigR : double
  var bsigL : double
  var bsigR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    xC = r_mesh[e3].x

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
     
      -- Gather Left Values
      if r_sig.bounds.lo.x == s.x then
        gsigL = plx_sig[eL7].g 
        bsigL = plx_sig[eL7].b 
        xL = plx_mesh[eL3].x
      else
        gsigL = r_sig[eL7].g
        bsigL = r_sig[eL7].b
        xL = r_mesh[eL3].x
      end

      -- Gather Right Values
      if r_sig.bounds.hi.x == s.x then
        gsigR = prx_sig[eR7].g
        bsigR = prx_sig[eR7].b
        xR = prx_mesh[eR3].x
      else
        gsigR = r_sig[eR7].g
        bsigR = r_sig[eR7].b
        xR = r_mesh[eR3].x
      end

      -- Compute Gradient of Gradient
      r_sig2[e8].g = VanLeer(gsigL, r_sig[e7].g, gsigR, xL, xC, xR)
      r_sig2[e8].b = VanLeer(bsigL, r_sig[e7].b, bsigR, xL, xC, xR)

    end
  end
end

-- y Gradient of sigx
task Step1b_sigx_y(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            ply_mesh : region(ispace(int8d), mesh),
            pry_mesh : region(ispace(int8d), mesh),
            ply_sig : region(ispace(int8d), grid),
            pry_sig : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_mesh, ply_mesh, pry_mesh, ply_sig, pry_sig),
  reads writes(r_sig2)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  -- VL(d_Dim2(VL(d_Dim(field))))
  var Dim : int32 = 0
  var Dim2 : int32 = 1

  -- Cell Centers
  var yC : double
  var yL : double
  var yR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e7 : int8d 
  var e8 : int8d 
  var eL7 : int8d 
  var eR7  : int8d

  -- Left/Right values of g/b
  var gsigL : double
  var gsigR : double
  var bsigL : double
  var bsigR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    yC = r_mesh[e3].y

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]

    eL3  = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3  = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
     
      -- Gather Left Values
      if r_sig.bounds.lo.y == s.y then
        gsigL = ply_sig[eL7].g 
        bsigL = ply_sig[eL7].b 
        yL = ply_mesh[eL3].y
      else
        gsigL = r_sig[eL7].g
        bsigL = r_sig[eL7].b
        yL = r_mesh[eL3].y
      end

      -- Gather Right Values
      if r_sig.bounds.hi.y == s.y then
        gsigR = pry_sig[eR7].g
        bsigR = pry_sig[eR7].b
        yR = pry_mesh[eR3].y
      else
        gsigR = r_sig[eR7].g
        bsigR = r_sig[eR7].b
        yR = r_mesh[eR3].y
      end

      -- Compute Gradient of Gradient
      r_sig2[e8].g = VanLeer(gsigL, r_sig[e7].g, gsigR, yL, yC, yR)
      r_sig2[e8].b = VanLeer(bsigL, r_sig[e7].b, bsigR, yL, yC, yR)

    end
  end
end

-- y Gradient of sigy
task Step1b_sigy_y(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            ply_mesh : region(ispace(int8d), mesh),
            pry_mesh : region(ispace(int8d), mesh),
            ply_sig : region(ispace(int8d), grid),
            pry_sig : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_mesh, ply_mesh, pry_mesh, ply_sig, pry_sig),
  reads writes(r_sig2)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  -- VL(d_Dim2(VL(d_Dim(field))))
  var Dim : int32 = 1
  var Dim2 : int32 = 1

  -- Cell Centers
  var yC : double
  var yL : double
  var yR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e7 : int8d 
  var e8 : int8d 
  var eL7 : int8d 
  var eR7  : int8d

  -- Left/Right values of g/b
  var gsigL : double
  var gsigR : double
  var bsigL : double
  var bsigR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    yC = r_mesh[e3].y

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
     
      -- Gather Left Values
      if r_sig.bounds.lo.y == s.y then
        gsigL = ply_sig[eL7].g 
        bsigL = ply_sig[eL7].b 
        yL = ply_mesh[eL3].y
      else
        gsigL = r_sig[eL7].g
        bsigL = r_sig[eL7].b
        yL = r_mesh[eL3].y
      end

      -- Gather Right Values
      if r_sig.bounds.hi.y == s.y then
        gsigR = pry_sig[eR7].g
        bsigR = pry_sig[eR7].b
        yR = pry_mesh[eR3].y
      else
        gsigR = r_sig[eR7].g
        bsigR = r_sig[eR7].b
        yR = r_mesh[eR3].y
      end

      -- Compute Gradient of Gradient
      r_sig2[e8].g = VanLeer(gsigL, r_sig[e7].g, gsigR, yL, yC, yR)
      r_sig2[e8].b = VanLeer(bsigL, r_sig[e7].b, bsigR, yL, yC, yR)

    end
  end
end

-- y Gradient of sigz
task Step1b_sigz_y(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            ply_mesh : region(ispace(int8d), mesh),
            pry_mesh : region(ispace(int8d), mesh),
            ply_sig : region(ispace(int8d), grid),
            pry_sig : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_mesh, ply_mesh, pry_mesh, ply_sig, pry_sig),
  reads writes(r_sig2)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  -- VL(d_Dim2(VL(d_Dim(field))))
  var Dim : int32 = 2
  var Dim2 : int32 = 1

  -- Cell Centers
  var yC : double
  var yL : double
  var yR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e7 : int8d 
  var e8 : int8d 
  var eL7 : int8d 
  var eR7  : int8d

  -- Left/Right values of g/b
  var gsigL : double
  var gsigR : double
  var bsigL : double
  var bsigR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    yC = r_mesh[e3].y

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
     
      -- Gather Left Values
      if r_sig.bounds.lo.y == s.y then
        gsigL = ply_sig[eL7].g 
        bsigL = ply_sig[eL7].b 
        yL = ply_mesh[eL3].y
      else
        gsigL = r_sig[eL7].g
        bsigL = r_sig[eL7].b
        yL = r_mesh[eL3].y
      end

      -- Gather Right Values
      if r_sig.bounds.hi.y == s.y then
        gsigR = pry_sig[eR7].g
        bsigR = pry_sig[eR7].b
        yR = pry_mesh[eR3].y
      else
        gsigR = r_sig[eR7].g
        bsigR = r_sig[eR7].b
        yR = r_mesh[eR3].y
      end

      -- Compute Gradient of Gradient
      r_sig2[e8].g = VanLeer(gsigL, r_sig[e7].g, gsigR, yL, yC, yR)
      r_sig2[e8].b = VanLeer(bsigL, r_sig[e7].b, bsigR, yL, yC, yR)

    end
  end
end

-- z Gradient of sigx
task Step1b_sigx_z(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            plz_mesh : region(ispace(int8d), mesh),
            prz_mesh : region(ispace(int8d), mesh),
            plz_sig : region(ispace(int8d), grid),
            prz_sig : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_mesh, plz_mesh, prz_mesh, plz_sig, prz_sig),
  reads writes(r_sig2)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  -- VL(d_Dim2(VL(d_Dim(field))))
  var Dim : int32 = 0
  var Dim2 : int32 = 2

  -- Cell Centers
  var zC : double
  var zL : double
  var zR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e7 : int8d 
  var e8 : int8d 
  var eL7 : int8d 
  var eR7  : int8d

  -- Left/Right values of g/b
  var gsigL : double
  var gsigR : double
  var bsigL : double
  var bsigR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    zC = r_mesh[e3].z

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
     
      -- Gather Left Values
      if r_sig.bounds.lo.z == s.z then
        gsigL = plz_sig[eL7].g 
        bsigL = plz_sig[eL7].b 
        zL = plz_mesh[eL3].z
      else
        gsigL = r_sig[eL7].g
        bsigL = r_sig[eL7].b
        zL = r_mesh[eL3].z
      end

      -- Gather Right Values
      if r_sig.bounds.hi.z == s.z then
        gsigR = prz_sig[eR7].g
        bsigR = prz_sig[eR7].b
        zR = prz_mesh[eR3].z
      else
        gsigR = r_sig[eR7].g
        bsigR = r_sig[eR7].b
        zR = r_mesh[eR3].z
      end

      -- Compute Gradient of Gradient
      r_sig2[e8].g = VanLeer(gsigL, r_sig[e7].g, gsigR, zL, zC, zR)
      r_sig2[e8].b = VanLeer(bsigL, r_sig[e7].b, bsigR, zL, zC, zR)

    end
  end
end

-- z Gradient of sigy
task Step1b_sigy_z(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            plz_mesh : region(ispace(int8d), mesh),
            prz_mesh : region(ispace(int8d), mesh),
            plz_sig : region(ispace(int8d), grid),
            prz_sig : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_mesh, plz_mesh, prz_mesh, plz_sig, prz_sig),
  reads writes(r_sig2)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  -- VL(d_Dim2(VL(d_Dim(field))))
  var Dim : int32 = 1
  var Dim2 : int32 = 2

  -- Cell Centers
  var zC : double
  var zL : double
  var zR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e7 : int8d 
  var e8 : int8d 
  var eL7 : int8d 
  var eR7  : int8d

  -- Left/Right values of g/b
  var gsigL : double
  var gsigR : double
  var bsigL : double
  var bsigR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    zC = r_mesh[e3].z

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
     
      -- Gather Left Values
      if r_sig.bounds.lo.z == s.z then
        gsigL = plz_sig[eL7].g 
        bsigL = plz_sig[eL7].b 
        zL = plz_mesh[eL3].z
      else
        gsigL = r_sig[eL7].g
        bsigL = r_sig[eL7].b
        zL = r_mesh[eL3].z
      end

      -- Gather Right Values
      if r_sig.bounds.hi.z == s.z then
        gsigR = prz_sig[eR7].g
        bsigR = prz_sig[eR7].b
        zR = prz_mesh[eR3].z
      else
        gsigR = r_sig[eR7].g
        bsigR = r_sig[eR7].b
        zR = r_mesh[eR3].z
      end

      -- Compute Gradient of Gradient
      r_sig2[e8].g = VanLeer(gsigL, r_sig[e7].g, gsigR, zL, zC, zR)
      r_sig2[e8].b = VanLeer(bsigL, r_sig[e7].b, bsigR, zL, zC, zR)

    end
  end
end

-- z Gradient of sigz
task Step1b_sigz_z(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            plz_mesh : region(ispace(int8d), mesh),
            prz_mesh : region(ispace(int8d), mesh),
            plz_sig : region(ispace(int8d), grid),
            prz_sig : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_mesh, plz_mesh, prz_mesh, plz_sig, prz_sig),
  reads writes(r_sig2)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  -- VL(d_Dim2(VL(d_Dim(field))))
  var Dim : int32 = 2
  var Dim2 : int32 = 2

  -- Cell Centers
  var zC : double
  var zL : double
  var zR : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var bc : int32[6]
  var IL : int32 
  var JL : int32 
  var KL : int32 
  var IR : int32 
  var JR : int32 
  var KR : int32 
  
  var e3 : int8d 
  var eL3 : int8d 
  var eR3 : int8d 

  var e7 : int8d 
  var e8 : int8d 
  var eL7 : int8d 
  var eR7  : int8d

  -- Left/Right values of g/b
  var gsigL : double
  var gsigR : double
  var bsigL : double
  var bsigR : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    zC = r_mesh[e3].z

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IL = bc[0]
    JL = bc[1]
    KL = bc[2]
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]

    eL3 = {IL, JL, KL, 0, 0, 0, 0, 0}
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
     
      -- Gather Left Values
      if r_sig.bounds.lo.z == s.z then
        gsigL = plz_sig[eL7].g 
        bsigL = plz_sig[eL7].b 
        zL = plz_mesh[eL3].z
      else
        gsigL = r_sig[eL7].g
        bsigL = r_sig[eL7].b
        zL = r_mesh[eL3].z
      end

      -- Gather Right Values
      if r_sig.bounds.hi.z == s.z then
        gsigR = prz_sig[eR7].g
        bsigR = prz_sig[eR7].b
        zR = prz_mesh[eR3].z
      else
        gsigR = r_sig[eR7].g
        bsigR = r_sig[eR7].b
        zR = r_mesh[eR3].z
      end

      -- Compute Gradient of Gradient
      r_sig2[e8].g = VanLeer(gsigL, r_sig[e7].g, gsigR, zL, zC, zR)
      r_sig2[e8].b = VanLeer(bsigL, r_sig[e7].b, bsigR, zL, zC, zR)

    end
  end
end

-- Derivatives at boundary
-- Now use Hessian to interpolate gradient to boundary 

-- sigx at x-boundary
task Step1b_sigx_x2(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_sigb : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            prx_mesh : region(ispace(int8d), mesh),
            prx_sig : region(ispace(int8d), grid),
            prx_sig2 : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_sig2, r_mesh, vxmesh, vymesh, vzmesh, prx_mesh, prx_sig, prx_sig2),
  reads writes(r_sigb)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  var Dim : int32 = 0
  var Dim2 : int32 = 0

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double
 
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32
  
  var e3 : int8d
  var e7 : int8d
  var e8 : int8d
  var eR3 : int8d
  var eR7 : int8d
  var eR8 : int8d
 
  var gsig : double
  var bsig : double
  var gsig2 : double
  var bsig2 : double
  var swap : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    sC = r_mesh[e3].dx

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
      eR8 = {IR, JR, KR, Dim, Dim2, v.x, v.y, v.z}
  
      -- If v < 0, gather right values 
      -- otherwise, use cell center values
      swap = 1.0
      if (vxmesh[v.x].v < 0 and Dim2 == 0) then
        if s.x == r_sigb.bounds.hi.x then
          gsig = prx_sig[eR7].g
          bsig = prx_sig[eR7].b
          gsig2 = prx_sig2[eR8].g
          bsig2 = prx_sig2[eR8].b
          sC = prx_mesh[eR3].dx
        else
          gsig = r_sig[eR7].g
          bsig = r_sig[eR7].b
          gsig2 = r_sig2[eR8].g
          bsig2 = r_sig2[eR8].b
          sC = r_mesh[eR3].dx
        end
        swap = -1 -- If v < 0, then interpolating from the right requires a minus sign grad*dx
      else
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
        gsig2 = r_sig2[e8].g
        bsig2 = r_sig2[e8].b
        sC = r_mesh[e3].dx
      end
 
      -- Interpolate Gradient to Boundary
      r_sigb[e8].g = gsig + swap*(sC/2.0)*gsig2
      r_sigb[e8].b = bsig + swap*(sC/2.0)*bsig2
      
    end
  end
end

-- sigy at x boundary
task Step1b_sigy_x2(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_sigb : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            prx_mesh : region(ispace(int8d), mesh),
            prx_sig : region(ispace(int8d), grid),
            prx_sig2 : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_sig2, r_mesh, vxmesh, vymesh, vzmesh, prx_mesh, prx_sig, prx_sig2),
  reads writes(r_sigb)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  var Dim : int32 = 1
  var Dim2 : int32 = 0

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double
 
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32
  
  var e3 : int8d
  var e7 : int8d
  var e8 : int8d
  var eR3 : int8d
  var eR7 : int8d
  var eR8 : int8d
 
  var gsig : double
  var bsig : double
  var gsig2 : double
  var bsig2 : double
  var swap : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    sC = r_mesh[e3].dx

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
      eR8 = {IR, JR, KR, Dim, Dim2, v.x, v.y, v.z}

      -- If v < 0, gather right values 
      -- otherwise, use cell center values
      swap = 1.0
      if (vxmesh[v.x].v < 0 and Dim2 == 0) then
        if s.x == r_sigb.bounds.hi.x then
          gsig = prx_sig[eR7].g
          bsig = prx_sig[eR7].b
          gsig2 = prx_sig2[eR8].g
          bsig2 = prx_sig2[eR8].b
          sC = prx_mesh[eR3].dx
        else
          gsig = r_sig[eR7].g
          bsig = r_sig[eR7].b
          gsig2 = r_sig2[eR8].g
          bsig2 = r_sig2[eR8].b
          sC = r_mesh[eR3].dx
        end
        swap = -1 -- If v < 0, then interpolating from the right requires a minus sign grad*dx
      else
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
        gsig2 = r_sig2[e8].g
        bsig2 = r_sig2[e8].b
        sC = r_mesh[e3].dx
      end
 
      -- Interpolate Gradient to Boundary
      r_sigb[e8].g = gsig + swap*(sC/2.0)*gsig2
      r_sigb[e8].b = bsig + swap*(sC/2.0)*bsig2
      
    end
  end
end

-- sigz at x-boundary
task Step1b_sigz_x2(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_sigb : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            prx_mesh : region(ispace(int8d), mesh),
            prx_sig : region(ispace(int8d), grid),
            prx_sig2 : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_sig2, r_mesh, vxmesh, vymesh, vzmesh, prx_mesh, prx_sig, prx_sig2),
  reads writes(r_sigb)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  var Dim : int32 = 2
  var Dim2 : int32 = 0

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double
 
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32
  
  var e3 : int8d
  var e7 : int8d
  var e8 : int8d
  var eR3 : int8d
  var eR7 : int8d
  var eR8 : int8d
 
  var gsig : double
  var bsig : double
  var gsig2 : double
  var bsig2 : double
  var swap : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    sC = r_mesh[e3].dx

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
      eR8 = {IR, JR, KR, Dim, Dim2, v.x, v.y, v.z}
  
      -- If v < 0, gather right values 
      -- otherwise, use cell center values
      swap = 1.0
      if (vxmesh[v.x].v < 0 and Dim2 == 0) then
        if s.x == r_sigb.bounds.hi.x then
          gsig = prx_sig[eR7].g
          bsig = prx_sig[eR7].b
          gsig2 = prx_sig2[eR8].g
          bsig2 = prx_sig2[eR8].b
          sC = prx_mesh[eR3].dx
        else
          gsig = r_sig[eR7].g
          bsig = r_sig[eR7].b
          gsig2 = r_sig2[eR8].g
          bsig2 = r_sig2[eR8].b
          sC = r_mesh[eR3].dx
        end
        swap = -1 -- If v < 0, then interpolating from the right requires a minus sign grad*dx
      else
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
        gsig2 = r_sig2[e8].g
        bsig2 = r_sig2[e8].b
        sC = r_mesh[e3].dx
      end
 
      -- Interpolate Gradient to Boundary
      r_sigb[e8].g = gsig + swap*(sC/2.0)*gsig2
      r_sigb[e8].b = bsig + swap*(sC/2.0)*bsig2
      
    end
  end
end

-- sigx at y-boundary
task Step1b_sigx_y2(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_sigb : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            pry_mesh : region(ispace(int8d), mesh),
            pry_sig : region(ispace(int8d), grid),
            pry_sig2 : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_sig2, r_mesh, vxmesh, vymesh, vzmesh, pry_mesh, pry_sig, pry_sig2),
  reads writes(r_sigb)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  var Dim : int32 = 0
  var Dim2 : int32 = 1

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double
 
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32
  
  var e3 : int8d
  var e7 : int8d
  var e8 : int8d
  var eR3 : int8d
  var eR7 : int8d
  var eR8 : int8d
 
  var gsig : double
  var bsig : double
  var gsig2 : double
  var bsig2 : double
  var swap : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    sC = r_mesh[e3].dy

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
      eR8 = {IR, JR, KR, Dim, Dim2, v.x, v.y, v.z}
  
      -- If v < 0, gather right values 
      -- otherwise, use cell center values
      swap = 1.0
      if (vymesh[v.y].v < 0 and Dim2 == 1) then
        if s.y == r_sigb.bounds.hi.y then
          gsig = pry_sig[eR7].g
          bsig = pry_sig[eR7].b
          gsig2 = pry_sig2[eR8].g
          bsig2 = pry_sig2[eR8].b
          sC = pry_mesh[eR3].dy
        else
          gsig = r_sig[eR7].g
          bsig = r_sig[eR7].b
          gsig2 = r_sig2[eR8].g
          bsig2 = r_sig2[eR8].b
          sC = r_mesh[eR3].dy
        end
        swap = -1 -- If v < 0, then interpolating from the right requires a minus sign grad*dx
      else
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
        gsig2 = r_sig2[e8].g
        bsig2 = r_sig2[e8].b
        sC = r_mesh[e3].dy
      end
 
      -- Interpolate Gradient to Boundary
      r_sigb[e8].g = gsig + swap*(sC/2.0)*gsig2
      r_sigb[e8].b = bsig + swap*(sC/2.0)*bsig2
      
    end
  end
end

-- sigy at y-boundary
task Step1b_sigy_y2(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_sigb : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            pry_mesh : region(ispace(int8d), mesh),
            pry_sig : region(ispace(int8d), grid),
            pry_sig2 : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_sig2, r_mesh, vxmesh, vymesh, vzmesh, pry_mesh, pry_sig, pry_sig2),
  reads writes(r_sigb)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  var Dim : int32 = 1
  var Dim2 : int32 = 1

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double
 
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32
  
  var e3 : int8d
  var e7 : int8d
  var e8 : int8d
  var eR3 : int8d
  var eR7 : int8d
  var eR8 : int8d
 
  var gsig : double
  var bsig : double
  var gsig2 : double
  var bsig2 : double
  var swap : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    sC = r_mesh[e3].dy

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
      eR8 = {IR, JR, KR, Dim, Dim2, v.x, v.y, v.z}
  
      -- If v < 0, gather right values 
      -- otherwise, use cell center values
      swap = 1.0
      if (vymesh[v.y].v < 0 and Dim2 == 1) then
        if s.y == r_sigb.bounds.hi.y then
          gsig = pry_sig[eR7].g
          bsig = pry_sig[eR7].b
          gsig2 = pry_sig2[eR8].g
          bsig2 = pry_sig2[eR8].b
          sC = pry_mesh[eR3].dy
        else
          gsig = r_sig[eR7].g
          bsig = r_sig[eR7].b
          gsig2 = r_sig2[eR8].g
          bsig2 = r_sig2[eR8].b
          sC = r_mesh[eR3].dy
        end
        swap = -1 -- If v < 0, then interpolating from the right requires a minus sign grad*dx
      else
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
        gsig2 = r_sig2[e8].g
        bsig2 = r_sig2[e8].b
        sC = r_mesh[e3].dy
      end

      -- Interpolate Gradient to Boundary
      r_sigb[e8].g = gsig + swap*(sC/2.0)*gsig2
      r_sigb[e8].b = bsig + swap*(sC/2.0)*bsig2
      
    end
  end
end

-- sigz at y-boundary
task Step1b_sigz_y2(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_sigb : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            pry_mesh : region(ispace(int8d), mesh),
            pry_sig : region(ispace(int8d), grid),
            pry_sig2 : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_sig2, r_mesh, vxmesh, vymesh, vzmesh, pry_mesh, pry_sig, pry_sig2),
  reads writes(r_sigb)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  var Dim : int32 = 2
  var Dim2 : int32 = 1

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double
 
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32
  
  var e3 : int8d
  var e7 : int8d
  var e8 : int8d
  var eR3 : int8d
  var eR7 : int8d
  var eR8 : int8d
 
  var gsig : double
  var bsig : double
  var gsig2 : double
  var bsig2 : double
  var swap : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    sC = r_mesh[e3].dy

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
      eR8 = {IR, JR, KR, Dim, Dim2, v.x, v.y, v.z}
  
      -- If v < 0, gather right values 
      -- otherwise, use cell center values
      swap = 1.0
      if (vymesh[v.y].v < 0 and Dim2 == 1) then
        if s.y == r_sigb.bounds.hi.y then
          gsig = pry_sig[eR7].g
          bsig = pry_sig[eR7].b
          gsig2 = pry_sig2[eR8].g
          bsig2 = pry_sig2[eR8].b
          sC = pry_mesh[eR3].dy
        else
          gsig = r_sig[eR7].g
          bsig = r_sig[eR7].b
          gsig2 = r_sig2[eR8].g
          bsig2 = r_sig2[eR8].b
          sC = r_mesh[eR3].dy
        end
        swap = -1 -- If v < 0, then interpolating from the right requires a minus sign grad*dx
      else
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
        gsig2 = r_sig2[e8].g
        bsig2 = r_sig2[e8].b
        sC = r_mesh[e3].dy
      end
 
      -- Interpolate Gradient to Boundary
      r_sigb[e8].g = gsig + swap*(sC/2.0)*gsig2
      r_sigb[e8].b = bsig + swap*(sC/2.0)*bsig2
      
    end
  end
end

-- sigx at z-boundary
task Step1b_sigx_z2(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_sigb : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            prz_mesh : region(ispace(int8d), mesh),
            prz_sig : region(ispace(int8d), grid),
            prz_sig2 : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_sig2, r_mesh, vxmesh, vymesh, vzmesh, prz_mesh, prz_sig, prz_sig2),
  reads writes(r_sigb)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  var Dim : int32 = 0
  var Dim2 : int32 = 2

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double
 
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32
  
  var e3 : int8d
  var e7 : int8d
  var e8 : int8d
  var eR3 : int8d
  var eR7 : int8d
  var eR8 : int8d
 
  var gsig : double
  var bsig : double
  var gsig2 : double
  var bsig2 : double
  var swap : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    sC = r_mesh[e3].dz

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
      eR8 = {IR, JR, KR, Dim, Dim2, v.x, v.y, v.z}
  
      -- If v < 0, gather right values 
      -- otherwise, use cell center values
      swap = 1.0
      if (vzmesh[v.z].v < 0 and Dim2 == 2) then
        if s.z == r_sigb.bounds.hi.z then
          gsig = prz_sig[eR7].g
          bsig = prz_sig[eR7].b
          gsig2 = prz_sig2[eR8].g
          bsig2 = prz_sig2[eR8].b
          sC = prz_mesh[eR3].dz
        else
          gsig = r_sig[eR7].g
          bsig = r_sig[eR7].b
          gsig2 = r_sig2[eR8].g
          bsig2 = r_sig2[eR8].b
          sC = r_mesh[eR3].dz
        end
        swap = -1 -- If v < 0, then interpolating from the right requires a minus sign grad*dx
      else
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
        gsig2 = r_sig2[e8].g
        bsig2 = r_sig2[e8].b
        sC = r_mesh[e3].dz
      end
 
      -- Interpolating Gradient to Boundary
      r_sigb[e8].g = gsig + swap*(sC/2.0)*gsig2
      r_sigb[e8].b = bsig + swap*(sC/2.0)*bsig2
      
    end
  end
end

-- sigy at z-boundary
task Step1b_sigy_z2(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_sigb : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            prz_mesh : region(ispace(int8d), mesh),
            prz_sig : region(ispace(int8d), grid),
            prz_sig2 : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_sig2, r_mesh, vxmesh, vymesh, vzmesh, prz_mesh, prz_sig, prz_sig2),
  reads writes(r_sigb)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  var Dim : int32 = 1
  var Dim2 : int32 = 2

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double
 
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32
  
  var e3 : int8d
  var e7 : int8d
  var e8 : int8d
  var eR3 : int8d
  var eR7 : int8d
  var eR8 : int8d
 
  var gsig : double
  var bsig : double
  var gsig2 : double
  var bsig2 : double
  var swap : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    sC = r_mesh[e3].dz

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
      eR8 = {IR, JR, KR, Dim, Dim2, v.x, v.y, v.z}
  
      -- If v < 0, gather right values 
      -- otherwise, use cell center values
      swap = 1.0
      if (vzmesh[v.z].v < 0 and Dim2 == 2) then
        if s.z == r_sigb.bounds.hi.z then
          gsig = prz_sig[eR7].g
          bsig = prz_sig[eR7].b
          gsig2 = prz_sig2[eR8].g
          bsig2 = prz_sig2[eR8].b
          sC = prz_mesh[eR3].dz
        else
          gsig = r_sig[eR7].g
          bsig = r_sig[eR7].b
          gsig2 = r_sig2[eR8].g
          bsig2 = r_sig2[eR8].b
          sC = r_mesh[eR3].dz
        end
        swap = -1 -- If v < 0, then interpolating from the right requires a minus sign grad*dx
      else
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
        gsig2 = r_sig2[e8].g
        bsig2 = r_sig2[e8].b
        sC = r_mesh[e3].dz
      end
 
      -- Interpolate Gradient to Boundary
      r_sigb[e8].g = gsig + swap*(sC/2.0)*gsig2
      r_sigb[e8].b = bsig + swap*(sC/2.0)*bsig2
      
    end
  end
end

-- sigz at z-boundary
task Step1b_sigz_z2(r_sig : region(ispace(int8d), grid),
            r_sig2 : region(ispace(int8d), grid),
            r_sigb : region(ispace(int8d), grid),
            r_mesh : region(ispace(int8d), mesh),
            prz_mesh : region(ispace(int8d), mesh),
            prz_sig : region(ispace(int8d), grid),
            prz_sig2 : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            BCs : int32[6], N : int32[3])
where
  reads(r_sig, r_sig2, r_mesh, vxmesh, vymesh, vzmesh, prz_mesh, prz_sig, prz_sig2),
  reads writes(r_sigb)
do
  -- Dim  is vector component that is being interpolated.
  -- Dim2 is direction of interpolation.
  var Dim : int32 = 2
  var Dim2 : int32 = 2

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double
 
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32
  
  var e3 : int8d
  var e7 : int8d
  var e8 : int8d
  var eR3 : int8d
  var eR7 : int8d
  var eR8 : int8d
 
  var gsig : double
  var bsig : double
  var gsig2 : double
  var bsig2 : double
  var swap : double

  for s in s3 do
    
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}
    sC = r_mesh[e3].dz

    -- Gather Left and Right Indices
    bc = BC(s.x, s.y, s.z, Dim2, BCs, N)
    IR = bc[3]
    JR = bc[4]
    KR = bc[5]
    eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

    for v in v3 do

      e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
      e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}
      eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}
      eR8 = {IR, JR, KR, Dim, Dim2, v.x, v.y, v.z}

      -- If v < 0, gather right values 
      -- otherwise, use cell center values
      swap = 1.0
      if (vzmesh[v.z].v < 0 and Dim2 == 2) then
        if s.z == r_sigb.bounds.hi.z then
          gsig = prz_sig[eR7].g
          bsig = prz_sig[eR7].b
          gsig2 = prz_sig2[eR8].g
          bsig2 = prz_sig2[eR8].b
          sC = prz_mesh[eR3].dz
        else
          gsig = r_sig[eR7].g
          bsig = r_sig[eR7].b
          gsig2 = r_sig2[eR8].g
          bsig2 = r_sig2[eR8].b
          sC = r_mesh[eR3].dz
        end
        swap = -1 -- If v < 0, then interpolating from the right requires a minus sign grad*dx
      else
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
        gsig2 = r_sig2[e8].g
        bsig2 = r_sig2[e8].b
        sC = r_mesh[e3].dz
      end

      -- Interpolate Gradient to Boundary
      r_sigb[e8].g = gsig + swap*(sC/2.0)*gsig2
      r_sigb[e8].b = bsig + swap*(sC/2.0)*bsig2
      
    end
  end
end

-- Now that we have gradients at cell center and at boundary,
-- several things are computed.
-- First, interpolate phibarplus to boundary.
task Step1b_b(r_sig : region(ispace(int8d), grid),
              r_mesh : region(ispace(int8d), mesh),
              r_gridbarp : region(ispace(int8d), grid),
              r_gridbarpb : region(ispace(int8d), grid),
              prx_gridbarp : region(ispace(int8d), grid),
              pry_gridbarp : region(ispace(int8d), grid),
              prz_gridbarp : region(ispace(int8d), grid),
              prx_sig : region(ispace(int8d), grid),
              pry_sig : region(ispace(int8d), grid),
              prz_sig : region(ispace(int8d), grid),
          prx_mesh : region(ispace(int8d), mesh),
          pry_mesh : region(ispace(int8d), mesh),
          prz_mesh : region(ispace(int8d), mesh),
              vxmesh : region(ispace(int1d), vmesh),
              vymesh : region(ispace(int1d), vmesh),
              vzmesh : region(ispace(int1d), vmesh),
              BCs : int32[6], N : int32[3], effD : int32)
where
  reads writes(r_gridbarpb),
  reads(r_sig, r_gridbarp, r_mesh.{dx,dy,dz}, vxmesh, vymesh, vzmesh),
  reads(prx_gridbarp, pry_gridbarp, prz_gridbarp, prx_sig, pry_sig, prz_sig, prx_mesh.dx, pry_mesh.dy, prz_mesh.dz)
do

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var sC : double[3]
  
  var bc : int32[6]
  var IR : int32
  var JR : int32
  var KR : int32

  var e3 : int8d
  var e6 : int8d
  var e7 : int8d
  var eR3 : int8d
  var eR6 : int8d
  var eR7 : int8d

  var swap : double
  var gb : double
  var bb : double
  var gsig : double
  var bsig : double

  for s in s3 do

    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}

    for Dim = 0, effD do

      -- Gather Right Indices
      bc = BC(s.x, s.y, s.z, Dim, BCs, N)
      IR = bc[3]
      JR = bc[4]
      KR = bc[5]
      eR3 = {IR, JR, KR, 0, 0, 0, 0, 0}

      for v in v3 do      

        e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z}
        e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}

        -- Gather Right Indices 
        eR6 = {IR, JR, KR, 0, 0, v.x, v.y, v.z}
        eR7 = {IR, JR, KR, Dim, 0, v.x, v.y, v.z}

        -- Dot Product is just a single product when using rectangular mesh
        swap = 1.0
        gb = r_gridbarp[e6].g
        bb = r_gridbarp[e6].b
        gsig = r_sig[e7].g
        bsig = r_sig[e7].b
      
        sC[0] = r_mesh[e3].dx
        sC[1] = r_mesh[e3].dy
        sC[2] = r_mesh[e3].dz

        -- If v < 0, gather right values 
        -- otherwise, use cell center values
        if (vxmesh[v.x].v < 0 and Dim == 0) then
          swap = -1 -- need minus sign when interpolating from right
          if s.x == r_mesh.bounds.hi.x then
            gsig = prx_sig[eR7].g
            bsig = prx_sig[eR7].b
            gb = prx_gridbarp[eR6].g
            bb = prx_gridbarp[eR6].b
            sC[Dim] = prx_mesh[eR3].dx
           else
            gsig = r_sig[eR7].g
            bsig = r_sig[eR7].b
            gb = r_gridbarp[eR6].g
            bb = r_gridbarp[eR6].b
            sC[Dim] = r_mesh[eR3].dx
           end
        elseif (vymesh[v.y].v < 0 and Dim == 1) then
          swap = -1
          if s.y == r_mesh.bounds.hi.y then
            gsig = pry_sig[eR7].g
            bsig = pry_sig[eR7].b
            gb = pry_gridbarp[eR6].g
            bb = pry_gridbarp[eR6].b
            sC[Dim] = pry_mesh[eR3].dy
          else
            gsig = r_sig[eR7].g
            bsig = r_sig[eR7].b
            gb = r_gridbarp[eR6].g
            bb = r_gridbarp[eR6].b
            sC[Dim] = r_mesh[eR3].dy
          end
        elseif (vzmesh[v.z].v < 0 and Dim == 2) then
          swap = -1
          if s.z == r_mesh.bounds.hi.z then
            gsig = prz_sig[eR7].g
            bsig = prz_sig[eR7].b
            gb = prz_gridbarp[eR6].g
            bb = prz_gridbarp[eR6].b
            sC[Dim] = prz_mesh[eR3].dz
          else
            gsig = r_sig[eR7].g
            bsig = r_sig[eR7].b
            gb = r_gridbarp[eR6].g
            bb = r_gridbarp[eR6].b
            sC[Dim] = r_mesh[eR3].dz
          end
        end
     
        -- Interpolate gridbarplus to Boundary
        r_gridbarpb[e7].g = gb + swap*sC[Dim]/2.0*gsig 
        r_gridbarpb[e7].b = bb + swap*sC[Dim]/2.0*bsig

      end
    end 
  end
end

-- Now use gradient at boundary to compute gridbarplus at velocity dependent location
-- 
-- Step 1c: Compute phibar at interface in velocity dependent location, x-Xi*dt/2
-- 
-- Note: Memory is being recycled, i.e. the gridbarpb region originally used to
-- store phibarplus is now being used to store phibar
task Step1c(r_gridbarpb : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),        
            vymesh : region(ispace(int1d), vmesh),        
            vzmesh : region(ispace(int1d), vmesh),        
            r_sigb : region(ispace(int8d), grid),
            dt : double, BCs : int32[6],  N : int32[3], effD : int32)
where
  reads(vxmesh, vymesh, vzmesh, r_sigb), 
  reads writes(r_gridbarpb)
do     
  -- Declaration for velocity vector
  var Xi : double[3]
  
  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_gridbarpb.bounds.lo.x, r_gridbarpb.bounds.lo.y, r_gridbarpb.bounds.lo.z}
  var shi : int3d = {r_gridbarpb.bounds.hi.x, r_gridbarpb.bounds.hi.y, r_gridbarpb.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var e7 : int8d
  var e8 : int8d

  for v in v3 do
    Xi[0] = vxmesh[v.x].v
    Xi[1] = vymesh[v.y].v
    Xi[2] = vzmesh[v.z].v

    for s in s3 do
      for Dim = 0, effD do
        for Dim2 = 0, effD do

          -- Gather Indices
          e7 = {s.x, s.y, s.z, Dim2, 0, v.x, v.y, v.z}
          e8 = {s.x, s.y, s.z, Dim, Dim2, v.x, v.y, v.z}

          -- Interpolate gridbarplus from boundary to velocity dependent location
          r_gridbarpb[e7].g = r_gridbarpb[e7].g - dt/2.0*Xi[Dim]*r_sigb[e8].g
          r_gridbarpb[e7].b = r_gridbarpb[e7].b - dt/2.0*Xi[Dim]*r_sigb[e8].b
    
          regentlib.assert(not [bool](isnan(r_gridbarpb[e7].g)), "Step 1c\n")
          regentlib.assert(not [bool](isnan(r_gridbarpb[e7].b)), "Step 1c\n")
        
        end 
      end 
    end
  end 
end

--Step 2: Microflux
--Step 2a: Compute W at interface.
task Step2a(r_gridbarpb : region(ispace(int8d), grid),
            vxmesh : region(ispace(int1d), vmesh),
            vymesh : region(ispace(int1d), vmesh),
            vzmesh : region(ispace(int1d), vmesh),
            r_Wb   : region(ispace(int8d), W),
            dt : double, effD : int32)
where
  reads(r_gridbarpb, vxmesh, vymesh, vzmesh),
  reads writes(r_Wb)
do    
  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_Wb.bounds.lo.x, r_Wb.bounds.lo.y, r_Wb.bounds.lo.z}
  var shi : int3d = {r_Wb.bounds.hi.x, r_Wb.bounds.hi.y, r_Wb.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  var e4 : int8d
  var e7 : int8d

  -- First compute density at boundary; density is needed for others.
  -- Initialize with zero, then iterate over contributions in velocity space
  for s in s3 do
    for Dim = 0, effD do
      e4 = {s.x, s.y, s.z, Dim, 0, 0, 0, 0}
      r_Wb[e4].rho = 0

      -- Add up all phase space contributions to density
      -- Fourth Order Newton Cotes
      for v in v3 do
        e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
        r_Wb[e4].rho = r_Wb[e4].rho + vxmesh[v.x].w*vymesh[v.y].w*vzmesh[v.z].w*r_gridbarpb[e7].g
      end
    end
  end
      
  -- Then compute momentum and energy
  -- Initialize, then iterate over contributions in velocity space
  var U : double[3]
  for s in s3 do
    for Dim = 0, effD do

      e4 = {s.x, s.y, s.z, Dim, 0, 0, 0, 0} 

      -- Initialization is not zero when external acceleration != 0, since this is not phi but rather phibar 
      for d = 0, effD do
        r_Wb[e4].rhov[d] = dt/2.0*r_Wb[e4].rho*0 -- TODO: In future, replace 0 with acceleration field 
      end
      r_Wb[e4].rhoE = dt/2.*r_Wb[e4].rho*0 -- TODO: In future replace 0 with u.dot(a), vel dot acc

      for v in v3 do

        U[0] = vxmesh[v.x].v
        U[1] = vymesh[v.y].v
        U[2] = vzmesh[v.z].v
 

        e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}    

        -- Add up all phase space contributions to momentum and energy
        -- Fourth Order Newton Cotes
        for d = 0, effD do
          r_Wb[e4].rhov[d] = r_Wb[e4].rhov[d] + vxmesh[v.x].w*vymesh[v.y].w*vzmesh[v.z].w*U[d]*r_gridbarpb[e7].g 
        end
        r_Wb[e4].rhoE = r_Wb[e4].rhoE + vxmesh[v.x].w*vymesh[v.y].w*vzmesh[v.z].w*r_gridbarpb[e7].b

      end
    end
  end

  -- NaN checker
  for e in r_Wb do
    
    regentlib.assert(not [bool](isnan(r_Wb[e].rho)), "Step 2a rho\n")
    regentlib.assert(not [bool](isnan(r_Wb[e].rhov[0])), "Step 2a rhov0\n")
    regentlib.assert(not [bool](isnan(r_Wb[e].rhov[1])), "Step 2a rhov1\n")
    regentlib.assert(not [bool](isnan(r_Wb[e].rhov[2])), "Step 2a rhov2\n")
    regentlib.assert(not [bool](isnan(r_Wb[e].rhoE)), "Step 2a rhoE\n")
    
  end

end

-- Step 2b: compute original phi at interface using gbar, W at interface
-- Note: Memory is being recycled, i.e. the gridbarpb region originally used to
-- store phibarplus is now being used to store phibar
task Step2b(r_gridbarpb : region(ispace(int8d), grid), 
            r_Wb      : region(ispace(int8d), W),
            vxmesh    : region(ispace(int1d), vmesh),
            vymesh    : region(ispace(int1d), vmesh),
            vzmesh    : region(ispace(int1d), vmesh),
            dt : double, R : double, K : double, Cv : double, g : double,
            w : double, ur : double, Tr : double, Pr : double, effD : int32,
            thermal_bath : bool, thermal_T : double)
where
  reads writes(r_gridbarpb),
  reads(r_Wb, vxmesh, vymesh, vzmesh)
do
  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_Wb.bounds.lo.x, r_Wb.bounds.lo.y, r_Wb.bounds.lo.z}
  var shi : int3d = {r_Wb.bounds.hi.x, r_Wb.bounds.hi.y, r_Wb.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)
  
  var tg : double      -- tau_g
  var tb : double      -- tau_b
  var u : double       -- Bulk Velocity
  var T : double       -- Temperature
  var Xi : double[3]   -- Velocity Vector
  var c2 : double      -- Peculiar Velocity squared

  -- Equilibrium Distributions
  var g_eq : double
  var b_eq : double

  -- Indices
  var e3 : int8d
  var e4 : int8d
  var e7 : int8d

  for s in s3 do

    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}

    for Dim = 0, effD do

      e4 = {s.x, s.y, s.z, Dim, 0, 0, 0, 0}

      -- Compute Bulk Velocity
      u = 0 
      for d = 0, effD do
        u = u + r_Wb[e4].rhov[d]/r_Wb[e4].rho*r_Wb[e4].rhov[d]/r_Wb[e4].rho
      end
      u = sqrt(u)
      
      -- Compute Temeprature
      T = Temperature(r_Wb[e4].rhoE/r_Wb[e4].rho, u, g, R)
      if T < 0 then
        -- Stop Simulation if Negative Temperature
        c.printf("T < 0, r_Wb[{%d, %d, %d, %d}].rhoE = %f, r_Wb[e4].rho = %f, u = %f, g = %f, R = %f\n", e4.x, e4.y, e4.z, e4.w, r_Wb[e4].rhoE, r_Wb[e4].rho, u, g, R)
        regentlib.assert(T >= 0, "Negative Temperature\n")
      end

      -- Compute Relaxation Times
      tg = visc(T, ur, Tr, w)/r_Wb[e4].rho/R/T
      tb = tg/Pr

      for v in v3 do

        e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}

        Xi[0] = vxmesh[v.x].v
        Xi[1] = vymesh[v.y].v
        Xi[2] = vzmesh[v.z].v

        -- Compute Peculiar Velocity squared
        c2 = 0
        for d = 0, effD do
          c2 =  c2 + (Xi[d] - r_Wb[e4].rhov[d]/r_Wb[e4].rho)*(Xi[d] - r_Wb[e4].rhov[d]/r_Wb[e4].rho)
        end

        -- Compute Equilibrium Distributions
        if thermal_bath then
          g_eq = geq(c2, r_Wb[e4].rho, thermal_T, R, effD)
          b_eq = g_eq*(Xi[0]*Xi[0] + Xi[1]*Xi[1] + Xi[2]*Xi[2] + (3.0-effD+K)*R*thermal_T)/2.0
        else
          g_eq = geq(c2, r_Wb[e4].rho, T, R, effD)
          b_eq = g_eq*(Xi[0]*Xi[0] + Xi[1]*Xi[1] + Xi[2]*Xi[2] + (3.0-effD+K)*R*T)/2.0
        end

        if (isnan(g_eq) == 1 or isnan(b_eq) == 1) then

          c.printf("c2 = %f, r_Wb[e4].rho = %f, T = %f, R = %f, effD = %d\n", c2, r_Wb[e4].rho, T, R, effD) 
      
          regentlib.assert(not  [bool](isnan(g_eq)), "Step 2b: g_eq\n")
          regentlib.assert(not  [bool](isnan(b_eq)), "Step 2b: b_eq\n")
    
        end

        -- Compute phi from phibar
        -- Recall: this is actually the original distribution function, recycling memory from gbar/bbar
        r_gridbarpb[e7].g = 2*tg/(2*tg + dt/2.)*r_gridbarpb[e7].g + dt/(4*tg + dt)*g_eq + dt*tg/(4*tg + dt)*0 -- TODO replace this last *0 with source term 
        r_gridbarpb[e7].b = 2*tb/(2*tb + dt/2.)*r_gridbarpb[e7].b + dt/(4*tb + dt)*b_eq + dt*tb/(4*tb + dt)*0 -- TODO replace this last *0 with source term

        if (isnan(r_gridbarpb[e7].g) == 1 or isnan(r_gridbarpb[e7].b) == 1) then

          c.printf("gbar = %.10f, bbar = %.10f, g_eq = %.10f, tg = %.10f, tb = %.10f\n", r_gridbarpb[e7].g, r_gridbarpb[e7].b, g_eq, tg, tb)
      
          regentlib.assert(not [bool](isnan(r_gridbarpb[e7].g)), "Step 2b: gridbarpb_g\n")
          regentlib.assert(not [bool](isnan(r_gridbarpb[e7].b)), "Step 2b: gridbarpb_b\n")
    
        end

      end
    end 
  end
end

-- Now that we have phi at the interface, we can compute the flux ~ phi * Xi * Area
-- Step 2c: Compute Microflux F at interface at half timestep using W/phi at interface.
task Step2c(r_gridbarpb : region(ispace(int8d), grid),
            r_F       : region(ispace(int8d), grid),
            r_mesh    : region(ispace(int8d), mesh),
            vxmesh    : region(ispace(int1d), vmesh),
            vymesh    : region(ispace(int1d), vmesh),
            vzmesh    : region(ispace(int1d), vmesh),
            plx_gridbarpb : region(ispace(int8d), grid),
            ply_gridbarpb : region(ispace(int8d), grid),
            plz_gridbarpb : region(ispace(int8d), grid),
            BCs : int32[6], R : double, K : double, Cv : double, g : double,
            w : double, Tr : double, Pr : double, effD : int32, N : int32[3])
where
  reads(r_gridbarpb, vxmesh, vymesh, vzmesh, r_mesh, plx_gridbarpb, ply_gridbarpb, plz_gridbarpb),
  reads writes(r_F)
do    
  var A : double[3]   -- Area of particular cell face
  var Xi : double[3]  -- Velocity Vector

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_mesh.bounds.lo.x, r_mesh.bounds.lo.y, r_mesh.bounds.lo.z}
  var shi : int3d = {r_mesh.bounds.hi.x, r_mesh.bounds.hi.y, r_mesh.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var e3 : int8d
  var e7 : int8d 
  var e6 : int8d 
  var eL7 : int8d

  -- Left and Right Indices
  var bc : int32[6]
  var IL : int32
  var JL : int32
  var KL : int32
  var IR : int32
  var JK : int32
  var KR : int32

  -- (pseudo)Booleans for Boundary Conditions
  var right : double = 1.0 
  var left : double = 1.0

  -- Declarations for distributions on left face
  var gL : double
  var bL : double

  for s in s3 do
    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}

    -- Area for rectangular mesh
    A[0] = r_mesh[e3].dy*r_mesh[e3].dz
    A[1] = r_mesh[e3].dx*r_mesh[e3].dz
    A[2] = r_mesh[e3].dx*r_mesh[e3].dy


    for Dim = 0, effD do

      -- Gather Left and Right Indices
      bc = BC(s.x, s.y, s.z, Dim, BCs, N)
      IL = bc[0]
      JL = bc[1]
      KL = bc[2]
      IR = bc[3]
      JK = bc[4]
      KR = bc[5]

      -- Periodic & Outflow Boundary Conditions
      -- and also default non-boundary case
      right = 1.0 
      left = 1.0

      -- Dirichlet Boundary Conditions
      -- No flux means no update
      if (Dim == 0 and BCs[0] == 1 and (s.x == 0 or s.x == N[0] - 1)) then
        left = 0
        right = 0
      end 
      if (Dim == 1 and BCs[1] == 1 and (s.y == 0 or s.y == N[1] - 1)) then
        left = 0
        right = 0
      end
      if (Dim == 2 and BCs[2] == 1 and (s.z == 0 or s.z == N[2] - 1)) then
        left = 0
        right = 0
      end

      for v in v3 do 

        -- Gather Left Indices
        e7 = {s.x, s.y, s.z, Dim, 0, v.x, v.y, v.z}
        e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z}
        eL7 = {IL, JL, KL, Dim, 0, v.x, v.y, v.z}

        -- Fill in Velocity Vector
        Xi[0] = vxmesh[v.x].v
        Xi[1] = vymesh[v.y].v
        Xi[2] = vzmesh[v.z].v
  
        -- Gather Left Values
        if Dim == 0 then
          if s.x == s3.bounds.lo.x then
            gL = plx_gridbarpb[eL7].g
            bL = plx_gridbarpb[eL7].b
          else
            gL = r_gridbarpb[eL7].g
            bL = r_gridbarpb[eL7].b
          end
        end

        if Dim == 1 then
          if s.y == s3.bounds.lo.y then
            gL = ply_gridbarpb[eL7].g
            bL = ply_gridbarpb[eL7].b
          else
            gL = r_gridbarpb[eL7].g
            bL = r_gridbarpb[eL7].b
          end
        end

        if Dim == 2 then
          if s.z == s3.bounds.lo.z then
            gL = plz_gridbarpb[eL7].g
            bL = plz_gridbarpb[eL7].b
          else
            gL = r_gridbarpb[eL7].g
            bL = r_gridbarpb[eL7].b
          end
        end

        -- Compute Flux  
        r_F[e6].g = r_F[e6].g + Xi[Dim]*A[Dim]*(right*r_gridbarpb[e7].g - left*gL)
        r_F[e6].b = r_F[e6].b + Xi[Dim]*A[Dim]*(right*r_gridbarpb[e7].b - left*bL)

        regentlib.assert(not [bool](isnan(r_F[e6].g)), "Step 2c\n")
        regentlib.assert(not [bool](isnan(r_F[e6].b)), "Step 2c\n")

      end 
    end
  end 
end

task Step3()
 -- TODO : External Forces
end

-- Step 4: Update conservative variables W at cell center at next timestep
-- Step 5: Update phi at cell center at next time step
-- Note: Updating phi was broken up into two steps for easier readability.
-- The two steps involve new and old quantities, respectively.
task Step4and5(r_grid : region(ispace(int8d), grid),
               r_W    : region(ispace(int8d), W),
               r_mesh : region(ispace(int8d), mesh),
               r_F    : region(ispace(int8d), grid),
               r_S    : region(ispace(int8d), grid),
               vxmesh : region(ispace(int1d), vmesh),
               vymesh : region(ispace(int1d), vmesh),
               vzmesh : region(ispace(int1d), vmesh),
               dt : double, BCs : int32[6], R : double, K : double, Cv : double, N : int32[3],
               g : double, w : double, ur : double, Tr : double, Pr : double, effD : int32,
               thermal_bath : bool, thermal_T : double)
where
  reads(vxmesh, vymesh, vzmesh, r_mesh, r_F, r_S),
  reads writes(r_W, r_grid)
do
  var V : double      -- Volume of Cell
  var Xi : double[3]  -- Discrete Velocity 
  var uo : double     -- Old Flow Velocity
  var To : double     -- Old Temperature
  var tgo : double    -- Old tau_g
  var tbo : double    -- Old tau_b
  var u : double      -- New Flow Velocity
  var T : double      -- New Temperature 
  var tg : double     -- New tau_g
  var tb : double     -- New tau_b
  var c2 : double     -- Peculiar Velocity squared

  -- Equilibrium Distributions
  -- New & Old
  var g_eq : double   
  var b_eq : double
  var g_eqo : double
  var b_eqo : double

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_F.bounds.lo.x, r_F.bounds.lo.y, r_F.bounds.lo.z}
  var shi : int3d = {r_F.bounds.hi.x, r_F.bounds.hi.y, r_F.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  -- Indices
  var e3 : int8d 
  var e6 : int8d 
  var i : int32
  var j : int32
  var k : int32

  for s in s3 do

    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}

    -- Compute Volume
    V = r_mesh[e3].dx*r_mesh[e3].dy*r_mesh[e3].dz

    -- Compute Old Bulk Velocity
    uo = 0
    for d = 0, effD do
      uo += r_W[e3].rhov[d]/r_W[e3].rho*r_W[e3].rhov[d]/r_W[e3].rho
    end
    uo = sqrt(uo)
    regentlib.assert(bool(uo>=0), "uo")

    -- Compute Old Temperature
    To = Temperature(r_W[e3].rhoE/r_W[e3].rho, uo, g, R)
    regentlib.assert(bool(To>=0), "To")
  
    -- Compute Old Timescales
    tgo = visc(To, ur, Tr, w)/r_W[e3].rho/R/To
    tbo = tgo/Pr 
  
    for v in v3 do 

      e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z}

      -- Fill in Velocity Vector
      Xi[0] = vxmesh[v.x].v
      Xi[1] = vymesh[v.y].v
      Xi[2] = vzmesh[v.z].v

      -- Compute Old Equilibrium Distributions
      -- Need squared Peculiar Velocity
      c2 = 0
      for d = 0, effD do
        c2 += (Xi[d]-r_W[e3].rhov[d]/r_W[e3].rho)*(Xi[d]-r_W[e3].rhov[d]/r_W[e3].rho)
      end
      if thermal_bath then
        g_eqo = geq(c2, r_W[e3].rho, thermal_T, R, effD)
        b_eqo = g_eqo*(Xi[0]*Xi[0] + Xi[1]*Xi[1] + Xi[2]*Xi[2] + (3.0-effD+K)*R*thermal_T)/2.0

        r_W[e3].rhoE = r_W[e3].rhoE - dt*(r_grid[e6].b - b_eqo)/tbo*vxmesh[v.x].w*vymesh[v.y].w*vzmesh[v.z].w   
      else
        g_eqo = geq(c2, r_W[e3].rho, To, R, effD)
        b_eqo = g_eqo*(Xi[0]*Xi[0] + Xi[1]*Xi[1] + Xi[2]*Xi[2] + (3.0-effD+K)*R*To)/2.0
      end

      -- First Update phi
      i = s.x
      j = s.y
      k = s.z

      -- Update First Step (terms involving oldW)
      if ((BCs[0] == 1 and i == 0) or (BCs[3] == 1 and i == N[0] - 1) or
          (BCs[1] == 1 and j == 0 and effD > 1) or (BCs[4] == 1 and j == N[1] - 1 and effD > 1) or
          (BCs[2] == 1 and k == 0 and effD > 2) or (BCs[5] == 1 and k == N[2] - 1 and effD > 2)) then
       
        -- Dirichlet Boundary Conditions: No Change
        --r_grid[e6].g = r_grid[e6].g
        --r_grid[e6].b = r_grid[e6].b

      else

        r_grid[e6].g = r_grid[e6].g + dt/2.0*(g_eqo-r_grid[e6].g)/tgo - dt/V*r_F[e6].g + dt*r_S[e6].g
        r_grid[e6].b = r_grid[e6].b + dt/2.0*(b_eqo-r_grid[e6].b)/tbo - dt/V*r_F[e6].b + dt*r_S[e6].b

      end

    end
  end

  -- Step 4: Update W at cell center
  for s in s3 do

    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}

    -- Momentum and Energy require Density
    -- Update Density first
    if ((BCs[0] == 1 and i == 0) or (BCs[3] == 1 and i == N[0] - 1) or
        (BCs[1] == 1 and j == 0 and effD > 1) or (BCs[4] == 1 and j == N[1] - 1 and effD > 1) or
        (BCs[2] == 1 and k == 0 and effD > 2) or (BCs[5] == 1 and k == N[2] - 1 and effD > 2)) then

      -- Dirichlet Boundary Conditions: No Change
      --r_W[e3].rho = r_W[e3].rho

    else   
    
      for v in v3 do 

        e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z}

        -- Fill in Velocity Vector
        Xi[0] = vxmesh[v.x].v
        Xi[1] = vymesh[v.y].v
        Xi[2] = vzmesh[v.z].v
        
        -- Add all phase space contributions to density, momentum, and energy
        r_W[e3].rho = r_W[e3].rho - dt*(r_F[e6].g/V - r_S[e6].g)*vxmesh[v.x].w*vymesh[v.y].w*vzmesh[v.z].w
        for d = 0, effD do
          r_W[e3].rhov[d] = r_W[e3].rhov[d] - dt*Xi[d]*(r_F[e6].g/V - r_S[e6].g)*vxmesh[v.x].w*vymesh[v.y].w*vzmesh[v.z].w
        end

        r_W[e3].rhoE = r_W[e3].rhoE - dt*(r_F[e6].b/V - r_S[e6].b)*vxmesh[v.x].w*vymesh[v.y].w*vzmesh[v.z].w   

      end
    end
  end     

  -- Second Update for phi at cell center using new tau/W

  for s in s3 do

    e3 = {s.x, s.y, s.z, 0, 0, 0, 0, 0}

    -- Compute New Bulk Velocity
    u = 0 
    for d = 0, effD do 
      u += r_W[e3].rhov[d]/r_W[e3].rho*r_W[e3].rhov[d]/r_W[e3].rho
    end
    u = sqrt(u)
    regentlib.assert(bool(u>=0), "u")

    -- Compute New Temperature
    T = Temperature(r_W[e3].rhoE/r_W[e3].rho, u, g, R)
    if T < 0 then
      -- Stop Simulation if Negative Temperature
      c.printf("r_W[%d].rhoE = %f, r_W[e3].rho = %f, u = %f, g = %f, R = %f\n", e3.x, r_W[e3].rhoE, r_W[e3].rho, u, g, R)
    end
    regentlib.assert(bool(T>=0), "T")

    -- Compute New Taus
    tg = visc(T, ur, Tr, w)/r_W[e3].rho/R/T 
    tb = tg/Pr 

    -- When using a thermal bath, energy is not conserved.
    -- Must recompute energy.

    for v in v3 do
      Xi[0] = vxmesh[v.x].v
      Xi[1] = vymesh[v.y].v
      Xi[2] = vzmesh[v.z].v

      -- Compute New Equilibrium Distributions
      c2 = 0 
      for d = 0, effD do
        c2 += (Xi[d]-r_W[e3].rhov[d]/r_W[e3].rho)*(Xi[d]-r_W[e3].rhov[d]/r_W[e3].rho)
      end
      if thermal_bath then
        g_eq = geq(c2, r_W[e3].rho, thermal_T, R, effD)
        b_eq = g_eq*(Xi[0]*Xi[0] + Xi[1]*Xi[1] + Xi[2]*Xi[2] + (3.0-effD+K)*R*thermal_T)/2.0
      else
        g_eq = geq(c2, r_W[e3].rho, T, R, effD)
        b_eq = g_eq*(Xi[0]*Xi[0] + Xi[1]*Xi[1] + Xi[2]*Xi[2] + (3.0-effD+K)*R*T)/2.0
      end


      -- Second Update phi
      -- Terms involving new tau/W
      i = s.x
      j = s.y
      k = s.z
      e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z} 

      if ((BCs[0] == 1 and i == 0) or (BCs[3] == 1 and i == N[0] - 1) or
          (BCs[1] == 1 and j == 0 and effD > 1) or (BCs[4] == 1 and j == N[1] - 1 and effD > 1) or
          (BCs[2] == 1 and k == 0 and effD > 2) or (BCs[5] == 1 and k == N[2] - 1 and effD > 2)) then
                
        -- Dirichlet Boundary Condition: No Change
        --r_grid[e6].g = r_grid[e6].g
        --r_grid[e6].b = r_grid[e6].b

      else

        r_grid[e6].g = (r_grid[e6].g + dt/2.0*g_eq/tg)/(1+dt/2.0/tg)
        r_grid[e6].b = (r_grid[e6].b + dt/2.0*b_eq/tb)/(1+dt/2.0/tb)

      end

      if isnan(r_grid[e6].g) == 1 then
        c.printf("Step4and5: g_eq = %f, tg = %f, tgo = %f, r_F[e6].g = %f\n", g_eq, tg, tgo, r_F[e6].g)
      end 
      if isnan(r_grid[e6].b) == 1 then
        c.printf("Step4and5: b_eq = %f, tb = %f, tbo = %f, r_F[e6].b = %f\n", b_eq, tb, tbo, r_F[e6].b)
      end 
      regentlib.assert(not [bool](isnan(r_grid[e6].g)), "Step4and5\n")
      regentlib.assert(not [bool](isnan(r_grid[e6].b)), "Step4and5\n")
    end
  end

  -- Outflow Boundary Conditions
  -- Cells on the outer edge of the grid becomes ghost zones.
  for s in s3 do

    var e3 : int8d = {s.x, s.y, s.z, 0, 0, 0, 0, 0}

    -- Left x Edge
    if (BCs[0] == 2 and s.x == 0) then

      var e3R : int8d = {1, s.y, s.z, 0, 0, 0, 0, 0}
      var e3R2 : int8d = {2, s.y, s.z, 0, 0, 0, 0, 0}

      -- Three versions: copy, average, interpolate
      r_W[e3].rho = r_W[e3R].rho -- copy
      --r_W[e3].rho = (r_W[e3].rho + r_W[e3R].rho)/2 -- avg
      --r_W[e3].rho = 2*r_W[e3R].rho - r_W[e3R2].rho -- interp

      for d = 0, effD do
        r_W[e3].rhov[d] = r_W[e3R].rhov[d] -- copy
        --r_W[e3].rhov[d] = (r_W[e3].rhov[d] + r_W[e3R].rhov[d])/2 -- avg
        --r_W[e3].rhov[d] = 2*r_W[e3R].rhov[d]-r_W[e3R2].rhov[d] --interp
      end
      r_W[e3].rhoE = r_W[e3R].rhoE -- copy
      --r_W[e3].rhoE = (r_W[e3].rhoE + r_W[e3R].rhoE)/2 -- acerage
      --r_W[e3].rhoE = 2*r_W[e3R].rhoE-r_W[e3R2].rhoE -- interp

      for v in v3 do

        e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z} 
        var eR6 : int8d = {e3R.x, e3R.y, e3R.z, 0, 0, v.x, v.y, v.z}
        var eR62 : int8d = {e3R2.x, e3R2.y, e3R2.z, 0, 0, v.x, v.y, v.z}

        r_grid[e6].g = r_grid[eR6].g -- copy
        r_grid[e6].b = r_grid[eR6].b -- copy
        --r_grid[e6].g = (r_grid[e6].g + r_grid[eR6].g)/2 -- avg
        --r_grid[e6].b = (r_grid[e6].b + r_grid[eR6].b)/2 -- avg
        --r_grid[e6].g = 2*r_grid[eR6].g - r_grid[eR62].g -- interp
        --r_grid[e6].b = 2*r_grid[eR6].b - r_grid[eR62].b -- interp

      end        
    end

    -- Right x Edge
    if (BCs[3] == 2 and s.x == N[0] - 1) then

      var e3R : int8d = {s.x - 1, s.y, s.z, 0, 0, 0, 0, 0}
      var e3R2 : int8d = {s.x - 2, s.y, s.z, 0, 0, 0, 0, 0}

      r_W[e3].rho = r_W[e3R].rho -- copy
      --r_W[e3].rho = (r_W[e3].rho + r_W[e3R].rho)/2 -- avg
      --r_W[e3].rho = 2*r_W[e3R].rho - r_W[e3R2].rho -- interp
      for d = 0, effD do
        r_W[e3].rhov[d] = r_W[e3R].rhov[d] -- copy
        --r_W[e3].rhov[d] = (r_W[e3].rhov[d] + r_W[e3R].rhov[d])/2 -- avg
        --r_W[e3].rhov[d] = 2*r_W[e3R].rhov[d] - r_W[e3R2].rhov[d] -- interp
      end
      r_W[e3].rhoE = r_W[e3R].rhoE -- copy
      --r_W[e3].rhoE = (r_W[e3].rhoE + r_W[e3R].rhoE)/2 -- avg
      --r_W[e3].rhoE = 2*r_W[e3R].rhoE - r_W[e3R2].rhoE -- interp

      for v in v3 do

        e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z} 
        var eR6 : int8d = {e3R.x, e3R.y, e3R.z, 0, 0, v.x, v.y, v.z}
        var eR62 : int8d = {e3R2.x, e3R2.y, e3R2.z, 0, 0, v.x, v.y, v.z}

        r_grid[e6].g = r_grid[eR6].g -- copy
        r_grid[e6].b = r_grid[eR6].b -- copy
        --r_grid[e6].g = (r_grid[e6].g + r_grid[eR6].g)/2 -- avg
        --r_grid[e6].b = (r_grid[e6].b + r_grid[eR6].b)/2 -- avg
        --r_grid[e6].g = 2*r_grid[eR6].g - r_grid[eR62].g -- interp
        --r_grid[e6].b = 2*r_grid[eR6].b - r_grid[eR62].b -- interp

      end        
    end

    -- Left y Edge
    if (BCs[1] == 2 and s.y == 0) then

      var e3R : int8d = {s.x, 1, s.z, 0, 0, 0, 0, 0}
      var e3R2 : int8d = {s.x, 2, s.z, 0, 0, 0, 0, 0}

      r_W[e3].rho = r_W[e3R].rho -- copy
      --r_W[e3].rho = (r_W[e3].rho + r_W[e3R].rho)/2 -- avg
      --r_W[e3].rho = 2*r_W[e3R].rho - r_W[e3R2].rho -- interp
      for d = 0, effD do
        r_W[e3].rhov[d] = r_W[e3R].rhov[d] -- copy
        --r_W[e3].rhov[d] = (r_W[e3].rhov[d] + r_W[e3R].rhov[d])/2 -- avg
        --r_W[e3].rhov[d] = 2*r_W[e3R].rhov[d] - r_W[e3R2].rhov[d] -- interp
      end
      r_W[e3].rhoE = r_W[e3R].rhoE -- copy
      --r_W[e3].rhoE = (r_W[e3].rhoE + r_W[e3R].rhoE)/2 -- avg
      --r_W[e3].rhoE = 2*r_W[e3R].rhoE - r_W[e3R2].rhoE -- interp

      for v in v3 do

        e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z} 
        var eR6 : int8d = {e3R.x, e3R.y, e3R.z, 0, 0, v.x, v.y, v.z}
        var eR62 : int8d = {e3R2.x, e3R2.y, e3R2.z, 0, 0, v.x, v.y, v.z}

        r_grid[e6].g = r_grid[eR6].g -- copy
        r_grid[e6].b = r_grid[eR6].b -- copy
        --r_grid[e6].g = (r_grid[e6].g + r_grid[eR6].g)/2 -- avg
        --r_grid[e6].b = (r_grid[e6].b + r_grid[eR6].b)/2 -- avg 
        --r_grid[e6].g = 2*r_grid[eR6].g - r_grid[eR62].g -- interp
        --r_grid[e6].b = 2*r_grid[eR6].b - r_grid[eR62].b -- interp

      end        
    end

    -- Right y Edge
    if (BCs[4] == 2 and s.y == N[1] - 1) then

      var e3R : int8d = {s.x, s.y - 1, s.z, 0, 0, 0, 0, 0}
      var e3R2 : int8d = {s.x, s.y - 2, s.z, 0, 0, 0, 0, 0}

      r_W[e3].rho = r_W[e3R].rho -- copy
      --r_W[e3].rho = (r_W[e3].rho + r_W[e3R].rho)/2 -- avg
      --r_W[e3].rho = 2*r_W[e3R].rho - r_W[e3R2].rho -- interp
      for d = 0, effD do
        r_W[e3].rhov[d] = r_W[e3R].rhov[d] -- copy
        --r_W[e3].rhov[d] = (r_W[e3].rhov[d] + r_W[e3R].rhov[d])/2 -- avg
        --r_W[e3].rhov[d] = 2*r_W[e3R].rhov[d] - r_W[e3R2].rhov[d] -- interp
      end
      r_W[e3].rhoE = r_W[e3R].rhoE -- copy
      --r_W[e3].rhoE = (r_W[e3].rhoE + r_W[e3R].rhoE)/2 -- avg
      --r_W[e3].rhoE = 2*r_W[e3R].rhoE - r_W[e3R2].rhoE -- interp

      for v in v3 do

        e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z} 
        var eR6 : int8d = {e3R.x, e3R.y, e3R.z, 0, 0, v.x, v.y, v.z}
        var eR62 : int8d = {e3R2.x, e3R2.y, e3R2.z, 0, 0, v.x, v.y, v.z}

        r_grid[e6].g = r_grid[eR6].g -- copy
        r_grid[e6].b = r_grid[eR6].b -- copy
        --r_grid[e6].g = (r_grid[e6].g + r_grid[eR6].g)/2 -- avg
        --r_grid[e6].b = (r_grid[e6].b + r_grid[eR6].b)/2 -- avg
        --r_grid[e6].g = 2*r_grid[eR6].g - r_grid[eR62].g -- interp
        --r_grid[e6].b = 2*r_grid[eR6].b - r_grid[eR62].b -- interp

      end        
    end

    -- Left z Edge
    if (BCs[2] == 2 and s.z == 0) then

      var e3R : int8d = {s.x, s.y, 1, 0, 0, 0, 0, 0}
      var e3R2 : int8d = {s.x, s.y, 2, 0, 0, 0, 0, 0}

      r_W[e3].rho = r_W[e3R].rho -- copy
      --r_W[e3].rho = (r_W[e3].rho + r_W[e3R].rho)/2 -- avg
      --r_W[e3].rho = 2*r_W[e3R].rho - r_W[e3R2].rho -- interp
      for d = 0, effD do
        r_W[e3].rhov[d] = r_W[e3R].rhov[d] -- copy
        --r_W[e3].rhov[d] = (r_W[e3].rhov[d] + r_W[e3R].rhov[d])/2 -- avg
        --r_W[e3].rhov[d] = 2*r_W[e3R].rhov[d] - r_W[e3R2].rhov[d] -- interp
      end
      r_W[e3].rhoE = r_W[e3R].rhoE -- copy
      --r_W[e3].rhoE = (r_W[e3].rhoE + r_W[e3R].rhoE)/2 -- avg
      --r_W[e3].rhoE = 2*r_W[e3R].rhoE - r_W[e3R2].rhoE -- interp

      for v in v3 do

        e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z} 
        var eR6 : int8d = {e3R.x, e3R.y, e3R.z, 0, 0, v.x, v.y, v.z}
        var eR62 : int8d = {e3R2.x, e3R2.y, e3R2.z, 0, 0, v.x, v.y, v.z}

        r_grid[e6].g = r_grid[eR6].g -- copy
        r_grid[e6].b = r_grid[eR6].b -- copy
        --r_grid[e6].g = (r_grid[e6].g + r_grid[eR6].g)/2 -- avg
        --r_grid[e6].b = (r_grid[e6].b + r_grid[eR6].b)/2 -- avg
        --r_grid[e6].g = 2*r_grid[eR6].g - r_grid[eR62].g -- interp
        --r_grid[e6].b = 2*r_grid[eR6].b - r_grid[eR62].b -- interp

      end        
    end

    -- Right z Edge
    if (BCs[5] == 2 and s.z == N[2] - 1) then

      var e3R : int8d = {s.x, s.y, s.z - 1, 0, 0, 0, 0, 0}
      var e3R2 : int8d = {s.x, s.y, s.z - 2, 0, 0, 0, 0, 0}

      r_W[e3].rho = r_W[e3R].rho -- copy
      --r_W[e3].rho = (r_W[e3].rho + r_W[e3R].rho)/2 -- avg
      --r_W[e3].rho = 2*r_W[e3R].rho - r_W[e3R2].rho -- interp
      for d = 0, effD do
        r_W[e3].rhov[d] = r_W[e3R].rhov[d] -- copy
        --r_W[e3].rhov[d] = (r_W[e3].rhov[d] + r_W[e3R].rhov[d])/2 -- avg
        --r_W[e3].rhov[d] = 2*r_W[e3R].rhov[d] - r_W[e3R2].rhov[d] -- interp
      end
      r_W[e3].rhoE = r_W[e3R].rhoE -- copy
      --r_W[e3].rhoE = (r_W[e3].rhoE + r_W[e3R].rhoE)/2 -- avg
      --r_W[e3].rhoE = 2*r_W[e3R].rhoE - r_W[e3R2].rhoE -- interp

      for v in v3 do

        e6 = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z} 
        var eR6 : int8d = {e3R.x, e3R.y, e3R.z, 0, 0, v.x, v.y, v.z}
        var eR62 : int8d = {e3R2.x, e3R2.y, e3R2.z, 0, 0, v.x, v.y, v.z}

        r_grid[e6].g = r_grid[eR6].g -- copy
        r_grid[e6].b = r_grid[eR6].b -- copy
        --r_grid[e6].g = (r_grid[e6].g + r_grid[eR6].g)/2 -- avg
        --r_grid[e6].b = (r_grid[e6].b + r_grid[eR6].b)/2 -- avg
        --r_grid[e6].g = 2*r_grid[eR6].g - r_grid[eR62].g -- interp
        --r_grid[e6].b = 2*r_grid[eR6].b - r_grid[eR62].b -- interp

      end        
    end
  end
end



task MaxwellianInitialization(r_grid  : region(ispace(int8d), grid),
         r_mesh : region(ispace(int8d), mesh),
         r_W    : region(ispace(int8d), W),
         vxmesh : region(ispace(int1d), vmesh),
         vymesh : region(ispace(int1d), vmesh),
         vzmesh : region(ispace(int1d), vmesh),
         testProblem: int32, R : double, K : double, Cv : double, 
         g : double, w : double, ur : double, Tr : double, Pr : double,
         N : int32[3], NV : int32[3], effD : int32)
where 
  reads writes(r_grid), 
  reads(r_mesh, r_W, vxmesh, vymesh, vzmesh)
do

  var T : double -- Temperature 
  var u : double -- Bulk Velocity
  var Xi : double[3] -- Velocity Vector

  -- Generate Index Spaces for Iteration
  var slo : int3d = {r_grid.bounds.lo.x, r_grid.bounds.lo.y, r_grid.bounds.lo.z}
  var shi : int3d = {r_grid.bounds.hi.x, r_grid.bounds.hi.y, r_grid.bounds.hi.z}
  var vlo : int3d = {vxmesh.bounds.lo, vymesh.bounds.lo, vzmesh.bounds.lo}
  var vhi : int3d = {vxmesh.bounds.hi, vymesh.bounds.hi, vzmesh.bounds.hi}
  var s3 = ispace(int3d, shi - slo + {1,1,1}, slo)
  var v3 = ispace(int3d, vhi - vlo + {1,1,1}, vlo)

  for s in s3 do

    var e3 : int8d = {s.x, s.y, s.z, 0, 0, 0, 0, 0}

    -- Compute Bulk Velocity
    u = 0
    for dim = 0, effD do
      u += r_W[e3].rhov[dim]/r_W[e3].rho*r_W[e3].rhov[dim]/r_W[e3].rho
    end
    u = sqrt(u)
      
    -- Compute Temperature
    T = Temperature(r_W[e3].rhoE/r_W[e3].rho, u, g, R)
    
    for v in v3 do
    
      var e6 : int8d = {s.x, s.y, s.z, 0, 0, v.x, v.y, v.z}

      -- Fill in Velocity Vector
      Xi[0] = vxmesh[v.x].v
      Xi[1] = vymesh[v.y].v
      Xi[2] = vzmesh[v.z].v

      -- Compute Peculiar Velocity squared
      var c2 : double = 0
      for d = 0, effD do
        c2 += (Xi[d] - r_W[e3].rhov[d]/r_W[e3].rho)*(Xi[d] - r_W[e3].rhov[d]/r_W[e3].rho) --TODO could be bugged
      end

      -- Initialize with Equilibrium Distributions
      r_grid[e6].g = geq(c2, r_W[e3].rho, T, R, effD)
      r_grid[e6].b = r_grid[e6].g*(Xi[0]*Xi[0] + Xi[1]*Xi[1] + Xi[2]*Xi[2] + (3.0-effD+K)*R*T)/2.0
  
    end
  end
end

task InitializeGrid(r_grid  : region(ispace(int8d), grid),
                r_mesh : region(ispace(int8d), mesh),
        r_W    : region(ispace(int8d), W),
        vxmesh : region(ispace(int1d), vmesh),
        vymesh : region(ispace(int1d), vmesh),
        vzmesh : region(ispace(int1d), vmesh),
                testProblem: int32, R : double, K : double, Cv : double, g : double, w : double, ur : double, Tr : double, Pr : double,
        N : int32[3], NV : int32[3], effD : int32)
where
  reads writes(r_grid),
  reads(r_mesh, r_W, vxmesh, vymesh, vzmesh)
do

  -- InitializeTestProblem
  if testProblem == 0 then
    -- TODO : User Defined
  elseif testProblem > 0 or testProblem == -1 then
    MaxwellianInitialization(r_grid, r_mesh, r_W, vxmesh, vymesh, vzmesh, testProblem, R, K, Cv, g, w, ur, Tr, Pr, N, NV, effD)
  end
end

-- Helper Factorize Functions
-- These functions determine how the grids are broken up given {parallelism} number of cpus
task factorize1d(parallelism : int) : int3d
  var sizex = parallelism
  return int3d {sizex, 1, 1} 
end

task factorize2d(parallelism : int) : int3d
  var limit = [int](cmath.sqrt([double](parallelism)))
  var size_x : int32 = 1
  var size_y : int32 = parallelism
  for i = 1, limit + 1 do
    if parallelism % i == 0 then
      size_x, size_y =  i, parallelism / i
      if size_x > size_y then
        size_x, size_y = size_y, size_x
      end
    end
  end
  return int3d { size_x, size_y, 1 }
end

task factorize3d(parallelism : int) : int3d
  var limit = [int](cmath.pow([double](parallelism), 1/3))
  var size_x = 1
  var size_y = 1
  var size_z = parallelism
  for i = 1, limit + 1 do
    if parallelism % i == 0 then
      size_x, size_z = i, parallelism / i
      if size_x > size_z then
        size_x, size_z = size_z, size_x
      end
    end

    if parallelism % i*i == 0 then
      size_x, size_y, size_z = i, i, parallelism/i*i
    end
  end
  return int3d { size_x, size_y, size_z }
end

task factorize(parallelism: int, fdims : int32[3])

  var d : int32 = 0
  if fdims[0] == 1 then d += 1 end
  if fdims[1] == 1 then d += 1 end
  if fdims[2] == 1 then d += 1 end

  var f6 : int6d = {1, 1, 1, 1, 1, 1}
  if d == 1 then
    var f3 = factorize1d(parallelism)
    if fdims[0] == 1 then f6.x = f3.x
    elseif fdims[1] == 1 then f6.y = f3.x
    elseif fdims[2] == 1 then f6.z = f3.x end
  elseif d == 2 then
    var f3 = factorize2d(parallelism)
    if fdims[0] == 1 then
      f6.x = f3.x
      if fdims[1] == 1 then f6.y = f3.y elseif fdims[2] == 1 then f6.z = f3.y end
    else
      f6.y, f6.z = f6.x, f6.y
    end
  elseif d == 3 then
    var f3 = factorize3d(parallelism)
    f6.x, f6.y, f6.z = f3.x, f3.y, f3.z
  end

  return f6
end

-- Helper Wait Function
terra wait_for(x : int) return 1 end
task block_task(r_W : region(ispace(int8d), W))
where
  reads writes(r_W)
do
  return 1
end

-- Helper I/O Functions
-- Given a file and value, output type to binary
terra dumpdouble(f : &c.FILE, val : double)
  var a : double[1]
  a[0] = val
  c.fwrite(&a, 8, 1, f)
end
terra dumpint32(f : &c.FILE, val : int32)
  var a : int32[1]
  a[0] = val
  c.fwrite(&a, 4, 1, f)
end

-- This task dumps conserved variables given iteration number
task Dump(r_W : region(ispace(int8d), W), iter : int32)
where
  reads (r_W)
do
  var rhofile : int8[1000]
  c.sprintf([&int8](rhofile), './Data/rho_%04d',iter)
  var rho = c.fopen(rhofile,'wb')

  var rhovxfile : int8[1000]
  c.sprintf([&int8](rhovxfile), './Data/rhovx_%04d',iter)
  var rhovx = c.fopen(rhovxfile,'wb')

  var rhovyfile : int8[1000]
  c.sprintf([&int8](rhovyfile), './Data/rhovy_%04d',iter)
  var rhovy = c.fopen(rhovyfile,'wb')

  var rhovzfile : int8[1000]
  c.sprintf([&int8](rhovzfile), './Data/rhovz_%04d',iter)
  var rhovz = c.fopen(rhovzfile,'wb')

  var rhoEfile : int8[1000]
  c.sprintf([&int8](rhoEfile), './Data/rhoE_%04d',iter)
  var rhoE = c.fopen(rhoEfile,'wb')


  for e in r_W do
    dumpdouble(rho, r_W[e].rho)
  end
  c.fclose(rho)

  for e in r_W do
    dumpdouble(rhovx, r_W[e].rhov[0])
  end
  c.fclose(rhovx)

  for e in r_W do
    dumpdouble(rhovy, r_W[e].rhov[1])
  end
  c.fclose(rhovy)

  for e in r_W do
    dumpdouble(rhovz, r_W[e].rhov[2])
  end
  c.fclose(rhovz)

  for e in r_W do
    dumpdouble(rhoE, r_W[e].rhoE)
  end
  c.fclose(rhoE)
  __fence(__execution, __block)
  return 1
end

-- This task dumps the whole phase space distribution given iteration number
task DumpPhase(r_grid : region(ispace(int8d), grid), iter : int32)
where
  reads (r_grid)
do
  var phasefile : int8[1000]
  c.sprintf([&int8](phasefile), './Data/phase_%04d',iter)
  var phase = c.fopen(phasefile,'wb')

  for e in r_grid do
    dumpdouble(phase, r_grid[e].g)
  end
  c.fclose(phase)

  var bphasefile : int8[1000]
  c.sprintf([&int8](bphasefile), './Data/bphase_%04d',iter)
  var bphase = c.fopen(bphasefile,'wb')

  for e in r_grid do
    dumpdouble(bphase, r_grid[e].b)
  end
  c.fclose(bphase)

  __fence(__execution, __block)
  return 1
end

-- This task does the same as above, but is intended to be used with the boundary phi
-- and has a different file output name
task DumpBoundaryPhase(r_grid : region(ispace(int8d), grid), iter : int32)
where
  reads (r_grid)
do
  var phasefile : int8[1000]
  c.sprintf([&int8](phasefile), './Data/boundaryphase_%04d',iter)
  var phase = c.fopen(phasefile,'wb')

  for e in r_grid do
    dumpdouble(phase, r_grid[e].g)
  end
  c.fclose(phase)

  __fence(__execution, __block)
  return 1
end

terra get_config() 

  var config: Config
  config:initialize_from_command()

  return config
end

get_config.replicable = true
c.printf.replicable = true


task PrintDump(d: int32)
  c.printf("Dump %d\n", d)
  return 1
end

task PrintPartition(x : int32, y : int32, z : int32, w : int32, u : int32, v : int32)
  c.printf("Partitioning as {%d, %d, %d, %d, %d, %d, %d, %d}\n", x, y, z, 1, 1, w, v, u)
  return 1
end

task FinishSimulation(End: double, Start: double)
  c.printf("Finished simulation in %.4f seconds.\n", (End-Start)*1e-9)
end

task PrintParams(
  testProblem : int32,
  N : int32[3],
  NV : int32[3],
  effD : int32,
  BCs : int32[6],
  Vmin : double[3],
  Vmax : double[3],
  R : float,
  K : float,
  g : float,
  Cv : float,
  w : float,
  ur : float,
  Tr : float,
  Pr : float,
  Tf : float,
  dtdump : float
)
  c.printf("Simulation Parameters\n")
  if testProblem > 0 then c.printf("testProblem = %d\n", testProblem) end
  c.printf("N = {%d, %d, %d}, NV = {%d, %d, %d}, effD = %d\n", N[0], N[1], N[2], NV[0], NV[1], NV[2], effD)
  c.printf("BCs = {{%d, %d, %d}, {%d, %d, %d}}, Vmin = {%f, %f, %f}, Vmax = {%f, %f, %f}\n", BCs[0], BCs[1], BCs[2], BCs[3], BCs[4], BCs[5], Vmin[0], Vmin[1], Vmin[2], Vmax[0], Vmax[1], Vmax[2])
  c.printf("R = %f, K = %f, g = %f, Cv = %f\n", R, K, g, Cv)
  c.printf("w = %f, ur = %f, Tr = %f, Pr = %f\n", w, ur, Tr, Pr)
  c.printf("End Time = %f, dtdump %f\n", Tf, dtdump)
  return 1
end

task PrintIteration(iter: int32, Tsim: double, End: double, Start: double)
  c.printf("Iteration = %d, Tsim = %f, Realtime = %f\n", iter, Tsim, (End-Start)*1e-9)
  c.fflush(c.stdout)
  return 1
end

__demand(__replicable)
task toplevel()
  var config = get_config()

  -- Simulation Parameters
  var testProblem : int32 = config.testproblem
  var r_params = region(ispace(int1d, 1), params)
  TestProblem(r_params, testProblem)
  -- Unpack TestProblem
  var N  : int32[3] = r_params[0].N
  var NV : int32[3] = r_params[0].NV
  var Nc : int64 = r_params[0].Nc
  var Nv : int64 = r_params[0].Nv
  var R : double = r_params[0].R
  var K : double = r_params[0].K
  var g : double = r_params[0].g
  var w : double = r_params[0].w
  var Cv : double = r_params[0].Cv
  var ur : double = r_params[0].ur
  var Tr : double = r_params[0].Tr
  var Pr : double = r_params[0].Pr
  var effD : int32 = r_params[0].effD
  var BCs : int32[6] = r_params[0].BCs
  var Vmin : double[3] = r_params[0].Vmin
  var Vmax : double[3] = r_params[0].Vmax
  var Tf : double = r_params[0].Tf
  var dtdump : double = r_params[0].dtdump
  var thermal_bath : bool = r_params[0].thermal_bath
  var thermal_T : double = r_params[0].thermal_T

  PrintParams(testProblem, N, NV, effD, BCs, Vmin, Vmax, R, K, g, Cv, w, ur, Tr, Pr, Tf, dtdump)

  -- Create regions for distribution functions and gradients
  var r_grid      = region(ispace(int8d, {N[0], N[1], N[2], 1, 1, NV[0], NV[1], NV[2]}), grid)
  var r_gridbarp  = region(ispace(int8d, {N[0], N[1], N[2], 1, 1, NV[0], NV[1], NV[2]}), grid)
  var r_gridbarpb = region(ispace(int8d, {N[0], N[1], N[2], effD, 1, NV[0], NV[1], NV[2]}), grid)
  var r_sig       = region(ispace(int8d, {N[0], N[1], N[2], effD, 1, NV[0], NV[1], NV[2]}), grid)
  var r_sig2      = region(ispace(int8d, {N[0], N[1], N[2], effD, effD, NV[0], NV[1], NV[2]}), grid)
  var r_sigb      = region(ispace(int8d, {N[0], N[1], N[2], effD, effD, NV[0], NV[1], NV[2]}), grid)
 
  -- Create regions for mesh and conserved variables (cell center and interface)
  var r_mesh = region(ispace(int8d, {N[0], N[1], N[2], 1, 1, 1, 1, 1}), mesh)
  var r_W    = region(ispace(int8d, {N[0], N[1], N[2], 1, 1, 1, 1, 1}), W)
  var r_Wb   = region(ispace(int8d, {N[0], N[1], N[2], effD, 1, 1, 1, 1}), W)
 
  -- Create regions for velocity space and initialize
  var vxmesh = region(ispace(int1d, NV[0]), vmesh) 
  var vymesh = region(ispace(int1d, NV[1]), vmesh) 
  var vzmesh = region(ispace(int1d, NV[2]), vmesh) 
  NewtonCotes(vxmesh, vymesh, vzmesh, NV, Vmin, Vmax)

  -- Create regions for source terms and flux
  var r_S = region(ispace(int8d, {N[0], N[1], N[2], 1, 1, NV[0], NV[1], NV[2]}), grid)
  var r_F = region(ispace(int8d, {N[0], N[1], N[2], 1, 1, NV[0], NV[1], NV[2]}), grid)

  -- Check Dimensions for Factorization
  -- Need at least 8 cells before parallelization is considered along that dimension
  var fdims : int32[3]
  if N[0] >= 8 then fdims[0] = 1 else fdims[0] = 0 end
  if N[1] >= 8 then fdims[1] = 1 else fdims[1] = 0 end
  if N[2] >= 8 then fdims[2] = 1 else fdims[2] = 0 end

  -- Create partitions for regions
  var f6 : int6d = factorize(config.cpus, fdims)  
  var f8 : int8d = {f6.x, f6.y, f6.z, 1, 1, f6.w, f6.v, f6.u}
  PrintPartition(f6.x, f6.y, f6.z, f6.w, f6.v, f6.u)
  var p8 = ispace(int8d, f8)
  var p_grid = partition(equal, r_grid, p8)
  var p_gridbarp = partition(equal, r_gridbarp, p8)
  var p_gridbarpb = partition(equal, r_gridbarpb, p8)
  var p_sig = partition(equal, r_sig, p8)
  var p_sig2 = partition(equal, r_sig2, p8)
  var p_sigb = partition(equal, r_sigb, p8)
  var p_mesh = partition(equal, r_mesh, p8)
  var p_W = partition(equal, r_W, p8)
  var p_Wb = partition(equal, r_Wb, p8)
  var p_S = partition(equal, r_S, p8)
  var p_F = partition(equal, r_F, p8)
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("Equal Partitions Done\n")
  end

  -- Create coloring for partitions for left/right ghost regions
  var c3Lx = coloring.create()
  var c3Ly = coloring.create()
  var c3Lz = coloring.create()
  var c4Lx = coloring.create()
  var c4Ly = coloring.create()
  var c4Lz = coloring.create()
  var c6Lx = coloring.create()
  var c6Ly = coloring.create()
  var c6Lz = coloring.create()
  var c7Lx = coloring.create()
  var c7Ly = coloring.create()
  var c7Lz = coloring.create()
  var c8Lx = coloring.create()
  var c8Ly = coloring.create()
  var c8Lz = coloring.create()

  var c3Rx = coloring.create()
  var c3Ry = coloring.create()
  var c3Rz = coloring.create()
  var c4Rx = coloring.create()
  var c4Ry = coloring.create()
  var c4Rz = coloring.create()
  var c6Rx = coloring.create()
  var c6Ry = coloring.create()
  var c6Rz = coloring.create()
  var c7Rx = coloring.create()
  var c7Ry = coloring.create()
  var c7Rz = coloring.create()
  var c8Rx = coloring.create()
  var c8Ry = coloring.create()
  var c8Rz = coloring.create()
 
  var cvxmesh = coloring.create()
  var cvymesh = coloring.create()
  var cvzmesh = coloring.create()
  -- Create Rects for colorings for partitions
  for col8 in p_sig2.colors do
    var bounds = p_sig2[col8].bounds
    
    -- Leftmost and Rightmost indices
    var il : int32 = bounds.lo.x
    var jl : int32 = bounds.lo.y
    var kl : int32 = bounds.lo.z
    var ir : int32 = bounds.hi.x
    var jr : int32 = bounds.hi.y
    var kr : int32 = bounds.hi.z

    var lx = BC(il, jl, kl, 0, BCs, N)[0]
    var rx = BC(ir, jr, kr, 0, BCs, N)[3]
    var ly = BC(il, jl, kl, 1, BCs, N)[1]
    var ry = BC(ir, jr, kr, 1, BCs, N)[4]
    var lz = BC(il, jl, kl, 2, BCs, N)[2]
    var rz = BC(ir, jr, kr, 2, BCs, N)[5]

    var rleftx3 : rect8d = { {lx, bounds.lo.y, bounds.lo.z, 0, 0, 0, 0, 0}, 
                         {lx, bounds.hi.y, bounds.hi.z, 0, 0, 0, 0, 0}}
    var rlefty3 : rect8d = { {bounds.lo.x, ly, bounds.lo.z, 0, 0, 0, 0, 0},
                         {bounds.hi.x, ly, bounds.hi.z, 0, 0, 0, 0, 0}}
    var rleftz3 : rect8d = { {bounds.lo.x, bounds.lo.y, lz, 0, 0, 0, 0, 0},
                         {bounds.hi.x, bounds.hi.y, lz, 0, 0, 0, 0, 0}}

    var rrightx3 : rect8d = { {rx, bounds.lo.y, bounds.lo.z, 0, 0, 0, 0, 0}, 
                         {rx, bounds.hi.y, bounds.hi.z, 0, 0, 0, 0, 0}}
    var rrighty3 : rect8d = { {bounds.lo.x, ry, bounds.lo.z, 0, 0, 0, 0, 0},
                         {bounds.hi.x, ry, bounds.hi.z, 0, 0, 0, 0, 0}}
    var rrightz3 : rect8d = { {bounds.lo.x, bounds.lo.y, rz, 0, 0, 0, 0, 0},
                         {bounds.hi.x, bounds.hi.y, rz, 0, 0, 0, 0, 0}}

    var rleftx4 : rect8d = { {lx, bounds.lo.y, bounds.lo.z, bounds.lo.w, 0, 0, 0, 0}, 
                         {lx, bounds.hi.y, bounds.hi.z, bounds.hi.w, 0, 0, 0, 0}}
    var rlefty4 : rect8d = { {bounds.lo.x, ly, bounds.lo.z, bounds.lo.w, 0, 0, 0, 0},
                         {bounds.hi.x, ly, bounds.hi.z, bounds.hi.w, 0, 0, 0, 0}}
    var rleftz4 : rect8d = { {bounds.lo.x, bounds.lo.y, lz, bounds.lo.w, 0, 0, 0, 0},
                         {bounds.hi.x, bounds.hi.y, lz, bounds.hi.w, 0, 0, 0, 0}}

    var rrightx4 : rect8d = { {rx, bounds.lo.y, bounds.lo.z, bounds.lo.w, 0, 0, 0, 0}, 
                         {rx, bounds.hi.y, bounds.hi.z, bounds.hi.w, 0, 0, 0, 0}}
    var rrighty4 : rect8d = { {bounds.lo.x, ry, bounds.lo.z, bounds.lo.w, 0, 0, 0, 0},
                         {bounds.hi.x, ry, bounds.hi.z, bounds.hi.w, 0, 0, 0, 0}}
    var rrightz4 : rect8d = { {bounds.lo.x, bounds.lo.y, rz, bounds.lo.w, 0, 0, 0, 0},
                         {bounds.hi.x, bounds.hi.y, rz, bounds.hi.w, 0, 0, 0, 0}}

    var rleftx6 : rect8d = { {lx, bounds.lo.y, bounds.lo.z, 0, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s}, 
                         {lx, bounds.hi.y, bounds.hi.z, 0, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rlefty6 : rect8d = { {bounds.lo.x, ly, bounds.lo.z, 0, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, ly, bounds.hi.z, 0, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rleftz6 : rect8d = { {bounds.lo.x, bounds.lo.y, lz, 0, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, bounds.hi.y, lz, 0, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}

    var rrightx6 : rect8d = { {rx, bounds.lo.y, bounds.lo.z, 0, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s}, 
                         {rx, bounds.hi.y, bounds.hi.z, 0, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rrighty6 : rect8d = { {bounds.lo.x, ry, bounds.lo.z, 0, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, ry, bounds.hi.z, 0, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rrightz6 : rect8d = { {bounds.lo.x, bounds.lo.y, rz, 0, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, bounds.hi.y, rz, 0, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}

    var rleftx7 : rect8d = { {lx, bounds.lo.y, bounds.lo.z, bounds.lo.w, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s}, 
                         {lx, bounds.hi.y, bounds.hi.z, bounds.hi.w, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rlefty7 : rect8d = { {bounds.lo.x, ly, bounds.lo.z, bounds.lo.w, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, ly, bounds.hi.z, bounds.hi.w, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rleftz7 : rect8d = { {bounds.lo.x, bounds.lo.y, lz, bounds.lo.w, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, bounds.hi.y, lz, bounds.hi.w, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}

    var rrightx7 : rect8d = { {rx, bounds.lo.y, bounds.lo.z, bounds.lo.w, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s}, 
                         {rx, bounds.hi.y, bounds.hi.z, bounds.hi.w, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rrighty7 : rect8d = { {bounds.lo.x, ry, bounds.lo.z, bounds.lo.w, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, ry, bounds.hi.z, bounds.hi.w, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rrightz7 : rect8d = { {bounds.lo.x, bounds.lo.y, rz, bounds.lo.w, 0, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, bounds.hi.y, rz, bounds.hi.w, 0, bounds.hi.u, bounds.hi.t, bounds.hi.s}}

    var rleftx8 : rect8d = { {lx, bounds.lo.y, bounds.lo.z, bounds.lo.w, bounds.lo.v, bounds.lo.u, bounds.lo.t, bounds.lo.s}, 
                         {lx, bounds.hi.y, bounds.hi.z, bounds.hi.w, bounds.hi.v, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rlefty8 : rect8d = { {bounds.lo.x, ly, bounds.lo.z, bounds.lo.w, bounds.lo.v, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, ly, bounds.hi.z, bounds.hi.w, bounds.hi.v, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rleftz8 : rect8d = { {bounds.lo.x, bounds.lo.y, lz, bounds.lo.w, bounds.lo.v, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, bounds.hi.y, lz, bounds.hi.w, bounds.hi.v, bounds.hi.u, bounds.hi.t, bounds.hi.s}}

    var rrightx8 : rect8d = { {rx, bounds.lo.y, bounds.lo.z, bounds.lo.w, bounds.lo.v, bounds.lo.u, bounds.lo.t, bounds.lo.s}, 
                         {rx, bounds.hi.y, bounds.hi.z, bounds.hi.w, bounds.hi.v, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rrighty8 : rect8d = { {bounds.lo.x, ry, bounds.lo.z, bounds.lo.w, bounds.lo.v, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, ry, bounds.hi.z, bounds.hi.w, bounds.hi.v, bounds.hi.u, bounds.hi.t, bounds.hi.s}}
    var rrightz8 : rect8d = { {bounds.lo.x, bounds.lo.y, rz, bounds.lo.w, bounds.lo.v, bounds.lo.u, bounds.lo.t, bounds.lo.s},
                         {bounds.hi.x, bounds.hi.y, rz, bounds.hi.w, bounds.hi.v, bounds.hi.u, bounds.hi.t, bounds.hi.s}}

    var rvx : rect1d = {vxmesh.bounds.lo, vxmesh.bounds.hi}
    var rvy : rect1d = {vymesh.bounds.lo, vymesh.bounds.hi}
    var rvz : rect1d = {vzmesh.bounds.lo, vzmesh.bounds.hi}
    
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("rect8d Done\n")
    end

    -- Color in left strips
    coloring.color_domain(c3Lx, col8, rleftx3)
    coloring.color_domain(c3Ly, col8, rlefty3)
    coloring.color_domain(c3Lz, col8, rleftz3)
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("3d Coloring Done\n")
    end

    coloring.color_domain(c6Lx, col8, rleftx6)
    coloring.color_domain(c6Ly, col8, rlefty6)
    coloring.color_domain(c6Lz, col8, rleftz6)
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("6d Coloring Done\n")
    end


    coloring.color_domain(c7Lx, col8, rleftx7)
    coloring.color_domain(c7Ly, col8, rlefty7)
    coloring.color_domain(c7Lz, col8, rleftz7)
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("7d Coloring Done\n")
    end

    coloring.color_domain(c8Lx, col8, rleftx8)
    coloring.color_domain(c8Ly, col8, rlefty8)
    coloring.color_domain(c8Lz, col8, rleftz8)
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("8d Coloring Done\n")
    end

    -- Color in right strips
    coloring.color_domain(c3Rx, col8, rrightx3)
    coloring.color_domain(c3Ry, col8, rrighty3)
    coloring.color_domain(c3Rz, col8, rrightz3)

    coloring.color_domain(c6Rx, col8, rrightx6)
    coloring.color_domain(c6Ry, col8, rrighty6)
    coloring.color_domain(c6Rz, col8, rrightz6)

    coloring.color_domain(c7Rx, col8, rrightx7)
    coloring.color_domain(c7Ry, col8, rrighty7)
    coloring.color_domain(c7Rz, col8, rrightz7)

    coloring.color_domain(c8Rx, col8, rrightx8)
    coloring.color_domain(c8Ry, col8, rrighty8)
    coloring.color_domain(c8Rz, col8, rrightz8)

    coloring.color_domain(cvxmesh, col8, rvx) 
    coloring.color_domain(cvymesh, col8, rvy) 
    coloring.color_domain(cvzmesh, col8, rvz) 

    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Coloring Done\n")
    end
  end

  -- Create Partitions
  var plx_mesh = partition(disjoint, r_mesh, c3Lx, p8)
  var ply_mesh = partition(disjoint, r_mesh, c3Ly, p8)
  var plz_mesh = partition(disjoint, r_mesh, c3Lz, p8)
  var prx_mesh = partition(disjoint, r_mesh, c3Rx, p8)
  var pry_mesh = partition(disjoint, r_mesh, c3Ry, p8)
  var prz_mesh = partition(disjoint, r_mesh, c3Rz, p8)
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("Mesh Strips Done\n")
  end

  var plx_gridbarp = partition(disjoint, r_gridbarp, c6Lx, p8)
  var ply_gridbarp = partition(disjoint, r_gridbarp, c6Ly, p8)
  var plz_gridbarp = partition(disjoint, r_gridbarp, c6Lz, p8)
  var prx_gridbarp = partition(disjoint, r_gridbarp, c6Rx, p8)
  var pry_gridbarp = partition(disjoint, r_gridbarp, c6Ry, p8)
  var prz_gridbarp = partition(disjoint, r_gridbarp, c6Rz, p8)
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("gridbarp Strips Done\n")
  end

  var plx_gridbarpb = partition(disjoint, r_gridbarpb, c7Lx, p8)
  var ply_gridbarpb = partition(disjoint, r_gridbarpb, c7Ly, p8)
  var plz_gridbarpb = partition(disjoint, r_gridbarpb, c7Lz, p8)
  var prx_gridbarpb = partition(disjoint, r_gridbarpb, c7Rx, p8)
  var pry_gridbarpb = partition(disjoint, r_gridbarpb, c7Ry, p8)
  var prz_gridbarpb = partition(disjoint, r_gridbarpb, c7Rz, p8)
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("gridbarpbb Strips Done\n")
  end

  var plx_sig = partition(disjoint, r_sig, c7Lx, p8)
  var ply_sig = partition(disjoint, r_sig, c7Ly, p8)
  var plz_sig = partition(disjoint, r_sig, c7Lz, p8)
  var prx_sig = partition(disjoint, r_sig, c7Rx, p8)
  var pry_sig = partition(disjoint, r_sig, c7Ry, p8)
  var prz_sig = partition(disjoint, r_sig, c7Rz, p8)
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("sig Strips Done\n")
  end

  var plx_sig2 = partition(disjoint, r_sig2, c8Lx, p8)
  var ply_sig2 = partition(disjoint, r_sig2, c8Ly, p8)
  var plz_sig2 = partition(disjoint, r_sig2, c8Lz, p8)
  var prx_sig2 = partition(disjoint, r_sig2, c8Rx, p8)
  var pry_sig2 = partition(disjoint, r_sig2, c8Ry, p8)
  var prz_sig2 = partition(disjoint, r_sig2, c8Rz, p8)
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("sig2 Strips Done\n")
  end
 
  var plx_sigb = partition(disjoint, r_sigb, c8Lx, p8)
  var ply_sigb = partition(disjoint, r_sigb, c8Ly, p8)
  var plz_sigb = partition(disjoint, r_sigb, c8Lz, p8)
  var prx_sigb = partition(disjoint, r_sigb, c8Rx, p8)
  var pry_sigb = partition(disjoint, r_sigb, c8Ry, p8)
  var prz_sigb = partition(disjoint, r_sigb, c8Rz, p8)
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("sigb Strips Done\n")
    c.printf("Left/Right Strip Partitioning Done\n")
  end

  var pxmesh = partition(aliased, vxmesh, cvxmesh, p8)
  var pymesh = partition(aliased, vymesh, cvymesh, p8)
  var pzmesh = partition(aliased, vzmesh, cvzmesh, p8)

  -- Initialize r_mesh
  var MeshType : int32 = 1
  InitializeMesh(r_mesh, N, MeshType) --TODO Needs more input for nested, user-def etc.
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("Mesh Initialized\n")
  end

  -- Initialize r_W
  __demand(__index_launch)
  for col8 in p_W.colors do
    InitializeW(p_W[col8], p_mesh[col8], N, NV, testProblem, R, Cv, g)
  end
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("W Initialized\n")
  end
 
  -- Initialize r_grid
  __demand(__index_launch)
  for col8 in p_grid.colors do
    InitializeGrid(p_grid[col8], p_mesh[col8], p_W[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], testProblem, R, K, Cv, g, w, ur, Tr, Pr, N, NV, effD)
  end
  if config.debug == true then
    __fence(__execution, __block)
    c.printf("Grid Initialized\n")
  end

  -- Timestep
  var CFL : double = 0.5 -- Safety Factor
  var dxmin : double = 1.0/cmath.fmax(cmath.fmax(N[0],N[1]),N[2]) -- Smallest Cell Width (TODO : Non-Uniform Meshes)
  var umax : double  = 2.0 -- Estimated maximum flow velocity, TODO calculate at each iteration for stronger problems
  var calcdt : double = CFL*dxmin/(umax + sqrt(Vmax[0]*Vmax[0] + Vmax[1]*Vmax[1] + Vmax[2]*Vmax[2]))
  
  var Tsim : double = 0.0  -- Sim time
  var Tdump : double = 0.0 -- Time since last dump 
  
  var iter : int32 = 0
  var dumpiter : int32 = 0
  if testProblem >= 0 and config.out == true then 

    Dump(r_W, dumpiter) -- Initial Conditions
    if config.phase == true then
      DumpPhase(r_grid, dumpiter)
    end

    PrintDump(dumpiter)
  end
  
  var Start : double = c.legion_get_current_time_in_nanos()
  var End : double 
  
  var dt : double = 0
  while Tsim < Tf do --and iter < 10 do
    iter += 1

    if config.out == true then
      dt = TimeStep(calcdt, dtdump-Tdump, Tf-Tsim)
    else
      -- if no output, then dtdump-Tdump is irrelevant 
      dt = TimeStep(calcdt, 10*calcdt, Tf-Tsim)
    end  

    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Starting Step1a\n")
      c.fflush(c.stdout)
    end
    -- Step 1a
    __demand(__index_launch)
    for col8 in p_grid.colors do 
      Step1a(p_grid[col8], p_gridbarp[col8], p_S[col8], p_W[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], dt, R, K, Cv, g, w, ur, Tr, Pr, effD, thermal_bath, thermal_T)
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Step1a Complete\n")
      c.fflush(c.stdout)
    end

    -- Step 1b: Compute Gradient Sigma
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Computing Gradients\n")
      c.fflush(c.stdout)
    end
    __demand(__index_launch)
    for col8 in p_grid.colors do 
      Step1b_sigx(p_gridbarp[col8], p_sig[col8], p_mesh[col8], plx_mesh[col8], prx_mesh[col8], plx_gridbarp[col8], prx_gridbarp[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N, effD)
    end
    if effD > 1 then
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigy(p_gridbarp[col8], p_sig[col8], p_mesh[col8], ply_mesh[col8], pry_mesh[col8], ply_gridbarp[col8], pry_gridbarp[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N, effD)
      end  
    end
    if effD > 2 then
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigz(p_gridbarp[col8], p_sig[col8], p_mesh[col8], plz_mesh[col8], prz_mesh[col8], plz_gridbarp[col8], prz_gridbarp[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N, effD)
      end  
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Gradients Computed\n")
      c.fflush(c.stdout)
    end

    -- Step 1b: Compute Gradient of Gradient Sigma, Sigma2
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Computing Gradients of Gradients\n")
      c.fflush(c.stdout)
    end
    __demand(__index_launch)
    for col8 in p_grid.colors do 
      Step1b_sigx_x(p_sig[col8], p_sig2[col8], p_mesh[col8], plx_mesh[col8], prx_mesh[col8], plx_sig[col8], prx_sig[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
    end  
    if effD > 1 then
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigx_y(p_sig[col8], p_sig2[col8], p_mesh[col8], ply_mesh[col8], pry_mesh[col8], ply_sig[col8], pry_sig[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigy_y(p_sig[col8], p_sig2[col8], p_mesh[col8], ply_mesh[col8], pry_mesh[col8], ply_sig[col8], pry_sig[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigy_x(p_sig[col8], p_sig2[col8], p_mesh[col8], plx_mesh[col8], prx_mesh[col8], plx_sig[col8], prx_sig[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
    end
    if effD > 2 then
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigz_x(p_sig[col8], p_sig2[col8], p_mesh[col8], plx_mesh[col8], prx_mesh[col8], plx_sig[col8], prx_sig[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigz_y(p_sig[col8], p_sig2[col8], p_mesh[col8], ply_mesh[col8], pry_mesh[col8], ply_sig[col8], pry_sig[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigz_z(p_sig[col8], p_sig2[col8], p_mesh[col8], plz_mesh[col8], prz_mesh[col8], plz_sig[col8], prz_sig[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigx_z(p_sig[col8], p_sig2[col8], p_mesh[col8], plz_mesh[col8], prz_mesh[col8], plz_sig[col8], prz_sig[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigy_z(p_sig[col8], p_sig2[col8], p_mesh[col8], plz_mesh[col8], prz_mesh[col8], plz_sig[col8], prz_sig[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Gradients of Gradients Computed\n")
      c.fflush(c.stdout)
    end

    -- Step1b: Compute Sig at Boundary, Sigb
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Computing Gradient at Interface\n")
      c.fflush(c.stdout)
    end
    __demand(__index_launch)
    for col8 in p_grid.colors do 
      Step1b_sigx_x2(p_sig[col8], p_sig2[col8], p_sigb[col8], p_mesh[col8], prx_mesh[col8], prx_sig[col8], prx_sig2[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
    end  

    if effD > 1 then
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigy_x2(p_sig[col8], p_sig2[col8], p_sigb[col8], p_mesh[col8], prx_mesh[col8], prx_sig[col8], prx_sig2[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigx_y2(p_sig[col8], p_sig2[col8], p_sigb[col8], p_mesh[col8], pry_mesh[col8], pry_sig[col8], pry_sig2[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigy_y2(p_sig[col8], p_sig2[col8], p_sigb[col8], p_mesh[col8], pry_mesh[col8], pry_sig[col8], pry_sig2[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
    end

    if effD > 2 then
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigz_x2(p_sig[col8], p_sig2[col8], p_sigb[col8], p_mesh[col8], prx_mesh[col8], prx_sig[col8], prx_sig2[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigz_y2(p_sig[col8], p_sig2[col8], p_sigb[col8], p_mesh[col8], pry_mesh[col8], pry_sig[col8], pry_sig2[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigx_z2(p_sig[col8], p_sig2[col8], p_sigb[col8], p_mesh[col8], prz_mesh[col8], prz_sig[col8], prz_sig2[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigy_z2(p_sig[col8], p_sig2[col8], p_sigb[col8], p_mesh[col8], prz_mesh[col8], prz_sig[col8], prz_sig2[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
      __demand(__index_launch)
      for col8 in p_grid.colors do 
        Step1b_sigz_z2(p_sig[col8], p_sig2[col8], p_sigb[col8], p_mesh[col8], prz_mesh[col8], prz_sig[col8], prz_sig2[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N)
      end  
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Gradients at boundary computed\n")
      c.fflush(c.stdout)
    end

    -- Step 1b_b: Interpolate boundary
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Interpolating to boundary\n")
      c.fflush(c.stdout)
    end
    __demand(__index_launch)
    for col8 in p_gridbarpb.colors do
      Step1b_b(p_sig[col8], p_mesh[col8], p_gridbarp[col8], p_gridbarpb[col8], prx_gridbarp[col8], pry_gridbarp[col8], prz_gridbarp[col8], prx_sig[col8], pry_sig[col8], prz_sig[col8], prx_mesh[col8], pry_mesh[col8], prz_mesh[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], BCs, N, effD)
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Interpolating to boundary Complete\n")
      c.fflush(c.stdout)
    end

    -- Step 1c
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Interpolating to velocity-dependent past at boundary\n")
      c.fflush(c.stdout)
    end
    __demand(__index_launch)
    for col8 in p_grid.colors do
      Step1c(p_gridbarpb[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], p_sigb[col8], dt, BCs, N, effD)
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Interpolating to Past Complete\n")
      c.fflush(c.stdout)
    end

    -- Step 2a
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Computing Wb\n")
      c.fflush(c.stdout)
    end
    __demand(__index_launch)
    for col8 in p_gridbarpb.colors do
      Step2a(p_gridbarpb[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], p_Wb[col8], dt, effD)
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Computed Wb\n")
      c.fflush(c.stdout)
    end

    -- Step 2b
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Computing original phi at boundary\n")
      c.fflush(c.stdout)
    end
    __demand(__index_launch)
    for col8 in p_gridbarpb.colors do
      Step2b(p_gridbarpb[col8], p_Wb[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], dt, R, K, Cv, g, w, ur, Tr, Pr, effD, thermal_bath, thermal_T)
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Computed original phi at boundary\n")
      c.fflush(c.stdout)
    end

    -- Step 2c
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Computing Microflux\n")
      c.fflush(c.stdout)
    end
    fill(r_F.g, 0)
    fill(r_F.b, 0)
    __demand(__index_launch)
    for col8 in p_gridbarpb.colors do
      Step2c(p_gridbarpb[col8], p_F[col8], p_mesh[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], plx_gridbarpb[col8], ply_gridbarpb[col8], plz_gridbarpb[col8], BCs, R, K, Cv, g, w, Tr, Pr, effD, N)
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Computed Microflux\n")
      c.fflush(c.stdout)
    end

    -- Step 3
    Step3()
    --__demand(__index_launch)
    --for col8 in p_gridbarp.colors do
    --  Step3(p_S[col8], p_W[col8], p_grid[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], R, K, Cv, N, g, w, ur, Tr, Pr, effD) -- TODO: vsig
    --end

    -- Step 4 and 5
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Updating W and Phi\n")
      c.fflush(c.stdout)
    end
    __demand(__index_launch)
    for col8 in p_grid.colors do
      Step4and5(p_grid[col8], p_W[col8], p_mesh[col8], p_F[col8], p_S[col8], pxmesh[col8], pymesh[col8], pzmesh[col8], dt, BCs, R, K, Cv, N, g, w, ur, Tr, Pr, effD, thermal_bath, thermal_T)
    end
    if config.debug == true then
      __fence(__execution, __block)
      c.printf("Updated W and Phi\n")
      c.fflush(c.stdout)
    end
    if dt < calcdt and config.out == true then
    
      dumpiter += 1
      Tdump = 0

      Dump(r_W, dumpiter)
      if config.phase == true then
        DumpPhase(r_grid, dumpiter)
      end

      __fence(__execution, __block)
      c.printf("Dump %d\n", dumpiter)
      c.fflush(c.stdout)
    else
      Tdump += dt
    end

    Tsim += dt

    __fence(__execution, __block)
    End = c.legion_get_current_time_in_nanos()
    PrintIteration(iter, Tsim, End, Start)
  end


  __fence(__execution, __block)
  End = c.legion_get_current_time_in_nanos()
  FinishSimulation(End, Start)
  c.fflush(c.stdout)
end

regentlib.start(toplevel)
