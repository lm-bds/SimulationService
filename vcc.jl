using DataStructures
using Distributions
using StableRNGs
using Printf
using Dates
using StatsBase
abstract type Event end
abstract type PatientEvent <: Event end
# Entities
mutable struct Patient
    ID::Int
    arrival_time::Float64
    served_by_nurse::Int
    service_start::Float64
    service_time::Float64
    blood_pressure_systolic::Int
    blood_pressure_diastolic::Int
    heart_rate::Int
    temperature::Float64
    spo2::Float64
    departure_time::Float64
    procedure_code::String
    urgent::Function
end
function is_patient_urgent(patient::Patient)
    if patient.blood_pressure_diastolic < 60 ||patient.blood_pressure_diastolic > 100|| patient.blood_pressure_systolic < 90 || patient.blood_pressure_systolic > 150 ||patient.heart_rate < 50 || patient.heart_rate > 100 || patient.temperature < 36.0 || patient.temperature > 38.0
        return true
    else
        return false
    end
end

mutable struct Nurse
    ID::Int
    busy::Bool
    time_with_patient::Float64
end

mutable struct State
    n_arrived::Int
    n_served::Int
    t::Float64
    event_queue::PriorityQueue{Float64, Event, Base.Order.ForwardOrdering}
    patients::Vector{Patient}
    nurses::Vector{Nurse}
    served_patients::Vector{Patient}  

end

# Specific event type
mutable struct initial_event <: PatientEvent
 end

mutable struct Arrival <: PatientEvent
    time::Float64
    patient::Patient
end

mutable struct StartService <: Event
    time::Float64
    patient::Patient
    nurse::Nurse
end

mutable struct Review <: PatientEvent
    time::Float64
    patient::Patient
end

mutable struct CareCoordination <: PatientEvent
    time::Float64
    patient::Patient
end

mutable struct Assessment <: PatientEvent
    time::Float64
    patient::Patient
end

mutable struct NursingService <: PatientEvent
    time::Float64
    patient::Patient
end




mutable struct EndService <: PatientEvent
    time::Float64
    patient::Patient
    nurse::Nurse
end

mutable struct NurseAvailable <: Event
    time::Float64
    nurse::Nurse
end

mutable struct NurseBusy <: Event
    time::Float64
    nurse::Nurse
end

mutable struct Parameters
    n::Int
    mean_interarrival_time::Float64
    std_interarrival_time::Float64
    mean_service_time_review::Float64
    std_service_time_review::Float64
    mean_service_time_assessment::Float64
    std_service_time_assessment::Float64
    mean_service_time_nursing::Float64
    std_service_time_nursing::Float64
    mean_service_time_carecoordination::Float64
    std_service_time_carecoordination::Float64
    n_nurses::Int
end
function Base.isless(a::Event, b::Event)
    return a.time < b.time
end
function write_parameters(output::IO, P::Parameters)
    T = typeof(P)
    for name in fieldnames(T)
    end
end

write_parameters(P::Parameters) = write_parameters(stdout, P)

mutable struct RandomNGs
    rng::StableRNGs.LehmerRNG
    interarrival_time::SkewNormal{Float64}
    service_time_review::Normal{Float64}
    service_time_assessment::Normal{Float64}
    service_time_nursing::Normal{Float64}
    service_time_carecoordination::Normal{Float64}
    blood_pressure_systolic::SkewNormal{Float64}
    blood_pressure_diastolic::SkewNormal{Float64}
    heart_rate::SkewNormal{Float64}
    temperature::Normal{Float64}
    spo2::SkewNormal{Float64}

end

function determine_service_type()
    service_types = ["Review", "NursingService", "Assessment", "CareCoordination"]
    frequencies = [12245, 3200, 32, 2681]
    total = sum(frequencies)
    probabilities = frequencies ./ total
    
    selected_index = sample(1:length(service_types), Weights(probabilities))

    return service_types[selected_index]
end

function handle_start_service(state::State, event::StartService, rngs::RandomNGs, P::Parameters)
    event.patient.service_start = event.time
    service_type = event.patient.procedure_code
    event.patient.procedure_code = service_type
    # Service time based on service type
    if service_type == "Review"
        service_time = rand(rngs.service_time_review)
    elseif service_type == "NursingService"
        service_time = rand(rngs.service_time_nursing)
    elseif service_type == "Assessment"
        service_time = rand(rngs.service_time_assessment)
    elseif service_type == "CareCoordination"
        service_time = rand(rngs.service_time_carecoordination)
    end

    schedule!(state, EndService(event.time + service_time, event.patient, event.nurse), event.time + service_time)
end

function RandomNGs(seed::Int, P::Parameters)
    rng = StableRNGs.LehmerRNG(seed)
    interarrival_time = SkewNormal(P.mean_interarrival_time, P.std_interarrival_time, 0.2)
    service_time_review = Normal(P.mean_service_time_review, P.std_service_time_review)
    service_time_assessment = Normal(P.mean_service_time_assessment, P.std_service_time_assessment)
    service_time_nursing = Normal(P.mean_service_time_nursing, P.std_service_time_nursing)
    service_time_carecoordination = Normal(P.mean_service_time_carecoordination, P.std_service_time_carecoordination)
    blood_pressure_systolic = SkewNormal(128, 23.237, 0.345)
    blood_pressure_diastolic = SkewNormal(75, 14.497, 0.79)
    heart_rate = SkewNormal(74.2, 14.84, 0.903)
    temperature = Normal(36.5, 0.89)
    spo2 = SkewNormal(98.6, 1.6,-1.997)
    return RandomNGs(rng, interarrival_time, service_time_review, service_time_assessment, service_time_nursing, service_time_carecoordination, blood_pressure_systolic, blood_pressure_diastolic, heart_rate, temperature, spo2)
