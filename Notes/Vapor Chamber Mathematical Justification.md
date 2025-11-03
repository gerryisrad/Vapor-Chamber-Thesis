# Mathematical Justification
## Introduction
This document is created to evaluate the performance of my experimental vapor chamber (VC) model. This is a 1-D, steady-state, analytical approach to solving for the performance of my conceptual VC. This document will serve as a helper-style guide to better understand the MATLAB code used to solve for a feasible VC. The script was made to provide a first-order prediction of the two performance metrics that define a VC's usefulness. 
- The first of these metrics is the **capillary heat transport limit ($Q_{max}$)**, which defines the maximum heat transfer rate that the VC can achieve before capillary (wick) limitations begin to cause failure during operation. This is typically attributed to a wick's inability to return sufficient liquid to the evaporator section of the VC, thereby failing to match the actual evaporation rate of the liquid under vacuum.
- The second metric of interest is the **total thermal resistance ($R_{th}$)**. This is a measure of the total opposition to heat flow from the outside of the evaporator to the outside of the condenser. It's extremely similar to electrical resistance. Where electrical resistance opposes the flow of electrical current, thermal resistance opposes the flow of heat energy. Having a lower thermal resistance means the vapor chamber can transfer heat more effectively with a smaller temperature difference, moving heat more efficiently.

This model will serve as a foundation for the initial design of the vapor chamber and its validation. It allows for the analysis of parametric sensitivity, enabling the user to quickly iterate on a design for a desired $Q_{max}$ and $R_{th}$, or any other desired variable. This enables users to attempt prototyping based on a verified model.

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
- $r_{c_{eff}} = \frac{1}{2*mesh_{number_{evap}}}$ (Effective Capillary Radius, m) approximates the pore radius as half the mesh opening width. A validation check makes sure $r_{c_{eff}} > 0$ to avoid having fake results. []() 
