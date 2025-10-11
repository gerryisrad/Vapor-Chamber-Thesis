import math

def vapor_chamber_model():
    """
    Implements a steady-state, 1D analytical model for a vapor chamber.
    """
    # =================== 1. MODEL CONFIGURATION & INPUTS ===================
    # --- Boundary Conditions & Operational Parameters ---
    T_op = 70 + 273.15   # Design-point operating temperature [K]
    Q_in = 150           # Target heat load for analysis [W]
    phi_deg = 0          # Operational angle [deg] (0=horizontal)

    # --- Fabrication & Experimental Parameters ---
    filling_ratio = 0.30
    target_vacuum_Pa = 10

    # --- Model Calibration ---
    experimental_correction_factor = 1.2

    # --- VC Envelope Geometry ---
    vc_length = 0.070
    vc_width  = 0.070

    # --- Internal Component Geometry ---
    t_evap_wall = 0.00225
    t_cond_wall = 0.00225
    t_vapor     = 0.00192

    # --- Heat Source Definition ---
    evap_length = 0.020
    evap_width  = 0.020

    # --- Material Properties ---
    k_shell = 380

    # --- Evaporator Wick Specification (Screen Mesh) ---
    mesh_number_evap_wpi = 200
    d_w_evap = 0.000051
    num_layers_evap = 5

    # --- Condenser Wick Specification (Screen Mesh) ---
    mesh_number_cond_wpi = 80
    d_w_cond = 0.00015
    num_layers_cond = 5

    # =================== 2. THERMOPHYSICAL PROPERTIES ======================
    # Working Fluid: Deionized Water at T_op
    rho_l = 977.8
    rho_v = 0.198
    mu_l = 4.04e-4
    mu_v = 1.09e-5
    sigma = 0.0644
    h_fg = 2.33e6
    k_l = 0.668
    theta_deg = 0

    # =================== 3. DERIVED PARAMETER CALCULATION ==================
    # --- Unit Conversions ---
    in_to_m = 0.0254
    mesh_number_evap = mesh_number_evap_wpi / in_to_m
    mesh_number_cond = mesh_number_cond_wpi / in_to_m

    # --- Total Wick Thickness ---
    t_evap_wick = 2 * d_w_evap * num_layers_evap
    t_cond_wick = 2 * d_w_cond * num_layers_cond

    # --- Screen Mesh Wick Characterization ---
    epsilon_evap = 1 - (math.pi * mesh_number_evap * d_w_evap) / 4
    epsilon_cond = 1 - (math.pi * mesh_number_cond * d_w_cond) / 4
    rc_eff = 1 / (2 * mesh_number_evap)
    K_evap = (d_w_evap**2 * epsilon_evap**3) / (122 * (1 - epsilon_evap)**2)
    K_cond = (d_w_cond**2 * epsilon_cond**3) / (122 * (1 - epsilon_cond)**2)

    # --- Characteristic Flow Length & Volumes ---
    L_eff = (vc_length + evap_length) / 4
    internal_area = vc_length * vc_width
    vol_vapor_space = internal_area * t_vapor
    vol_evap_wick_pore = internal_area * t_evap_wick * epsilon_evap
    vol_cond_wick_pore = internal_area * t_cond_wick * epsilon_cond
    vol_internal_total = vol_vapor_space + vol_evap_wick_pore + vol_cond_wick_pore
    liquid_charge_volume_mL = (vol_internal_total * filling_ratio) * 1e6

    # --- Cross-Sectional Areas ---
    A_evap = evap_length * evap_width
    A_cond = (vc_length * vc_width) - A_evap
    A_wick_evap = t_evap_wick * vc_width
    A_wick_cond = t_cond_wick * vc_width
    A_vapor = t_vapor * vc_width

    # --- Hydraulic Diameter ---
    d_h_vapor = (2 * t_vapor * vc_width) / (t_vapor + vc_width)

    # ============== 4. CAPILLARY PERFORMANCE ANALYSIS ======================
    # --- Angle Conversions to Radians ---
    phi = math.radians(phi_deg)
    theta = math.radians(theta_deg)
    
    # --- Pressure Terms Calculation ---
    dP_cap = (2 * sigma * math.cos(theta)) / rc_eff
    dP_l_cond = (mu_l * Q_in * (L_eff / 2)) / (rho_l * A_wick_cond * K_cond * h_fg)
    dP_l_evap = (mu_l * Q_in * (L_eff / 2)) / (rho_l * A_wick_evap * K_evap * h_fg)
    dP_l = dP_l_cond + dP_l_evap
    C_vapor = 96
    dP_v = (C_vapor * mu_v * Q_in * L_eff) / (2 * rho_v * A_vapor * d_h_vapor**2 * h_fg)
    g = 9.81
    dP_g = rho_l * g * L_eff * math.sin(phi)
    dP_total = dP_l + dP_v + dP_g

    # --- Maximum Heat Flux (Q_max) Calculation ---
    vapor_pressure_term = (C_vapor * mu_v * L_eff) / (2 * rho_v * A_vapor * d_h_vapor**2 * h_fg)
    liquid_pressure_term = ((mu_l * (L_eff / 2)) / (rho_l * A_wick_cond * K_cond * h_fg)) + \
                           ((mu_l * (L_eff / 2)) / (rho_l * A_wick_evap * K_evap * h_fg))
    Q_max = (dP_cap - dP_g) / (liquid_pressure_term + vapor_pressure_term)

    # ============== 5. THERMAL RESISTANCE NETWORK ANALYSIS ================
    # --- Effective Wick Conductivity ---
    k_wick_evap = k_l * ((k_shell + k_l + (1 - epsilon_evap) * (k_shell - k_l)) /
                         (k_shell + k_l - (1 - epsilon_evap) * (k_shell - k_l)))
    k_wick_cond = k_l * ((k_shell + k_l + (1 - epsilon_cond) * (k_shell - k_l)) /
                         (k_shell + k_l - (1 - epsilon_cond) * (k_shell - k_l)))

    # --- Component Thermal Resistances ---
    R_evap_wall = t_evap_wall / (k_shell * A_evap)
    R_evap_wick = t_evap_wick / (k_wick_evap * A_evap)
    R_phase_change = 0.01
    R_cond_wick = t_cond_wick / (k_wick_cond * A_cond)
    R_cond_wall = t_cond_wall / (k_shell * A_cond)
    R_total_ideal = R_evap_wall + R_evap_wick + R_phase_change + R_cond_wick + R_cond_wall

    # --- Corrected Thermal Resistance ---
    R_total_corrected = R_total_ideal * experimental_correction_factor

    # =================== 6. RESULTS SUMMARY ================================
    print("====================================================")
    print("   VAPOR CHAMBER 1D ANALYTICAL MODEL - RESULTS")
    print("====================================================\n")
    print("--- DERIVED WICK GEOMETRY ---")
    print(f"Total Evaporator Wick Thickness: {t_evap_wick * 1000:.2f} mm")
    print(f"Total Condenser Wick Thickness:  {t_cond_wick * 1000:.2f} mm\n")
    print("--- FABRICATION TARGETS ---")
    print(f"Target Filling Ratio: {filling_ratio * 100:.0f} %")
    print(f"Required Liquid Charge Volume: {liquid_charge_volume_mL:.4f} mL")
    print(f"Target Initial Vacuum: {target_vacuum_Pa:.2f} Pa\n")
    print("--- ANALYSIS CONDITIONS ---")
    print(f"Operating Temperature: {T_op - 273.15:.1f} C")
    print(f"Input Heat Load (Q_in): {Q_in:.1f} W")
    print(f"Orientation Angle: {phi_deg:.1f} degrees\n")
    print("--- PRESSURE BALANCE ANALYSIS ---")
    print(f"Max Capillary Pressure (dP_cap):   {dP_cap:.2f} Pa")
    print(f"Total Pressure Drop (dP_total):    {dP_total:.2f} Pa")
    print(f"  - Liquid Drop (dP_l):            {dP_l:.2f} Pa")
    print(f"  - Vapor Drop (dP_v):             {dP_v:.2f} Pa")
    print(f"  - Gravity Drop (dP_g):           {dP_g:.2f} Pa\n")
    print("--- PREDICTED PERFORMANCE METRICS ---")
    if dP_cap >= dP_total:
        print(f"YES! CAPILLARY LIMIT: MET for the specified heat load ({Q_in:.1f} W).")
    else:
        print("NO! CAPILLARY LIMIT: FAILED. Wick cannot sustain the required flow.")
        print(f"   The design is limited to Q_max = {Q_max:.1f} W under these conditions.")
    print(f"Maximum Heat Transport (Q_max): {Q_max:.1f} W")
    print(f"Ideal Thermal Resistance (R_ideal): {R_total_ideal:.4f} K/W")
    print(f"Corrected Thermal Resistance (R_corrected): {R_total_corrected:.4f} K/W")
    delta_T = Q_in * R_total_corrected
    print(f"Predicted Corrected Temp. Drop (ΔT): {delta_T:.2f} C\n")

if __name__ == "__main__":
    vapor_chamber_model()