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
% What:
% - check the symmetry of configuration, before pressure field computation
% - 2048-element w/ rift
% How:
% - this is a DEMO of SYMMETRIC configuration --- important for k-wave based simulation
% When:
% - created on 2022-03-03
% - lasted modified on 2022-03-03
% ================================================================

%%
% Simulation parameters setup
% ----------------------------------------------------------------
% number of grid per dim
grid_num = 2048;
% grid size per dim [m]
grid_sz = 0.125e-3;
% define the grid → align w/ kWaveGrid
grid_pos = transpose(RegularGrid( ...
	grid_sz .* [1, 1], ...
	grid_num .* [1, 1], ...
	grid_sz/2 .* [-1, 1] ...
));

% sampling frequency [Hz] → align w/ COCOLY
fs = 31.25e+6;
dt = 1/fs;
% number of samples per channel → align w/ COCOLY
sample_num = 5e+3; % [NOTE] NO need to record reflected signal

% ########## kgrid ###############################################
% kgrid = kWaveGrid(grid_num, grid_sz, grid_num, grid_sz);
% kgrid.setTime(sample_num, dt);
% ////////////////////////////////////////////////////////////////

% background properties → water, non-attenuating
c0 = fT2C(36.8); % [m/s]
rho0 = 1000; % [kg/m^3]

% ########## medium ##############################################
% non-absorbing 
medium.sound_speed = c0;
medium.density = rho0;
% ////////////////////////////////////////////////////////////////

% radius of USCT ring [m]
usct_radius = 117 * 1e-3;
% number of transducer elements
ele_num = 2048;
% rift size, in terms of number of elements, between 8 transducer blocks
rift_sz = 14;
% transducer blocks number
blk_num = 8;
% dummy transducer number if there were NO rifts
dummy_num = ele_num + rift_sz * blk_num;
% number of independent channels per TX event
ch_num = 256;

% define dummy element position uniformally distributed on the ring
dummy_pos = transpose(CirclePoints( ...
	usct_radius, ...
	dummy_num, ...
	-pi/2 + pi/dummy_num, ...
	grid_sz/2 .* [-1, 1] ...
));

% index to select the actual elements
ele_idx = repmat((1 : ch_num).', 1, blk_num) + ...
	((rift_sz / 2) : (ch_num + rift_sz) : (rift_sz / 2 + (ch_num + rift_sz) * (blk_num - 1)));

ele_pos = dummy_pos(:, ele_idx);

ele_mask = zeros([grid_num, grid_num]);
ele_mask_idx = sub2ind( ...
	grid_num .* [1, 1], ...
	round(-(ele_pos(2, :) - grid_pos(2, 1)) ./ grid_sz) + 1, ...
	round((ele_pos(1, :) - grid_pos(1, 1)) ./ grid_sz) + 1 ...
);

ele_mask(ele_mask_idx) = 1;

% CHECKPOINT
% >	draw the elements
	S = ele_mask + flipud(ele_mask) + fliplr(ele_mask) + rot90(ele_mask, 2);
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
