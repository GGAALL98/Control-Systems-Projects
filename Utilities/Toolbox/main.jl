using ControlSystems
using Plots


# 1. Controller transfer function
function define_controller()
  global controller, s  # Declare as global to store the result, s for tf('s')
  global T_sys = nothing # Clear the system transfer function
  controllers = []   # Store multiple controllers

  while true
    println("\nSelect a controller type to add:")
    println("1. Proportional (P)")
    println("2. Custom Transfer Function (C)")
    println("3. PID Controller")
    println("4. Lead-Lag Controller")
    println("5. Done (Finish Adding)")

    choice = parse(Int, readline())

    if choice == 1
      println("Enter gain value for P controller: ")
      gain = parse(Float64, readline())
      push!(controllers, tf(gain))  # Convert gain to transfer function

    elseif choice == 2
      println("Enter transfer function for C controller (e.g., (s * (s + 1)) / (s + 2)): ")
      tf_input = readline()
      try
        tf_expr = eval(Meta.parse(tf_input))  # Parse input as Julia expression
        push!(controllers, tf_expr)
      catch
        println("Invalid transfer function format. Try again.")
      end

    elseif choice == 3
      println("Enter proportional gain (Kp): ")
      Kp = parse(Float64, readline())
      println("Enter integral gain (Ki): ")
      Ki = parse(Float64, readline())
      println("Enter derivative gain (Kd): ")
      Kd = parse(Float64, readline())
      push!(controllers, pid(Kp, Ki, Kd))

    elseif choice == 4
      println("Lead-Lag Controller (K * (T1s + 1) / (T2s + 1))")
      println("Enter gain (K): ")
      K = parse(Float64, readline())
      println("Enter lead time constant (T1): ")
      T1 = parse(Float64, readline())
      println("Enter lag time constant (T2): ")
      T2 = parse(Float64, readline())
      push!(controllers, K * tf([T1, 1], [T2, 1]))  # (T1s + 1) / (T2s + 1)

    elseif choice == 5
      break  # Exit loop when user selects "Done"

    else
      println("Invalid choice. Try again.")
    end
  end

  if length(controllers) == 0
    controller = nothing  # Set global controller to nothing if no controllers were added
  else
    controller = prod(controllers)  # Multiply all controllers together and store globally
  end

  println("\nFinal controller:")
  display(controller)
end


# 2. Plant transfer function
function define_plant()
  global plant, s  # Declare plant as global, s for tf('s')
  global T_sys = nothing # Clear the system transfer function
  println("Enter the plant transfer function (e.g., (s + 5) / (s^2 + 3s + 2)): ")
  tf_input = readline()

  try
    plant = eval(Meta.parse(tf_input))  # Convert input string to a Julia expression
    println("\nPlant:")
    display(plant)
  catch
    println("Invalid transfer function format. Try again.")
    plant = nothing
  end
end

# 3. System type (open-loop or closed-loop)
function system_type()
  global controller, plant, H, T_sys, s  # Declare as global

  println("Select the system type:")
  println("1. Open-Loop")
  println("2. Closed-Loop")

  sys_type = parse(Int, readline())

  if controller === nothing || plant === nothing
    println("Error: Define both controller and plant first.")
    return
  end

  if sys_type == 1  # Open-loop system
    println("\nController:")
    display(controller)
    println("\nPlant:")
    display(plant)

    try
      T_sys = controller * plant
      println("\nOpen-Loop System:")
      display(T_sys)
    catch
      println("Error: Invalid multiplication of transfer functions.")
    end

  elseif sys_type == 2  # Closed-loop system
    println("Enter the feedback transfer function (e.g., 1/(s^2+3s+2)): ")
    feedback_tf = readline()

    try
      H = eval(Meta.parse(feedback_tf))  # Parse feedback function
      T_sys = feedback(controller * plant, H)
      println("\nClosed-Loop System:")
      display(T_sys)
    catch
      println("Invalid feedback transfer function format. Try again.")
      T_sys = nothing
    end

  else
    println("Invalid choice. Try again.")
    T_sys = nothing
  end
