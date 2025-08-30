%{
	@file: PD_2025_08_30_a.m
	@brief: Forward simulation using k-Wave for posterior shadow exploration.

	@date: [created: 2025-08-30, updated: 2025-08-30]
	@author: madpang

	@note:
	- This script requires [k-wave](https://github.com/madpang/k-wave.git) package.
%}

% --- Workspace ---
% @note: Assuming directory structure -- `<workspace-name>/src/<this-script>.m`
ws = fileparts(fileparts(mfilename('fullpath')));
wsPath = sprintf('%1$s/src:%1$s/madmat', ws);
addpath(wsPath);
inputDir = fullfile(ws, 'data', '2025-08-28-a');
if ~isfolder(inputDir)
	error('Input directory does not exist: %s', inputDir);
end
outputDir = fullfile(ws, 'data', '2025-08-30-a');
if ~exist(outputDir, 'dir')
	mkdir(outputDir);
end

% --- Parameters configuration ---
% Number of grid per dim
gridNum = 2048;
% Grid size per dim [m]
gridSz = 0.125e-3;
% Center position (account for kGrid off-centric issue)
centPos = gridSz/2 .* [-1, 1];
% Define the grid to align w/ kWaveGrid
gridPos = RegularGrid( ...
	gridSz .* [1, 1], ...
	gridNum .* [1, 1], ...
	centPos ...
);

% USCT radius [m]
R = 117.0e-3;
% USCT number of elements
eleNum = 2048;
% USCT elements position, (x, y) in Cartesian coordinates
elePos = CirclePoints(R, eleNum, -pi/2 + pi/eleNum, centPos);

% Tranmission wave central frequency [Hz]
fc = 3.6e+6;
% Sampling frequency [Hz], align w/ COCOLY RingEcho system
fs = 31.25e+6;
dt = 1/fs;
% Number of samples per channel, align w/ COCOLY RingEcho system
ns = 9344;

% --- Load the medium data
fhC = fopen(fullfile(inputDir, 'C_MAP.bin'), 'r');
C_MAP = reshape(fread(fhC, Inf, 'double'), [gridNum, gridNum]);
fclose(fhC);
fhA = fopen(fullfile(inputDir, 'A_MAP.bin'), 'r');
A_MAP = reshape(fread(fhA, Inf, 'double'), [gridNum, gridNum]);
fclose(fhA);
fhD = fopen(fullfile(inputDir, 'D_MAP.bin'), 'r');
D_MAP = reshape(fread(fhD, Inf, 'double'), [gridNum, gridNum]);
fclose(fhD);

% --- k-Wave setup ---
% --- kgrid
% kgrid = kWaveGrid(gridNum, gridSz, gridNum, gridSz);
% kgrid.setTime(ns, dt);

% --- medium
% compensation of non-unit power coefficient of attenuation law
b = 1.9;
medium = struct( ...
	'sound_speed', C_MAP, ...
	'density', D_MAP, ...
	'alpha_power', b, ...
	'alpha_coeff', A_MAP .* (fc/1e+6) / (fc/1e+6)^b ...
);

% --- sensor (full RX)
sensorMask = zeros(gridNum, gridNum);
sensorMaskIndex = sub2ind( ...
	gridNum .* [1, 1], ...
	round(-(elePos(:, 2) - gridPos(1, 2)) ./ gridSz) + 1, ...
	round((elePos(:, 1) - gridPos(1, 1)) ./ gridSz) + 1 ...
);
sensorMask(sensorMaskIndex) = 1;

% CHECKPOINT
% >	draw the elements
	S = sensorMask + flipud(sensorMask) + fliplr(sensorMask) + rot90(sensorMask, 2);
	figure;
	if nnz(S(:)) ~= 2048
		disp('WARNING: the source/sensor element is NOT symmetric on GRID');
		spy(S, 'rx');
	else
		disp('PASS: the source/sensor element is symmetric on GRID');
		spy(S, 'k');
	end
% <

% POST-LOG
% ================================================================
% There is no way to change kgrid.x_vector, w/o modify k-Wave, therefore, it is necessary to consider the shift of coordinates to maintain the SYMMETRY OF ARRANGEMENT ON GRID.
