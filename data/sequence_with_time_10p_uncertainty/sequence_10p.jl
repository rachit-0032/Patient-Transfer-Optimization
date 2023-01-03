using CSV, Tables, LinearAlgebra, Random, Gurobi, JuMP, DataFrames, Plots, Statistics

## Function to Load Data.
function load_data(fname)
    data = DataFrame(CSV.File(fname, header=false)) |> DataFrame;
    return data
end;

hospital_mapping = CSV.read("hospital_mapping.csv", DataFrame, pool=true);
distance_cost_vehicle_type_mapping = CSV.read("distance_cost_vehicle_type_mapping.csv", DataFrame, pool=true);
fixed_cost_vehicle_type_mapping = CSV.read("fixed_cost_vehicle_type_mapping.csv", DataFrame, pool=true);
vehicle_depot_mapping_binary = CSV.read("vehicle_depot_mapping.csv", DataFrame, pool=true);
distance_mapping = CSV.read("distance_mapping.csv", DataFrame, pool=true);
vehicle_type = CSV.read("vehicle_type.csv", DataFrame, pool=true);
time_mapping = CSV.read("time_mapping.csv", DataFrame, pool=true);

distance_cost_vehicle_type_mapping

vehicle_depot_mapping_binary

hospital_mapping = hospital_mapping[:,2:end]

patient_hospital_mapping = []
max_transfers = maximum(Matrix(hospital_mapping))
for i=1:max_transfers
    transfers = sort(Tuple.(findall(>=(i), Matrix(hospital_mapping))))
    for item in transfers
        push!(patient_hospital_mapping, item)
    end
#    push!(patient_hospital_mapping, sort(Tuple.(findall(>=(i), Matrix(hospital_mapping))))[0])
end

df_patient_hospital_mapping = DataFrame(patient_hospital_mapping)

# CSV.write("../data/sequence_with_time/df_patient_hospital_mapping.csv", df_patient_hospital_mapping)


distance_cost_vehicle_type_mapping = distance_cost_vehicle_type_mapping[:,2:end]

fixed_cost_vehicle_type_mapping = fixed_cost_vehicle_type_mapping[:,2:end]

vehicle_depot_mapping_binary = vehicle_depot_mapping_binary[:,2:end]

vehicle_depot_mapping = copy(vehicle_depot_mapping_binary)

for i = 1:size(vehicle_depot_mapping_binary)[2]
    vehicle_depot_mapping[:,i] = i*vehicle_depot_mapping_binary[:,i]
end

vehicle_depot_mapping[:,1] = sum(eachcol(vehicle_depot_mapping))

vehicle_depot_mapping = select!(vehicle_depot_mapping, [:depot1])

vehicle_depot_mapping

distance_mapping = distance_mapping[:,3:end]

time_mapping = time_mapping[:,3:end]

# vehicle_type = vehicle_type[:,2:end]



electric_vehicles = filter(:type => n -> n == 2, vehicle_type)[:,"vehicle_num"]


n_depots = 2
n_pickup = 10
n_destination = n_pickup
V = n_depots + n_pickup + n_destination    # Total locations

depots = [1: 1: n_depots;]
pickups = [1+n_depots: 1: n_depots+n_pickup;]
destinations = [1+n_depots+n_pickup: 1: n_depots+n_pickup+n_destination;];

depots

pickups

destinations

# n_vehicles_types = maximum(vehicle_type[!,1])
K = size(vehicle_type)[1] # n_vehicles



# max_pickups_per_vehicle = 15

max_time_per_vehicle = 2*60*60

vehicle_depot_mapping

distance_per_elec_charge = 60*1.6*1000

for vehicle_num in electric_vehicles
   println(vehicle_num) 
end

#Ref: https://www.salary.com/research/salary/benchmark/ambulance-driver-hourly-wages
# https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwjPwvvuydz7AhXTMlkFHUjjD40QFnoECBoQAQ&url=https%3A%2F%2Fwww.payscale.com%2Fresearch%2FUS%2FJob%3DAmbulance_Driver%2FHourly_Rate%2Fef469288%2FBoston-MA&usg=AOvVaw0lTE_fdHxQ9ZcuvFwIDwtQ
driver_hourly_wage = 16
buffer_time = 20*60;
# max_pickups_per_vehicle = 8
# fixed_driver_cost = 50;

distance_cost_vehicle_type_mapping = Matrix(distance_cost_vehicle_type_mapping)

distance_mapping = Matrix(distance_mapping)

# Build model.
model = Model(Gurobi.Optimizer)
# set_optimizer_attribute(model, "OutputFlag", true)
model = Model(optimizer_with_attributes(Gurobi.Optimizer, "TimeLimit" => 14400))


# Insert variable.
# We create a huge number of variables because we map multiple locations with the same index.
@variable(model, x[i=1:V, j=1:V, k=1:K], Bin)
@variable(model, y[k=1:K], Bin)
@variable(model, u[i=1:V, k=1:K], Int)


# Insert constraints.

## Related with x.
@constraint(model, [i=pickups[1]:pickups[n_pickup]], sum(sum(x[i,j,k] for j=1:V) for k=1:K) == 1)
@constraint(model, [i=pickups[1]:pickups[n_pickup]], sum(x[i,i+n_pickup,k] for k=1:K) == 1)
@constraint(model, [j=1:V, k=1:K], sum(x[i,j,k] for i=1:V) - sum(x[j,i,k] for i=1:V) == 0)
# @constraint(model, [k=1:K], sum(sum(x[i,j,k] for j=1:V) for i=pickups[1]:pickups[n_pickup]) <= max_pickups_per_vehicle)
@constraint(model, [k=1:K], sum(sum(x[i,j,k]*(time_mapping[i,j] + buffer_time) for j=1:V) for i=1:V) <= max_time_per_vehicle)

