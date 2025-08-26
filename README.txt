Attenuation estimation using only reflected signal for USCT

Run
```
export DISPLAY=:2
/usr/local/MATLAB/R2025a/bin/matlab -nodesktop
```

## Visualization

Use `getframe` + `imwrite` to save the plot to file.
Neither `exportgraphics` nor `saveas` would give you what you see on the screen as it is (confirmed by testing with MATLAB R2025a).

--- Reference

1. https://www.mathworks.com/help/matlab/ref/exportgraphics.html
2. https://www.mathworks.com/help/matlab/ref/saveas.html
3. https://www.mathworks.com/help/matlab/creating_plots/compare-ways-to-export-save-graphics-plots-from-figures.html
