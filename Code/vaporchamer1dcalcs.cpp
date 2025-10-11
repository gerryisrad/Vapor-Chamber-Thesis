#include <iostream>
#include <cmath>
#include <iomanip>

// Define PI if not already defined in <cmath>
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Function to convert degrees to radians
double toRadians(double degrees) {
    return degrees * M_PI / 180.0;
}

int main() {
    // =================== 1. MODEL CONFIGURATION & INPUTS ===================
    // --- Boundary Conditions & Operational Parameters ---
    const double T_op = 70 + 273.15;   // Design-point operating temperature [K]
    const double Q_in = 150;           // Target heat load for analysis [W]
    const double phi_deg = 0;          // Operational angle [deg] (0=horizontal)

    // --- Fabrication & Experimental Parameters ---
    const double filling_ratio = 0.30;
    const double target_vacuum_Pa = 10;

    // --- Model Calibration ---
    const double experimental_correction_factor = 1.2;

    // --- VC Envelope Geometry ---
    const double vc_length = 0.070;
    const double vc_width  = 0.070;

    // --- Internal Component Geometry ---
    const double t_evap_wall = 0.00225;
    const double t_cond_wall = 0.00225;
    const double t_vapor     = 0.00192;

    // --- Heat Source Definition ---
    const double evap_length = 0.020;
    const double evap_width  = 0.020;

    // --- Material Properties ---
    const double k_shell = 380;

    // --- Evaporator Wick Specification (Screen Mesh) ---
    const double mesh_number_evap_wpi = 200;
    const double d_w_evap = 0.000051;
    const int num_layers_evap = 5;

    // --- Condenser Wick Specification (Screen Mesh) ---
    const double mesh_number_cond_wpi = 80;
    const double d_w_cond = 0.00015;
    const int num_layers_cond = 5;

    // =================== 2. THERMOPHYSICAL PROPERTIES ======================
    // Working Fluid: Deionized Water at T_op
    const double rho_l = 977.8;
    const double rho_v = 0.198;
    const double mu_l = 4.04e-4;
    const double mu_v = 1.09e-5;
    const double sigma = 0.0644;
    const double h_fg = 2.33e6;
    const double k_l = 0.668;
    const double theta_deg = 0;

    // =================== 3. DERIVED PARAMETER CALCULATION ==================
    // --- Unit Conversions ---
    const double in_to_m = 0.0254;
    const double mesh_number_evap = mesh_number_evap_wpi / in_to_m;
    const double mesh_number_cond = mesh_number_cond_wpi / in_to_m;

    // --- Total Wick Thickness ---
    const double t_evap_wick = 2 * d_w_evap * num_layers_evap;
    const double t_cond_wick = 2 * d_w_cond * num_layers_cond;

    // --- Screen Mesh Wick Characterization ---
    const double epsilon_evap = 1 - (M_PI * mesh_number_evap * d_w_evap) / 4;
    const double epsilon_cond = 1 - (M_PI * mesh_number_cond * d_w_cond) / 4;
    const double rc_eff = 1 / (2 * mesh_number_evap);
    const double K_evap = (pow(d_w_evap, 2) * pow(epsilon_evap, 3)) / (122 * pow(1 - epsilon_evap, 2));
    const double K_cond = (pow(d_w_cond, 2) * pow(epsilon_cond, 3)) / (122 * pow(1 - epsilon_cond, 2));

    // --- Characteristic Flow Length & Volumes ---
    const double L_eff = (vc_length + evap_length) / 4;
    const double internal_area = vc_length * vc_width;
    const double vol_vapor_space = internal_area * t_vapor;
    const double vol_evap_wick_pore = internal_area * t_evap_wick * epsilon_evap;
    const double vol_cond_wick_pore = internal_area * t_cond_wick * epsilon_cond;
    const double vol_internal_total = vol_vapor_space + vol_evap_wick_pore + vol_cond_wick_pore;
    const double liquid_charge_volume_mL = (vol_internal_total * filling_ratio) * 1e6;

    // --- Cross-Sectional Areas ---
    const double A_evap = evap_length * evap_width;
    const double A_cond = (vc_length * vc_width) - A_evap;
    const double A_wick_evap = t_evap_wick * vc_width;
    const double A_wick_cond = t_cond_wick * vc_width;
    const double A_vapor = t_vapor * vc_width;

    // --- Hydraulic Diameter ---
    const double d_h_vapor = (2 * t_vapor * vc_width) / (t_vapor + vc_width);

    // ============== 4. CAPILLARY PERFORMANCE ANALYSIS ======================
    // --- Angle Conversions to Radians ---
    const double phi = toRadians(phi_deg);
    const double theta = toRadians(theta_deg);

    // --- Pressure Terms Calculation ---
    const double dP_cap = (2 * sigma * cos(theta)) / rc_eff;
    const double dP_l_cond = (mu_l * Q_in * (L_eff / 2)) / (rho_l * A_wick_cond * K_cond * h_fg);
    const double dP_l_evap = (mu_l * Q_in * (L_eff / 2)) / (rho_l * A_wick_evap * K_evap * h_fg);
    const double dP_l = dP_l_cond + dP_l_evap;
    const double C_vapor = 96;
    const double dP_v = (C_vapor * mu_v * Q_in * L_eff) / (2 * rho_v * A_vapor * pow(d_h_vapor, 2) * h_fg);
    const double g = 9.81;
    const double dP_g = rho_l * g * L_eff * sin(phi);
    const double dP_total = dP_l + dP_v + dP_g;

    // --- Maximum Heat Flux (Q_max) Calculation ---
    const double vapor_pressure_term = (C_vapor * mu_v * L_eff) / (2 * rho_v * A_vapor * pow(d_h_vapor, 2) * h_fg);
    const double liquid_pressure_term = ((mu_l * (L_eff / 2)) / (rho_l * A_wick_cond * K_cond * h_fg)) +
                                        ((mu_l * (L_eff / 2)) / (rho_l * A_wick_evap * K_evap * h_fg));
    const double Q_max = (dP_cap - dP_g) / (liquid_pressure_term + vapor_pressure_term);

    // ============== 5. THERMAL RESISTANCE NETWORK ANALYSIS ================
    // --- Effective Wick Conductivity ---
    const double k_wick_evap = k_l * ((k_shell + k_l + (1 - epsilon_evap) * (k_shell - k_l)) /
                                      (k_shell + k_l - (1 - epsilon_evap) * (k_shell - k_l)));
    const double k_wick_cond = k_l * ((k_shell + k_l + (1 - epsilon_cond) * (k_shell - k_l)) /
                                      (k_shell + k_l - (1 - epsilon_cond) * (k_shell - k_l)));

    // --- Component Thermal Resistances ---
    const double R_evap_wall = t_evap_wall / (k_shell * A_evap);
    const double R_evap_wick = t_evap_wick / (k_wick_evap * A_evap);
    const double R_phase_change = 0.01;
    const double R_cond_wick = t_cond_wick / (k_wick_cond * A_cond);
    const double R_cond_wall = t_cond_wall / (k_shell * A_cond);
    const double R_total_ideal = R_evap_wall + R_evap_wick + R_phase_change + R_cond_wick + R_cond_wall;

    // --- Corrected Thermal Resistance ---
    const double R_total_corrected = R_total_ideal * experimental_correction_factor;

    // =================== 6. RESULTS SUMMARY ================================
    std::cout << "====================================================\n";
    std::cout << "   VAPOR CHAMBER 1D ANALYTICAL MODEL - RESULTS\n";
    std::cout << "====================================================\n\n";
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "--- DERIVED WICK GEOMETRY ---\n";
    std::cout << "Total Evaporator Wick Thickness: " << t_evap_wick * 1000 << " mm\n";
    std::cout << "Total Condenser Wick Thickness:  " << t_cond_wick * 1000 << " mm\n\n";
    std::cout << "--- FABRICATION TARGETS ---\n";
    std::cout << std::setprecision(0);
    std::cout << "Target Filling Ratio: " << filling_ratio * 100 << " %\n";
    std::cout << std::setprecision(4);
    std::cout << "Required Liquid Charge Volume: " << liquid_charge_volume_mL << " mL\n";
    std::cout << std::setprecision(2);
    std::cout << "Target Initial Vacuum: " << target_vacuum_Pa << " Pa\n\n";
    std::cout << "--- ANALYSIS CONDITIONS ---\n";
    std::cout << std::setprecision(1);
    std::cout << "Operating Temperature: " << T_op - 273.15 << " C\n";
    std::cout << "Input Heat Load (Q_in): " << Q_in << " W\n";
    std::cout << "Orientation Angle: " << phi_deg << " degrees\n\n";
    std::cout << "--- PRESSURE BALANCE ANALYSIS ---\n";
    std::cout << std::setprecision(2);
    std::cout << "Max Capillary Pressure (dP_cap):   " << dP_cap << " Pa\n";
    std::cout << "Total Pressure Drop (dP_total):    " << dP_total << " Pa\n";
    std::cout << "  - Liquid Drop (dP_l):            " << dP_l << " Pa\n";
    std::cout << "  - Vapor Drop (dP_v):             " << dP_v << " Pa\n";
    std::cout << "  - Gravity Drop (dP_g):           " << dP_g << " Pa\n\n";
    std::cout << "--- PREDICTED PERFORMANCE METRICS ---\n";
    if (dP_cap >= dP_total) {
        std::cout << "YES! CAPILLARY LIMIT: MET for the specified heat load (" << std::setprecision(1) << Q_in << " W).\n";
    } else {
        std::cout << "NO! CAPILLARY LIMIT: FAILED. Wick cannot sustain the required flow.\n";
        std::cout << "   The design is limited to Q_max = " << std::setprecision(1) << Q_max << " W under these conditions.\n";
    }
    std::cout << std::setprecision(1);
    std::cout << "Maximum Heat Transport (Q_max): " << Q_max << " W\n";
    std::cout << std::setprecision(4);
    std::cout << "Ideal Thermal Resistance (R_ideal): " << R_total_ideal << " K/W\n";
    std::cout << "Corrected Thermal Resistance (R_corrected): " << R_total_corrected << " K/W\n";
    const double delta_T = Q_in * R_total_corrected;
    std::cout << std::setprecision(2);
    std::cout << "Predicted Corrected Temp. Drop (ΔT): " << delta_T << " C\n\n";

    return 0;
}