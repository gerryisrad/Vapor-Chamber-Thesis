# Mathematical Justification
## Introduction
This document is created to do the logic of my 1D theoretical vapor chamber (VC) model. This is a 1-D, steady-state, analytical approach to solving for the performance of my conceptual VC. This document will serve as a helper-style guide to better understand the MATLAB code used to solve for a feasible VC. The script was made to provide a first-order prediction of the two performance metrics that define a VC's usefulness. 
- The first of these metrics is the **capillary heat transport limit ($Q_{max}$)**, which defines the maximum heat transfer rate that the VC can achieve before capillary (wick) limitations begin to cause failure during operation. This is typically attributed to a wick's inability to return sufficient liquid to the evaporator section of the VC, thereby failing to match the actual evaporation rate of the liquid under vacuum.
- The second metric of interest is the **total thermal resistance ($R_{th}$)**. This is a measure of the total opposition to heat flow from the outside of the evaporator to the outside of the condenser. It's extremely similar to electrical resistance. Where electrical resistance opposes the flow of electrical current, thermal resistance opposes the flow of heat energy. Having a lower thermal resistance means the vapor chamber can transfer heat more effectively with a smaller temperature difference, moving heat more efficiently.

This model will serve as a foundation for the initial experimental design of the vapor chamber and its validation. It allows for the analysis of parametric sensitivity, enabling the user to quickly iterate on a design for a desired $Q_{max}$ and $R_{th}$, or any other desired variable. This enables users to attempt prototyping based on a verified model.

It is divided into two main analytical sections: 
- The first is an analysis of the pressure balance to determine the operational limits of the wick structure. This is important as it verifies if the pumping done by the vapor chamber will function correctly under the given heat load and frictional forces. 
- The second is a thermal resistance circuit analysis to predict the temperature drop across the entire VC.
## 1 Model Configuration and Inputs
This section is dedicated to defining physical parameters and user-inputted variables, such as wick density.
### Boundary Conditions & Operational Parameters
1. $T_{op}$ (Operational Temperature, K) is defined by the user as the operating temperature of the vapor chamber and the working fluid inside the VC.
2. $Q_{in}$ (Input Heat Load, W) is the heat load inputted at the evaporator. Please think of this as the heat input we are trying to dissipate. This will come from an ASIC, CPU, or GPU die. This is used to calculate the required fluid flow rate and resulting pressure drops throughout the VC system.
3. $\phi$ (Inclination Angle, Degrees) is the orientation of the VC with respect to the pull of gravity. Used to calculate the gravitational head ${\Delta}P_{g}$ that the wicks have to overcome in pumping (capillary action).
### Fabrication and Experimental Parameters
The following parameters pertain to the physical design of the VC prototype.
1. FR (Filling Ratio) is the liquid filling ratio (water). This is a ratio based on the volume of the fluid over the volume of the void space (vapor space + wick pore volume). This is an important parameter that affects the dry-out potential of the VC or increases thermal resistance. Too little fluid will cause early dryout, while too much liquid causes increased thermal resistance and obstructs vapor flow. This number has been set to 30% based on my literature review.
2. $P_{vac}$ (Target Vacuum) is the vacuum goal for the VC. We need to evacuate any non-condensable gases that would detrimentally degrade the condensation and performance of the VC. The hope is <10Pa to make sure the working fluid (water) is the most prominent.
### VC Geometry and Material Properties
This section defines the physical dimensions and material of the VC. 
- $vc_{length}$ and $vc_{width}$ ((m)eters) are the width and length of the vapor chamber. For this project, the length and width are identical to make a square
- $t_{vapor}$ and $t_{wall}$ are the thicknesses of the solid walls of the vapor chamber. These are critical for understanding thermal resistance in our VC network. Use a uniform thickness for this script.
- $k_{shell}$ (Shell Thermal Conductivity) is the thermal conductivity value for the vapor chamber walls. In this case, the properties of C11000 copper were used.
- Wick Specifications were defined as follows
  - $d_{w}$ (Mesh number) is the wire count per unit length, which determines the capillary pore radius ($r_{app}$) and therefore the total capillary pressure. As you can see, a higher mesh number yields a smaller pore size and more pumping capability.
  - $d_{w}$ (Wire Diameter) is used in conjunction with the mesh number to calculate the porosity and permeability of the mesh.
  - $n_{layers}$ (Number of Layers) is the total thickness of the wick as you stack layers. This helps determine the vapor core dimensions during the design process. This, of course, also defines the cross-sectional area for liquid flow ($A_{wick}$), which reduces the liquid pressure drop ($\Delta P_{l}$). This is most helpful when designing for specific wick types and hybrid wick approaches.

