%{ 
	@brief: Create a MATLAB figure window with proper size, position and aspect ratio.

	@param[out]:
	- hF: handle to the created figure
	@param[in]:
	- num_ax: number of *canvas* axes in the figure, [row_num, col_num]
	- num_unit: aspect ratio of height and width, [height_unit, width_unit], in terms of number of unit size
	- unit_sz: unit size, for HiDPI monitor, it is in terms of *logical* pixels
%}
function hF = createFigure(num_ax, num_unit, unit_sz)
	% Get the screen size to proper positioning
	screen_sz = get(groot, 'ScreenSize');
	bk_color = '#FFFFFF';

	fig_height = (num_unit(1) * num_ax(1) + (num_ax(1) - 1) * 2 + 1 * 2) * unit_sz;
	fig_width = (num_unit(2) * num_ax(2) + (num_ax(2) - 1) * 2 + 2 * 2) * unit_sz;

	hF = figure( ...
		'Units', 'pixels', ...
		'Position', [ ...
			(screen_sz(3) - fig_width)/2 + 1, ...
			(screen_sz(4) - fig_height)/2 + 1, ...
			fig_width, ...
			fig_height ...
		], ... % canvas size, excluding the figure borders, title bar, menu bar, and tool bars
		'Color', bk_color ...
	);
end
