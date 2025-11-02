%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Vapor Chamber 1D Analytical Model for Thesis Research
%
% Author: Gerardo Silvestre Gutierrez
% Date: 2025-10-11
%
% Description:
% This script implements a steady-state, 1D analytical model to evaluate
% the performance of a custom vapor chamber design. The model is based on
% the capillary limit pressure balance and a thermal resistance network.
% It uses screen mesh wick properties defined by mesh number, wire
% diameter, and layer count to predict Q_max and total thermal resistance.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all;

%% =================== 05.Wick Types for Cond and Evap ===================

Evap_Wick_Number = input("Input Evaporator Wick Number (80/200): ");

Cond_Wick_Number = input("Input Condensor Wick Number (80/200): ");

%% =================== 1. MODEL CONFIGURATION & INPUTS ===================
% All units are SI unless otherwise specified.

% --- Boundary Conditions & Operational Parameters ---
T_op = 70 + 273.15;   % Design-point operating temperature [K]
Q_in = 150;           % Target heat load for analysis [W]
phi = 0;              % Operational angle [deg] (0=horizontal)

% --- Fabrication & Experimental Parameters ---
filling_ratio = 0.30; % Target liquid filling ratio (FR) V_l/V_int
target_vacuum_Pa = 10;% Target pre-seal vacuum level [Pa] for NCG removal

% --- Model Calibration ---
experimental_correction_factor = 1.2; % Correction factor to align R_th with empirical data

% --- VC Envelope Geometry ---
vc_length = 0.070;    % Overall VC length [m]
vc_width  = 0.070;    % Overall VC width [m]

% --- Internal Component Geometry ---
t_evap_wall = 0.00225;% Evaporator wall thickness [m]
t_cond_wall = 0.00225;% Condenser wall thickness [m]
% t_vapor     = 0.00192;% Vapor core thickness [m]
t_int_tot   = 0.00357;% Vapor internal total thickness [m] 

% --- Heat Source Definition ---
evap_length = 0.020;  % Evaporator area length [m]
evap_width  = 0.020;  % Evaporator area width [m]

% --- Material Properties ---
k_shell = 380;        % Thermal conductivity of copper shell [W/m-K]

if Evap_Wick_Number == 200
    % --- Evaporator Wick Specification (Screen Mesh) 200 ---
    mesh_number_evap_wpi = 200;  % Mesh count [wires/inch]
    d_w_evap = 0.000051;         % Wire diameter [m]
    num_layers_evap = 5;        % Number of layers in the stack
elseif Evap_Wick_Number == 80
    % --- Evaporator Wick Specification (Screen Mesh) 80 ---
    mesh_number_evap_wpi = 80;  % Mesh count [wires/inch]
    d_w_evap = 0.00015;         % Wire diameter [m]
    num_layers_evap = 5;        % Number of layers in the stack
end

if Cond_Wick_Number == 200
    % --- Condenser Wick Specification (Screen Mesh) 200 ---
    mesh_number_cond_wpi = 200;   % Mesh count [wires/inch]
    d_w_cond = 0.000051;          % Wire diameter [m]
    num_layers_cond = 5;        % Number of layers in the stack
elseif Cond_Wick_Number == 80    
    % --- Condenser Wick Specification (Screen Mesh) 80 ---
    mesh_number_cond_wpi = 80;   % Mesh count [wires/inch]
    d_w_cond = 0.00015;          % Wire diameter [m]
    num_layers_cond = 5;        % Number of layers in the stack
end

%% =================== 2. THERMOPHYSICAL PROPERTIES ======================
% Working Fluid: Deionized Water at T_op.
% Properties sourced from standard steam tables for the specified T_op.
rho_l = 977.77;       % Liquid density [kg/m^3]
rho_v = 0.198;        % Vapor density [kg/m^3]
mu_l = 4.047e-4;      % Liquid dynamic viscosity [Pa-s]
mu_v = 1.10e-5;       % Vapor dynamic viscosity [Pa-s]
sigma = 0.0642;       % Surface tension [N/m]
h_fg = 2.338e6;       % Latent heat of vaporization [J/kg]
k_l = 0.662;          % Liquid thermal conductivity [W/m-K]
theta = 0;            % Assumed perfect wetting contact angle [deg]

