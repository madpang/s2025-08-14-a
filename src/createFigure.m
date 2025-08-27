%{ 
	@brief: Create a MATLAB figure window with proper size, position and aspect ratio.

	@details:
	- This function allows figure window configuration using custom unit, so the caller can think about the aspect ratio, and focus on the real asset where pixels will be painted.
	- It also puts the figure in the center of the screen for better visibility.

	@param[out]:
	- hF: handle to the created figure
	@param[in]:
	- unitLength: length of each unit, in pixels
	- realAssetSize: [width, height] of the real asset, in units
	- marginSize: [horizontal, vertical] margins, in units

	@author: madpang
	@date: [created: 2025-04-13, updated: 2025-08-27]
%}
function hF = createFigure(unitLength, realAssetSize, marginSize, varargin)

	% --- Minimal argument check & parsing
	narginchk(3, 4);
	if length(varargin) >= 1
		backgroundColor = varargin{1};
	else
		backgroundColor = '#FFFFFF';
	end

	% --- Get the screen size to proper positioning
	% screenSize = [x, y, width, height]
	screenSize = get(groot, 'ScreenSize');

	% --- Set figure window
	% @note: This excludes the figure borders, title bar, menu bar, and tool bars
	% figureSize = [figureWidth, figureHeight]
	figureSize = (realAssetSize + 2 * marginSize) * unitLength;

	hF = figure( ...
		'Units', 'pixels', ...
		'Position', [ ...
			(screenSize(3) - figureSize(1))/2 + 1, ...
			(screenSize(4) - figureSize(2))/2 + 1, ...
			figureSize(1), ...
			figureSize(2) ...
		], ...
		'Color', backgroundColor ...
	);
end