end

# 4. System response
function systems_response()
  global T_sys  # Declare  T_sys as global
  while true # Keep the menu loop running until the user chooses "Back"
    println("Input Function:")
    println("1. Step")
    println("2. Ramp")
    println("3. Impulse")
    println("4. Pulse")
    println("5. Sinusoidal")
    println("6. Cosine")
    println("9. Back")

    input = parse(Int, readline())

    if input == 1
      display(plot(step(T_sys)))

    elseif input == 2
      println("Enter sampling time: ")
      Ts = parse(Float64, readline())
      println("Enter simulation time: ")
      Tsim = parse(Float64, readline())
      println("Enter slope gain: ")
      K = parse(Float64, readline())

      ramp(t) = K * t  # Ramp with a slope of K

      # Discretize the system using c2d
      sys_d = c2d(T_sys, Ts)

      # Create a time vector from 0 to Tsim with step Ts
      time_vec = 0:Ts:Tsim

      # Generate ramp input for each time step and reshape as a matrix (1 row x N columns)
      ramp_input = [ramp(t) for t in time_vec]
      ramp_input_matrix = reshape(ramp_input, 1, length(ramp_input))

      display(plot(lsim(sys_d, ramp_input_matrix, time_vec)))

    elseif input == 3
      println("Enter simulation time: ")
      Tsim = parse(Float64, readline())
      display(plot(impulse(T_sys, 0:Tsim)))

    elseif input == 4
      println("Enter sampling time: ")
      Ts = parse(Float64, readline())

      println("Enter simulation time: ")
      Tsim = parse(Float64, readline())

      println("Enter gain: ")
      K = parse(Float64, readline())

      println("Enter pulse width: ")
      W = parse(Float64, readline())

      println("Enter pulse period: ")
      t_off = parse(Float64, readline())

      pulse(x, t) = K * (t >= t_off && t <= t_off + W)  # Pulse with amplitude K, width W, and period T

      # Discretize the system using c2d
      sys_d = c2d(T_sys, Ts)

      # Generate pulse input for the discrete-time system
      pulse_input = [pulse(x, t) for t in tsim]

      # Plot the system response to the pulse input using lsim
      display(plot(lsim(sys_d, pulse_input, tsim)))

    elseif input == 5
      println("Enter sampling time: ")
      Ts = parse(Float64, readline())

      println("Enter simulation time: ")
      Tsim = parse(Float64, readline())

      println("Enter amplitude: ")
      A = parse(Float64, readline())

      println("Enter frequency: ")
      f = parse(Float64, readline())

      sin(x, t) = A * sin(2 * pi * f * t)  # Sinusoidal input with amplitude A and frequency f

      # Discretize the system using c2d
      sys_d = c2d(T_sys, Ts)

      # Generate sinusoidal input for the discrete-time system
      sin_input = [sin(x, t) for t in tsim]

      # Reshape sinusoidal input to match the expected input format for lsim
      sin_input_matrix = reshape(sin_input, 1, length(sin_input))

      # Plot the system response to the sinusoidal input using lsim
      display(plot(lsim(sys_d, sin_input_matrix, tsim)))

    elseif input == 6
      println("Enter sampling time: ")
      Ts = parse(Float64, readline())

      println("Enter simulation time: ")
      Tsim = parse(Float64, readline())

      println("Enter amplitude: ")
      A = parse(Float64, readline())

      println("Enter frequency: ")
      f = parse(Float64, readline())

      cos(x, t) = A * cos(2 * pi * f * t)  # Cosine input with amplitude A and frequency f

      # Discretize the system using c2d
      sys_d = c2d(T_sys, Ts)

      # Generate cosine input for the discrete-time system
      cos_input = [cos(x, t) for t in tsim]

      # Reshape cosine input to match the expected input format for lsim
      cos_input_matrix = reshape(cos_input, 1, length(cos_input))

      # Plot the system response to the cosine input using lsim
      display(plot(lsim(sys_d, cos_input_matrix, tsim)))

    elseif input == 9
      return false

    else
      println("Invalid choice. Try again.")
    end
  end