%% =================== 3. DERIVED PARAMETER CALCULATION ==================
% --- Unit Conversions ---
in_to_m = 0.0254;
mesh_number_evap = mesh_number_evap_wpi / in_to_m; % [wires/m]
mesh_number_cond = mesh_number_cond_wpi / in_to_m; % [wires/m]

% --- Total Wick Thickness from Layer Specification ---
% Approximating single layer thickness as 2*d_w due to weave.
t_evap_wick = 2 * d_w_evap * num_layers_evap;
t_cond_wick = 2 * d_w_cond * num_layers_cond;

% --- Vapor Core Thickness ---
t_vapor = t_int_tot - t_evap_wick - t_cond_wick; % Vapor Core Thicnkess [m] (empty space)

% --- Screen Mesh Wick Characterization ---
% Standard correlations for porosity, capillary radius, and permeability.
epsilon_evap = 1 - (1.05 * pi * mesh_number_evap * d_w_evap) / 4; % Added weave factor for porosity (Blake)
epsilon_cond = 1 - (1.05 * pi * mesh_number_cond * d_w_cond) / 4; % Added weave factor for porosity (Blake)

rc_eff = 1 / (2 * mesh_number_evap); % Effective capillary radius [m], standard for screen mesh

% Validate capillary radius is positive
if rc_eff <= 0
    error('Effective capillary radius is non-positive. Check mesh parameters.');
end

K_evap = (d_w_evap^2 * epsilon_evap^3) / (122 * (1-epsilon_evap)^2); % Permeability [m^2]
K_cond = (d_w_cond^2 * epsilon_cond^3) / (122 * (1-epsilon_cond)^2); % Permeability [m^2]

% --- Characteristic Flow Length & Volumes ---
L_eff = vc_length / 2; % Effective length approximation for VCs. Reworked for center die spread
internal_area = vc_length * vc_width;
vol_vapor_space = internal_area * t_vapor;
vol_evap_wick_pore = internal_area * t_evap_wick * epsilon_evap;
vol_cond_wick_pore = internal_area * t_cond_wick * epsilon_cond;
vol_internal_total = vol_vapor_space + vol_evap_wick_pore + vol_cond_wick_pore;
liquid_charge_volume_mL = (vol_internal_total * filling_ratio) * 1e6; % Required liquid charge [mL]

% --- Cross-Sectional Areas for Flow Calculation ---
A_evap = evap_length * evap_width;
% A_cond = vc_length * vc_width;
A_cond = vc_length * vc_width; % Full condenser area [m²]
perimeter_evap = 2 * (evap_length + evap_width);  % All four sides
perimeter_cond = 2 * (vc_length + vc_width);
A_wick_evap_radial = t_evap_wick * perimeter_evap; % Radial
A_wick_cond_radial = t_cond_wick * perimeter_cond;
A_vapor = t_vapor * vc_width;

% --- Hydraulic Diameter of Vapor Core ---
d_h_vapor = (2 * t_vapor * vc_width) / (t_vapor + vc_width);

%% ============== 4. CAPILLARY PERFORMANCE ANALYSIS ======================
% Evaluate pressure balance to determine the capillary limit (Q_max).
% Condition for operation: dP_cap >= dP_total.

% --- Pressure Terms Calculation [Pa] ---
dP_cap = (2 * sigma * cosd(theta)) / rc_eff; % Capillary head (driving pressure)

L_flow_evap = evap_length / 4; % Average radial flow distance
L_flow_cond = sqrt((vc_length/2)^2 + (vc_width/2)^2) - sqrt((evap_length/2)^2 + (evap_width/2)^2);

dP_l_evap = (mu_l * Q_in * L_flow_evap) / (rho_l * A_wick_evap_radial * K_evap * h_fg); % fixed
dP_l_cond = (mu_l * Q_in * L_flow_cond) / (rho_l * A_wick_cond_radial * K_cond * h_fg);
dP_l = dP_l_cond + dP_l_evap; % Total liquid viscous loss

% For parallel plates with high aspect ratio (W/H >> 1)
AR_vapor = vc_width / t_vapor; % Aspect ratio of vapor core
% Ensure AR_vapor >= 1 for correlation validity
AR_use = max(AR_vapor, 1/AR_vapor);
if AR_use > 10
    C_vapor = 24; % Parallel plates approximation (Shah & London, 1978)
