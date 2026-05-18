%% 3D density field and vector field combined plotting script (Enhanced version: supports dual density fields + eigenvalue ellipsoids)
% Functions:
%   1. Read density data file (primary density field), supports three visualization methods: scatter, slice, isosurface
%   2. Read beta density data file (secondary density field), supports scatter and slice visualization
%   3. Read vector data file, plot 3D vector field
%   4. Support vector field display mode control (none/full/multi-layer slice)
%   5. Vector slices support simultaneous selection of multi-layer slices in X, Y, Z directions
%   6. Customizable coordinate axis boundaries
%   7. Colorbar ticks uniformly displayed with specified decimal places
%   8. Eigenvalue ellipsoid visualization (supports regular grid data)
%   9. Density-weighted volume (ellipsoid volume × density) affecting ellipsoid size
%  10. Lambda coloring scheme with fixed colorbar range [0, 1.5]
%  11. Absolute max eigenvalue minus 0.5 raw value coloring scheme (dual-color transparent gradient)
%  12. Beta density coloring scheme (single-color transparent gradient + dual-color gradient)
%  13. Plane border drawing function (X/Y/Z directions selectable, using layer numbers to specify positions)
%  14. Three-point gradient coloring scheme for absolute max eigenvalue minus 0.5 (customizable colors for min, zero, max)

clear; clc; close all;

%% ==================== User adjustable parameters ====================
% ===== File related =====
density_filename = 'density_data.dat';    % Density data file name
beta_density_filename = 'biaxis_data.dat';  % Beta/biaxis density data file name
vector_filename = 'vector_data.dat';      % Vector data file name
eigen_filename = 'SA_Eigs.dat';           % Eigenvalue ellipsoid data file name

% ===== Eigenvalue ellipsoid visualization options =====
show_eigen_ellipsoids = true;             % Whether to display eigenvalue ellipsoids
eigen_grid_size = [32, 32, 64];            % Eigenvalue grid size [I, J, K]
eigen_sampling_interval = [4, 4, 4];       % Sampling interval [Z, Y, X]
eigen_scale_factor = 0.05;                 % Ellipsoid scaling factor
eigen_fixed_plane = [1, 16];               % Fixed plane parameters [dimension, index], e.g., [1, 16] fixes Z=16 plane, set [] to disable
eigen_ellipsoid_resolution = 40;           % Ellipsoid surface resolution

% Eigenvalue ellipsoid coloring scheme selection
% Coloring schemes: 'volume', 'lambda_max_minus_0.5', 
%          'lambda_absmax_minus_05_raw' (absolute max eigenvalue minus 0.5 raw value), 
%          'fixed' (fixed color), 'density_weighted_volume' (density-weighted volume),
%          'lambda_absmax_minus_05_gradient' (absolute max eigenvalue minus 0.5 three-point gradient coloring)
eigen_coloring_scheme = 'lambda_absmax_minus_05_gradient';  
eigen_color_map_name = 'red';              % Ellipsoid color map name: 'jet', 'hot', 'cool', 'red', 'blue', 'green', 'black', 'purple', 'orange', 'cyan'
eigen_fixed_color = 'red';                 % Fixed color (used when eigen_coloring_scheme='fixed')

% ===== Absolute max eigenvalue minus 0.5 three-point gradient coloring scheme parameters =====
% This scheme for each ellipsoid point:
%   1. Subtract 0.5 from each eigenvalue, take absolute value
%   2. Find the eigenvalue with the largest absolute value
%   3. Use the raw value (with sign) of that eigenvalue minus 0.5 as the color value
% Uses three-point gradient: min, zero, max correspond to three customizable colors

% Three-point gradient color settings
eigen_absmax_gradient_color_min = [1.0, 0.843, 0.0];    % Min value color
eigen_absmax_gradient_color_zero = [0.85, 0.85, 0.85];   % Zero value color
eigen_absmax_gradient_color_max = [1.0, 0.0, 0.0];       % Max value color

% Colorbar display range
eigen_absmax_gradient_fixed_range = [-0.3, 1.0];      % Fixed colorbar range for this coloring scheme [min, max]
eigen_absmax_gradient_use_fixed_range = true;         % Whether to use fixed colorbar range

% Colorbar display options
eigen_absmax_gradient_show_colorbar = true;            % Whether to show colorbar for this coloring scheme
eigen_absmax_gradient_colorbar_divisions = 5;         % Colorbar divisions (generates n+1 ticks)
eigen_absmax_gradient_colorbar_scientific = false;    % Whether to use scientific notation
eigen_absmax_gradient_colorbar_decimal_places = 2;    % Number of decimal places

% Density-weighted volume options
use_density_weighted_volume = true;        % Whether to use density-weighted volume (volume × density), affects both ellipsoid size and color
density_weighting_scale = 1.0;             % Density weighting scaling factor (larger value = stronger density effect on ellipsoid size)

% Volume coloring colorbar parameters
eigen_volume_show_colorbar = false;         % Whether to show volume colorbar
eigen_volume_colorbar_divisions = 5;       % Volume colorbar divisions
eigen_volume_colorbar_scientific = false;   % Whether to use scientific notation
eigen_volume_colorbar_decimal_places = 2;  % Number of decimal places

% Max eigenvalue minus 0.5 coloring parameters (legacy, kept for compatibility)
eigen_lambda_show_colorbar = false;         % Whether to show colorbar for this coloring scheme
eigen_lambda_colorbar_divisions = 6;       % Colorbar divisions (generates n+1 ticks)
eigen_lambda_colorbar_scientific = false;   % Whether to use scientific notation
eigen_lambda_colorbar_decimal_places = 2;  % Number of decimal places
eigen_lambda_fixed_range = [0, 1.5];       % Fixed colorbar range for lambda coloring scheme [min, max]
eigen_lambda_use_fixed_range = false;       % Whether to use fixed colorbar range

% ===== Dual-color transparent gradient coloring scheme parameters (for eigenvalues) =====
% Color mapping rules:
%   First interval: [map_min_neg, 0] 
%     - map_min_neg (e.g., -0.5) corresponds to first color (fully opaque)
%     - 0 corresponds to fully transparent
%   Second interval: [0, map_max_pos]
%     - 0 corresponds to fully transparent
%     - map_max_pos (e.g., 1.0) corresponds to second color (fully opaque)
%   Colorbar display range: [min_cbar, max_cbar] can be a subset of the mapping range

% First interval parameters (negative value interval)
eigen_absmax_raw_color_neg = [1.0,0.843,0.0];        % Negative interval color
eigen_absmax_raw_map_min_neg = -0.2;        % Negative interval mapping minimum (corresponds to fully opaque first color)

% Second interval parameters (positive value interval)
eigen_absmax_raw_color_pos = [0.8,0.0,0];         % Positive interval color
eigen_absmax_raw_map_max_pos = 0.4;         % Positive interval mapping maximum (corresponds to fully opaque second color)

% Colorbar display range
eigen_absmax_raw_fixed_range = [-0.2, 0.4];  % Fixed colorbar range for this coloring scheme [min, max]
eigen_absmax_raw_use_fixed_range = true;       % Whether to use fixed colorbar range

% Other parameters
eigen_absmax_raw_show_colorbar = true;          % Whether to show colorbar for this coloring scheme
eigen_absmax_raw_colorbar_divisions = 5;       % Colorbar divisions (generates n+1 ticks)
eigen_absmax_raw_colorbar_scientific = false;  % Whether to use scientific notation
eigen_absmax_raw_colorbar_decimal_places = 2;  % Number of decimal places

eigen_face_alpha = 1.0;                        % Ellipsoid surface base transparency (0-1, 1 = fully opaque)

% ==================== Beta density coloring scheme parameters ====================
% Beta density coloring scheme options:
%   'solid' - solid color scheme
%   'transparent_gradient' - single-color transparent gradient
%   'dual_color_gradient' - dual-color gradient (new)

beta_color_scheme = 'dual_color_gradient';   % Beta coloring scheme: 'solid', 'transparent_gradient', 'dual_color_gradient'

% === Dual-color gradient coloring scheme parameters (new) ===
beta_dual_color_min = [1.0, 1.0, 1.0];        % Min value color (white)
beta_dual_color_max = [0.5, 0.0, 0.5];        % Max value color (purple)
beta_dual_map_min = 0.0;                      % Color mapping minimum (corresponds to first color)
beta_dual_map_max = 0.20;                     % Color mapping maximum (corresponds to second color)
beta_dual_cbar_min = 0.0;                     % Colorbar display minimum (can be subset of mapping range)
beta_dual_cbar_max = 0.20;                    % Colorbar display maximum (can be subset of mapping range)
beta_dual_use_fixed_range = true;             % Whether to use fixed colorbar range
beta_dual_show_colorbar = true;               % Whether to show colorbar
beta_dual_colorbar_divisions = 5;             % Colorbar divisions (generates n+1 ticks)
beta_dual_colorbar_decimal_places = 2;        % Number of decimal places
beta_dual_colorbar_scientific = false;        % Whether to use scientific notation

% === Single-color transparent gradient scheme parameters (legacy) ===
beta_transparent_color = [0.5, 0.0, 0.13];    % Beta density transparent gradient color
beta_map_min = 0.0;                           % Beta density mapping minimum (corresponds to fully transparent)
beta_map_max = 0.15;                          % Beta density mapping maximum (corresponds to fully opaque)
beta_cbar_min = 0.0;                          % Beta colorbar display minimum
beta_cbar_max = 0.15;                         % Beta colorbar display maximum
beta_use_fixed_range = true;                  % Whether to use fixed colorbar range
beta_fade_from_white = true;                  % Whether to fade from white

% === Solid color scheme parameters (legacy) ===
beta_slice_color = 'blue';                    % Beta slice color

% === General Beta display settings ===
show_beta_scatter = false;                    % Whether to show Beta density scatter plot
beta_scatter_color = 'blue';                  % Beta scatter color
beta_scatter_alpha = 1.0;                     % Beta scatter transparency
beta_scatter_marker_size = 1;                 % Beta scatter marker size
beta_scatter_brightness = 1.0;                % Beta scatter brightness coefficient

show_beta_slice = false;                       % Whether to show Beta density slices

% Beta slice settings - supports multi-layer slices
beta_slice_settings = struct();
beta_slice_settings.x.enable = false;         % X-direction slice switch
beta_slice_settings.x.positions = [64];       % X-direction slice position list
beta_slice_settings.y.enable = false;         % Y-direction slice switch
beta_slice_settings.y.positions = [0];        % Y-direction slice position list
beta_slice_settings.z.enable = true;          % Z-direction slice switch
beta_slice_settings.z.positions = [16];       % Z-direction slice position list
beta_slice_alpha = 0.8;                       % Beta slice transparency

% Beta density colorbar settings (global)
show_beta_colorbar = false;                    % Whether to show Beta density colorbar
beta_colorbar_divisions = 5;                  % Beta colorbar divisions
beta_colorbar_decimal_places = 2;             % Beta colorbar tick decimal places

% ======================================================
% ===== Density field visualization options =====

show_density_scatter = false;              % Whether to show scatter plot
scatter_alpha = 0.8;                      % Scatter transparency
scatter_marker_size = 1;                  % Scatter marker size

show_density_slice = true;                % Whether to show slices
% Slice settings - supports multi-layer slices
slice_settings = struct();
% X-direction slice settings
slice_settings.x.enable = false;           % X-direction slice switch
slice_settings.x.positions = [64];        % X-direction slice position list (integers, corresponding to original data layers), e.g., [4,8,12]
% Y-direction slice settings
slice_settings.y.enable = false;           % Y-direction slice switch
slice_settings.y.positions = [0];          % Y-direction slice position list
% Z-direction slice settings
slice_settings.z.enable = true;            % Z-direction slice switch
slice_settings.z.positions = [1];         % Z-direction slice position list
slice_alpha = 0.6;                        % Slice transparency

show_density_isosurface = true;           % Whether to show isosurface
isosurface_value = 0.5;                   % Isosurface density value
isosurface_color = [0,0.4,0];             % Isosurface color [R,G,B] or 'red', 'blue'
isosurface_alpha = 0.2;                   % Isosurface transparency

% ===== Density field general settings =====
% Grid resolution (for interpolation)
grid_resolution = 50;                     % Grid resolution (number of points in each direction)
smooth_factor = 2.0;                      % Smoothing factor (>1 = smoother)

% Density field color settings (single-color gradient, transparent at zero density)
density_color = 'red';                    % Density color: 'red', 'blue', or RGB
density_zero_transparent = true;          % Whether zero density is fully transparent

% ===== Vector field parameters =====
vector_display_mode = 'slice';            % Display mode: 'none', 'full', 'slice'
% Vector slice settings - supports multi-direction multi-layer slices
vector_slice_settings = struct();
% X-direction slice settings
vector_slice_settings.x.enable = false;    % X-direction slice switch
vector_slice_settings.x.positions = [1,8];  % X-direction slice position list
% Y-direction slice settings
vector_slice_settings.y.enable = false;    % Y-direction slice switch
vector_slice_settings.y.positions = [1];  % Y-direction slice position list
% Z-direction slice settings
vector_slice_settings.z.enable = true;    % Z-direction slice switch
vector_slice_settings.z.positions = [8];  % Z-direction slice position list

% Vector display spacing
vector_spacing_x = 1;                     % X-direction display spacing
vector_spacing_y = 1;                     % Y-direction display spacing
vector_spacing_z = 1;                     % Z-direction display spacing

% Arrow style
arrow_mode = 'quiver3';                   % Arrow mode: 'quiver3', 'coneplot', 'line'
arrow_scale = 0.3;                        % Vector scaling factor
arrow_color = [0.6, 0.2, 0.2];                    % Arrow color
arrow_head_size = 0.04;                   % Arrow head size
arrow_line_width = 1.2;                   % Arrow shaft thickness
arrow_shaft_style = 'line';               % Shaft style: 'line', 'dashed', 'dotted'

% ===== Plane border settings (new feature) =====
% This feature draws plane borders in X, Y, Z directions at specified layer positions
% Layer numbers start from 1, corresponding to original data layers

% X-direction plane border settings (YZ plane)
plane_border_x = struct();
plane_border_x.enable = false;             % Whether to enable X-direction plane border
plane_border_x.layers = [8];       % X-direction layer number list (starting from 1)
plane_border_x.color = [0, 0, 1];          % Border color [R,G,B]
plane_border_x.line_width = 1.0;           % Border line width
plane_border_x.line_style = '-';           % Border line style: '-', '--', ':', '-.'

