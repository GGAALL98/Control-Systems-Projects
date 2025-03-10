position = out.data_log.theta.Data;     % Position data (angle of the rod)
time = out.tout;                        % Time data

% Define the target position
target_position = pi/4;

% Calculate the end position of the rod for each time step
x = cos(position);  % X position of the rod's end
y = sin(position);  % Y position of the rod's end

% Round the positions for clarity (optional)
x_rounded = round(x, 3);  % Round X positions to 3 decimal places
y_rounded = round(y, 3);  % Round Y positions to 3 decimal places

% Create the figure to plot
figure;
hold on;

% Plot the points and connect them with a light dashed line
plot(x_rounded, y_rounded, 'k--', 'LineWidth', 1.5);  % Light dashed line (black)

% Plot the rod as an orange line from the origin to the last position
plot([0 x_rounded(end)], [0 y_rounded(end)], 'Color', [1, 0.647, 0], 'LineWidth', 3);  % Orange line

% Plot the starting point (steady state) as an "X" marker
plot(x_rounded(1), y_rounded(1), 'kx', 'MarkerSize', 10, 'LineWidth', 2);  % Starting point (steady state)

% Plot the target position (light dashed line)
target_x = cos(target_position);
target_y = sin(target_position);
plot([0 target_x], [0 target_y], 'k--', 'LineWidth', 1.5);  % Target line

% Set axis limits
axis([-1.25 1.25 -1.25 1.25]);

% Labels and title
xlabel('X position');
ylabel('Y position');
title('Rod Position vs. Time with Target Position');

% Display the figure
hold off;

disp('Plot generated.');