else
    % Use exact solution for rectangular ducts (Shah & London, 1978, Table 51)
    C_vapor = 24*(1 - 1.3553/AR_use + 1.9467/AR_use^2 - 1.7012/AR_use^3 + ...
              0.9564/AR_use^4 - 0.2537/AR_use^5);
end

dP_v = (C_vapor * mu_v * Q_in * L_eff) / (2 * rho_v * A_vapor * d_h_vapor^2 * h_fg); % Vapor viscous loss
g = 9.81;
dP_g = rho_l * g * L_eff * sind(phi); % Gravitational head
dP_total = dP_l + dP_v + dP_g; % Total pressure losses

% --- Maximum Heat Flux (Q_max) Calculation ---
% Rearranging the pressure balance equation to solve for Q at the limit.
liquid_coeff = (mu_l * L_flow_evap) / (rho_l * A_wick_evap_radial * K_evap * h_fg) + ...
               (mu_l * L_flow_cond) / (rho_l * A_wick_cond_radial * K_cond * h_fg);
vapor_coeff = (C_vapor * mu_v * L_eff) / (2 * rho_v * A_vapor * d_h_vapor^2 * h_fg);
Q_max = (dP_cap - dP_g) / (liquid_coeff + vapor_coeff);

%% ============== 5. THERMAL RESISTANCE NETWORK ANALYSIS ================
% Model VC as a 1D series thermal resistance network.

% --- Effective Wick Conductivity (k_wick) ---
% Perpendicular heat flow model for mesh screens.
k_wick_evap = epsilon_evap * k_l + (1 - epsilon_evap) * k_shell; % Parallel model
k_wick_cond = epsilon_cond * k_l + (1 - epsilon_cond) * k_shell; % Parallel model

% --- Vapor Core Resistance ---
T_sat_Pa = 31164; % Saturation pressure at 70°C [Pa]
v_fg = (1/rho_v) - (1/rho_l); % Specific volume change
dT_dP = (T_op * v_fg) / h_fg; % Clausius-Clapeyron approximation [K/Pa]

% --- Component Thermal Resistances [K/W] ---
R_evap_wall = t_evap_wall / (k_shell * A_evap);
R_evap_wick = t_evap_wick / (k_wick_evap * A_evap);

% sigma_evap = 1.0; % Accommodation coefficient for water (conservative)
sigma_evap = 0.1; % Accommodation coefficient for water (realistic average for copper surfaces)
M_water = 0.018; % Molar mass of water [kg/mol]
R_gas = 8314; % Universal gas constant [J/(mol·K)]
R_evap_interface = (T_op * sqrt(2 * pi * R_gas / M_water)) / (2 * sigma_evap * h_fg^2 * rho_v * A_evap);
R_cond_interface = (T_op * sqrt(2 * pi * R_gas / M_water)) / (2 * sigma_evap * h_fg^2 * rho_v * A_cond);
R_phase_change = R_evap_interface + R_cond_interface;

R_cond_wick = t_cond_wick / (k_wick_cond * A_cond);

% Vapor temperature drop using Clausius-Clapeyron
dT_vapor = dP_v * dT_dP; % [K]
R_vapor = dT_vapor / Q_in; % [K/W]

R_cond_wall = t_cond_wall / (k_shell * A_cond);
R_ideal = R_evap_wall + R_evap_wick + R_phase_change + R_vapor + R_cond_wick + R_cond_wall; % Renamed for consistency

% Spreading resistance in evaporator wall (approximation for finite source on infinite plate)
a = evap_length / 2; % Half-length of square evaporator [m]
t = t_evap_wall; % Wall thickness [m]
k = k_shell; % Wall conductivity [W/m-K]
R_spread_evap = (1 / (pi * k * a)) * (log(2 * a / t) + 0.5); % [K/W], simplified Lee model

% Similarly for condenser (symmetric, but often smaller; approximate as half for balance)
R_spread_cond = R_spread_evap / 2; % Conservative estimate

% Add to ideal resistance instead of multiplying (no further empirical factor)
R_corrected = R_ideal + R_spread_evap + R_spread_cond; % Corrected for spreading [K/W]