% Y-direction plane border settings (XZ plane)
plane_border_y = struct();
plane_border_y.enable = false;             % Whether to enable Y-direction plane border
plane_border_y.layers = [8, 16, 24];       % Y-direction layer number list (starting from 1)
plane_border_y.color = [0, 1, 0];          % Border color [R,G,B]
plane_border_y.line_width = 1.0;           % Border line width
plane_border_y.line_style = '-';           % Border line style: '-', '--', ':', '-.'

% Z-direction plane border settings (XY plane)
plane_border_z = struct();
plane_border_z.enable = true;              % Whether to enable Z-direction plane border
plane_border_z.layers = [15];  % Z-direction layer number list (starting from 1)
plane_border_z.color = [0, 0, 0];          % Border color [R,G,B]
plane_border_z.line_width = 0.5;           % Border line width
plane_border_z.line_style = '--';          % Border line style: '-', '--', ':', '-.'

% ===== Coordinate axis boundary control =====
% Boundary line style
border_line_width = 1.0;                  % Boundary line thickness
border_line_color = [0, 0, 0];            % Boundary line color [R,G,B]
border_line_style = '-';                  % Boundary line style: '-', '--', ':', '-.'

% Coordinate axis tick and label control
hide_axis_ticks = true;                   % Hide tick marks and tick labels
hide_axis_labels = true;                  % Hide axis label text
hide_axis_lines = true;                   % Hide axis lines (preserve boundaries)

% Axis label text
xlabel_text = 'X Coordinate';                   % X-axis label text
ylabel_text = 'Y Coordinate';                   % Y-axis label text
zlabel_text = 'Z Coordinate';                   % Z-axis label text
axis_label_fontsize = 12;                 % Axis label font size
axis_tick_fontsize = 10;                  % Tick label font size

% ===== Density colorbar settings =====
show_colorbar = false;                     % Whether to show density colorbar
colorbar_divisions = 5;                   % Colorbar divisions
colorbar_decimal_places = 2;              % Colorbar tick decimal places (user selectable)

% ===== Figure display =====
figure_width = 1200;                      % Figure width (pixels)
figure_height = 900;                      % Figure height (pixels)
view_azimuth = 45;                        % View azimuth angle
view_elevation = 30;                      % View elevation angle
background_color = [1, 1, 1];             % Background color
% ======================================================

%% ==================== Helper functions ====================
% Get RGB value from color name
function rgb = get_color_rgb(color_name)
    if ischar(color_name)
        switch lower(color_name)
            case 'red'
                rgb = [1, 0, 0];
            case 'blue'
                rgb = [0, 0, 1];
            case 'green'
                rgb = [0, 1, 0];
            case 'black'
                rgb = [0, 0, 0];
            case 'purple'
                rgb = [0.5, 0, 0.5];
            case 'orange'
                rgb = [1, 0.5, 0];
            case 'cyan'
                rgb = [0, 1, 1];
            case 'white'
                rgb = [1, 1, 1];
            case 'yellow'
                rgb = [1, 1, 0];
            case 'magenta'
                rgb = [1, 0, 1];
            otherwise
                rgb = [0, 0, 0];
        end
    else
        rgb = color_name;
    end
end

