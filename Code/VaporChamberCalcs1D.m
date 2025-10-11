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
t_vapor     = 0.00192;% Vapor core thickness [m]

% --- Heat Source Definition ---
evap_length = 0.020;  % Evaporator area length [m]
evap_width  = 0.020;  % Evaporator area width [m]

% --- Material Properties ---
k_shell = 380;        % Thermal conductivity of copper shell [W/m-K]

% --- Evaporator Wick Specification (Screen Mesh) ---
mesh_number_evap_wpi = 200;  % Mesh count [wires/inch]
d_w_evap = 0.000051;         % Wire diameter [m]
num_layers_evap = 5;        % Number of layers in the stack

% --- Condenser Wick Specification (Screen Mesh) ---
mesh_number_cond_wpi = 80;   % Mesh count [wires/inch]
d_w_cond = 0.00015;          % Wire diameter [m]
num_layers_cond = 5;        % Number of layers in the stack

%% =================== 2. THERMOPHYSICAL PROPERTIES ======================
% Working Fluid: Deionized Water at T_op.
% Properties sourced from standard steam tables for the specified T_op.
rho_l = 977.8;        % Liquid density [kg/m^3]
rho_v = 0.198;        % Vapor density [kg/m^3]
mu_l = 4.04e-4;       % Liquid dynamic viscosity [Pa-s]
mu_v = 1.09e-5;       % Vapor dynamic viscosity [Pa-s]
sigma = 0.0644;       % Surface tension [N/m]
h_fg = 2.33e6;        % Latent heat of vaporization [J/kg]
k_l = 0.668;          % Liquid thermal conductivity [W/m-K]
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

% --- Screen Mesh Wick Characterization ---
% Standard correlations for porosity, capillary radius, and permeability.
epsilon_evap = 1 - (pi * mesh_number_evap * d_w_evap) / 4;
epsilon_cond = 1 - (pi * mesh_number_cond * d_w_cond) / 4;
rc_eff = 1 / (2 * mesh_number_evap); % Effective capillary radius, driven by evaporator mesh.
K_evap = (d_w_evap^2 * epsilon_evap^3) / (122 * (1-epsilon_evap)^2); % Permeability [m^2]
K_cond = (d_w_cond^2 * epsilon_cond^3) / (122 * (1-epsilon_cond)^2); % Permeability [m^2]

% --- Characteristic Flow Length & Volumes ---
L_eff = (vc_length + evap_length) / 4; % Effective length approximation for VCs.
internal_area = vc_length * vc_width;
vol_vapor_space = internal_area * t_vapor;
vol_evap_wick_pore = internal_area * t_evap_wick * epsilon_evap;
vol_cond_wick_pore = internal_area * t_cond_wick * epsilon_cond;
vol_internal_total = vol_vapor_space + vol_evap_wick_pore + vol_cond_wick_pore;
liquid_charge_volume_mL = (vol_internal_total * filling_ratio) * 1e6; % Required liquid charge [mL]

% --- Cross-Sectional Areas for Flow Calculation ---
A_evap = evap_length * evap_width;
% A_cond = vc_length * vc_width;
A_cond = (vc_length * vc_width) - A_evap; % finer calculation
A_wick_evap = t_evap_wick * vc_width;
A_wick_cond = t_cond_wick * vc_width;
A_vapor = t_vapor * vc_width;

% --- Hydraulic Diameter of Vapor Core ---
d_h_vapor = (2 * t_vapor * vc_width) / (t_vapor + vc_width);

%% ============== 4. CAPILLARY PERFORMANCE ANALYSIS ======================
% Evaluate pressure balance to determine the capillary limit (Q_max).
% Condition for operation: dP_cap >= dP_total.

% --- Pressure Terms Calculation [Pa] ---
dP_cap = (2 * sigma * cosd(theta)) / rc_eff; % Capillary head (driving pressure)
dP_l_cond = (mu_l * Q_in * (L_eff/2)) / (rho_l * A_wick_cond * K_cond * h_fg); % Liquid viscous loss (condenser)
dP_l_evap = (mu_l * Q_in * (L_eff/2)) / (rho_l * A_wick_evap * K_evap * h_fg); % Liquid viscous loss (evaporator)
dP_l = dP_l_cond + dP_l_evap; % Total liquid viscous loss
%C_vapor = 16; % Assumed f*Re constant for laminar vapor flow for pipe
C_vapor = 96; % Assumed f*Re constant for laminar vapor flow for two flat plates
dP_v = (C_vapor * mu_v * Q_in * L_eff) / (2 * rho_v * A_vapor * d_h_vapor^2 * h_fg); % Vapor viscous loss
g = 9.81;
dP_g = rho_l * g * L_eff * sind(phi); % Gravitational head
dP_total = dP_l + dP_v + dP_g; % Total pressure losses