for vehicle_num in electric_vehicles
    @constraint(model, sum(sum(x[i,j,vehicle_num] for j=1:V) for i=1:V) <= distance_per_elec_charge)
end


@constraint(model, [i=depots[1]:depots[n_depots], j=depots[1]:depots[n_depots], k=1:K], x[i,j,k] == 0) ##############

## Related with y.
# @constraint(model, [k=1:K], sum(x[depots[vehicle_depot_mapping[k,1]],j,k] for j=pickups[1]:pickups[n_pickup]) <= y[k]*vehicle_depot_mapping_binary[k,depots[vehicle_depot_mapping[k,1]]])
# @constraint(model, [i=1:V, j=1:V, k=1:K], x[i,j,k] <= y[k])

@constraint(model, [i=depots[1]:depots[n_depots], j=1:V, k=1:K], x[i,j,k] <= y[k]*vehicle_depot_mapping_binary[k,i])
# @constraint(model, [i=depots[1]:depots[n_depots], j=1:V, k=1:K], x[i,j,k] <= y[k])


## Related with u.
@constraint(model, [i=depots[1]:depots[n_depots], k=1:K], u[i,k] == 1)
@constraint(model, [i=n_depots+1:V, j=n_depots+1:V, k=1:K], u[i,k] - u[j,k] + 1 <= (V-1)*(1-x[i,j,k]))
@constraint(model, [i=n_depots+1:V, k=1:K], 2 <= u[i,k] <= V)

# # Objective.
# @objective(model, Min, 
#     sum(fixed_cost_vehicle_type_mapping[vehicle_type[k,2],1]*y[k] for k=1:K) +
#     sum(sum(sum(distance_cost_vehicle_type_mapping[vehicle_type[k,2],1]*distance_mapping[i,j]*x[i,j,k] for i=1:V) for j=1:V) for k=1:K)
# )

# Objective.
@objective(model, Min, 
    sum(fixed_cost_vehicle_type_mapping[vehicle_type[k,2],1]*y[k] for k=1:K) +
    (driver_hourly_wage/3600)*(sum(sum(sum((time_mapping[i,j] + buffer_time)*x[i,j,k] for j=1:V) for i=1:V) for k=1:K)) +
#     fixed_driver_cost*(sum(y[k] for k=1:K)) +
    sum(sum(sum(distance_cost_vehicle_type_mapping[vehicle_type[k,2],1]*distance_mapping[i,j]*x[i,j,k] for i=1:V) for j=1:V) for k=1:K)
#     (1/1000)*sum(sum(sum(distance_cost_vehicle_type_mapping[vehicle_type[k,2],1]*distance_mapping*x[:,:,k] for i=1:V) for j=1:V) for k=1:K)
)


# Optimize.
optimize!(model)



x_sol = Dict()
u_sol = Dict()
path_mappings = Dict()
sequences = Dict()

for i=1:K
    x_sol[i] = DataFrame(value.(x)[:,:,i], :auto);
    u_sol[i] = value.(u)[:,i];
    path_mappings[i] = sort(Tuple.(findall(>=(0.5), Matrix(x_sol[i]))))
    sequences[i] = sort(DataFrame(Start=[1:1:size(u_sol[i])[1];], Sequence=u_sol[i]), :Sequence)
end

println(value.(y))

fixed_costs = sum(fixed_cost_vehicle_type_mapping[vehicle_type[k,2],1]*value.(y)[k] for k=1:K)
println(fixed_costs)

driver_wages = (driver_hourly_wage/3600)*(sum(sum(sum(time_mapping[i,j]*value.(x)[i,j,k] for j=1:V) for i=1:V) for k=1:K))
println(driver_wages)

travelling_cost = sum(sum(sum(distance_cost_vehicle_type_mapping[vehicle_type[k,2],1]*distance_mapping[i,j]*value.(x)[i,j,k] for i=1:V) for j=1:V) for k=1:K)
println(travelling_cost)



sequence_travelled = Dict()

for vehicle_num = 1:K
    println("The vehicle number we are talking about is: ", vehicle_num)
    if size(path_mappings[vehicle_num])[1] == 0
        continue
    else
        path = path_mappings[vehicle_num]
        sequence = sort(sequences[vehicle_num], :Start)
        sequence_dict = Dict(pairs(sequence.Sequence))
        start_nodes = path[:,1]
#         println(start_nodes)
        nodes = []
        sequence = []
        
        for node_index = 1:size(start_nodes)[1]
            node_num = start_nodes[node_index][1]
            seq = sequence_dict[start_nodes[node_index][1]]
            push!(nodes, node_num)
            push!(sequence, seq)
#             println(nodes)
#             println(sequence_dict[start_nodes[node_index][1]])
        end
        
#         println(sort(DataFrame(Nodes=nodes, VistedAt=sequence), :VistedAt))
        sequence_travelled[vehicle_num] = sort(DataFrame(Nodes=nodes, VistedAt=sequence), :VistedAt)[:,1]
        
#         nodes_travelled[vehicle_num] = nodes
#         sequence_travelled[vehicle_num] = sequence
    end
end

print(sequence_travelled)

total_cost = objective_value.(model)


for i=1:K
    path_map = path_mappings[i]
    CSV.write("df_sequence_mapping_$i.csv", DataFrame(path_map))
    try
        sequence_map = sequence_travelled[i]
        CSV.write("sequence_$i.csv",  Tables.table(sequence_map), writeheader=false)
    catch
        println("Vehicle $i is not used!")
    end
end


