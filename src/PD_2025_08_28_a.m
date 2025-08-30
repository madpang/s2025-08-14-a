%{
	@file: PD_2025_08_28_a.m
	@brief: Generate medium data for forward simulation using k-Wave for posterior shadow exploration.

	@date: [created: 2025-08-28, updated: 2025-08-30]
	@author: madpang
%}

% --- Random seed for reproducibility ---
rng(42, "twister"); % Set fixed seed for reproducible results

% --- Helper functions ---
% Functional style subset extraction
fParen = @(x, varargin) x(varargin{:});

% --- Workspace ---
% @note: Assuming directory structure -- `<workspace-name>/src/<this-script>.m`
ws = fileparts(fileparts(mfilename('fullpath')));
wsPath = genpath(ws);
addpath(wsPath);
outputDir = fullfile(ws, 'data', '2025-08-28-a');
if ~exist(outputDir, 'dir')
	mkdir(outputDir);
end

% --- Parameters configuration ---
% Background sound speed [m/s]
c0 = fT2C(36.8);
% Background attenuation [dB/MHz/cm]
att0 = 0.4;
% Attenuation variation
att1 = 1.0; % medium high
att2 = 1.2; % high
% Background density [kg/m^3]
rho0 = 1000;
% Density variation
rho1 = 954; % low
rho2 = 1200; % high

% Number of simulation grid per dim.
gridNum = 2048;
% Grid spacing [m]
dx = 0.125e-3;
% Grid center coordinates [m]
centPos = dx/2 .* [-1, 1];
% Grid coordinates [x, y]
gridPos = RegularGrid( ...
	dx .* [1, 1], ...
	gridNum .* [1, 1], ...
	centPos ...
);

% --- Medium data generation ---
C_MAP = c0 .* ones(gridNum, gridNum);   % sound speed map (constant)
A_MAP = zeros(gridNum, gridNum);        % attenuation map
D_MAP = rho0 .* ones(gridNum, gridNum); % density map

% --- Anonymous functions
% Create disk shape mask (in terms of polar coordinates relative to center)
fMask = @(theta, d, r) ...
	fP2P(transpose(gridPos), transpose(centPos + d .* [cos(theta), sin(theta)])) <= r;
% Mix two kinds of particles with different density to create scattering effect
% - nn: total number of particles
% - par: percentage of alien particles
fDisperse = @(rhoA, rhoB, nn, par) ...
    fParen( ...
        [ ...
            rhoA .* ones(1, nn - round(nn * par)), ...
            rhoB .* ones(1, round(nn * par)) ...
        ], ...
        randperm(nn) ...
    );

% --- Mask 0: a radius 80 mm area of "breast", enclosing a radius-5 mm high attenuation region
mask0 = fMask(0, 0, 80e-3);
A_MAP(mask0) = att0;
D_MAP(mask0) = fDisperse(rho0, rho1, nnz(mask0), 1/4);

% --- Mask 1: low echogenicity, w/ high attenuation (radius 5 mm)
mask1 = fMask(-3/8 * pi, 60e-3, 5e-3);
A_MAP(mask1) = att1;
D_MAP(mask1) = fDisperse(rho0, rho1, nnz(mask1), 1/20);

% --- Mask 2: low echogenicity, w/ background attenuation (radius 5 mm)
mask2 = fMask(pi * 5/8, 60e-3, 5e-3);
A_MAP(mask2) = att0;
D_MAP(mask2) = fDisperse(rho0, rho1, nnz(mask2), 1/20);

% --- Mask 3: high echogenicity, w/ high attenuation, mimicking calcification spot (radius 5 mm)
mask3 = fMask(-pi * 5/8, 20e-3, 2.5e-3);
A_MAP(mask3) = att2;
D_MAP(mask3) = fDisperse(rho0, rho2, nnz(mask3), 1/2);

% --- Mask 4: low echogenicity, w/ low attenuation, mimicking cyst (radius 10 mm)
mask4 = fMask(pi * 3/8, 30e-3, 10e-3);
A_MAP(mask4) = 0.0;
D_MAP(mask4) = rho1;

% --- Mask 5: low echogenicity, high attenuation, at center (radius 5 mm)
mask5 = fMask(0, 0, 5e-3);
A_MAP(mask5) = att1;
D_MAP(mask5) = fDisperse(rho0, rho1, nnz(mask5), 1/20);

%% /// Save map to data ///
% Save maps as binary files with double precision
fhC = fopen(fullfile(outputDir, 'C_MAP.bin'), 'w');
fwrite(fhC, C_MAP, 'double');
fclose(fhC);

fhA = fopen(fullfile(outputDir, 'A_MAP.bin'), 'w');
fwrite(fhA, A_MAP, 'double');
fclose(fhA);

fhD = fopen(fullfile(outputDir, 'D_MAP.bin'), 'w');
fwrite(fhD, D_MAP, 'double');
fclose(fhD);

%% /// Visualization ///
figure; imagesc(D_MAP); axis image; colorbar;
figure; imagesc(A_MAP); axis image; colorbar;
figure; imagesc(C_MAP); axis image; colorbar;