% --- Maximum Heat Flux (Q_max) Calculation ---
% Rearranging the pressure balance equation to solve for Q at the limit.
vapor_pressure_term = (C_vapor*mu_v*L_eff)/(2*rho_v*A_vapor*d_h_vapor^2*h_fg);
liquid_pressure_term = (mu_l*(L_eff/2))/(rho_l*A_wick_cond*K_cond*h_fg) + ...
                       (mu_l*(L_eff/2))/(rho_l*A_wick_evap*K_evap*h_fg);
Q_max = (dP_cap - dP_g) / (liquid_pressure_term + vapor_pressure_term);
%% ============== 5. THERMAL RESISTANCE NETWORK ANALYSIS ================
% Model VC as a 1D series thermal resistance network.

% --- Effective Wick Conductivity (k_wick) ---
% Perpendicular heat flow model for mesh screens.
k_wick_evap = k_l * ((k_shell + k_l + (1-epsilon_evap)*(k_shell-k_l)) / (k_shell + k_l - (1-epsilon_evap)*(k_shell-k_l)));
k_wick_cond = k_l * ((k_shell + k_l + (1-epsilon_cond)*(k_shell-k_l)) / (k_shell + k_l - (1-epsilon_cond)*(k_shell-k_l)));

% --- Component Thermal Resistances [K/W] ---
R_evap_wall = t_evap_wall / (k_shell * A_evap);
R_evap_wick = t_evap_wick / (k_wick_evap * A_evap);
R_phase_change = 0.01; % Simplified placeholder for complex phase change phenomena.
R_cond_wick = t_cond_wick / (k_wick_cond * A_cond);
R_cond_wall = t_cond_wall / (k_shell * A_cond);
R_total_ideal = R_evap_wall + R_evap_wick + R_phase_change + R_cond_wick + R_cond_wall;

% --- Corrected Thermal Resistance ---
% Applying calibration factor to account for non-ideal experimental conditions.
R_total_corrected = R_total_ideal * experimental_correction_factor;

%% =================== 6. RESULTS SUMMARY ================================
fprintf('====================================================\n');
fprintf('   VAPOR CHAMBER 1D ANALYTICAL MODEL - RESULTS\n');
fprintf('====================================================\n\n');

fprintf('--- DERIVED WICK GEOMETRY ---\n');
fprintf('Total Evaporator Wick Thickness: %.2f mm\n', t_evap_wick * 1000);
fprintf('Total Condenser Wick Thickness:  %.2f mm\n\n', t_cond_wick * 1000);

fprintf('--- FABRICATION TARGETS ---\n');
fprintf('Target Filling Ratio: %.0f %%\n', filling_ratio*100);
fprintf('Required Liquid Charge Volume: %.4f mL\n', liquid_charge_volume_mL);
fprintf('Target Initial Vacuum: %.2f Pa\n\n', target_vacuum_Pa);

fprintf('--- ANALYSIS CONDITIONS ---\n');
fprintf('Operating Temperature: %.1f C\n', T_op - 273.15);
fprintf('Input Heat Load (Q_in): %.1f W\n', Q_in);
fprintf('Orientation Angle: %.1f degrees\n\n', phi);

fprintf('--- PRESSURE BALANCE ANALYSIS ---\n');
fprintf('Max Capillary Pressure (dP_cap):   %.2f Pa\n', dP_cap);
fprintf('Total Pressure Drop (dP_total):    %.2f Pa\n', dP_total);
fprintf('  - Liquid Drop (dP_l):            %.2f Pa\n', dP_l);
fprintf('  - Vapor Drop (dP_v):             %.2f Pa\n', dP_v);
fprintf('  - Gravity Drop (dP_g):           %.2f Pa\n', dP_g);

fprintf('\n--- PREDICTED PERFORMANCE METRICS ---\n');
if dP_cap >= dP_total
    fprintf('YES! CAPILLARY LIMIT: MET for the specified heat load (%.1f W).\n', Q_in);
else
    fprintf('NO! CAPILLARY LIMIT: FAILED. Wick cannot sustain the required flow.\n');
    fprintf('   The design is limited to Q_max = %.1f W under these conditions.\n', Q_max);
end

fprintf('Maximum Heat Transport (Q_max): %.1f W\n', Q_max);
fprintf('Ideal Thermal Resistance (R_ideal): %.4f K/W\n', R_total_ideal);
fprintf('Corrected Thermal Resistance (R_corrected): %.4f K/W\n', R_total_corrected);

delta_T = Q_in * R_total_corrected;
fprintf('Predicted Corrected Temp. Drop (ΔT): %.2f C\n\n', delta_T);

%% =================== 7. MODEL LIMITATIONS ==============================
% This 1D model serves as a first-order approximation. Deviations from
% experimental results are expected due to:
%   1. 3D heat spreading and fluid flow phenomena.
%   2. Complex boiling/condensation heat transfer coefficients not captured
%      by the simplified R_phase_change.
%   3. Unaccounted for contact resistances (e.g., wick-shell, TIMs).
%   4. Assumption of a perfect vacuum (zero NCGs).
%
% The experimental_correction_factor is intended to help bridge the gap
% between this idealized model and empirical measurements.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%