% Create single-color gradient colormap (new version: supports custom start and end colors)
function cmap = create_color_map_gradient(start_rgb, end_rgb, n_colors, zero_transparent)
    % start_rgb: start color (low values)
    % end_rgb: end color (high values)
    % n_colors: number of colors
    % zero_transparent: whether to make low values transparent (unused, kept for compatibility)
    cmap = [linspace(start_rgb(1), end_rgb(1), n_colors)', ...
            linspace(start_rgb(2), end_rgb(2), n_colors)', ...
            linspace(start_rgb(3), end_rgb(3), n_colors)'];
end

% Create single-color gradient colormap (original version, kept for compatibility)
function cmap = create_color_map(color_rgb, n_colors, zero_transparent)
    if zero_transparent
        cmap = [linspace(1, color_rgb(1), n_colors)', ...
                linspace(1, color_rgb(2), n_colors)', ...
                linspace(1, color_rgb(3), n_colors)'];
    else
        cmap = [linspace(0, color_rgb(1), n_colors)', ...
                linspace(0, color_rgb(2), n_colors)', ...
                linspace(0, color_rgb(3), n_colors)'];
    end
end

% Create general colormap (supports multiple color schemes)
function colorMap = createGeneralColormap(color_name, n)
    if ischar(color_name) || isstring(color_name)
        switch lower(char(color_name))
            case 'jet'
                colorMap = jet(n);
            case 'hot'
                colorMap = hot(n);
            case 'cool'
                colorMap = cool(n);
            case 'parula'
                colorMap = parula(n);
            case 'red'
                target_rgb = [1, 0, 0];
                colorMap = zeros(n, 3);
                for i = 1:3
                    colorMap(:, i) = linspace(1, target_rgb(i), n)';
                end
            case 'blue'
                target_rgb = [0, 0, 1];
                colorMap = zeros(n, 3);
                for i = 1:3
                    colorMap(:, i) = linspace(1, target_rgb(i), n)';
                end
            case 'green'
                target_rgb = [0, 1, 0];
                colorMap = zeros(n, 3);
                for i = 1:3
                    colorMap(:, i) = linspace(1, target_rgb(i), n)';
                end
            case 'black'
                target_rgb = [0, 0, 0];
                colorMap = zeros(n, 3);
                for i = 1:3
                    colorMap(:, i) = linspace(1, target_rgb(i), n)';
                end
            case 'purple'
                target_rgb = [0.5, 0, 0.5];
                colorMap = zeros(n, 3);
                for i = 1:3
                    colorMap(:, i) = linspace(1, target_rgb(i), n)';
                end
            case 'orange'
                target_rgb = [1, 0.5, 0];
                colorMap = zeros(n, 3);
                for i = 1:3
                    colorMap(:, i) = linspace(1, target_rgb(i), n)';
                end
            case 'cyan'
                target_rgb = [0, 1, 1];
                colorMap = zeros(n, 3);
                for i = 1:3
                    colorMap(:, i) = linspace(1, target_rgb(i), n)';
                end
            otherwise
                colorMap = jet(n);
        end
    else
        % If RGB value, create gradient
        target_rgb = color_name;
        colorMap = zeros(n, 3);
        for i = 1:3
            colorMap(:, i) = linspace(1, target_rgb(i), n)';
        end
    end
end

% Create dual-color gradient colormap (for Beta density coloring)
% Mapping rule: [map_min, map_max] -> [color_min, color_max]
% Colorbar display range: [min_cbar, max_cbar] can be a subset of mapping range
function [colorMap, cbarColorMap] = createDualColorGradientColormap(...
    color_min, color_max, n_colors, map_min, map_max, min_cbar_val, max_cbar_val)
    % color_min: minimum value color name or RGB value
    % color_max: maximum value color name or RGB value
    % n_colors: number of colors
    % map_min: color mapping minimum (corresponds to first color)
    % map_max: color mapping maximum (corresponds to second color)
    % min_cbar_val: colorbar display minimum
    % max_cbar_val: colorbar display maximum
    
    % Get RGB values of target colors
    if ischar(color_min) || isstring(color_min)
        target_rgb_min = get_color_rgb(char(color_min));
    else
        target_rgb_min = color_min;
    end
    
    if ischar(color_max) || isstring(color_max)
        target_rgb_max = get_color_rgb(char(color_max));
    else
        target_rgb_max = color_max;
    end
    
    % Create full mapping range colormap (for value-to-color conversion)
    colorMap = zeros(n_colors, 3);
    for i = 1:n_colors
        t = (i - 1) / (n_colors - 1);  % t in [0,1] range
        colorMap(i, :) = (1 - t) * target_rgb_min + t * target_rgb_max;
    end
    
    % Create corresponding colormap for colorbar (based on colorbar display range)
    cbar_n_colors = 256;
    cbarColorMap = zeros(cbar_n_colors, 3);
    
    for i = 1:cbar_n_colors
        t_cbar = (i - 1) / (cbar_n_colors - 1);
        cbar_value = min_cbar_val + t_cbar * (max_cbar_val - min_cbar_val);
        
        % Calculate normalized position in full mapping
        if map_max > map_min
            t_global = (cbar_value - map_min) / (map_max - map_min);
            t_global = max(0, min(1, t_global));
        else
            t_global = 0;
        end
        
        cbarColorMap(i, :) = (1 - t_global) * target_rgb_min + t_global * target_rgb_max;
    end
end

% Create three-point gradient colormap (for absolute max eigenvalue minus 0.5 coloring scheme)
% Mapping rule: values in [minVal, maxVal] range, three-point linear interpolation through zero
% Color mapping: min value → color_min, zero → color_zero, max value → color_max
function [colorMap, cbarColorMap] = createThreePointGradientColormap(...
    color_min, color_zero, color_max, n_colors, minVal, maxVal)
    
    % Get RGB values of target colors
    if ischar(color_min) || isstring(color_min)
        target_rgb_min = get_color_rgb(char(color_min));
    else
        target_rgb_min = color_min;
    end
    
    if ischar(color_zero) || isstring(color_zero)
        target_rgb_zero = get_color_rgb(char(color_zero));
    else
        target_rgb_zero = color_zero;
    end
    
    if ischar(color_max) || isstring(color_max)
        target_rgb_max = get_color_rgb(char(color_max));
    else
        target_rgb_max = color_max;
    end
    
    colorMap = zeros(n_colors, 3);
    
    % Calculate zero point position in color mapping (normalized coordinate)
    if maxVal > minVal
        zero_t = (0 - minVal) / (maxVal - minVal);
    else
        zero_t = 0.5;
    end
    zero_t = max(0, min(1, zero_t));
    
    % Generate color mapping
    for i = 1:n_colors
        t = (i - 1) / (n_colors - 1);  % t in [0,1] range
        
        if t <= zero_t
            % Negative interval (including zero): gradient from color_min to color_zero
            if zero_t > 0
                t_neg = t / zero_t;
                t_neg = max(0, min(1, t_neg));
                colorMap(i, :) = (1 - t_neg) * target_rgb_min + t_neg * target_rgb_zero;
            else
                colorMap(i, :) = target_rgb_zero;
            end
        else
            % Positive interval: gradient from color_zero to color_max
            if zero_t < 1
                t_pos = (t - zero_t) / (1 - zero_t);
                t_pos = max(0, min(1, t_pos));
                colorMap(i, :) = (1 - t_pos) * target_rgb_zero + t_pos * target_rgb_max;
            else
                colorMap(i, :) = target_rgb_zero;
            end
        end
    end
    
    % Colorbar uses the same colormap
    cbarColorMap = colorMap;
end

% Create single-color transparent gradient colormap (for Beta density coloring)
function [colorMap, alphaMap, cbarColorMap] = createSingleColorTransparentColormap(...
    target_color, n_colors, map_min, map_max, min_cbar_val, max_cbar_val, fade_from_white, max_alpha)
    
    % Get RGB values of target color
    if ischar(target_color) || isstring(target_color)
        target_rgb = createGeneralColormap(char(target_color), 2);
        target_rgb = target_rgb(end, :);
    else
        target_rgb = target_color;
    end
    
    colorMap = zeros(n_colors, 3);
    alphaMap = zeros(n_colors, 1);
    
    for i = 1:n_colors
        t = (i - 1) / (n_colors - 1);  % t in [0,1] range
        
        if fade_from_white
            % Gradient from white to target color (RGB changes)
            colorMap(i, :) = (1 - t) * [1, 1, 1] + t * target_rgb;
        else
            % Direct target color gradient (RGB fixed, alpha changes)
            colorMap(i, :) = target_rgb;
        end
        
        % Alpha linear gradient from 0 to max_alpha
        alphaMap(i) = t * max_alpha;
    end
    
    % Create corresponding colormap for colorbar (based on colorbar display range)
    cbar_n_colors = 256;
    cbarColorMap = zeros(cbar_n_colors, 3);
    
    for i = 1:cbar_n_colors
        t_cbar = (i - 1) / (cbar_n_colors - 1);
        cbar_value = min_cbar_val + t_cbar * (max_cbar_val - min_cbar_val);
        
        % Calculate normalized position in full mapping
        if map_max > map_min
            t_global = (cbar_value - map_min) / (map_max - map_min);
            t_global = max(0, min(1, t_global));
        else
            t_global = 0;
        end
        
        if fade_from_white
            cbarColorMap(i, :) = (1 - t_global) * [1, 1, 1] + t_global * target_rgb;
        else
            cbarColorMap(i, :) = target_rgb;
        end
    end
end

% Create dual-color transparent gradient colormap (specifically for absolute max eigenvalue coloring scheme)
function [colorMap, alphaMap, cbarColorMap] = createDualColorTransparentColormap(...
    color_neg, color_pos, n_colors, map_min_neg, map_max_pos, min_cbar_val, max_cbar_val, max_alpha)
    
    % Get RGB values of target colors
    if ischar(color_neg) || isstring(color_neg)
        target_rgb_neg = createGeneralColormap(char(color_neg), 2);
        target_rgb_neg = target_rgb_neg(end, :);
    else
        target_rgb_neg = color_neg;
    end
    
    if ischar(color_pos) || isstring(color_pos)
        target_rgb_pos = createGeneralColormap(char(color_pos), 2);
        target_rgb_pos = target_rgb_pos(end, :);
    else
        target_rgb_pos = color_pos;
    end
    
    colorMap = zeros(n_colors, 3);
    alphaMap = zeros(n_colors, 1);
    
    for i = 1:n_colors
        t = (i - 1) / (n_colors - 1);  % t in [0,1] range
        
        % Map t to actual value range [map_min_neg, map_max_pos]
        value = map_min_neg + t * (map_max_pos - map_min_neg);
        
        if value <= 0
            % Negative interval: gradient from color1 to transparent
            t_neg = (value - map_min_neg) / (0 - map_min_neg);
            t_neg = max(0, min(1, t_neg));
            colorMap(i, :) = (1 - t_neg) * target_rgb_neg + t_neg * [1, 1, 1];
            alphaMap(i) = (1 - t_neg) * max_alpha;
        else
            % Positive interval: gradient from transparent to color2
            t_pos = (value - 0) / (map_max_pos - 0);
            t_pos = max(0, min(1, t_pos));
            colorMap(i, :) = (1 - t_pos) * [1, 1, 1] + t_pos * target_rgb_pos;
            alphaMap(i) = t_pos * max_alpha;
        end
    end
    
    % Create corresponding colormap for colorbar
    cbar_n_colors = 256;
    cbarColorMap = zeros(cbar_n_colors, 3);
    
    for i = 1:cbar_n_colors
        t_cbar = (i - 1) / (cbar_n_colors - 1);
        cbar_value = min_cbar_val + t_cbar * (max_cbar_val - min_cbar_val);
        
        if cbar_value <= 0
            if map_min_neg < 0
                t_neg_cbar = (cbar_value - map_min_neg) / (0 - map_min_neg);
                t_neg_cbar = max(0, min(1, t_neg_cbar));
                cbarColorMap(i, :) = (1 - t_neg_cbar) * target_rgb_neg + t_neg_cbar * [1, 1, 1];
            else
                cbarColorMap(i, :) = [1, 1, 1];
            end
        else
            if map_max_pos > 0
                t_pos_cbar = (cbar_value - 0) / (map_max_pos - 0);
                t_pos_cbar = max(0, min(1, t_pos_cbar));
                cbarColorMap(i, :) = (1 - t_pos_cbar) * [1, 1, 1] + t_pos_cbar * target_rgb_pos;
            else
                cbarColorMap(i, :) = [1, 1, 1];
            end
        end
    end
end

% Set colorbar scientific notation format
function setColorbarScientificFormatCustom(hColorbar, minVal, maxVal, numDivisions, decimalPlaces)
    numTicks = numDivisions + 1;
    tickPositions = linspace(minVal, maxVal, numTicks);
    
    tickLabels = cell(1, numTicks);
    for i = 1:numTicks
        value = tickPositions(i);
        if abs(value) < 1e-12
            tickLabels{i} = '0';
        else
            exponent = floor(log10(abs(value)));
            coefficient = value / (10^exponent);
            coefficient = round(coefficient * 10^decimalPlaces) / 10^decimalPlaces;
            if abs(coefficient - 1) < 1e-10
                tickLabels{i} = sprintf('10^{%d}', exponent);
            elseif abs(coefficient + 1) < 1e-10
                tickLabels{i} = sprintf('-10^{%d}', exponent);
            else
                format_str = sprintf('%%.%df', decimalPlaces);
                if exponent >= 0
                    tickLabels{i} = sprintf([format_str '×10^{%d}'], coefficient, exponent);
                else
                    tickLabels{i} = sprintf([format_str '×10^{%d}'], coefficient, exponent);
                end
            end
        end
    end
    
    hColorbar.Ticks = tickPositions;
    hColorbar.TickLabels = tickLabels;
    hColorbar.FontSize = 10;
    hColorbar.TickDirection = 'out';
    hColorbar.Box = 'on';
    hColorbar.FontName = 'Arial';
end

% Set colorbar decimal format
function setColorbarDecimalFormat(hColorbar, minVal, maxVal, numDivisions, decimalPlaces)
    numTicks = numDivisions + 1;
    tickPositions = linspace(minVal, maxVal, numTicks);
    
    tickLabels = cell(1, numTicks);
    format_str = sprintf('%%.%df', decimalPlaces);
    for i = 1:numTicks
        tickLabels{i} = sprintf(format_str, tickPositions(i));
    end
    
    hColorbar.Ticks = tickPositions;
    hColorbar.TickLabels = tickLabels;
    hColorbar.FontSize = 10;
    hColorbar.TickDirection = 'out';
    hColorbar.Box = 'on';
    hColorbar.FontName = 'Arial';
end

% Read eigenvalue data file
function eigen_data = readEigenDataFile(filename)
    fid = fopen(filename, 'r');
    if fid == -1
        eigen_data = [];
        return;
    end
    eigen_data = fscanf(fid, '%f', [7, Inf])';
    fclose(fid);
end

% Validate eigenvalue data integrity
function validateEigenData(eigen_data, gridSize)
    if isempty(eigen_data)
        return;
    end
    totalPoints = prod(gridSize);
    if size(eigen_data, 1) ~= totalPoints * 3
        warning('Eigenvalue data point count (%d) does not match grid size (%d×%d×%d=%d), may not display correctly', ...
            size(eigen_data, 1)/3, gridSize(1), gridSize(2), gridSize(3), totalPoints);
    end
end

% Calculate ellipsoid volumes
function volumes = calculateEllipsoidVolumes(eigen_data, gridSize, scaleFactor)
    [I, J, K] = deal(gridSize(1), gridSize(2), gridSize(3));
    volumes = zeros(I, J, K);
    
    for k = 1:K
        for j = 1:J
            for i = 1:I
                linearIndex = ((k-1)*J*I + (j-1)*I + (i-1)) * 3 + 1;
                if linearIndex + 2 <= size(eigen_data, 1)
                    pointData = eigen_data(linearIndex:linearIndex+2, :);
                    axesLengths = abs(pointData(:, 4)) * scaleFactor;
                    volumes(i, j, k) = (4/3) * pi * axesLengths(1) * axesLengths(2) * axesLengths(3);
                end
            end
        end
    end
end

% Calculate density-weighted ellipsoid volumes
function volumes_weighted = calculateDensityWeightedVolumes(eigen_data, gridSize, scaleFactor, density_interp, X_mesh, Y_mesh, Z_mesh, scale_coeff)
    [I, J, K] = deal(gridSize(1), gridSize(2), gridSize(3));
    volumes_weighted = zeros(I, J, K);
    
    x_coords = X_mesh(1,:,1);
    y_coords = Y_mesh(:,1,1);
    z_coords = squeeze(Z_mesh(1,1,:));
    
    for k = 1:K
        for j = 1:J
            for i = 1:I
                linearIndex = ((k-1)*J*I + (j-1)*I + (i-1)) * 3 + 1;
                if linearIndex + 2 <= size(eigen_data, 1)
                    pointData = eigen_data(linearIndex:linearIndex+2, :);
                    axesLengths = abs(pointData(:, 4)) * scaleFactor;
                    volume = (4/3) * pi * axesLengths(1) * axesLengths(2) * axesLengths(3);
                    
                    center = pointData(1, 1:3);
                    [~, x_idx] = min(abs(x_coords - center(1)));
                    [~, y_idx] = min(abs(y_coords - center(2)));
                    [~, z_idx] = min(abs(z_coords - center(3)));
                    
                    x_idx = max(1, min(length(x_coords), x_idx));
                    y_idx = max(1, min(length(y_coords), y_idx));
                    z_idx = max(1, min(length(z_coords), z_idx));
                    
                    density_val = density_interp(y_idx, x_idx, z_idx);
                    volumes_weighted(i, j, k) = volume * density_val * scale_coeff;
                end
            end
        end
    end
end

% Calculate max eigenvalue minus 0.5 for each ellipsoid
function lambda_max_abs_minus_05 = calculateLambdaMaxAbsMinus05(eigen_data, gridSize)
    [I, J, K] = deal(gridSize(1), gridSize(2), gridSize(3));
    lambda_max_abs_minus_05 = zeros(I, J, K);
    
    for k = 1:K
        for j = 1:J
            for i = 1:I
                linearIndex = ((k-1)*J*I + (j-1)*I + (i-1)) * 3 + 1;
                if linearIndex + 2 <= size(eigen_data, 1)
                    pointData = eigen_data(linearIndex:linearIndex+2, :);
                    eigenvalues = abs(pointData(:, 4));
                    lambda_max_abs_minus_05(i, j, k) = max(eigenvalues) - 0.5;
                end
            end
        end
    end
end

% Calculate raw value of (eigenvalue minus 0.5) with maximum absolute value for each ellipsoid
function lambda_absmax_minus_05_raw = calculateLambdaAbsMaxMinus05Raw(eigen_data, gridSize)
    [I, J, K] = deal(gridSize(1), gridSize(2), gridSize(3));
    lambda_absmax_minus_05_raw = zeros(I, J, K);
    
    for k = 1:K
        for j = 1:J
            for i = 1:I
                linearIndex = ((k-1)*J*I + (j-1)*I + (i-1)) * 3 + 1;
                if linearIndex + 2 <= size(eigen_data, 1)
                    pointData = eigen_data(linearIndex:linearIndex+2, :);
                    eigenvalues = pointData(:, 4);
                    lambda_minus_05 = eigenvalues - 0.5;
                    lambda_minus_05_abs = abs(lambda_minus_05);
                    [~, max_abs_idx] = max(lambda_minus_05_abs);
                    lambda_absmax_minus_05_raw(i, j, k) = lambda_minus_05(max_abs_idx);
                end
            end
        end
    end
end

% Calculate three-point gradient coloring values for absolute max eigenvalue minus 0.5
function lambda_absmax_gradient_values = calculateLambdaAbsMaxGradientValues(eigen_data, gridSize)
    [I, J, K] = deal(gridSize(1), gridSize(2), gridSize(3));
    lambda_absmax_gradient_values = zeros(I, J, K);
    
    for k = 1:K
        for j = 1:J
            for i = 1:I
                linearIndex = ((k-1)*J*I + (j-1)*I + (i-1)) * 3 + 1;
                if linearIndex + 2 <= size(eigen_data, 1)
                    pointData = eigen_data(linearIndex:linearIndex+2, :);
                    eigenvalues = pointData(:, 4);
                    lambda_minus_05 = eigenvalues - 0.5;
                    lambda_minus_05_abs = abs(lambda_minus_05);
                    [~, max_abs_idx] = max(lambda_minus_05_abs);
                    lambda_absmax_gradient_values(i, j, k) = lambda_minus_05(max_abs_idx);
                end
            end
        end
    end
end

% Draw plane border function
function drawPlaneBorderByLayer(dim, layers, unique_coords, coord_range, border_settings)
    if isempty(layers) || ~border_settings.enable
        return;
    end
    
    positions = [];
    for layer = layers
        if layer >= 1 && layer <= length(unique_coords)
            positions = [positions, unique_coords(layer)];
        else
            fprintf('  Warning: %s direction layer %d out of range [1, %d], ignored\n', ...
                    upper(dim), layer, length(unique_coords));
        end
    end
    
    if isempty(positions)
        return;
    end
    
    x_min = coord_range.x_min;
    x_max = coord_range.x_max;
    y_min = coord_range.y_min;
    y_max = coord_range.y_max;
    z_min = coord_range.z_min;
    z_max = coord_range.z_max;
    
    switch lower(dim)
        case 'x'
            for x_pos = positions
                border_x = x_pos * ones(5, 1);
                border_y = [y_min, y_max, y_max, y_min, y_min]';
                border_z = [z_min, z_min, z_max, z_max, z_min]';
                line(border_x, border_y, border_z, ...
                     'Color', border_settings.color, ...
                     'LineWidth', border_settings.line_width, ...
                     'LineStyle', border_settings.line_style);
                fprintf('    X-direction plane: layer %d, coordinate = %.4f\n', find(unique_coords == x_pos, 1), x_pos);
            end
            
        case 'y'
            for y_pos = positions
                border_x = [x_min, x_max, x_max, x_min, x_min]';
                border_y = y_pos * ones(5, 1);
                border_z = [z_min, z_min, z_max, z_max, z_min]';
                line(border_x, border_y, border_z, ...
                     'Color', border_settings.color, ...
                     'LineWidth', border_settings.line_width, ...
                     'LineStyle', border_settings.line_style);
                fprintf('    Y-direction plane: layer %d, coordinate = %.4f\n', find(unique_coords == y_pos, 1), y_pos);
            end
            
        case 'z'
            for z_pos = positions
                border_x = [x_min, x_max, x_max, x_min, x_min]';
                border_y = [y_min, y_min, y_max, y_max, y_min]';
                border_z = z_pos * ones(5, 1);
                line(border_x, border_y, border_z, ...
                     'Color', border_settings.color, ...
                     'LineWidth', border_settings.line_width, ...
                     'LineStyle', border_settings.line_style);
                fprintf('    Z-direction plane: layer %d, coordinate = %.4f\n', find(unique_coords == z_pos, 1), z_pos);
            end
    end
end

% Draw eigenvalue ellipsoids
function drawEigenEllipsoids(eigen_data, gridSize, samplingInterval, scaleFactor, ...
                              fixedPlane, ellipsoidResolution, volumes, lambda_max_minus_05, ...
                              border_line_color, color_map_name, fixed_color, face_alpha, ...
                              coloring_scheme, volume_show_colorbar, volume_colorbar_divisions, ...
                              volume_use_scientific, volume_decimal_places, ...
                              lambda_show_colorbar, lambda_colorbar_divisions, ...
                              lambda_use_scientific, lambda_decimal_places, ...
                              lambda_fixed_range, lambda_use_fixed_range, ...
                              density_weighted_volumes, use_density_weighted, ...
                              density_interp, X_mesh, Y_mesh, Z_mesh, density_weighting_scale, ...
                              lambda_absmax_raw_values, ...
                              absmax_raw_show_colorbar, absmax_raw_colorbar_divisions, ...
                              absmax_raw_use_scientific, absmax_raw_decimal_places, ...
                              absmax_raw_fixed_range, absmax_raw_use_fixed_range, ...
                              absmax_raw_color_neg, absmax_raw_map_min_neg, ...
                              absmax_raw_color_pos, absmax_raw_map_max_pos, ...
                              lambda_absmax_gradient_values, ...
                              absmax_gradient_show_colorbar, absmax_gradient_colorbar_divisions, ...
                              absmax_gradient_use_scientific, absmax_gradient_decimal_places, ...
                              absmax_gradient_fixed_range, absmax_gradient_use_fixed_range, ...
                              absmax_gradient_color_min, absmax_gradient_color_zero, absmax_gradient_color_max)
    if isempty(eigen_data)
        fprintf('  Eigenvalue data is empty, skipping ellipsoid drawing\n');
        return;
    end
    
    [I, J, K] = deal(gridSize(1), gridSize(2), gridSize(3));
    
    [unitX, unitY, unitZ] = ellipsoid(0, 0, 0, 1, 1, 1, ellipsoidResolution);
    unitPoints = [unitX(:), unitY(:), unitZ(:)]';
    
    if use_density_weighted && ~isempty(density_interp)
        x_coords = X_mesh(1,:,1);
        y_coords = Y_mesh(:,1,1);
        z_coords = squeeze(Z_mesh(1,1,:));
        fprintf('    Density-weighted ellipsoid size enabled, density weighting scale factor: %.2f\n', density_weighting_scale);
    end
    
    % Determine color data range based on coloring scheme
    switch coloring_scheme
        case 'volume'
            color_values = volumes;
            minColorVal = min(volumes(:));
            maxColorVal = max(volumes(:));
            show_colorbar = volume_show_colorbar;
            colorbar_divisions = volume_colorbar_divisions;
            use_scientific = volume_use_scientific;
            decimal_places = volume_decimal_places;
            colorbar_label = 'Ellipsoid Volume';
        case 'lambda_max_minus_0.5'
            color_values = lambda_max_minus_05;
            if lambda_use_fixed_range
                minColorVal = lambda_fixed_range(1);
                maxColorVal = lambda_fixed_range(2);
                fprintf('    Lambda coloring scheme using fixed colorbar range: [%.2f, %.2f]\n', minColorVal, maxColorVal);
            else
                minColorVal = min(lambda_max_minus_05(:));
                maxColorVal = max(lambda_max_minus_05(:));
                fprintf('    Lambda coloring scheme using actual data range: [%.6e, %.6e]\n', minColorVal, maxColorVal);
            end
            show_colorbar = lambda_show_colorbar;
            colorbar_divisions = lambda_colorbar_divisions;
            use_scientific = lambda_use_scientific;
            decimal_places = lambda_decimal_places;
            colorbar_label = 'Max Eigenvalue - 0.5';
        case 'lambda_absmax_minus_05_raw'
            color_values = lambda_absmax_raw_values;
            if absmax_raw_use_fixed_range
                minColorVal = absmax_raw_fixed_range(1);
                maxColorVal = absmax_raw_fixed_range(2);
                fprintf('    Absolute max eigenvalue minus 0.5 raw value coloring scheme using fixed colorbar range: [%.2f, %.2f]\n', minColorVal, maxColorVal);
                fprintf('    Dual-color mapping rules:\n');
                fprintf('      Negative interval: [%.2f, 0] → %s(opaque) → transparent\n', absmax_raw_map_min_neg, absmax_raw_color_neg);
                fprintf('      Positive interval: [0, %.2f] → transparent → %s(opaque)\n', absmax_raw_map_max_pos, absmax_raw_color_pos);
            else
                minColorVal = min(lambda_absmax_raw_values(:));
                maxColorVal = max(lambda_absmax_raw_values(:));
                fprintf('    Absolute max eigenvalue minus 0.5 raw value coloring scheme using actual data range: [%.6e, %.6e]\n', minColorVal, maxColorVal);
            end
            show_colorbar = absmax_raw_show_colorbar;
            colorbar_divisions = absmax_raw_colorbar_divisions;
            use_scientific = absmax_raw_use_scientific;
            decimal_places = absmax_raw_decimal_places;
            colorbar_label = 'max(|λ-0.5|) corresponding (λ-0.5)';
        case 'density_weighted_volume'
            color_values = density_weighted_volumes;
            minColorVal = min(density_weighted_volumes(:));
            maxColorVal = max(density_weighted_volumes(:));
            show_colorbar = volume_show_colorbar;
            colorbar_divisions = volume_colorbar_divisions;
            use_scientific = volume_use_scientific;
            decimal_places = volume_decimal_places;
            colorbar_label = 'Density-Weighted Volume';
        case 'lambda_absmax_minus_05_gradient'
            color_values = lambda_absmax_gradient_values;
            if absmax_gradient_use_fixed_range
                minColorVal = absmax_gradient_fixed_range(1);
                maxColorVal = absmax_gradient_fixed_range(2);
                fprintf('    Absolute max eigenvalue minus 0.5 three-point gradient coloring scheme using fixed colorbar range: [%.2f, %.2f]\n', minColorVal, maxColorVal);
                fprintf('    Three-point gradient mapping rules:\n');
                fprintf('      Min (%.2f) → [%.2f,%.2f,%.2f]\n', minColorVal, absmax_gradient_color_min(1), absmax_gradient_color_min(2), absmax_gradient_color_min(3));
                fprintf('      Zero (0.00) → [%.2f,%.2f,%.2f]\n', absmax_gradient_color_zero(1), absmax_gradient_color_zero(2), absmax_gradient_color_zero(3));
                fprintf('      Max (%.2f) → [%.2f,%.2f,%.2f]\n', maxColorVal, absmax_gradient_color_max(1), absmax_gradient_color_max(2), absmax_gradient_color_max(3));
            else
                minColorVal = min(lambda_absmax_gradient_values(:));
                maxColorVal = max(lambda_absmax_gradient_values(:));
                fprintf('    Absolute max eigenvalue minus 0.5 three-point gradient coloring scheme using actual data range: [%.6e, %.6e]\n', minColorVal, maxColorVal);
            end
            show_colorbar = absmax_gradient_show_colorbar;
            colorbar_divisions = absmax_gradient_colorbar_divisions;
            use_scientific = absmax_gradient_use_scientific;
            decimal_places = absmax_gradient_decimal_places;
            colorbar_label = 'max(|λ-0.5|) corresponding (λ-0.5) (3-point gradient)';
        case 'fixed'
            color_values = [];
            minColorVal = 0;
            maxColorVal = 1;
            show_colorbar = false;
        otherwise
            color_values = volumes;
            minColorVal = min(volumes(:));
            maxColorVal = max(volumes(:));
            show_colorbar = false;
    end
    
    % Create colormap
    use_rgba_colormap = false;
    ellipsoidColorMapRGB = [];
    alphaMap = [];
    cbarColorMap = [];
    
    if ~strcmp(coloring_scheme, 'fixed') && maxColorVal > minColorVal
        n_colors = 256;
        
        if strcmp(coloring_scheme, 'lambda_absmax_minus_05_raw') && absmax_raw_use_fixed_range
            [ellipsoidColorMapRGB, alphaMap, cbarColorMap] = createDualColorTransparentColormap(...
                absmax_raw_color_neg, absmax_raw_color_pos, n_colors, ...
                absmax_raw_map_min_neg, absmax_raw_map_max_pos, ...
                minColorVal, maxColorVal, face_alpha);
            use_rgba_colormap = true;
            fprintf('    Using dual-color transparent gradient colormap\n');
        elseif strcmp(coloring_scheme, 'lambda_absmax_minus_05_gradient') && absmax_gradient_use_fixed_range
            [ellipsoidColorMapRGB, cbarColorMap] = createThreePointGradientColormap(...
                absmax_gradient_color_min, absmax_gradient_color_zero, absmax_gradient_color_max, n_colors, ...
                minColorVal, maxColorVal);
            fprintf('    Using three-point gradient colormap\n');
        else
            ellipsoidColorMapRGB = createGeneralColormap(color_map_name, n_colors);
            fprintf('    Using standard colormap: %s gradient\n', color_map_name);
        end
    end
    
    % Parse fixed color
    if ischar(fixed_color) || isstring(fixed_color)
        fixed_color_rgb = get_color_rgb(char(fixed_color));
    else
        fixed_color_rgb = fixed_color;
    end
    
    % Determine loop range
    if ~isempty(fixedPlane)
        dim = fixedPlane(1);
        idx = fixedPlane(2);
        switch dim
            case 1
                i_range = idx;
                j_range = 1:samplingInterval(2):J;
                k_range = 1:samplingInterval(3):K;
            case 2
                i_range = 1:samplingInterval(1):I;
                j_range = idx;
                k_range = 1:samplingInterval(3):K;
            case 3
                i_range = 1:samplingInterval(1):I;
                j_range = 1:samplingInterval(2):J;
                k_range = idx;
            otherwise
                i_range = 1:samplingInterval(1):I;
                j_range = 1:samplingInterval(2):J;
                k_range = 1:samplingInterval(3):K;
        end
    else
        i_range = 1:samplingInterval(1):I;
        j_range = 1:samplingInterval(2):J;
        k_range = 1:samplingInterval(3):K;
    end
    
    ellipsoid_count = 0;
    
    % Loop and draw ellipsoids
    for k = k_range
        for j = j_range
            for i = i_range
                linearIndex = ((k-1)*J*I + (j-1)*I + (i-1)) * 3 + 1;
                if linearIndex + 2 > size(eigen_data, 1)
                    continue;
                end
                
                pointData = eigen_data(linearIndex:linearIndex+2, :);
                center = pointData(1, 1:3);
                axesLengths_original = abs(pointData(:, 4)) * scaleFactor;
                
                if use_density_weighted && ~isempty(density_interp)
                    [~, x_idx] = min(abs(x_coords - center(1)));
                    [~, y_idx] = min(abs(y_coords - center(2)));
                    [~, z_idx] = min(abs(z_coords - center(3)));
                    x_idx = max(1, min(length(x_coords), x_idx));
                    y_idx = max(1, min(length(y_coords), y_idx));
                    z_idx = max(1, min(length(z_coords), z_idx));
                    density_val = density_interp(y_idx, x_idx, z_idx);
                    volume_scale_factor = density_val * density_weighting_scale;
                    axis_scale_factor = volume_scale_factor^(1/3);
                    axesLengths = axesLengths_original * axis_scale_factor;
                else
                    axesLengths = axesLengths_original;
                end
                
                eigenvectors = pointData(:, 5:7);
                R = eigenvectors';
                S = diag(axesLengths');
                transformedPoints = R * S * unitPoints;
                transformedPoints(1, :) = transformedPoints(1, :) + center(1);
                transformedPoints(2, :) = transformedPoints(2, :) + center(2);
                transformedPoints(3, :) = transformedPoints(3, :) + center(3);
                
                n = sqrt(size(unitPoints, 2));
                x = reshape(transformedPoints(1, :), [n, n]);
                y = reshape(transformedPoints(2, :), [n, n]);
                z = reshape(transformedPoints(3, :), [n, n]);
                
                % Determine color and transparency based on coloring scheme
                if strcmp(coloring_scheme, 'fixed')
                    color = fixed_color_rgb;
                    alpha_val = face_alpha;
                else
                    if strcmp(coloring_scheme, 'density_weighted_volume')
                        colorValue = (density_weighted_volumes(i, j, k) - minColorVal) / (maxColorVal - minColorVal);
                    elseif (strcmp(coloring_scheme, 'lambda_absmax_minus_05_raw') && absmax_raw_use_fixed_range)
                        raw_value = color_values(i, j, k);
                        if absmax_raw_map_max_pos > absmax_raw_map_min_neg
                            colorValue = (raw_value - absmax_raw_map_min_neg) / (absmax_raw_map_max_pos - absmax_raw_map_min_neg);
                        else
                            colorValue = 0.5;
                        end
                        colorValue = max(0, min(1, colorValue));
                    elseif strcmp(coloring_scheme, 'lambda_absmax_minus_05_gradient') && absmax_gradient_use_fixed_range
                        raw_value = color_values(i, j, k);
                        if maxColorVal > minColorVal
                            colorValue = (raw_value - minColorVal) / (maxColorVal - minColorVal);
                        else
                            colorValue = 0.5;
                        end
                        colorValue = max(0, min(1, colorValue));
                    else
                        colorValue = (color_values(i, j, k) - minColorVal) / (maxColorVal - minColorVal);
                    end
                    colorValue = max(0, min(1, colorValue));
                    index = round(colorValue * (size(ellipsoidColorMapRGB, 1) - 1)) + 1;
                    color = ellipsoidColorMapRGB(index, :);
                    
                    if use_rgba_colormap
                        alpha_val = alphaMap(index);
                    else
                        alpha_val = face_alpha;
                    end
                end
                
                surf(x, y, z, 'FaceAlpha', alpha_val, 'EdgeColor', 'none', 'FaceColor', color);
                ellipsoid_count = ellipsoid_count + 1;
            end
        end
    end
    
    fprintf('  Eigenvalue ellipsoid drawing completed: %d ellipsoids\n', ellipsoid_count);
    
    % Add colorbar
    if ~strcmp(coloring_scheme, 'fixed') && show_colorbar && maxColorVal > minColorVal
        if use_rgba_colormap && ~isempty(cbarColorMap)
            colormap(gca, cbarColorMap);
        else
            colormap(gca, ellipsoidColorMapRGB);
        end
        clim([minColorVal, maxColorVal]);
        h_cb = colorbar('Location', 'eastoutside');
        ylabel(h_cb, colorbar_label);
        
        if use_scientific
            setColorbarScientificFormatCustom(h_cb, minColorVal, maxColorVal, colorbar_divisions, decimal_places);
            fprintf('    Ellipsoid colorbar: scientific notation (divisions=%d, coefficient decimal places=%d)\n', colorbar_divisions, decimal_places);
        else
            setColorbarDecimalFormat(h_cb, minColorVal, maxColorVal, colorbar_divisions, decimal_places);
            fprintf('    Ellipsoid colorbar: decimal format (divisions=%d, decimal places=%d)\n', colorbar_divisions, decimal_places);
        end
        
        ax_pos = get(gca, 'Position');
        set(h_cb, 'Position', [ax_pos(1)+ax_pos(3)+0.02, ax_pos(2), 0.02, ax_pos(4)]);
    end
end

%% ==================== Read density data ====================
fprintf('%s\n', repmat('=', 1, 70));
fprintf('=== Processing density data file: %s ===\n', density_filename);
fprintf('%s\n', repmat('=', 1, 70));

if ~isfile(density_filename)
    error('Density file does not exist: %s', density_filename);
end

density_data = load(density_filename);

if size(density_data, 2) < 4
    error('Density data file must contain at least 4 columns: x, y, z, density');
end

x_density = density_data(:, 1);
y_density = density_data(:, 2);
z_density = density_data(:, 3);
density = density_data(:, 4);

density_min = min(density);
density_max = max(density);

unique_x_density = sort(unique(x_density));
unique_y_density = sort(unique(y_density));
unique_z_density = sort(unique(z_density));

nx_density_layers = length(unique_x_density);
ny_density_layers = length(unique_y_density);
nz_density_layers = length(unique_z_density);

fprintf('Successfully read %d density data points\n', length(x_density));
fprintf('Density range: [%.6f, %.6f]\n', density_min, density_max);
fprintf('Coordinate ranges:\n');
fprintf('  X: [%.6f, %.6f] (%d layers)\n', min(x_density), max(x_density), nx_density_layers);
fprintf('  Y: [%.6f, %.6f] (%d layers)\n', min(y_density), max(y_density), ny_density_layers);
fprintf('  Z: [%.6f, %.6f] (%d layers)\n', min(z_density), max(z_density), nz_density_layers);

%% ==================== Read Beta density data ====================
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('=== Processing Beta density data file: %s ===\n', beta_density_filename);
fprintf('%s\n', repmat('=', 1, 70));

beta_exists = isfile(beta_density_filename);

if beta_exists
    beta_data = load(beta_density_filename);
    
    if size(beta_data, 2) < 4
        warning('Beta density data file must contain at least 4 columns: x, y, z, beta_density. Skipping Beta density visualization.');
        beta_exists = false;
    else
        x_beta = beta_data(:, 1);
        y_beta = beta_data(:, 2);
        z_beta = beta_data(:, 3);
        beta_density = beta_data(:, 4);
        
        beta_min = min(beta_density);
        beta_max = max(beta_density);
        
        unique_x_beta = sort(unique(x_beta));
        unique_y_beta = sort(unique(y_beta));
        unique_z_beta = sort(unique(z_beta));
        
        nx_beta_layers = length(unique_x_beta);
        ny_beta_layers = length(unique_y_beta);
        nz_beta_layers = length(unique_z_beta);
        
        x_beta_min = min(x_beta);
        x_beta_max = max(x_beta);
        y_beta_min = min(y_beta);
        y_beta_max = max(y_beta);
        z_beta_min = min(z_beta);
        z_beta_max = max(z_beta);
        
        fprintf('Successfully read %d Beta density data points\n', length(x_beta));
        fprintf('Beta density range: [%.6f, %.6f]\n', beta_min, beta_max);
        fprintf('Beta coordinate ranges:\n');
        fprintf('  X: [%.6f, %.6f] (%d layers)\n', x_beta_min, x_beta_max, nx_beta_layers);
        fprintf('  Y: [%.6f, %.6f] (%d layers)\n', y_beta_min, y_beta_max, ny_beta_layers);
        fprintf('  Z: [%.6f, %.6f] (%d layers)\n', z_beta_min, z_beta_max, nz_beta_layers);
    end
else
    fprintf('Beta density file does not exist: %s, skipping Beta density visualization\n', beta_density_filename);
end

%% ==================== Read eigenvalue ellipsoid data ====================
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('=== Processing eigenvalue ellipsoid data file: %s ===\n', eigen_filename);
fprintf('%s\n', repmat('=', 1, 70));

eigen_exists = isfile(eigen_filename);
eigen_data = [];
eigen_volumes = [];
eigen_lambda_max_minus_05 = [];
eigen_lambda_absmax_raw_values = [];
eigen_lambda_absmax_gradient_values = [];
eigen_density_weighted_volumes = [];

if eigen_exists && show_eigen_ellipsoids
    eigen_data = readEigenDataFile(eigen_filename);
    
    if ~isempty(eigen_data)
        validateEigenData(eigen_data, eigen_grid_size);
        eigen_volumes = calculateEllipsoidVolumes(eigen_data, eigen_grid_size, eigen_scale_factor);
        eigen_lambda_max_minus_05 = calculateLambdaMaxAbsMinus05(eigen_data, eigen_grid_size);
        eigen_lambda_absmax_raw_values = calculateLambdaAbsMaxMinus05Raw(eigen_data, eigen_grid_size);
        eigen_lambda_absmax_gradient_values = calculateLambdaAbsMaxGradientValues(eigen_data, eigen_grid_size);
        
        fprintf('Successfully read eigenvalue data, total data rows: %d\n', size(eigen_data, 1));
        fprintf('Eigenvalue grid size: [%d, %d, %d]\n', eigen_grid_size(1), eigen_grid_size(2), eigen_grid_size(3));
        fprintf('Ellipsoid volume range: [%.6e, %.6e]\n', min(eigen_volumes(:)), max(eigen_volumes(:)));
        fprintf('Ellipsoid color coloring scheme: %s\n', eigen_coloring_scheme);
    else
        fprintf('Eigenvalue data file is empty, skipping ellipsoid visualization\n');
        eigen_exists = false;
    end
elseif ~eigen_exists && show_eigen_ellipsoids
    fprintf('Eigenvalue file does not exist: %s, skipping ellipsoid visualization\n', eigen_filename);
    eigen_exists = false;
elseif ~show_eigen_ellipsoids
    fprintf('Eigenvalue ellipsoid visualization disabled\n');
end

%% ==================== Read vector data ====================
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('=== Processing vector data file: %s ===\n', vector_filename);
fprintf('%s\n', repmat('=', 1, 70));

if ~isfile(vector_filename)
    error('Vector file does not exist: %s', vector_filename);
end

vector_data = load(vector_filename);

if size(vector_data, 2) < 6
    error('Vector data file must contain 6 columns: x, y, z, u, v, w');
end

x_vector = vector_data(:, 1);
y_vector = vector_data(:, 2);
z_vector = vector_data(:, 3);
u = vector_data(:, 4);
v = vector_data(:, 5);
w = vector_data(:, 6);

unique_x_vector = sort(unique(x_vector));
unique_y_vector = sort(unique(y_vector));
unique_z_vector = sort(unique(z_vector));

nx_vector_layers = length(unique_x_vector);
ny_vector_layers = length(unique_y_vector);
nz_vector_layers = length(unique_z_vector);

total_vector_points = length(x_vector);
fprintf('Successfully read %d vector data points\n', total_vector_points);
fprintf('Vector field grid structure:\n');
fprintf('  X: [%.6f, %.6f] (%d layers)\n', min(x_vector), max(x_vector), nx_vector_layers);
fprintf('  Y: [%.6f, %.6f] (%d layers)\n', min(y_vector), max(y_vector), ny_vector_layers);
fprintf('  Z: [%.6f, %.6f] (%d layers)\n', min(z_vector), max(z_vector), nz_vector_layers);

is_structured = (nx_vector_layers * ny_vector_layers * nz_vector_layers == total_vector_points);
if is_structured
    fprintf('Vector data has regular grid structure\n');
else
    fprintf('Vector data does not have regular grid structure\n');
end

%% ==================== Density field interpolation processing ====================
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('=== Density field interpolation processing ===\n');

x_min = min(x_density); x_max = max(x_density);
y_min = min(y_density); y_max = max(y_density);
z_min = min(z_density); z_max = max(z_density);

x_grid = linspace(x_min, x_max, grid_resolution);
y_grid = linspace(y_min, y_max, grid_resolution);
z_grid = linspace(z_min, z_max, grid_resolution);

[X_mesh, Y_mesh, Z_mesh] = meshgrid(x_grid, y_grid, z_grid);

fprintf('Performing density field interpolation (resolution: %d x %d x %d)...\n', ...
        grid_resolution, grid_resolution, grid_resolution);

F = scatteredInterpolant(x_density, y_density, z_density, density, 'natural', 'linear');
D_interp = F(X_mesh, Y_mesh, Z_mesh);

nan_mask = isnan(D_interp);
if any(nan_mask(:))
    fprintf('  Warning: Interpolation produced %d NaN values, filling with nearest neighbor interpolation\n', sum(nan_mask(:)));
    F_nearest = scatteredInterpolant(x_density, y_density, z_density, density, 'nearest', 'nearest');
    D_interp(nan_mask) = F_nearest(X_mesh(nan_mask), Y_mesh(nan_mask), Z_mesh(nan_mask));
end

if smooth_factor > 0
    fprintf('Applying smoothing filter, smoothing factor: %.2f\n', smooth_factor);
    kernel_size = max(3, round(smooth_factor * 3));
    if mod(kernel_size, 2) == 0
        kernel_size = kernel_size + 1;
    end
    kernel_size = min(kernel_size, 11);
    
    try
        h = fspecial3('gaussian', [kernel_size, kernel_size, kernel_size], smooth_factor);
        D_interp = imfilter(D_interp, h, 'replicate');
        fprintf('  Smoothing completed\n');
    catch
        fprintf('  Note: Smoothing filter unavailable, skipping\n');
    end
end

fprintf('Interpolation completed, density range: [%.6f, %.6f]\n', min(D_interp(:)), max(D_interp(:)));

if eigen_exists && show_eigen_ellipsoids && ~isempty(eigen_data) && use_density_weighted_volume
    fprintf('\nCalculating density-weighted volume (volume × density)...\n');
    eigen_density_weighted_volumes = calculateDensityWeightedVolumes(eigen_data, eigen_grid_size, ...
                                       eigen_scale_factor, D_interp, X_mesh, Y_mesh, Z_mesh, ...
                                       density_weighting_scale);
    fprintf('Density-weighted volume range: [%.6e, %.6e]\n', min(eigen_density_weighted_volumes(:)), max(eigen_density_weighted_volumes(:)));
end

%% ==================== Beta density field interpolation processing ====================
if beta_exists
    fprintf('\n%s\n', repmat('=', 1, 70));
    fprintf('=== Beta density field interpolation processing ===\n');
    
    x_beta_grid = linspace(x_beta_min, x_beta_max, grid_resolution);
    y_beta_grid = linspace(y_beta_min, y_beta_max, grid_resolution);
    z_beta_grid = linspace(z_beta_min, z_beta_max, grid_resolution);
    
    [X_beta_mesh, Y_beta_mesh, Z_beta_mesh] = meshgrid(x_beta_grid, y_beta_grid, z_beta_grid);
    
    F_beta = scatteredInterpolant(x_beta, y_beta, z_beta, beta_density, 'natural', 'linear');
    Beta_interp = F_beta(X_beta_mesh, Y_beta_mesh, Z_beta_mesh);
    
    beta_nan_mask = isnan(Beta_interp);
    if any(beta_nan_mask(:))
        fprintf('  Warning: Interpolation produced %d NaN values, filling with nearest neighbor interpolation\n', sum(beta_nan_mask(:)));
        F_beta_nearest = scatteredInterpolant(x_beta, y_beta, z_beta, beta_density, 'nearest', 'nearest');
        Beta_interp(beta_nan_mask) = F_beta_nearest(X_beta_mesh(beta_nan_mask), Y_beta_mesh(beta_nan_mask), Z_beta_mesh(beta_nan_mask));
    end
    
    fprintf('Beta density interpolation completed, range: [%.6f, %.6f]\n', min(Beta_interp(:)), max(Beta_interp(:)));
end

%% ==================== Vector field data processing ====================
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('=== Vector field data processing ===\n');

fprintf('\nVector field display mode: %s\n', vector_display_mode);

display_vectors = true;
slice_mask = true(total_vector_points, 1);

switch lower(vector_display_mode)
    case 'none'
        display_vectors = false;
        fprintf('  Vector field display disabled\n');
        
    case 'full'
        display_vectors = true;
        fprintf('  Displaying all vectors\n');
        
    case 'slice'
        display_vectors = true;
        slice_mask = false(total_vector_points, 1);
        total_slices = 0;
        
        directions = {'x', 'y', 'z'};
        coord_arrays = {x_vector, y_vector, z_vector};
        unique_coords = {unique_x_vector, unique_y_vector, unique_z_vector};
        max_layers = [nx_vector_layers, ny_vector_layers, nz_vector_layers];
        coord_names = {'X', 'Y', 'Z'};
        
        for dir_idx = 1:3
            dir_name = directions{dir_idx};
            coord_array = coord_arrays{dir_idx};
            unique_coord = unique_coords{dir_idx};
            max_layer = max_layers(dir_idx);
            coord_name = coord_names{dir_idx};
            
            field_name = dir_name;
            if isfield(vector_slice_settings, field_name) && ...
               isfield(vector_slice_settings.(field_name), 'enable') && ...
               vector_slice_settings.(field_name).enable
                
                slice_positions = vector_slice_settings.(field_name).positions;
                valid_positions = [];
                for pos = slice_positions
                    if pos >= 1 && pos <= max_layer
                        valid_positions = [valid_positions, pos];
                    else
                        fprintf('  Warning: %s direction slice position %d out of range [1, %d], ignored\n', ...
                                coord_name, pos, max_layer);
                    end
                end
                
                if ~isempty(valid_positions)
                    for pos = valid_positions
                        slice_coord = unique_coord(pos);
                        if length(unique_coord) > 1
                            tol = (unique_coord(2) - unique_coord(1)) / 2;
                        else
                            tol = 0.01;
                        end
                        layer_mask = abs(coord_array - slice_coord) < tol;
                        slice_mask = slice_mask | layer_mask;
                        total_slices = total_slices + 1;
                        fprintf('  %s direction slice: layer %d (%.4f)\n', coord_name, pos, slice_coord);
                    end
                end
            end
        end
        
        if total_slices == 0
            fprintf('  Warning: No slice directions enabled or slice positions invalid, vectors will not be displayed\n');
            display_vectors = false;
        else
            fprintf('  Total %d slices enabled, selected points: %d\n', total_slices, sum(slice_mask));
        end
        
    otherwise
        error('Invalid display mode');
end

if display_vectors
    fprintf('\nVector display spacing: X:%d, Y:%d, Z:%d\n', vector_spacing_x, vector_spacing_y, vector_spacing_z);
    
    if is_structured
        [x_idx, y_idx, z_idx] = ndgrid(1:nx_vector_layers, 1:ny_vector_layers, 1:nz_vector_layers);
        x_idx = x_idx(:);
        y_idx = y_idx(:);
        z_idx = z_idx(:);
        
        select_x = mod(x_idx - 1, vector_spacing_x) == 0;
        select_y = mod(y_idx - 1, vector_spacing_y) == 0;
        select_z = mod(z_idx - 1, vector_spacing_z) == 0;
        spacing_mask = select_x & select_y & select_z;
    else
        sampled_x = unique_x_vector(1:vector_spacing_x:end);
        sampled_y = unique_y_vector(1:vector_spacing_y:end);
        sampled_z = unique_z_vector(1:vector_spacing_z:end);
        
        spacing_mask = false(total_vector_points, 1);
        for i = 1:length(sampled_x)
            for j = 1:length(sampled_y)
                for k = 1:length(sampled_z)
                    match_x = abs(x_vector - sampled_x(i)) < 0.01;
                    match_y = abs(y_vector - sampled_y(j)) < 0.01;
                    match_z = abs(z_vector - sampled_z(k)) < 0.01;
                    spacing_mask = spacing_mask | (match_x & match_y & match_z);
                end
            end
        end
    end
    
    final_mask = slice_mask & spacing_mask;
    display_indices = find(final_mask);
    vector_display_count = length(display_indices);
    
    fprintf('Filtering result: displaying %d / %d vectors (%.1f%%)\n', ...
            vector_display_count, total_vector_points, 100*vector_display_count/total_vector_points);
    
    if vector_display_count == 0
        warning('No vector points satisfying the conditions found');
        display_vectors = false;
    else
        x_vec_disp = x_vector(display_indices);
        y_vec_disp = y_vector(display_indices);
        z_vec_disp = z_vector(display_indices);
        u_disp = u(display_indices) * arrow_scale;
        v_disp = v(display_indices) * arrow_scale;
        w_disp = w(display_indices) * arrow_scale;
    end
end

%% ==================== Create colormaps ====================
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('=== Creating colormaps ===\n');

density_rgb = get_color_rgb(density_color);
n_colors = 256;
cmap_density = create_color_map(density_rgb, n_colors, density_zero_transparent);

fprintf('Density colormap: %s gradient', density_color);
if density_zero_transparent
    fprintf(' (zero density: colorless/transparent)\n');
else
    fprintf('\n');
end

if beta_exists && (show_beta_scatter || show_beta_slice)
    beta_rgb = get_color_rgb(beta_slice_color);
    cmap_beta = create_color_map(beta_rgb, n_colors, true);
    fprintf('Beta density colormap: %s gradient (zero density: colorless/transparent)\n', beta_slice_color);
end

%% ==================== Create figure ====================
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('=== Creating combined figure ===\n');

fig = figure('Position', [100, 100, figure_width, figure_height], 'Color', background_color);
hold on;
colormap(gca, cmap_density);

%% 1. Density field scatter plot
if show_density_scatter
    fprintf('\nPlotting density scatter plot...\n');
    
    norm_density = (density - density_min) / (density_max - density_min);
    colors = zeros(length(density), 3);
    for i = 1:3
        colors(:, i) = density_rgb(i) * norm_density;
    end
    
    alpha_vals = scatter_alpha * norm_density;
    alpha_vals = max(0, min(1, alpha_vals));
    
    batch_size = 5000;
    num_batches = ceil(length(density) / batch_size);
    
    for batch = 1:num_batches
        start_idx = (batch-1)*batch_size + 1;
        end_idx = min(batch*batch_size, length(density));
        idx_range = start_idx:end_idx;
        
        scatter3(x_density(idx_range), y_density(idx_range), z_density(idx_range), ...
                 scatter_marker_size, colors(idx_range,:), 'filled', ...
                 'MarkerEdgeAlpha', 'flat', 'MarkerFaceAlpha', 'flat', ...
                 'AlphaData', alpha_vals(idx_range));
    end
    
    fprintf('  Density scatter plot completed (displaying %d points)\n', length(density));
end

%% 2. Beta density field scatter plot
if beta_exists && show_beta_scatter
    fprintf('\nPlotting Beta density scatter plot...\n');
    
    beta_scatter_rgb = get_color_rgb(beta_scatter_color);
    beta_norm = (beta_density - beta_min) / (beta_max - beta_min);
    beta_norm = max(0, min(1, beta_norm));
    beta_norm_adjusted = beta_norm * beta_scatter_brightness;
    beta_norm_adjusted = max(0, min(1, beta_norm_adjusted));
    
    beta_colors = zeros(length(beta_density), 3);
    for i = 1:3
        beta_colors(:, i) = beta_scatter_rgb(i) * beta_norm_adjusted;
    end
    
    beta_alpha_vals = beta_scatter_alpha * beta_norm;
    beta_alpha_vals = max(0, min(1, beta_alpha_vals));
    
    batch_size = 5000;
    num_batches = ceil(length(beta_density) / batch_size);
    
    for batch = 1:num_batches
        start_idx = (batch-1)*batch_size + 1;
        end_idx = min(batch*batch_size, length(beta_density));
        idx_range = start_idx:end_idx;
        
        scatter3(x_beta(idx_range), y_beta(idx_range), z_beta(idx_range), ...
                 beta_scatter_marker_size, beta_colors(idx_range,:), 'filled', ...
                 'MarkerEdgeAlpha', 'flat', 'MarkerFaceAlpha', 'flat', ...
                 'AlphaData', beta_alpha_vals(idx_range));
    end
    
    fprintf('  Beta density scatter plot completed (displaying %d points, color=%s, brightness coefficient=%.2f)\n', ...
            length(beta_density), beta_scatter_color, beta_scatter_brightness);
end

%% 3. Density field slices
if show_density_slice
    fprintf('\nPlotting density slices...\n');
    
    slice_x_list = [];
    slice_y_list = [];
    slice_z_list = [];
    
    if slice_settings.x.enable
        for pos = slice_settings.x.positions
            if pos >= 1 && pos <= nx_density_layers
                slice_x = unique_x_density(pos);
                slice_x_list = [slice_x_list, slice_x];
                fprintf('  X-direction slice: layer %d, coordinate = %.6f\n', pos, slice_x);
            else
                fprintf('  Warning: X-direction slice position %d out of range [1, %d], ignored\n', pos, nx_density_layers);
            end
        end
    end
    
    if slice_settings.y.enable
        for pos = slice_settings.y.positions
            if pos >= 1 && pos <= ny_density_layers
                slice_y = unique_y_density(pos);
                slice_y_list = [slice_y_list, slice_y];
                fprintf('  Y-direction slice: layer %d, coordinate = %.6f\n', pos, slice_y);
            else
                fprintf('  Warning: Y-direction slice position %d out of range [1, %d], ignored\n', pos, ny_density_layers);
            end
        end
    end
    
    if slice_settings.z.enable
        for pos = slice_settings.z.positions
            if pos >= 1 && pos <= nz_density_layers
                slice_z = unique_z_density(pos);
                slice_z_list = [slice_z_list, slice_z];
                fprintf('  Z-direction slice: layer %d, coordinate = %.6f\n', pos, slice_z);
            else
                fprintf('  Warning: Z-direction slice position %d out of range [1, %d], ignored\n', pos, nz_density_layers);
            end
        end
    end
    
    if ~isempty(slice_x_list) || ~isempty(slice_y_list) || ~isempty(slice_z_list)
        h_slice = slice(X_mesh, Y_mesh, Z_mesh, D_interp, ...
                        slice_x_list, slice_y_list, slice_z_list);
        shading interp;
        
        for i = 1:length(h_slice)
            set(h_slice(i), 'CDataMapping', 'scaled');
            set(h_slice(i), 'FaceAlpha', slice_alpha, 'EdgeColor', 'none');
        end
        fprintf('  Density slices plotted (X:%d, Y:%d, Z:%d)\n', ...
                length(slice_x_list), length(slice_y_list), length(slice_z_list));
    else
        fprintf('  No density slices enabled or slice positions invalid\n');
    end
end

%% 4. Beta density field slices (supports dual-color gradient scheme)
if beta_exists && show_beta_slice
    fprintf('\nPlotting Beta density slices...\n');
    
    beta_slice_x_list = [];
    beta_slice_y_list = [];
    beta_slice_z_list = [];
    
    if beta_slice_settings.x.enable
        for pos = beta_slice_settings.x.positions
            if pos >= 1 && pos <= nx_beta_layers
                slice_x = unique_x_beta(pos);
                beta_slice_x_list = [beta_slice_x_list, slice_x];
                fprintf('  Beta X-direction slice: layer %d, coordinate = %.6f\n', pos, slice_x);
            else
                fprintf('  Warning: Beta X-direction slice position %d out of range [1, %d], ignored\n', pos, nx_beta_layers);
            end
        end
    end
    
    if beta_slice_settings.y.enable
        for pos = beta_slice_settings.y.positions
            if pos >= 1 && pos <= ny_beta_layers
                slice_y = unique_y_beta(pos);
                beta_slice_y_list = [beta_slice_y_list, slice_y];
                fprintf('  Beta Y-direction slice: layer %d, coordinate = %.6f\n', pos, slice_y);
            else
                fprintf('  Warning: Beta Y-direction slice position %d out of range [1, %d], ignored\n', pos, ny_beta_layers);
            end
        end
    end
    
    if beta_slice_settings.z.enable
        for pos = beta_slice_settings.z.positions
            if pos >= 1 && pos <= nz_beta_layers
                slice_z = unique_z_beta(pos);
                beta_slice_z_list = [beta_slice_z_list, slice_z];
                fprintf('  Beta Z-direction slice: layer %d, coordinate = %.6f\n', pos, slice_z);
            else
                fprintf('  Warning: Beta Z-direction slice position %d out of range [1, %d], ignored\n', pos, nz_beta_layers);
            end
        end
    end
    
    if ~isempty(beta_slice_x_list) || ~isempty(beta_slice_y_list) || ~isempty(beta_slice_z_list)
        
        switch lower(beta_color_scheme)
            case 'dual_color_gradient'
                % ===== Dual-color gradient scheme =====
                fprintf('    Using dual-color gradient scheme: [%.2f,%.2f,%.2f] → [%.2f,%.2f,%.2f]\n', ...
                        beta_dual_color_min(1), beta_dual_color_min(2), beta_dual_color_min(3), ...
                        beta_dual_color_max(1), beta_dual_color_max(2), beta_dual_color_max(3));
                fprintf('      Mapping range: [%.4f, %.4f]\n', beta_dual_map_min, beta_dual_map_max);
                fprintf('      Colorbar range: [%.4f, %.4f]\n', beta_dual_cbar_min, beta_dual_cbar_max);
                
                % Create dual-color gradient colormap
                n_colors_beta = 256;
                [beta_color_rgb, beta_cbar_cmap] = createDualColorGradientColormap(...
                    beta_dual_color_min, beta_dual_color_max, n_colors_beta, ...
                    beta_dual_map_min, beta_dual_map_max, ...
                    beta_dual_cbar_min, beta_dual_cbar_max);
                
                % Save current colormap
                original_cmap = colormap(gca);
                
                % Set colormap
                colormap(gca, beta_cbar_cmap);
                
                % Set color axis range
                if beta_dual_use_fixed_range
                    caxis([beta_dual_cbar_min, beta_dual_cbar_max]);
                else
                    caxis([beta_dual_map_min, beta_dual_map_max]);
                end
                
                % X-direction slices
                for slice_x = beta_slice_x_list
                    [~, x_idx] = min(abs(x_beta_grid - slice_x));
                    slice_data = squeeze(Beta_interp(:, x_idx, :))';
                    [Y_slice, Z_slice] = meshgrid(y_beta_grid, z_beta_grid);
                    X_slice = ones(size(Y_slice)) * slice_x;
                    
                    surf(X_slice, Y_slice, Z_slice, slice_data, ...
                        'FaceColor', 'interp', ...
                        'EdgeColor', 'none', ...
                        'FaceAlpha', beta_slice_alpha);
                    
                    fprintf('    X-direction slice: coordinate = %.6f, data range [%.4f, %.4f]\n', ...
                            slice_x, min(slice_data(:)), max(slice_data(:)));
                end
                
                % Y-direction slices
                for slice_y = beta_slice_y_list
                    [~, y_idx] = min(abs(y_beta_grid - slice_y));
                    slice_data = squeeze(Beta_interp(y_idx, :, :));
                    [X_slice, Z_slice] = meshgrid(x_beta_grid, z_beta_grid);
                    Y_slice = ones(size(X_slice)) * slice_y;
                    
                    surf(X_slice, Y_slice, Z_slice, slice_data, ...
                        'FaceColor', 'interp', ...
                        'EdgeColor', 'none', ...
                        'FaceAlpha', beta_slice_alpha);
                    
                    fprintf('    Y-direction slice: coordinate = %.6f, data range [%.4f, %.4f]\n', ...
                            slice_y, min(slice_data(:)), max(slice_data(:)));
                end
                
                % Z-direction slices
                for slice_z = beta_slice_z_list
                    [~, z_idx] = min(abs(z_beta_grid - slice_z));
                    slice_data = squeeze(Beta_interp(:, :, z_idx));
                    [X_slice, Y_slice] = meshgrid(x_beta_grid, y_beta_grid);
                    Z_slice = ones(size(X_slice)) * slice_z;
                    
                    surf(X_slice, Y_slice, Z_slice, slice_data, ...
                        'FaceColor', 'interp', ...
                        'EdgeColor', 'none', ...
                        'FaceAlpha', beta_slice_alpha);
                    
                    fprintf('    Z-direction slice: coordinate = %.6f, data range [%.4f, %.4f]\n', ...
                            slice_z, min(slice_data(:)), max(slice_data(:)));
                end
                
                % Add Beta density colorbar
                if beta_dual_show_colorbar
                    cb_beta = colorbar('Location', 'eastoutside');
                    ylabel(cb_beta, 'Beta Density');
                    
                    if beta_dual_use_fixed_range
                        caxis_val_min = beta_dual_cbar_min;
                        caxis_val_max = beta_dual_cbar_max;
                    else
                        caxis_val_min = beta_dual_map_min;
                        caxis_val_max = beta_dual_map_max;
                    end
                    caxis([caxis_val_min, caxis_val_max]);
                    
                    if beta_dual_colorbar_scientific
                        setColorbarScientificFormatCustom(cb_beta, caxis_val_min, caxis_val_max, ...
                            beta_dual_colorbar_divisions, beta_dual_colorbar_decimal_places);
                    else
                        setColorbarDecimalFormat(cb_beta, caxis_val_min, caxis_val_max, ...
                            beta_dual_colorbar_divisions, beta_dual_colorbar_decimal_places);
                    end
                    
                    ax_pos = get(gca, 'Position');
                    set(cb_beta, 'Position', [ax_pos(1)+ax_pos(3)+0.02, ax_pos(2), 0.02, ax_pos(4)]);
                    
                    fprintf('  Beta density colorbar setup complete (dual-color gradient)\n');
                end
                
            case 'transparent_gradient'
                % ===== Single-color transparent gradient scheme =====
                fprintf('    Using single-color transparent gradient scheme: %s, mapping [%.2f,%.2f] → [transparent, %s], display [%.2f,%.2f]\n', ...
                        mat2str(beta_transparent_color), beta_map_min, beta_map_max, ...
                        mat2str(beta_transparent_color), beta_cbar_min, beta_cbar_max);
                
                n_colors_beta = 256;
                [beta_color_rgb, beta_alpha_map, beta_cbar_cmap] = createSingleColorTransparentColormap(...
                    beta_transparent_color, n_colors_beta, beta_map_min, beta_map_max, ...
                    beta_cbar_min, beta_cbar_max, beta_fade_from_white, beta_slice_alpha);
                
                original_cmap = colormap(gca);
                colormap(gca, beta_cbar_cmap);
                
                if beta_use_fixed_range
                    caxis([beta_cbar_min, beta_cbar_max]);
                else
                    caxis([beta_map_min, beta_map_max]);
                end
                
                for slice_x = beta_slice_x_list
                    [~, x_idx] = min(abs(x_beta_grid - slice_x));
                    slice_data = squeeze(Beta_interp(:, x_idx, :))';
                    [Y_slice, Z_slice] = meshgrid(y_beta_grid, z_beta_grid);
                    X_slice = ones(size(Y_slice)) * slice_x;
                    
                    surf_handle = surf(X_slice, Y_slice, Z_slice, slice_data, ...
                        'FaceColor', 'interp', ...
                        'EdgeColor', 'none', ...
                        'FaceAlpha', 'interp', ...
                        'AlphaData', slice_data);
                    
                    set(surf_handle, 'AlphaDataMapping', 'scaled');
                    set(gca, 'ALim', [beta_map_min, beta_map_max]);
                end
                
                for slice_y = beta_slice_y_list
                    [~, y_idx] = min(abs(y_beta_grid - slice_y));
                    slice_data = squeeze(Beta_interp(y_idx, :, :));
                    [X_slice, Z_slice] = meshgrid(x_beta_grid, z_beta_grid);
                    Y_slice = ones(size(X_slice)) * slice_y;
                    
                    surf_handle = surf(X_slice, Y_slice, Z_slice, slice_data, ...
                        'FaceColor', 'interp', ...
                        'EdgeColor', 'none', ...
                        'FaceAlpha', 'interp', ...
                        'AlphaData', slice_data);
                    
                    set(surf_handle, 'AlphaDataMapping', 'scaled');
                    set(gca, 'ALim', [beta_map_min, beta_map_max]);
                end
                
                for slice_z = beta_slice_z_list
                    [~, z_idx] = min(abs(z_beta_grid - slice_z));
                    slice_data = squeeze(Beta_interp(:, :, z_idx));
                    [X_slice, Y_slice] = meshgrid(x_beta_grid, y_beta_grid);
                    Z_slice = ones(size(X_slice)) * slice_z;
                    
                    surf_handle = surf(X_slice, Y_slice, Z_slice, slice_data, ...
                        'FaceColor', 'interp', ...
                        'EdgeColor', 'none', ...
                        'FaceAlpha', 'interp', ...
                        'AlphaData', slice_data);
                    
                    set(surf_handle, 'AlphaDataMapping', 'scaled');
                    set(gca, 'ALim', [beta_map_min, beta_map_max]);
                end
                
                if show_beta_colorbar
                    cb_beta = colorbar('Location', 'eastoutside');
                    ylabel(cb_beta, 'Beta Density');
                    
                    if beta_use_fixed_range
                        caxis_val_min = beta_cbar_min;
                        caxis_val_max = beta_cbar_max;
                    else
                        caxis_val_min = beta_map_min;
                        caxis_val_max = beta_map_max;
                    end
                    caxis([caxis_val_min, caxis_val_max]);
                    
                    num_ticks_beta = beta_colorbar_divisions + 1;
                    beta_tick_values = linspace(caxis_val_min, caxis_val_max, num_ticks_beta);
                    beta_tick_labels = cell(1, num_ticks_beta);
                    format_str_beta = sprintf('%%.%df', beta_colorbar_decimal_places);
                    for j = 1:num_ticks_beta
                        tick_val = beta_tick_values(j);
                        if abs(tick_val) < 1e-10
                            tick_val = 0;
                        end
                        beta_tick_labels{j} = sprintf(format_str_beta, tick_val);
                    end
                    
                    set(cb_beta, 'Ticks', beta_tick_values);
                    set(cb_beta, 'TickLabels', beta_tick_labels);
                    
                    ax_pos = get(gca, 'Position');
                    set(cb_beta, 'Position', [ax_pos(1)+ax_pos(3)+0.02, ax_pos(2), 0.02, ax_pos(4)]);
                end
                
            case 'solid'
                % ===== Solid color scheme =====
                fprintf('    Using solid color scheme: %s\n', beta_slice_color);
                
                beta_slice_rgb = get_color_rgb(beta_slice_color);
                current_cmap = colormap(gca);
                cmap_beta_local = create_color_map(beta_slice_rgb, 256, true);
                colormap(gca, cmap_beta_local);
                
                h_beta_slice = slice(X_beta_mesh, Y_beta_mesh, Z_beta_mesh, Beta_interp, ...
                                     beta_slice_x_list, beta_slice_y_list, beta_slice_z_list);
                shading interp;
                
                for i = 1:length(h_beta_slice)
                    set(h_beta_slice(i), 'CDataMapping', 'scaled');
                    set(h_beta_slice(i), 'FaceAlpha', beta_slice_alpha, 'EdgeColor', 'none');
                end
                
                colormap(gca, current_cmap);
                
                if show_beta_colorbar
                    cb_beta = colorbar('Location', 'eastoutside');
                    ylabel(cb_beta, 'Beta Density');
                    
                    num_ticks_beta = beta_colorbar_divisions + 1;
                    beta_tick_values = linspace(beta_min, beta_max, num_ticks_beta);
                    beta_tick_labels = cell(1, num_ticks_beta);
                    format_str_beta = sprintf('%%.%df', beta_colorbar_decimal_places);
                    for j = 1:num_ticks_beta
                        tick_val = beta_tick_values(j);
                        if abs(tick_val) < 1e-10
                            tick_val = 0;
                        end
                        beta_tick_labels{j} = sprintf(format_str_beta, tick_val);
                    end
                    
                    set(cb_beta, 'Ticks', beta_tick_values);
                    set(cb_beta, 'TickLabels', beta_tick_labels);
                    
                    ax_pos = get(gca, 'Position');
                    set(cb_beta, 'Position', [ax_pos(1)+ax_pos(3)+0.02, ax_pos(2), 0.02, ax_pos(4)]);
                end
        end
        
        fprintf('  Beta density slices plotted (X:%d, Y:%d, Z:%d)\n', ...
                length(beta_slice_x_list), length(beta_slice_y_list), length(beta_slice_z_list));
    else
        fprintf('  No Beta slices enabled or slice positions invalid\n');
    end
end

%% 5. Density isosurface
if show_density_isosurface
    fprintf('\nPlotting isosurface (ρ=%.6f)...\n', isosurface_value);
    
    iso_color = get_color_rgb(isosurface_color);
    
    try
        d_min = min(D_interp(:));
        d_max = max(D_interp(:));
        
        current_value = isosurface_value;
        
        if current_value < d_min || current_value > d_max
            fprintf('  Warning: Isosurface value %.6f out of range [%.6f, %.6f], using midpoint %.6f\n', ...
                    current_value, d_min, d_max, (d_min + d_max) / 2);
            current_value = (d_min + d_max) / 2;
        end
        
        fv = isosurface(X_mesh, Y_mesh, Z_mesh, D_interp, current_value);
        
        if ~isempty(fv.vertices) && ~isempty(fv.faces)
            patch('Faces', fv.faces, 'Vertices', fv.vertices, ...
                  'FaceColor', iso_color, 'EdgeColor', 'none', ...
                  'FaceAlpha', isosurface_alpha);
            
            fprintf('  Isosurface successfully plotted! Density value = %.6f, vertices: %d, faces: %d\n', ...
                    current_value, size(fv.vertices, 1), size(fv.faces, 1));
        else
            fprintf('  Warning: Isosurface not found (density value %.6f has no corresponding isosurface)\n', current_value);
        end
    catch ME
        fprintf('  Isosurface plotting failed: %s\n', ME.message);
    end
end

%% 6. Eigenvalue ellipsoid visualization
if eigen_exists && show_eigen_ellipsoids && ~isempty(eigen_data)
    fprintf('\nPlotting eigenvalue ellipsoids...\n');
    
    if strcmp(eigen_coloring_scheme, 'density_weighted_volume') && exist('eigen_density_weighted_volumes', 'var')
        volumes_to_use = eigen_density_weighted_volumes;
        coloring_scheme_effective = 'density_weighted_volume';
    else
        volumes_to_use = eigen_volumes;
        coloring_scheme_effective = eigen_coloring_scheme;
    end
    
    drawEigenEllipsoids(eigen_data, eigen_grid_size, eigen_sampling_interval, ...
                        eigen_scale_factor, eigen_fixed_plane, ...
                        eigen_ellipsoid_resolution, volumes_to_use, eigen_lambda_max_minus_05, ...
                        border_line_color, eigen_color_map_name, eigen_fixed_color, ...
                        eigen_face_alpha, coloring_scheme_effective, ...
                        eigen_volume_show_colorbar, eigen_volume_colorbar_divisions, ...
                        eigen_volume_colorbar_scientific, eigen_volume_colorbar_decimal_places, ...
                        eigen_lambda_show_colorbar, eigen_lambda_colorbar_divisions, ...
                        eigen_lambda_colorbar_scientific, eigen_lambda_colorbar_decimal_places, ...
                        eigen_lambda_fixed_range, eigen_lambda_use_fixed_range, ...
                        eigen_density_weighted_volumes, use_density_weighted_volume, ...
                        D_interp, X_mesh, Y_mesh, Z_mesh, density_weighting_scale, ...
                        eigen_lambda_absmax_raw_values, ...
                        eigen_absmax_raw_show_colorbar, eigen_absmax_raw_colorbar_divisions, ...
                        eigen_absmax_raw_colorbar_scientific, eigen_absmax_raw_colorbar_decimal_places, ...
                        eigen_absmax_raw_fixed_range, eigen_absmax_raw_use_fixed_range, ...
                        eigen_absmax_raw_color_neg, eigen_absmax_raw_map_min_neg, ...
                        eigen_absmax_raw_color_pos, eigen_absmax_raw_map_max_pos, ...
                        eigen_lambda_absmax_gradient_values, ...
                        eigen_absmax_gradient_show_colorbar, eigen_absmax_gradient_colorbar_divisions, ...
                        eigen_absmax_gradient_colorbar_scientific, eigen_absmax_gradient_colorbar_decimal_places, ...
                        eigen_absmax_gradient_fixed_range, eigen_absmax_gradient_use_fixed_range, ...
                        eigen_absmax_gradient_color_min, eigen_absmax_gradient_color_zero, eigen_absmax_gradient_color_max);
    
    fprintf('  Eigenvalue ellipsoid plotting completed\n');
end

%% 7. Draw vector field
if display_vectors && exist('x_vec_disp', 'var')
    fprintf('\nPlotting vector field (arrow mode: %s)...\n', arrow_mode);
    
    arrow_rgb = get_color_rgb(arrow_color);
    
    switch lower(arrow_shaft_style)
        case 'dashed'
            shaft_line_style = '--';
        case 'dotted'
            shaft_line_style = ':';
        otherwise
            shaft_line_style = '-';
    end
    
    try
        switch lower(arrow_mode)
            case 'quiver3'
                quiver3(x_vec_disp, y_vec_disp, z_vec_disp, ...
                        u_disp, v_disp, w_disp, 0, ...
                        'LineWidth', arrow_line_width, ...
                        'Color', arrow_rgb, ...
                        'MaxHeadSize', arrow_head_size, ...
                        'LineStyle', shaft_line_style, ...
                        'AutoScale', 'off');
                fprintf('  Plotted %d standard arrows\n', vector_display_count);
                
            case 'coneplot'
                if is_structured
                    [X_grid, Y_grid, Z_grid] = meshgrid(unique_x_vector, unique_y_vector, unique_z_vector);
                    U_grid = reshape(u, [ny_vector_layers, nx_vector_layers, nz_vector_layers]);
                    V_grid = reshape(v, [ny_vector_layers, nx_vector_layers, nz_vector_layers]);
                    W_grid = reshape(w, [ny_vector_layers, nx_vector_layers, nz_vector_layers]);
                    
                    coneplot(X_grid, Y_grid, Z_grid, U_grid, V_grid, W_grid, ...
                             x_vec_disp, y_vec_disp, z_vec_disp, 1);
                    fprintf('  Plotted %d cone arrows\n', length(x_vec_disp));
                else
                    fprintf('  Warning: coneplot requires regular grid, switching to quiver3\n');
                    quiver3(x_vec_disp, y_vec_disp, z_vec_disp, ...
                            u_disp, v_disp, w_disp, 0, ...
                            'LineWidth', arrow_line_width, ...
                            'Color', arrow_rgb, ...
                            'MaxHeadSize', arrow_head_size, ...
                            'LineStyle', shaft_line_style, ...
                            'AutoScale', 'off');
                end
                
            case 'line'
                for i = 1:length(x_vec_disp)
                    line([x_vec_disp(i), x_vec_disp(i)+u_disp(i)], ...
                         [y_vec_disp(i), y_vec_disp(i)+v_disp(i)], ...
                         [z_vec_disp(i), z_vec_disp(i)+w_disp(i)], ...
                         'Color', arrow_rgb, 'LineWidth', arrow_line_width, ...
                         'LineStyle', shaft_line_style);
                end
                fprintf('  Plotted %d vector lines\n', vector_display_count);
        end
    catch ME
        fprintf('  Vector plotting failed: %s\n', ME.message);
    end
end

%% 8. Draw plane borders
fprintf('\nPlotting plane borders...\n');

coord_range_plane = struct();
coord_range_plane.x_min = x_min;
coord_range_plane.x_max = x_max;
coord_range_plane.y_min = y_min;
coord_range_plane.y_max = y_max;
coord_range_plane.z_min = z_min;
coord_range_plane.z_max = z_max;

if plane_border_x.enable && ~isempty(plane_border_x.layers)
    fprintf('  X-direction plane borders:\n');
    drawPlaneBorderByLayer('x', plane_border_x.layers, unique_x_density, coord_range_plane, plane_border_x);
end

if plane_border_y.enable && ~isempty(plane_border_y.layers)
    fprintf('  Y-direction plane borders:\n');
    drawPlaneBorderByLayer('y', plane_border_y.layers, unique_y_density, coord_range_plane, plane_border_y);
end

if plane_border_z.enable && ~isempty(plane_border_z.layers)
    fprintf('  Z-direction plane borders:\n');
    drawPlaneBorderByLayer('z', plane_border_z.layers, unique_z_density, coord_range_plane, plane_border_z);
end

hold off;

%% ==================== Draw coordinate axis boundaries ====================
fprintf('\nPlotting coordinate axis boundaries...\n');

all_x_min = min([x_min, x_beta_min, min(x_vector)]);
all_x_max = max([x_max, x_beta_max, max(x_vector)]);
all_y_min = min([y_min, y_beta_min, min(y_vector)]);
all_y_max = max([y_max, y_beta_max, max(y_vector)]);
all_z_min = min([z_min, z_beta_min, min(z_vector)]);
all_z_max = max([z_max, z_beta_max, max(z_vector)]);

if eigen_exists && ~isempty(eigen_data)
    all_x_min = min(all_x_min, min(eigen_data(:,1)));
    all_x_max = max(all_x_max, max(eigen_data(:,1)));
    all_y_min = min(all_y_min, min(eigen_data(:,2)));
    all_y_max = max(all_y_max, max(eigen_data(:,2)));
    all_z_min = min(all_z_min, min(eigen_data(:,3)));
    all_z_max = max(all_z_max, max(eigen_data(:,3)));
end

x_limits_all = [all_x_min, all_x_max];
y_limits_all = [all_y_min, all_y_max];
z_limits_all = [all_z_min, all_z_max];

edges = [
    1, 2; 2, 4; 4, 3; 3, 1;
    5, 6; 6, 8; 8, 7; 7, 5;
    1, 5; 2, 6; 3, 7; 4, 8
];

vertices = [
    x_limits_all(1), y_limits_all(1), z_limits_all(1);
    x_limits_all(2), y_limits_all(1), z_limits_all(1);
    x_limits_all(1), y_limits_all(2), z_limits_all(1);
    x_limits_all(2), y_limits_all(2), z_limits_all(1);
    x_limits_all(1), y_limits_all(1), z_limits_all(2);
    x_limits_all(2), y_limits_all(1), z_limits_all(2);
    x_limits_all(1), y_limits_all(2), z_limits_all(2);
    x_limits_all(2), y_limits_all(2), z_limits_all(2);
];

for i = 1:size(edges, 1)
    line(vertices(edges(i,:), 1), vertices(edges(i,:), 2), vertices(edges(i,:), 3), ...
         'Color', border_line_color, 'LineWidth', border_line_width, ...
         'LineStyle', border_line_style);
end

fprintf('  Boundaries plotted (line width = %.1f, color = [%.2f,%.2f,%.2f], line style = %s)\n', ...
        border_line_width, border_line_color(1), border_line_color(2), ...
        border_line_color(3), border_line_style);

%% ==================== Figure post-processing ====================

ax = gca;
ax.FontSize = axis_tick_fontsize;
ax.Color = background_color;

if hide_axis_lines
    ax.XAxis.Visible = 'off';
    ax.YAxis.Visible = 'off';
    ax.ZAxis.Visible = 'off';
    fprintf('Axis lines hidden\n');
end

if hide_axis_ticks
    ax.XTick = [];
    ax.YTick = [];
    ax.ZTick = [];
    fprintf('Axis ticks hidden\n');
end

if ~hide_axis_labels
    xlabel(xlabel_text, 'FontSize', axis_label_fontsize, 'FontWeight', 'bold', 'Color', border_line_color);
    ylabel(ylabel_text, 'FontSize', axis_label_fontsize, 'FontWeight', 'bold', 'Color', border_line_color);
    zlabel(zlabel_text, 'FontSize', axis_label_fontsize, 'FontWeight', 'bold', 'Color', border_line_color);
    fprintf('Axis labels displayed\n');
else
    fprintf('Axis labels hidden\n');
end

xlim(x_limits_all);
ylim(y_limits_all);
zlim(z_limits_all);

ax_pos = get(gca, 'Position');

% ===== Primary density colorbar =====
if show_colorbar && density_max > density_min
    cb_density = colorbar('Location', 'westoutside');
    cb_density.Label.String = 'Density';
    cb_density.Label.FontSize = 11;
    cb_density.Label.FontWeight = 'bold';
    cb_density.Label.Color = density_rgb;
    cb_density.FontSize = 10;
    
    num_ticks = colorbar_divisions + 1;
    density_tick_values = linspace(density_min, density_max, num_ticks);
    
    if colorbar_decimal_places > 0
        decimal_places = colorbar_decimal_places;
    else
        density_range = density_max - density_min;
        if density_range < 0.001
            decimal_places = 5;
        elseif density_range < 0.01
            decimal_places = 4;
        elseif density_range < 0.1
            decimal_places = 3;
        elseif density_range < 1
            decimal_places = 2;
        else
            decimal_places = 1;
        end
    end
    
    density_tick_labels = cell(1, length(density_tick_values));
    format_str = sprintf('%%.%df', decimal_places);
    
    for i = 1:length(density_tick_values)
        tick_val = density_tick_values(i);
        if abs(tick_val) < 1e-10
            tick_val = 0;
        end
        density_tick_labels{i} = sprintf(format_str, tick_val);
    end
    
    set(cb_density, 'Ticks', density_tick_values);
    set(cb_density, 'TickLabels', density_tick_labels);
    
    try
        cb_density.TickLabelMode = 'manual';
        cb_density.TickMode = 'manual';
    catch
        try
            set(cb_density, 'TickLabelMode', 'manual');
            set(cb_density, 'TickMode', 'manual');
        catch
        end
    end
    
    caxis([density_min, density_max]);
    set(cb_density, 'Position', [ax_pos(1)-0.08, ax_pos(2), 0.02, ax_pos(4)]);
    cb_density.TickDirection = 'out';
    
    drawnow;
    
    try
        y_ax = cb_density.YAxis;
        y_ax.Location = 'right';
    catch
        try
            set(cb_density, 'YAxisLocation', 'right');
        catch
        end
    end
    
    set(cb_density, 'Limits', [density_min, density_max]);
    
    fprintf('Primary density colorbar configured (left side, ticks on right): range [%.4f, %.4f], %d ticks\n', ...
            density_min, density_max, num_ticks);
else
    if ~show_colorbar
        fprintf('Primary density colorbar disabled (show_colorbar = false)\n');
    elseif density_max <= density_min
        fprintf('Warning: Density range invalid, cannot display primary density colorbar\n');
    end
end

view(view_azimuth, view_elevation);
axis equal;
axis tight;

if show_density_isosurface
    light('Position', [1, 1, 1], 'Style', 'infinite');
    light('Position', [-1, -1, 1], 'Style', 'infinite');
    lighting gouraud;
end

drawnow;

%% Add information text box
info_lines = {
    sprintf('Density file: %s', density_filename);
    sprintf('Vector file: %s', vector_filename);
    sprintf('Density points: %d', length(x_density));
    sprintf('Vector points: %d', total_vector_points);
    sprintf('Grid resolution: %d x %d x %d', grid_resolution, grid_resolution, grid_resolution);
    sprintf('Density range: [%.6g, %.6g]', density_min, density_max);
    sprintf('Density color: %s gradient', density_color);
};

if beta_exists
    info_lines{end+1} = sprintf('Beta density file: %s', beta_density_filename);
    info_lines{end+1} = sprintf('Beta density points: %d', length(x_beta));
    info_lines{end+1} = sprintf('Beta density range: [%.6g, %.6g]', beta_min, beta_max);
    if strcmp(beta_color_scheme, 'dual_color_gradient')
        info_lines{end+1} = sprintf('Beta coloring scheme: dual-color gradient');
        info_lines{end+1} = sprintf('  Colors: [%.2f,%.2f,%.2f] → [%.2f,%.2f,%.2f]', ...
                beta_dual_color_min(1), beta_dual_color_min(2), beta_dual_color_min(3), ...
                beta_dual_color_max(1), beta_dual_color_max(2), beta_dual_color_max(3));
        info_lines{end+1} = sprintf('  Mapping range: [%.4f, %.4f]', beta_dual_map_min, beta_dual_map_max);
        info_lines{end+1} = sprintf('  Colorbar range: [%.4f, %.4f]', beta_dual_cbar_min, beta_dual_cbar_max);
        info_lines{end+1} = sprintf('  Colorbar divisions: %d', beta_dual_colorbar_divisions);
        info_lines{end+1} = sprintf('  Decimal places: %d', beta_dual_colorbar_decimal_places);
    elseif strcmp(beta_color_scheme, 'transparent_gradient')
        info_lines{end+1} = sprintf('Beta coloring scheme: transparent gradient (0→transparent, 1→%s)', mat2str(beta_transparent_color));
        info_lines{end+1} = sprintf('Beta mapping range: [%.2f, %.2f]', beta_map_min, beta_map_max);
        info_lines{end+1} = sprintf('Beta colorbar range: [%.2f, %.2f]', beta_cbar_min, beta_cbar_max);
    else
        info_lines{end+1} = sprintf('Beta density color: %s gradient', beta_slice_color);
    end
    info_lines{end+1} = sprintf('Beta colorbar divisions: %d (total %d ticks)', beta_colorbar_divisions, beta_colorbar_divisions+1);
end

if eigen_exists && show_eigen_ellipsoids
    info_lines{end+1} = sprintf('Eigenvalue file: %s', eigen_filename);
    info_lines{end+1} = sprintf('Ellipsoid scale factor: %.4f', eigen_scale_factor);
    info_lines{end+1} = sprintf('Ellipsoid coloring scheme: %s', eigen_coloring_scheme);
    if use_density_weighted_volume
        info_lines{end+1} = sprintf('Ellipsoid size density-weighted: enabled (scale factor=%.2f)', density_weighting_scale);
    end
end

if density_zero_transparent
    info_lines{end+1} = sprintf('Zero density: colorless/transparent');
end

if show_density_scatter
    info_lines{end+1} = sprintf('Density scatter plot: enabled');
end
if show_density_slice
    slice_info = {};
    if slice_settings.x.enable && ~isempty(slice_settings.x.positions)
        slice_info{end+1} = sprintf('X:%s', mat2str(slice_settings.x.positions));
    end
    if slice_settings.y.enable && ~isempty(slice_settings.y.positions)
        slice_info{end+1} = sprintf('Y:%s', mat2str(slice_settings.y.positions));
    end
    if slice_settings.z.enable && ~isempty(slice_settings.z.positions)
        slice_info{end+1} = sprintf('Z:%s', mat2str(slice_settings.z.positions));
    end
    if ~isempty(slice_info)
        info_lines{end+1} = sprintf('Density slices: %s', strjoin(slice_info, ', '));
    end
end

if beta_exists && show_beta_slice
    beta_slice_info = {};
    if beta_slice_settings.x.enable && ~isempty(beta_slice_settings.x.positions)
        beta_slice_info{end+1} = sprintf('X:%s', mat2str(beta_slice_settings.x.positions));
    end
    if beta_slice_settings.y.enable && ~isempty(beta_slice_settings.y.positions)
        beta_slice_info{end+1} = sprintf('Y:%s', mat2str(beta_slice_settings.y.positions));
    end
    if beta_slice_settings.z.enable && ~isempty(beta_slice_settings.z.positions)
        beta_slice_info{end+1} = sprintf('Z:%s', mat2str(beta_slice_settings.z.positions));
    end
    if ~isempty(beta_slice_info)
        info_lines{end+1} = sprintf('Beta slices: %s', strjoin(beta_slice_info, ', '));
    end
end

if show_density_isosurface
    info_lines{end+1} = sprintf('Isosurface: ρ=%.6g', isosurface_value);
end
if display_vectors
    info_lines{end+1} = sprintf('Vectors displayed: %d/%d', vector_display_count, total_vector_points);
    info_lines{end+1} = sprintf('Arrow mode: %s, scale=%.3g', arrow_mode, arrow_scale);
    if strcmpi(vector_display_mode, 'slice')
        slice_dir_info = {};
        if vector_slice_settings.x.enable && ~isempty(vector_slice_settings.x.positions)
            slice_dir_info{end+1} = sprintf('X:%s', mat2str(vector_slice_settings.x.positions));
        end
        if vector_slice_settings.y.enable && ~isempty(vector_slice_settings.y.positions)
            slice_dir_info{end+1} = sprintf('Y:%s', mat2str(vector_slice_settings.y.positions));
        end
        if vector_slice_settings.z.enable && ~isempty(vector_slice_settings.z.positions)
            slice_dir_info{end+1} = sprintf('Z:%s', mat2str(vector_slice_settings.z.positions));
        end
        if ~isempty(slice_dir_info)
            info_lines{end+1} = sprintf('Vector slices: %s', strjoin(slice_dir_info, ', '));
        end
    end
end

if plane_border_x.enable
    info_lines{end+1} = sprintf('X plane borders: layers=%s, color=[%.2f,%.2f,%.2f], line width=%.1f, line style=%s', ...
            mat2str(plane_border_x.layers), plane_border_x.color(1), plane_border_x.color(2), ...
            plane_border_x.color(3), plane_border_x.line_width, plane_border_x.line_style);
end
if plane_border_y.enable
    info_lines{end+1} = sprintf('Y plane borders: layers=%s, color=[%.2f,%.2f,%.2f], line width=%.1f, line style=%s', ...
            mat2str(plane_border_y.layers), plane_border_y.color(1), plane_border_y.color(2), ...
            plane_border_y.color(3), plane_border_y.line_width, plane_border_y.line_style);
end
if plane_border_z.enable
    info_lines{end+1} = sprintf('Z plane borders: layers=%s, color=[%.2f,%.2f,%.2f], line width=%.1f, line style=%s', ...
            mat2str(plane_border_z.layers), plane_border_z.color(1), plane_border_z.color(2), ...
            plane_border_z.color(3), plane_border_z.line_width, plane_border_z.line_style);
end

info_lines{end+1} = sprintf('Boundary line width: %.1f, line style: %s', border_line_width, border_line_style);
info_lines{end+1} = sprintf('Density colorbar decimal places: %d', colorbar_decimal_places);
if beta_exists
    info_lines{end+1} = sprintf('Beta colorbar decimal places: %d', beta_colorbar_decimal_places);
end

annotation('textbox', [0.02, 0.95, 0.3, 0.7], ...
           'String', info_lines, ...
           'FontSize', 9, ...
           'BackgroundColor', [1, 1, 1, 0.85], ...
           'EdgeColor', border_line_color, ...
           'LineWidth', border_line_width * 0.5, ...
           'VerticalAlignment', 'top', ...
           'FitBoxToText', 'on');

%% Output completion information
fprintf('\n%s\n', repmat('=', 1, 70));
fprintf('Combined plotting completed!\n');
fprintf('  Density field visualization: ');
if show_density_scatter, fprintf('Scatter '); end
if show_density_slice, fprintf('Slice '); end
if show_density_isosurface, fprintf('Isosurface'); end
fprintf('\n');
if beta_exists
    fprintf('  Beta density field visualization: ');
    if show_beta_scatter, fprintf('Scatter '); end
    if show_beta_slice, fprintf('Slice'); end
    fprintf('\n');
    fprintf('  Beta scatter plot color: %s\n', beta_scatter_color);
    if strcmp(beta_color_scheme, 'dual_color_gradient')
        fprintf('  Beta slice coloring scheme: dual-color gradient\n');
        fprintf('    Colors: [%.2f,%.2f,%.2f] → [%.2f,%.2f,%.2f]\n', ...
                beta_dual_color_min(1), beta_dual_color_min(2), beta_dual_color_min(3), ...
                beta_dual_color_max(1), beta_dual_color_max(2), beta_dual_color_max(3));
        fprintf('    Mapping range: [%.4f, %.4f]\n', beta_dual_map_min, beta_dual_map_max);
        fprintf('    Colorbar range: [%.4f, %.4f]\n', beta_dual_cbar_min, beta_dual_cbar_max);
        fprintf('    Colorbar divisions: %d, decimal places: %d\n', beta_dual_colorbar_divisions, beta_dual_colorbar_decimal_places);
    elseif strcmp(beta_color_scheme, 'transparent_gradient')
        fprintf('  Beta slice coloring scheme: transparent gradient (0→transparent, 1→%s)\n', mat2str(beta_transparent_color));
        fprintf('  Beta mapping range: [%.2f, %.2f]\n', beta_map_min, beta_map_max);
        fprintf('  Beta colorbar range: [%.2f, %.2f]\n', beta_cbar_min, beta_cbar_max);
    else
        fprintf('  Beta slice color: %s\n', beta_slice_color);
    end
end
if eigen_exists && show_eigen_ellipsoids
    fprintf('  Eigenvalue ellipsoid visualization: enabled\n');
    fprintf('    Ellipsoid coloring scheme: %s\n', eigen_coloring_scheme);
    fprintf('    Ellipsoid scale factor: %.4f\n', eigen_scale_factor);
    if use_density_weighted_volume
        fprintf('    Ellipsoid size density-weighted: enabled (scale factor=%.2f)\n', density_weighting_scale);
    end
end
fprintf('%s\n', repmat('=', 1, 70));