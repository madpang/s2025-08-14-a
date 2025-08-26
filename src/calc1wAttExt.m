%{
	@brief: Calculate the signal level at a specific pixel w/ a specific model.
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
