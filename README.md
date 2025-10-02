

\# Vapor Chamber Thermal Performance Analysis for Master's Thesis



\## 📝 Abstract

This repository contains the complete research materials for the Master's thesis titled "\[Your Thesis Title Here]". The project focuses on the design, simulation, and experimental validation of a high-performance, wick-based vapor chamber for electronics cooling applications. This repository includes all associated CAD models, simulation code, experimental procedures, raw data, and research notes.



---

\##  Repository Structure

This project is organized into the following directories:



├── README.md

├── CAD

├── Code

├── Experiment Data

├── Notes

---

\##  CAD Files

The `CAD/` directory contains the 3D models for all mechanical components of the vapor chamber and experimental test fixture.



\* \*\*Software Used: Solidworks 2024\*\*

\* \*\*Key Files:\*\*

&nbsp;   \* `GM-0005.SLDASM`: The main assembly file for the complete vapor chamber.

&nbsp;   \* `GM-0003.SLDPRT`: The top half of the VC shell with integrated support columns.

&nbsp;   \* `GM-0004.SLDPRT`: The bottom half of the VC shell.

\* \*\*Package Folder:\*\*

&nbsp;	\* Contains production step files and engineering drawings for fabrication. `Archive` is used for revision control 

\* \*\*Notes:\*\* All dimensions are in millimeters. Fabrication drawings are included in PDF format.



---

\##  Experimental Setup \& Procedure

The `Experiment/` directory contains all information related to the physical testing of the vapor chamber prototypes.



\### Hardware

\* \*\*Heating:\*\* TBD: 150W heating element

\* \*\*Cooling:\*\* TBD: A liquid-cooled cold plate connected to a recirculating water chiller.

\* \*\*Data Acquisition:\*\* TBD: Thermocouples

\* \*\*Vapor Chamber:\*\* Custom-fabricated copper vapor chamber with a multi-layer screen mesh wick, charged with deionized water.



\### Procedure

1\.  \*\*Assembly:\*\* Ensure consistent mounting pressure and uniform application of thermal interface material between the VC and the heater/cooler blocks.

2\.  \*\*Vacuum \& Charging:\*\* Evacuate the chamber to a target pressure of <10 Pa using an HVAC Vacuum pump. Charge with the calculated volume of deionized water using a precision syringe.

3\.  \*\*Testing:\*\* Apply power to the heater in 10W increments, allowing the system to reach steady-state at each interval. Log temperature data continuously at 1 Hz.

4\.  \*\*Data Collection:\*\* All raw experimental data is stored in the `Experiment/Data/` sub-folder in `.csv` format.



---

\##  MATLAB Simulation Code

The `Code/` directory contains the 1D analytical model used for design and performance prediction.



\* \*\*File:\*\* `VaporChamberCalcs1D.m`

\* \*\*Description:\*\* This script models the vapor chamber's performance by balancing the wick's capillary pressure against the liquid, vapor, and gravitational pressure drops. It calculates the maximum heat transport capacity (Q\_max) and the total thermal resistance.

\* \*\*How to Run:\*\*

&nbsp;   1.  Open the script in MATLAB.

&nbsp;   2.  Modify the parameters in the "USER-DEFINED INPUTS" section to match your design.

&nbsp;   3.  Run the script.

&nbsp;   4.  Results will be displayed in the command window.



---

\##  Project Notes

The `Notes/` directory serves as the research log for this project. It includes:

\* Weekly progress reports.

\* A literature review with summaries of key papers.

\* Preliminary data analysis and brainstorming sessions.



---

\### Author \& Contact

\* \*\*Gerardo Gutierrez\*\*

\* Master's Student, CSUF

\* \[gerardogutierrez6581@gmail.com] | \[https://www.linkedin.com/in/gerardo-s-gutierrez/]







