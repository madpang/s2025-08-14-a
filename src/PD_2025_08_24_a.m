%{
	@file: PD_2025_08_24_a.m
	@brief: Visualize the posterior shadow of data 2025-04-13-b and perform basic analysis.
	@date: [created: 2025-08-24, updated: 2025-08-24]
	@author: madpang
%}

% --- Workspace ---
% @note: Assuming directory structure -- `<workspace-name>/src/<this-script>.m`
ws = fileparts(fileparts(mfilename('fullpath')));
wsPath = genpath(ws);
addpath(wsPath);
inputDir = fullfile(ws, 'data', '2025-04-13-b');
if ~isfolder(inputDir)
	error('Input directory does not exist: %s', inputDir);
end

gridNum = 512;
% --- @todo ---

rxApSz = 610;

ii = 32;

fhIdx = fopen( ...
	fullfile( ...
		inputDir, ...
		['roiIdx', '-', num2str(ii, '%03d'), '.bin'] ...
	), ...
	'r' ...
);

roiIdx = logical(fread(fhIdx, inf, 'logical'));

fclose(fhIdx);

fhRcv = fopen( ...
	fullfile( ...
		inputDir, ...
		['rcvLvl', '-', num2str(ii, '%03d'), '.bin'] ...
	), ...
	'r' ...
);

rcvLvl = reshape(fread(fhRcv, inf, 'single'), [], rxApSz);
fclose(fhRcv);

beamformed_map = NaN(gridNum, gridNum);
beamformed_map(roiIdx) = 20 .* log10(sum(10.^(rcvLvl ./10), 2));

figure;
imagesc(beamformed_map);
axis image;

% --- Clean up ---
rmpath(wsPath);
