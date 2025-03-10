time = out.tout;                        % Time data
speed = out.data_log.thetha_dot.Data;   % Speed data

% Create the figure for speed vs time
figure;
plot(time, speed, 'r-', 'LineWidth', 2);  % Red line for speed
xlabel('Time (s)');
ylabel('Speed (rad/s)');
title('Speed vs Time');
grid on;

disp('Speed vs Time graph generated.');