end

# 5. System analysis
function system_analysis()
  global T_sys  # Declare  T_sys as global

  while true # Keep the menu loop running until the user chooses "Back"
    println("System Analysis")
    println("1. system poles")
    println("2. system zeros")
    println("3. step response information")
    println("9. back")

    input = parse(int, readline())

    if input == 1
      println("system poles: ", pole(T_sys))

    elseif input == 2
      println("system zeros: ", zero(T_sys))

    elseif input == 3
      si = stepinfo(T_sys)
      println(si)
      println("Do you want to plot the step response information? (y/n)")
      plot_step = readline()
      if plot_step == "y"
        display(plot(si))
      end

    elseif input == 9
      return false

    else
      println("Invalid choice. Try again.")
    end
  end
end

# 6. System plots
function system_plots()
  global T_sys  # Declare  T_sys as global
  while true # Keep the menu loop running until the user chooses "Back"
    println("System Plots")
    println("1. Bode Plot")
    println("2. Nyquist Plot")
    println("3. Root Locus")
    println("4. Pole-Zero Map")
    println("5. Nichols Chart")
    println("9. Back")

    input = parse(Int, readline())

    if input == 1
      display(bodeplot(T_sys))

    elseif input == 2
      display(nyquistplot(T_sys))

    elseif input == 3
      display(rlocusplot(T_sys))

    elseif input == 4
      display(pzmap(T_sys))

    elseif input == 5
      display(nicholsplot(T_sys))

    elseif input == 9
      return false

    else
      println("Invalid choice. Try again.")
    end
  end
end

# 9. Options
function options()
  println("Options")
  println("1. Plotting backend")
  println("9. Back")

  input = parse(Int, readline())

  if input == 1
    println("Choose a plotting backend:")
    println("1. GR (default)")
    println("2. PythonPlot")
    println("3. Plotly(JS)")
    println("9. UnicodePlots")

    backend = parse(Int, readline())

    if backend == 1
      GR()

    elseif backend == 2
      PythonPlot()

    elseif backend == 3
      PlotlyJS()

    elseif backend == 9
      UnicodePlots()

    else
      println("Invalid choice. Try again.")
    end
  end
end

# Main menu function
function main_menu()
  println("Goby's Control Systems Toolbox")
  while true # Keep the menu loop running until the user chooses "Exit"
    if isnothing(controller) || isnothing(plant) || isnothing(T_sys)
      println("1. Define Controller")
      println("2. Define Plant")
      println("3. Open-Loop / Closed-Loop System")
      println("9. Options")
      println("0. Exit")
    else
      println("1. Define Controller")
      println("2. Define Plant")
      println("3. Open-Loop / Closed-Loop System")
      println("4. System Response")
      println("5. System Analysis")
      println("6. System Plots")
      println("9. Options")
      println("0. Exit")
    end

    choice = parse(Int, readline())

    if choice == 1 # Define controller
      define_controller()

    elseif choice == 2 # Define plant
      define_plant()

    elseif choice == 3 && !isnothing(controller) && !isnothing(plant) # Define system type
      system_type()

    elseif choice == 4 && !isnothing(controller) && !isnothing(plant) && !isnothing(T_sys) # System response
      systems_response()

    elseif choice == 5 && !isnothing(controller) && !isnothing(plant) && !isnothing(T_sys) # System analysis
      system_analysis()

    elseif choice == 6 && !isnothing(controller) && !isnothing(plant) && !isnothing(T_sys) # System plots
      system_plots()

    elseif choice == 9 # Options
      options()

    elseif choice == 0 # Exit
      println("Exiting...")
      break

    else
      println("Invalid choice. Try again.")
    end
  end
end


# Run the menu
s = tf('s')
controller = nothing
plant = nothing
H = 1
T_sys = nothing

main_menu()
