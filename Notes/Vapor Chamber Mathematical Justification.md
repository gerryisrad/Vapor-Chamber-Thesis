# Mathematical Justification
## Introduction
This document is created to evaluate the performance of my experimental vapor chamber (VC) model. This is a 1-D, steady-state, analytical approach to solving for the performance of my conceptual VC. This document will serve as a helper-style guide to better understand the MATLAB code used to solve for a feasible VC. The script was made to provide a first-order prediction of the two performance metrics that define a VC's usefulness. 
- The first of these metrics is the **capillary heat transport limit ($Q_{max}$)**, which defines the maximum heat transfer rate that the VC can achieve before capillary (wick) limitations begin to cause failure during operation. This is typically attributed to a wick's inability to return sufficient liquid to the evaporator section of the VC, thereby failing to match the actual evaporation rate of the liquid under vacuum.
- The second metric of interest is the **total thermal resistance ($R_{th}$)**. This is a measure of the total opposition to heat flow from the outside of the evaporator to the outside of the condenser. It's extremely similar to electrical resistance. Where electrical resistance opposes the flow of electrical current, thermal resistance opposes the flow of heat energy. Having a lower thermal resistance means the vapor chamber can transfer heat more effectively with a smaller temperature difference, moving heat more efficiently.

This model will serve as a foundation for the initial design of the vapor chamber and its validation. It allows for the analysis of parametric sensitivity, enabling the user to quickly iterate on a design for a desired $Q_{max}$ and $R_{th}$, or any other desired variable. This enables users to attempt prototyping based on a verified model.

It is divided into two main analytical sections: 
- The first is an analysis of the pressure balance to determine the operational limits of the wick structure. This is important as it verifies if the pumping done by the vapor chamber will function correctly under the given heat load and frictional forces. 
- The second is a thermal resistance circuit analysis to predict the temperature drop across the entire VC.
## 1.1 Model Configuration and Inputs
This section is dedicated to defining physical parameters and user-inputted variables, such as wick density.
### Boundary Conditions & Operational Parameters
1. $T_{op}$ (Operational Temperature, K) is defined by the user as the operating temperature of the vapor chamber and the working fluid inside the VC.
2. $Q_{in}$ (Input Heat Load, W) is the heat load inputted at the evaporator. Think of this as the heat input we are trying to dissipate. This will come from an ASIC, CPU, or GPU die. This is used to calculate the required fluid flow rate and resulting pressure drops throughout the VC system.
3. $\phi$ (Inclination Angle, Degrees) is the orientation of the VC with respect to the pull of gravity. Used to calculate the gravitational head ${\Delta}P_{g}$ that the wicks have to overcome in pumping (capillary action).
### Fabrication and Experimental Parameters
The following parameters pertain to the physical design of the VC prototype.
1. FR (Filling Ratio) is the liquid filling ratio (water). This is a ratio based on the volume of the fluid over the volume of the void space (vapor space + wick pore volume). This is an important parameter that affects the dry-out potential of the VC or increases thermal resistance. Too little fluid will cause early dryout, while too much liquid causes increased thermal resistance and obstructs vapor flow. This number has been set to 30% based on my literature review.
2. $P_{vac}$ (Target Vacuum) is the vacuum goal for the VC. We need to evacuate any non-condensable gases that would detrimentally degrade the condensation and performance of the VC. The hope is <10Pa to make sure the working fluid (water) is the most prominent.
### VC Geometry and Material Properties

