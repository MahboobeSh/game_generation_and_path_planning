# Bezier Control Point Visualization

This folder contains scripts to visualize Bezier curve control points with distances (d) and angles (φ), similar to the hand-drawn sketch in the paper.

## Files

- `plot_bezier_control_points.m` - Main function to generate the visualization
- `example_plot_control_points.m` - Example script showing how to use the function

## Usage

```matlab
plot_bezier_control_points(set_number, pairs_number, base_folder)
```

### Parameters:
- `set_number`: The game set number to load (e.g., 14)
- `pairs_number`: Number of obstacle pairs (2, 3, or 4)
- `base_folder`: (Optional) Base folder path. Defaults to current directory.

### Example:
```matlab
base_folder = 'C:\Users\mahbo\OneDrive - University of Calgary\code\game_creation_and_fits';
plot_bezier_control_points(14, 3, base_folder);
```

## Requirements

The script requires:
- A `.mat` file in the `{pairs_number}pairs/fit/` folder with the following fields:
  - `variables_matrix`: Matrix containing d and φ values for each segment
  - `Start_points`: Start points for each Bezier segment
  - `End_points`: End points for each Bezier segment
  - `num_samples_list`: (Optional) Number of samples for each segment

## Output

The script generates a PNG figure showing:
- The Bezier curve path (black line)
- Main points (Pe, Pm3, Pm2, Pm1, Ps) with labels
- Control points (CP) with labels
- Lines connecting main points to control points with distance labels (d)
- Angle indicators (φ) showing angles between path direction and control points
- Circles with radius labels (ε3, r2, r1)

The figure is saved to: `{pairs_number}pairs/fit/bezier_control_points_set_{set_number}_{pairs_number}pairs.png`

## Notes

- The visualization is designed for 4th-order Bezier curves (5 control points per segment)
- The script assumes `n_d=2` and `n_phi=1` (2 distance parameters, 1 angle parameter)
- Control points are labeled according to their position: CPs (start), CPm (middle), CPe (end)

