# Patient Care Simulation

This repository contains a simulation model for patient care services in a healthcare environment. It tracks patients arriving at a healthcare facility, receiving different types of services (like nursing, review, assessment, and care coordination), and calculates key metrics such as the total time spent by patients in the system and the time spent with healthcare providers (nurses).

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Simulation Components](#simulation-components)
  - [Entities](#entities)
  - [Events](#events)
  - [Parameters](#parameters)
- [Usage](#usage)
- [Running Simulations](#running-simulations)
- [License](#license)

## Overview

This simulation framework models patients receiving various healthcare services, using discrete-event simulation. It supports:
- Different types of services (Review, Nursing, Assessment, Care Coordination)
- Patients arriving at a specified rate
- Multiple nurses providing service
- Calculation of key patient data (blood pressure, heart rate, etc.)
- Handling of urgent cases based on patient vitals

## Prerequisites

Before running the simulation, ensure that you have Julia installed on your system. You will also need the following Julia packages:

- `DataStructures`
- `Distributions`
- `StableRNGs`
- `StatsBase`
- `Dates`

Install the required packages using Julia's package manager:

```julia
using Pkg
Pkg.add("DataStructures")
Pkg.add("Distributions")
Pkg.add("StableRNGs")
Pkg.add("StatsBase")
Pkg.add("Dates")
```

## Simulation Components

### Entities

1. **Patient**: Each patient has a unique ID, arrival time, vitals (blood pressure, heart rate, temperature), procedure codes, and urgency status.
2. **Nurse**: Nurses provide services to patients and can be either busy or available.

### Events

1. **Arrival**: A patient arrives at the facility and waits for a nurse to be available.
2. **StartService**: A nurse starts serving a patient.
3. **EndService**: The service is completed, and the patient departs.
4. **NurseAvailable/NurseBusy**: Events to mark the availability or busyness of a nurse.

### Parameters

The `Parameters` struct defines the configuration for each simulation run:

- `n`: Number of patients
- `mean_interarrival_time`, `std_interarrival_time`: Time between patient arrivals
- `mean_service_time_review`, `std_service_time_review`: Service times for reviews
- Similar parameters for nursing, assessment, and care coordination
- `n_nurses`: Number of nurses in the system

## Usage

To define the system parameters, create a `Parameters` struct:

```julia
P = Parameters(
    100,      # Number of patients
    0.2,      # Mean interarrival time
    129.0,    # Std interarrival time
    14.7,     # Mean service time for review
    3.2,      # Std service time for review
    37.5,     # Mean service time for assessment
    10.6,     # Std service time for assessment
    16.72,    # Mean service time for nursing
    3.2,      # Std service time for nursing
    22.27,    # Mean service time for care coordination
    23.86,    # Std service time for care coordination
    5         # Number of nurses
)
```

## Running Simulations

To run the simulation with the defined parameters:

```julia
final_state = run_simulation(P, 1234)  # 'P' is the Parameters struct and '1234' is the random seed
```

The simulation will process patient arrivals and services, storing data like patient service times, urgency status, and nurse assignments. After the simulation ends, you can analyze the final state for key insights:

```julia
# Access the served patients
for patient in final_state.served_patients
    println("Patient ID: ", patient.ID)
    println("Time spent in system: ", patient.departure_time - patient.arrival_time)
end
```

### Example Simulation Output

- Patient service start and end times
- Total time spent by patients
- Time nurses spend with patients

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.