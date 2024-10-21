# Import your simulation file
include("vcc.jl")
using CSV
using DataFrames
using Makie
using GLMakie, FFMPEG
# Set parameters for the simulation
NURSE_NUMBERS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# number of patients list
PATIENT_NUMBERS = collect(1:100)



# Dictionary to store average total time and standard deviation for each nurse-patient configuration
data = Dict{Tuple{Int, Int}, Tuple{Float64, Float64}}()

# Loop over each number of nurses and patients
for nurse_number in NURSE_NUMBERS
    for patient_number in PATIENT_NUMBERS
        total_times = Float64[]  # Store total times for each simulation run

        # Run 100 simulations for each nurse-patient combination
        for i in 1:100
            # Define parameters for the simulation
            P = Parameters(
                patient_number,  # Number of patients
                0.2,  # Mean interarrival time
                129.0,  # Std interarrival time
                14.7,  # Mean service time for review
                3.2,  # Std service time for review
                37.5,  # Mean service time for assessment
                10.6,  # Std service time for assessment
                16.72,  # Mean service time for nursing
                3.2,  # Std service time for nursing
                22.27,  # Mean service time for care coordination
                23.86,  # Std service time for care coordination
                nurse_number  # Number of nurses
            )

            # Run the simulation
            final_state = run_simulation(P)
            push!(total_times, final_state.t)  # Store total simulation time
        end

        # Calculate the average and standard deviation of total times
        avg_time = mean(total_times)
        stddev_time = std(total_times)

        # Store the results in the dictionary
        data[(nurse_number, patient_number)] = (avg_time, stddev_time)

        # Output the results for the current nurse-patient combination
    end
end

# Push the data to a DataFrame
data_df = DataFrame(
    number_of_nurses = Int[],
    number_of_patients = Int[],
    average_time = Float64[],
    standard_deviation = Float64[]
)

# Populate the DataFrame from the dictionary
for (key, value) in data
    push!(data_df, (key[1], key[2], value[1], value[2]))  # key[1] is nurse_number, key[2] is patient_number, value[1] is avg_time, value[2] is stddev_time
end

# Write the DataFrame to a CSV file
CSV.write("summary.csv", data_df)
P = Parameters(
    80,  # Number of patients
    10.0,  # Mean interarrival time
    5.0,  # Std interarrival time
    14.7,  # Mean service time for review
    3.2,  # Std service time for review
    37.5,  # Mean service time for assessment
    10.6,  # Std service time for assessment
    16.72,  # Mean service time for nursing
    3.2,  # Std service time for nursing
    22.27,  # Mean service time for care coordination
    23.86,  # Std service time for care coordination
    4     # Number of nurses
)


#= # Run the simulation and record the execution time
@time begin
    final_state = run_simulation(P)
    # Order patients by ID
    sort!(final_state.served_patients, by = x -> x.ID)

    # Create a DataFrame to store patient data along with calculated fields
    patient_data = DataFrame(
        ID = Int[], 
        arrival_time = Float64[], 
        served_by_nurse = Int[],
        service_start = Float64[], 
        service_time = Float64[],
        blood_pressure_systolic = Int[],
        blood_pressure_diastolic = Int[],
        heart_rate = Int[],
        temperature = Float64[],
        departure_time = Float64[], 
        procedure_code = String[], 
        time_spent_in_system = Float64[], 
        time_spent_in_service = Float64[], 
        is_urgent = Bool[]
    )

    # Populate the DataFrame with patient data
    for patient in final_state.served_patients
        time_spent_in_system = patient.departure_time - patient.arrival_time
        time_spent_in_service = patient.departure_time - patient.service_start
        urgent_status = is_patient_urgent(patient)

        push!(patient_data, (
            patient.ID,
            patient.arrival_time,
            patient.served_by_nurse,
            patient.service_start,
            patient.service_time,
            patient.blood_pressure_systolic,
            patient.blood_pressure_diastolic,
            patient.heart_rate,
            patient.temperature,
            patient.departure_time,
            patient.procedure_code,
            time_spent_in_system,
            time_spent_in_service,
            urgent_status
        ))
    end
    # Write the patient data to a CSV file
    # remove duplicates
    patient_data = unique(patient_data, :ID)
    CSV.write("data.csv", patient_data)
end
# Output the total simulation time
println("Total simulation time: ", final_state.t)

# Optional: Analyze results, e.g., print patient data
patient_results = []

for patient in final_state.patients
    push!(patient_results, (patient.ID, patient.arrival_time, patient.service_start, patient.departure_time))
end

 =#