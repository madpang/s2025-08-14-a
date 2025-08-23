%{
	@file: PD_2025_04_13_b.m
	@brief: Investigate posterior shadows behind an object with strong attenuation.
	@details:
	- This script performs forward simulation using a full set of plane wave TXs;
	- It uses an analytical model of breast with tumor;
	- It computes the received signal level at each pixel in the region of interest (ROI) for each transmission.
	- It assumes uniform scattering energy loss and only focus on the *level* of the received signal which directly relates to attenuation.
	- One can think of the media model consists of point scatterers with the same echogenicity, but has a varying attenuation map.
	- By visualizing the *beamformed* `rcvLvl` data (one needs the pixel index `roiIdx` to restore it into grid), one can gain intuitive insights on the *posterior shadows*.
	@date: [created: 2025-04-13, updated: 2025-08-23]
	@author: madpang
%}

% --- Helper functions ---
% Functional style subset extraction
paren = @(x, varargin) x(varargin{:});

% Mathematica's `Mod[X, n, 1]` equivalent
mod1 = @(X, n) mod(X - 1, n) + 1;

% --- Workspace ---
% @note: Assuming directory structure -- `<workspace-name>/src/<this-script>.m`
ws = fileparts(fileparts(mfilename('fullpath')));
wsPath = genpath(ws);
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

% Number of Tranmissions
txNum = 256;
% Tranmission directions, (x, y) in Cartesian coordinates
txDir = CirclePoints(1, txNum, pi/2, [0, 0]);

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
startStamp = sprintf('Computation started at %s \n', char(datetime('now')));
fprintf(startStamp);
for ii = 1 : txNum
	% TX/RX aperture elements index
	txEleIdx = mod1(paren(circshift(1 : eleNum, txApSz/2), 1 : txApSz) + ii-1, eleNum);
	rxEleIdx = mod1(paren(circshift(1 : eleNum, rxApSz/2), 1 : rxApSz) + ii-1, eleNum);

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
	fwrite(fhIdx, single(roiIdx), 'single');
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
		repmat('>', 1, floor(per * 10)), ...
		repmat(' ', 1, 10 - floor(per * 10)) ...
		']' ...
	];
	fprintf([str_p1, '%%', ' ', str_p2]);
	fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');		
end
finishStamp = sprintf('Computation ended at %s \n',  char(datetime('now')));
fprintf(finishStamp);

% --- Log ---
logFile = fullfile(outputDir, 'process.log');
fid = fopen(logFile, 'a');
fprintf(fid, '%s\n', '---');
fprintf(fid, 'Script %s.m executed on %s\n', mfilename, char(java.net.InetAddress.getLocalHost.getHostName));
fprintf(fid, '%s', startStamp);
fprintf(fid, '%s', finishStamp);
fclose(fid);

% --- Clean up ---
rmpath(wsPath);

% --- Local function(s) ---
%{
	@brief: Calculate the signal level at a specific pixel w/ a specific model
	@usage: rcvLvl = calc1wAttExt(txPos, pixPos, region1Param, region2Param, freq, scattLoss, isSpread, pixSz)

	@param[out]:
	- rcvLvl: signal level at the pixel [dB].
	@param[in]:
	- txPos: transmission position, 2D vector, [x, y];
	- pixPos: pixel position, 2D vector, [x, y];
	- region1Param: parameter of region 1, cell array, {(x, y), r, att}
		- (x, y): center position of the region [mm]
		- r: radius of the region [mm]
		- att: attenuation coefficient [dB/MHz/cm]
	- region2Param: parameter of region 2, cell array, {(x, y), r, att}
	- freq: transmission wave central frequency [MHz]
	- scattLoss: scattering energy loss, scalar [dB]
	- isSpread: whether to consider spreading, bool
	- pixSz: pixel size, scalar [mm]

	@details:
	- This function calculates the received signal from a given point in ROI (pixel) on specific RX ch., given an *extra* attenuation area with disk shape, defined by {cent, r, att}, which represents center, radius and attenuation coefficient, respectively.
	- Scatterer is assumed to have size of the pixel grid (due to the requirement of finite power/energy and finite intensity).
	- Energy/power spreading from a point source is modeled, but if plane wave TX is modeled, there should be no need to account for spreading during TX.
	- This function depends on CircXLine.m

	@author: madpang
	@date: [created: 2025-04-13, updated: 2025-04-13]
%}
function rcvLvl = calc1wAttExt(txPos, pixPos, region1Param, region2Param, freq, scattLoss, isSpread, pixSz)
	% Parameter derivation
	[regPos1, regR1, regAc1] = region1Param{:};
	[regPos2, regR2, regAc2] = region2Param{:};
	a0 = 0;
	a1 = regAc1 * freq / 10;
	a2 = regAc2 * freq / 10;
	[~, ~, len1, dist_1w] = CircXLine(pixPos.', txPos.', regPos1.', regR1, 'segment');
	len2 = CircXLine(pixPos.', txPos.', regPos2.', regR2, 'segment');
	% Account for spreading
	if isSpread
		att_spr = 10 * log10(pixSz ./ (2 * pi * dist_1w));
	else
		att_spr = 0;
	end
	% Compute attenuation level
	rcvLvl = a0 .* dist_1w + ...
		(a1 - a0) .* len1 + ...
		(a2 - a1) .* len2 + ...
		scattLoss + ...
		att_spr;
end
