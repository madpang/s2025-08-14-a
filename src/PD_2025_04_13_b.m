%{
	@file: PD_2025_04_13_b.m
	@brief: Forward simulation using a full set of plane wave TXs, an analytical model of breast with tumor, for posterior shadows exploration.
	@details:
	- It computes the received signal level at each pixel in the region of interest (ROI) for each transmission.
	- It assumes uniform scattering energy loss and only focus on the *level* of the received signal which directly relates to attenuation.
	- One can think of the media model consists of point scatterers with the same echogenicity, but has a varying attenuation map.
	- By visualizing the *beamformed* `rcvLvl` data (one needs the pixel index `roiIdx` to restore it into grid), one can gain intuitive insights on the *posterior shadows*.

	@date: [created: 2025-04-13, updated: 2025-08-24]
	@author: madpang

	@note:
	- This script requires [madmat](https://github.com/madpang/madmat) package.
	- This script depends on calc1wAttExt.m
%}

% --- Helper functions ---
% Functional style subset extraction
fParen = @(x, varargin) x(varargin{:});

% Mathematica's `Mod[X, n, 1]` equivalent
fMod1 = @(X, n) mod(X - 1, n) + 1;

% --- Workspace ---
% @note: Assuming directory structure -- `<workspace-name>/src/<this-script>.m`
ws = fileparts(fileparts(mfilename('fullpath')));
wsPath = sprintf('%1$s/src:%1$s/madmat', ws);
addpath(wsPath);
outputDir = fullfile(ws, 'data', '2025-04-13-b');
if ~exist(outputDir, 'dir')
	mkdir(outputDir);
end

% --- Parameters configuration ---
% USCT radius [mm]
R = 117.0;
% USCT number of elements
eleNum = 2048;
% USCT elements position, (x, y) in Cartesian coordinates
elePos = CirclePoints(R, eleNum, -pi/2 + pi/eleNum, [0, 0]);
% USCT element directivity, in Cartesian coordinates
eleDir = CirclePoints(1, eleNum, pi/2 + pi/eleNum, [0, 0]);

% Number of Transmissions
txNum = 256;
% Transmission directions, (x, y) in Cartesian coordinates
txDir = CirclePoints(1, txNum, pi/2, [0, 0]);
% Transmission aperture moving step size
txStepSz = eleNum / txNum;

% Breast region parameters, (center, radius [mm], attenuation [dB/MHz/cm])
region1 = {[0, 0], 80, -0.4};
% Tumor region parameters (at 10:30 clock direction, inside the breast model)
region2 = {60 .* [cos(pi * 3/4), sin(pi * 3/4)], 5, -1.2};

% Transmission aperture size (in terms of num. of elements)
txApSz = 256;
% Reception aperture size (in terms of num. of elements)
rxApSz = 610;

% Pixel grid definition
gridNum = 512;
gridSz = 232./gridNum; % [mm]
gridPos = RegularGrid( ...
	gridSz .* [1, 1], ...
	gridNum .* [1, 1], ...
	[0, 0] ...
);

% Central frequency of transmission pulse [MHz]
fc = 3.6;

% --- Main loop ---
% Compute the received signal level at each pixel in ROI for each TX 
startStamp = sprintf('Computation started at %s', char(datetime('now')));
fprintf('%s\n', startStamp);
for ii = 1 : txNum
	% TX/RX aperture elements index
	txEleIdx = fMod1(fParen(circshift(1 : eleNum, txApSz/2), 1 : txApSz) + (ii-1) * txStepSz, eleNum);
	rxEleIdx = fMod1(fParen(circshift(1 : eleNum, rxApSz/2), 1 : rxApSz) + (ii-1) * txStepSz, eleNum);

	txApDir = txDir(ii, :);
	txDirNormal = [0, -1; 1, 0] * txApDir.';

	txPos = -txApDir * R;
	rxPos = elePos(rxEleIdx, :);

	% Find the area irradiated by TX aperture
	roiIdx = ( ...
		(gridPos - elePos(txEleIdx(1), :)) * txDirNormal...
	) < 0 & ( ...
		(gridPos - elePos(txEleIdx(end), :)) * txDirNormal ...
	) > 0 & ( ...
		sum(gridPos.^2, 2) < (R - 1)^2 ...
	);
	% Save data to file
	fhIdx = fopen( ...
		fullfile( ...
			outputDir, ...
			['roiIdx', '-', num2str(ii, '%03d'), '.bin'] ...
		), ...
		'w' ...
	);
	fwrite(fhIdx, roiIdx, 'logical');
	fclose(fhIdx);

	% Compute the received signal level at each pixel in ROI
	roiPos = gridPos(roiIdx, :);
	roiPix = size(roiPos, 1);
	rcvLvl = zeros(roiPix, rxApSz);	
	for jj = 1 : roiPix
		% Compute the effective transmission position (from plane wave)
		pixPos = roiPos(jj, :);
		pwPos = transpose((pixPos * txDirNormal) .* txDirNormal) + txPos;
		% Transmission attenuation
		txAtt = calc1wAttExt( ...
			pwPos, ...
			pixPos, ...
			region1, ...
			region2, ...
			fc, ...
			0, ...
			false, ...
			gridSz ... % pixel size
		);
		% Reception attenuation
		rxAtt = calc1wAttExt( ...
			rxPos, ...
			pixPos, ...
			region1, ...
			region2, ...
			fc, ...
			-10.0, ... % Assume scattering has -10 dB energy loss
			true, ...
			gridSz ...
		);

		rcvLvl(jj, :) = txAtt + rxAtt;
	end
	% Save data to file
	fhRcv = fopen( ...
		fullfile( ...
			outputDir, ...
			['rcvLvl', '-', num2str(ii, '%03d'), '.bin'] ...
		), ...
		'w' ...
	);
	fwrite(fhRcv, single(rcvLvl), 'single');
	fclose(fhRcv);

	% Progress bar
	per = ii / txNum;
	str_p1 = sprintf('%5.1f%', per * 100);
	str_p2 = [ ...
		'[', ...
		repmat('>', 1, floor(per * 50)), ...
		repmat(' ', 1, 50 - floor(per * 50)) ...
		']' ...
	];
	fprintf([str_p1, '%%', ' ', str_p2]);
	fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
end
fprintf('\n');
finishStamp = sprintf('Computation ended at %s',  char(datetime('now')));
fprintf('%s\n', finishStamp);

% --- Log ---
logFile = fullfile(outputDir, 'process.log');
fid = fopen(logFile, 'a');
fprintf(fid, '%s\n', '---');
fprintf(fid, 'Script %s.m executed on %s\n', mfilename, char(java.net.InetAddress.getLocalHost.getHostName));
fprintf(fid, '%s\n', startStamp);
fprintf(fid, '%s\n', finishStamp);
fclose(fid);

% --- Clean up ---
rmpath(wsPath);