end

function initialise(P::Parameters)
    n_arrived = 0
    n_served = 0
    t = 0.0
    event_queue = PriorityQueue{Float64, Event}()
    patients = Vector{Patient}()
    nurses = [Nurse(i, false, 0.0) for i in 1:P.n_nurses]
    served_patients = Vector{Patient}()
    return State(n_arrived, n_served, t, event_queue, patients, nurses, served_patients)
end

function schedule!(state::State, event::Event, time::Float64)
    # Ensure unique timestamps by adding a small epsilon if a time collision occurs
    adjusted_time = time
    while haskey(state.event_queue, adjusted_time)
        adjusted_time += 1e-6  
    end
    enqueue!(state.event_queue, adjusted_time, event)
end

function handle_arrival(state::State, event::Arrival, rngs::RandomNGs, P::Parameters)
    
    if event.patient.arrival_time == 0.0
        event.patient.arrival_time = event.time
    end
    push!(state.patients, event.patient)

    for nurse in state.nurses
        if !nurse.busy
            nurse.busy = true
            schedule!(state, StartService(event.time, event.patient, nurse), event.time)
            return
        end
    end

    if state.n_arrived < P.n
        state.n_arrived += 1
        next_arrival_time = event.time + rand(rngs.interarrival_time)
        new_patient = Patient(state.n_arrived, next_arrival_time, 0, 0.0, 0.0, 
                              round(rand(rngs.blood_pressure_systolic)), 
                              round(rand(rngs.blood_pressure_diastolic)), 
                              round(rand(rngs.heart_rate)), 
                              rand(rngs.temperature), 
                                rand(rngs.spo2),
                              0.0, 
                              determine_service_type(), 
                              is_patient_urgent)
        if is_patient_urgent(new_patient) == true
            new_patient.procedure_code = "NursingService"
        end

        schedule!(state, Arrival(next_arrival_time, new_patient), next_arrival_time)
    end
end

function handle_end_service(state::State, event::EndService, rngs::RandomNGs, P::Parameters)
    event.patient.departure_time = state.t
    
    time_spent_in_system = event.patient.departure_time - event.patient.arrival_time
    time_spent_in_service = event.patient.departure_time - event.patient.service_start


    state.n_served += 1  
    event.nurse.busy = false
    event.patient.served_by_nurse = event.nurse.ID
    push!(state.served_patients, event.patient)

    if !isempty(state.patients)
        next_patient = popfirst!(state.patients)  
        for nurse in state.nurses
            if !nurse.busy
                nurse.busy = true
                nurse.time_with_patient = state.t
                schedule!(state, StartService(state.t, next_patient, nurse), state.t)
                return
            end
        end
    end
end
function handle_nurse_busy(state::State, event::NurseBusy, rngs::RandomNGs, P::Parameters)
    # Mark the nurse as available
    for nurse in state.nurses
        if nurse.ID == event.nurse.ID
            nurse.busy = false  # Mark nurse as available
        end
    end

    # If there are any patients waiting, assign the next patient
    if !isempty(state.patients)
        next_patient = popfirst!(state.patients)
        
        for nurse in state.nurses
            if !nurse.busy
                nurse.busy = true
                nurse.time_with_patient = state.t
                schedule!(state, StartService(state.t, next_patient, nurse), state.t)
                return
            end
        end
    end
end
function run_simulation(P::Parameters, rng_seed::Int = 1234)
    state = initialise(P)
    rngs = RandomNGs(rng_seed, P)

    # Schedule the first arrival event
    first_arrival_time = 0.0
    state.n_arrived = round(P.n/4)
    let
    for i in 1:state.n_arrived
        next_arrival_time = first_arrival_time
        new_patient = Patient(
            i,  
            next_arrival_time, 0,
            0.0, 0.0, 
            round(Int, rand(rngs.blood_pressure_systolic)), 
            round(Int, rand(rngs.blood_pressure_diastolic)), 
            round(Int, rand(rngs.heart_rate)), 
            rand(rngs.temperature), 
            rand(rngs.spo2),
            0.0, 
            determine_service_type(), 
            is_patient_urgent
        )

        if is_patient_urgent(new_patient) == true
            new_patient.procedure_code = "NursingService"
        end
        state.n_arrived += 1
        schedule!(state, Arrival(next_arrival_time, new_patient), next_arrival_time)
    end
end
    # Main simulation loop
    while state.n_served < P.n && !isempty(state.event_queue)
        current_time, event = dequeue_pair!(state.event_queue)
        state.t = current_time  # Update simulation time
        
        if event isa Arrival
            handle_arrival(state, event, rngs, P)
        elseif event isa StartService
            handle_start_service(state, event, rngs, P)
        elseif event isa NurseBusy
            handle_nurse_busy(state, event, rngs, P)
        elseif event isa EndService
            handle_end_service(state, event, rngs, P)
        end
        
        
    end

    return state  # Return the final state for further analysis
end