% --- Corrected Thermal Resistance ---
% Applying calibration factor to account for non-ideal experimental conditions.
R_total_corrected = R_ideal * experimental_correction_factor;

%% =================== 6. RESULTS SUMMARY ================================
fprintf('====================================================\n');
fprintf('   VAPOR CHAMBER 1D ANALYTICAL MODEL - RESULTS\n');
fprintf('====================================================\n\n');

fprintf('--- DERIVED WICK GEOMETRY ---\n');
fprintf('Total Evaporator Wick Thickness: %.2f mm\n', t_evap_wick * 1000);
fprintf('Total Condenser Wick Thickness:  %.2f mm\n', t_cond_wick * 1000);
fprintf('Evaporator Wick Porosity: %.3f\n', epsilon_evap);
fprintf('Condenser Wick Porosity:  %.3f\n', epsilon_cond);
fprintf('Effective Capillary Radius: %.2f μm\n\n', rc_eff * 1e6);

fprintf('--- FABRICATION TARGETS ---\n');
fprintf('Target Filling Ratio: %.0f %%\n', filling_ratio*100);
fprintf('Required Liquid Charge Volume: %.4f mL\n', liquid_charge_volume_mL);
fprintf('Target Initial Vacuum: %.2f Pa\n\n', target_vacuum_Pa);

fprintf('--- ANALYSIS CONDITIONS ---\n');
fprintf('Operating Temperature: %.1f °C\n', T_op - 273.15);
fprintf('Input Heat Load (Q_in): %.1f W\n', Q_in);
fprintf('Orientation Angle: %.1f degrees\n\n', phi);

fprintf('--- PRESSURE BALANCE ANALYSIS ---\n');
fprintf('Max Capillary Pressure (dP_cap):   %.2f Pa\n', dP_cap);
fprintf('Total Pressure Drop (dP_total):    %.2f Pa\n', dP_total);
fprintf('  - Liquid Drop (dP_l):            %.2f Pa\n', dP_l);
fprintf('    • Evaporator (dP_l_evap):      %.2f Pa\n', dP_l_evap);
fprintf('    • Condenser (dP_l_cond):       %.2f Pa\n', dP_l_cond);
fprintf('  - Vapor Drop (dP_v):             %.2f Pa\n', dP_v);
fprintf('  - Gravity Drop (dP_g):           %.2f Pa\n', dP_g);

fprintf('\n--- THERMAL RESISTANCE BREAKDOWN ---\n');
fprintf('R_evap_wall:      %.5f K/W (%.1f%%)\n', R_evap_wall, R_evap_wall/R_ideal*100);
fprintf('R_evap_wick:      %.5f K/W (%.1f%%)\n', R_evap_wick, R_evap_wick/R_ideal*100);
fprintf('R_phase_change:   %.5f K/W (%.1f%%)\n', R_phase_change, R_phase_change/R_ideal*100);
fprintf('R_vapor:          %.5f K/W (%.1f%%)\n', R_vapor, R_vapor/R_ideal*100);
fprintf('R_cond_wick:      %.5f K/W (%.1f%%)\n', R_cond_wick, R_cond_wick/R_ideal*100);
fprintf('R_cond_wall:      %.5f K/W (%.1f%%)\n', R_cond_wall, R_cond_wall/R_ideal*100);

fprintf('\n--- PREDICTED PERFORMANCE METRICS ---\n');
if dP_cap >= dP_total
    fprintf('YES! CAPILLARY LIMIT: MET for the specified heat load (%.1f W).\n', Q_in);
    fprintf('  Safety Factor: %.2f (dP_cap/dP_total)\n', dP_cap/dP_total);
else
    fprintf('NO! CAPILLARY LIMIT: FAILED. Wick cannot sustain the required flow.\n');
    fprintf('   The design is limited to Q_max = %.1f W under these conditions.\n', Q_max);
end

fprintf('Maximum Heat Transport (Q_max): %.1f W\n', Q_max);
fprintf('Ideal Thermal Resistance (R_ideal): %.4f K/W\n', R_ideal);
fprintf('Corrected Thermal Resistance (R_corrected): %.4f K/W\n', R_total_corrected);

delta_T = Q_in * R_total_corrected;
fprintf('Predicted Corrected Temp. Drop (ΔT): %.2f °C\n\n', delta_T);