## 2 Thermophysical Properties
This section defines the thermophysical properties of the working fluid that will be used in the experimental setup for this VC. The working fluid for this VC is deionized water, which is non-conductive and suitable for use at the operating temperature $T_{op}$. These were taken from the steam charts as known values. You could interpolate them from a function if needed, but for a rough model like this, it didn't make sense for me to do so.
### Fluid Density and Viscosity
- $\rho_{l}$ (liquid density) is the density of the liquid phase of the working fluid. We use this for mass flow rate and gravitational head.
- $\rho_{v}$ (vapor density) is the density of the vapor phase of the working fluid. This will be used later to calculate the pressure drop in the vapor core, where the phase change occurs.
- $\mu_{l}$ (dynamic viscosity of liquid) is the viscosity of the liquid. This affects the pressure drop in the wic and the capillary pumping effect.
- $\mu_{v}$ (dynamic viscosity of vapor) is the viscosity of the vapor. Used to find the Reynolds number in the flow resistance equation.
### Surface and Thermal Properties
- $\sigma$ (Surface tension) is the surface tension of the mesh wick. This is the property that really determines the capillary pressure ($\Delta P_{cap}$) in the mesh wick, which drives the fluid circulation via capillary action. A higher surface tension value would increase the pumping capacity of the mesh
- $h_{fg}$ (Latent Heat) is the energy that is required to vaporize the liquid. To solve for dry-outthe mass flwo rate equation $\left(\dot{m} = \frac{Q_{in}}{h_{fg}}\right)$
- $k_{l}$ (Thermal Conductivity of Liquid) is the thermal conductivity of the liquid phase of the medium. This influences the effective thermal resistance in the wick and heat transfer rates during evaporation and condensation
### Wetting Properties
- $\theta$ (Contact Angle (Degrees)) is the angle of the VC where a flat ground is zero. More specifically, it is the angle between the liquid and the wick surface. 0 degrees is assumed for this VC setup. Angles don't seem to affect ultra-thin VCs.
## Derived Parameter Calculation
This section computes the majority of the wick characteristics and VC-specific calculations based on the values defined in the previous two sections. Additionally, flow areas, volumes, and hydraulic properties are calculated in order to model the VC performance. The calculations in this section enable the prediction of pressure drips, capillary limits, and overall heat transfer efficiency.
### Unit Conversions
This small but crucial part of section 3 converts units for consistency in mesh parameters. I converted to SI from imperial as it's easier for me to think in SI units :P.
- $in_{to_{m}}$ = 0.0254; A standard conversion factor used for our wires per inch (wpi) conversions.
- $mesh_{number_{evap}} = \frac{mesh_{number_{evap_{wpi}}}}{in_{to_{m}}}$ (Evaporator Mesh Number, wires/m) converts the evap wick mesh density to metric units. This affects pore size and capillary action calculations.
- $mesh_{number_{cond}} = \frac{mesh_{number_{cond_{wpi}}}}{in_{to_{m}}}$ (Condenser Mesh Number, wires/m) performs the same conversion for the condensor wick. The rest of this section will follow a similar flow where twin equations are calculated to differentiate the condenser wick and the evaporator wick.
### Wick Thickness
The wick thickness calculation approximates the wick thickness based on the wire diameter and layering.
- $t_{evap_{wick}} = 2*d_{w_{evap}}*num_{layers_{evap}}$ (Evaporator Wick Thickness, m) estimates the total thickness as twice the wire diameter per layer by the number of total layers.
- $t_{cond_{wick}} = 2*d_{w_{cond}}*num_{layers_{cond}}$ (Condenser Wick Thickness, m) same as before, but for condenser side.
### Vapor Core 
- $t_{vapor}$ describes the empty (vapor) space between the two mesh wicks. This is the empty space where vapor can spread. It's a difference of the taken space (by the wick) and the total space inside the vapor cavity.
- $\epsilon_{evap} = 1 - \frac{1.05*\pi*mesh_{number_{evap}}*d_{w_{evap}}}{4}$ (Evaporator Porosity) is a modified form of the mesh porosity equation with a 1.05 factor that accounts for crimping in woven meshes, derived from empirical correlations. [Zhao, Zenghui & Peles, Yoav & Jensen, M.K.. (2013). Properties of plain weave metallic wire mesh screens. International Journal of Heat and Mass Transfer. 57. 690-697. 10.1016/j.ijheatmasstransfer.2012.10.055.](https://www.researchgate.net/publication/275192568_Properties_of_plain_weave_metallic_wire_mesh_screens) [Zohuri, B. (2016). Heat Pipe Design and Technology: A Practical Approach. Springer International Publishing, Cham, Switzerland. p. 91 (Table 2.2: Wick Permeability K for Several Wick Structures; Wrapped Screen Wick subsection)]
- $\epsilon_{cond} = 1 - \frac{1.05*\pi*mesh_{number_{cond}}*d_{w_{cond}}}{4}$ (Condenser Porosity) is the same as the equation before, but for the condenser side
- $r_{c_{eff}} = \frac{1}{2*mesh_{number_{evap}}}$ (Effective Capillary Radius, m) approximates the pore radius as half the mesh opening width. A validation check makes sure $r_{c_{eff}} > 0$ to avoid having fake results.
- $K_{evap} = \frac{d_{w_{evap}}^{2}\epsilon_{evap}^{3}}{122(1-\epsilon_{evap}^{2})}$ (Evaporator Permeability, $m^{2}$) uses the Kozeny-Carman equation to determine the permeability of the mesh. The 122 constant is used from a paper. [Davoud Jafari, Wessel W. Wits, Bernard J. Geurts, Metal 3D-printed wick structures for heat pipe application: Capillary performance analysis, Applied Thermal Engineering, Volume 143,2018,Pages 403-414,](https://www.sciencedirect.com/science/article/pii/S1359431118322981)
- $K_{cond} = \frac{d_{w_{cond}}^{2}\epsilon_{cond}^{3}}{122(1-\epsilon_{cond}^{2})}$ (Condenser Permeability, $m^{2}$) is solved for the same reason as the last equation. [Davoud Jafari, Wessel W. Wits, Bernard J. Geurts, Metal 3D-printed wick structures for heat pipe application: Capillary performance analysis, Applied Thermal Engineering, Volume 143,2018,Pages 403-414,](https://www.sciencedirect.com/science/article/pii/S1359431118322981)
### Characteristic Flow Lengths and Volumes
This section determines the internal volumes for filling and performance modeling.
- $L_{eff} = \frac{vc_{length}}{2}$ (Effective Length, m) is the distance between the evaporator and condenser that the fluid travels through. This is used for pressure drop simplifications
- $internal_{area} = vc_{length}vc_{width}$ (Internal Cross-Sectional Area, $m^{2}$) is the area inside the vc that is then used for volume calculation.
- $vol_{vapor_{space}} = internal_{area}t_{vapor}$ (Vapor Space Volume, $m^{3}$) empty volume between evap wick and cond wick
- $vol_{evap_{wick_{pore}}} = internal_{area} t_{evap_{wick}} \epsilon_{evap}$ (Evaporator Wick Pore Volume, $m^{3}$) is the liquid-holding-space of the evaporator wick pores 
- $vol_{cond_{wick_{pore}}} = internal_{area} t_{cond_{wick}} \epsilon_{cond}$ (Condenser Wick Pore Volume, $m^{3}$) same as previous line but for condenser
- $vol_{internal_{total}} = vol_{vapor_{space}} + vol_{evap_{wick_{pore}}} + vol_{cond_{wick_{pore}}}$ (Tootla Internal Volume, $m^{3}$) sums all internal "void space"
- $liquid_{charge_{volume_{mL}}} = (vol_{internal_{total}} filling_{ratio}) \times 10^6$ (Liquid Charge Volume, mL) determines the volume that the working fluid would take
### Cross-Sectional Areas for Flow Calculation
Defining areas for flow rate and pressure drop equations, assuming radial and axial flow paths
- $A_{evap} = evap_{length} \times evap_{width}$ (Evaporator Area, $m^{2}$) Defines the area of the evaporator input side
- $A_{cond} = vc_{length} \times vc_{width}$ (Condenser Area, $m^{2}$) Defines the area of the condensor side. Since the heat is being dissipated by the entire copper area, we use that size
- $perimeter_{evap} = 2 \times (evap_{length} + evap_{width})$(Evaporator Perimeter, m) is the boundary for radial flow.
- $perimeter_{cond} = 2 \times (vc_{length} + vc_{width})$ (Condenser Perimeter, m) is the boundary for the radial flow
- $A_{wick_{evap_{radial}}} = t_{evap_{wick}} \times perimeter_{evap}$ (Evaporator Wick Radial Cross-Sectional Area, $m^{2}$) is the area that liquid can flow in the radial direction
- $A_{wick_{cond_{radial}}} = t_{cond_{wick}} \times perimeter_{cond}$ (Condenser Wick Radial Cross-Sectional Area, $m^{2}$) same as evap
- $A_{vapor} = t_{vapor} \times vc_{width}$ (Vapor Flow Cross-Sectional Area, $m^{2}$) is used for vapor transport
### Hydraulic Diameter of Vapor Core
- $d_{h_{vapor}} = \frac{2 \times t_{vapor} \times vc_{width}}{t_{vapor} + vc_{width}}$ (Vapor Core Hydraulic Diameter, m) calcautes the effective vapor flow in non-circular channels, used for reynolds number $\left( Re = \frac{\rho_{v}vd_{h}}{\mu_{v}} \right)$ and friciton factor corrleations for $\Delta P_{v}$
## 4 Capillary Performance Analysis
This section is meant to evaluate the capillary performance of the vapor chamber by determining the pressure head and comparing it to the total pressure loss in the VC. We want the capillary pressure head to exceed or equal the total pressure loss to prevent dry out. We will evaluate the capillary limit, which is the typical failure mode in the VC. The calculations are based on standard heat pipe theory.
### Pressure Terms Calculation
These terms are used to compute the pressure contributions from each component/combination of components. This will help us figure out our performance limits under operating conditions.
- $\Delta P_{cap} = \frac{2 \sigma \cos\theta}{r_{c_{eff}}}$ (Capillary Pressure Head, Pa) is the max driving pressure generated by the water tension force coming from the wick pores. [Wikipedia Link for Young Laplace eqn](https://en.wikipedia.org/wiki/Capillary_pressure)
- $L_{flow_{evap}} = \frac{evap_{length}}{4}$ (Evaporator Flow Length, m) The radial distance that liquid travels in the evaporator wick from edge to approximate center. A circular flow is easier to use here. (Fagahri Cite)
- $L_{flow_{cond}} = \sqrt{\left(\frac{vc_{length}}{2}\right)^2 + \left(\frac{vc_{width}}{2}\right)^2} - \sqrt{\left(\frac{evap_{length}}{2}\right)^2 + \left(\frac{evap_{width}}{2}\right)^2}$ (Condenser Flow Length, m) Same idea as evaporator side but for the whole VC internal size.
- $\Delta P_{l_{evap}} = \frac{\mu_l Q_{in} L_{flow_{evap}}}{\rho_l A_{wick_{evap_{radial}}} K_{evap} h_{fg}}$ (Evaporator Liquid Pressure Drop, Pa)is used to estimate the losses due to viscous liquid in the vaporator wick using Darcy's law for porous media flow. This is one of the pressure portions that the capillary head has to overcome (link to Darcy)
- $\Delta P_{l_{cond}} = \frac{\mu_l Q_{in} L_{flow_{cond}}}{\rho_l A_{wick_{cond_{radial}}} K_{cond} h_{fg}}$ (Condenser Liquid Pressure Drop, Pa) Same formula but for the condensor
- $\Delta P_l = \Delta P_{l_{cond}} + \Delta P_{l_{evap}}$ (Total Liquid Pressure Drop, Pa) Sums the losses due to the evap and condenser.
- $AR_{vapor} = \frac{vc_{width}}{t_{vapor}}$ (Vapor Core Aspect Ratio, dimensionless) Width to height ratio of the vapor "channel". This is used when using an empirical friction correlation for non-circular ducts.
- $AR_{use} = \max(AR_{vapor}, 1/AR_{vapor})$ (Adjusted Aspect Ratio, dimensionless) ensures aspect ratio conformity.
- $C_{vapor}$ (Vapor Friction Constant, dimensionless) is determined based on $AR_{use}$:
   - If $AR_{use} > 10$, $C_{vapor} = 24$ (parallel plates approximation).
   - Otherwise, $C_{vapor} = 24 \left(1 - \frac{1.3553}{AR_{use}} + \frac{1.9467}{AR_{use}^2} - \frac{1.7012}{AR_{use}^3} + \frac{0.9564}{AR_{use}^4} - \frac{0.2537}{AR_{use}^5}\right)$.
   This polynomial is an exact solution for fully developed laminar flow in rectangular ducts, used in the friction factor $f$
## 5 Thermal Resistance Network Analysis
This section models the vapor chamber as a 1D thermal resistance network to estimate the total thermal performance of the VC. We sum the individual resistances (conduction, phase change, and vapor transport), and the model predicts the temperature drop across the VC for a given heat load $Q_{in}$. This is a huge simplification from a 3d model. Formulas are based on heat transfer principles and the literature on heat pipes. 
### Effective Wick Conductivity
The *effective* thermal conductivity of the wick accounts for the wick structure and its porosity when filled with water.
- $k_{wick_{evap}} = \epsilon_{evap} k_l + (1 - \epsilon_{evap}) k_{shell}$ (Evaporator Wick Effective Conductivity, W/m·K) (Heat Pipe Science and Technology Faghri eqn 3.30)
- $k_{wick_{cond}} = \epsilon_{cond} k_l + (1 - \epsilon_{cond}) k_{shell}$ (Condenser Wick Effective Conductivity, W/m·K) (Heat Pipe Science and Technology Faghri eqn 3.30)
### Vapor Core Resistance
The following variables are used to calculate the temperature drops due to vapor pressure variations
- $T_{sat_{Pa}} = 31164$ (Saturation Pressure at 70°C, Pa) Known constant derived from table
- $v_{fg} = \frac{1}{\rho_v} - \frac{1}{\rho_l}$ (Specific Volume Change, m³/kg) [Thermodynamics, an Engineering Approach]
- $\frac{dT}{dP} = \frac{T_{op} v_{fg}}{h_{fg}}$ (Temperature-Pressure Derivative, K/Pa) Clapeyron Equation [Thermodynamics, an Engineering Approach]
### Component Thermal Resistances
These calculations determine individual resistances in the network, focusing on conduction through walls and wicks, as well as phase change at interfaces.
- $R_{evap_{wall}} = \frac{t_{evap_{wall}}}{k_{shell} A_{evap}}$ (Evaporator Wall Resistance, K/W)
- $R_{evap_{wick}} = \frac{t_{evap_{wick}}}{k_{wick_{evap}} A_{evap}}$ (Evaporator Wick Resistance, K/W)
- $\sigma_{evap} = 0.1$ (Evaporation Accommodation Coefficient, dimensionless)
