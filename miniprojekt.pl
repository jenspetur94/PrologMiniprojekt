vehicle(car).
vehicle(bus).
vehicle(bicycle).
vehicle(taxi) :- vehicle(car).

road(aalborg,aarhus, gravel, 120, 2).
road(aalborg,aarhus, motorway, 100, 0.5).
road(aalborg,vejle, paved, 120, 1.5).
road(aarhus,vejle, paved, 50, 0.5).
road(vejle,odense, paved, 50, 0.5).
road(odense,svendborg, paved, 20, 0.2).
road(svendborg,nyborg, paved, 50, 0.5).
road(odense,nyborg, motorway, 50, 0.5).
road(nyborg,naestved, motorway, 20, 0.2).
road(naestved,koebenhavn, motorway, 80, 0.8).
road(svendborg, fredericia, motorway, 20, 1).
road(fredericia, aarhus, motorway, 20, 1).

traveler(frederik, car).
traveler(andreas, bicycle).
traveler(andreas, car).
traveler(mathias, bus).
traveler(daniel, bicycle).
traveler(jp, taxi).

%Defines which terrain certain vehicles can drive on
drivable-terrain(car,Type) :- 
	Type == gravel;
	Type == paved;
	Type == motorway.

drivable-terrain(taxi,Type) :-
	drivable-terrain(car,Type).

drivable-terrain(bus, Type) :-
	Type == paved;
	Type == motorway.

drivable-terrain(bicycle, Type) :-
	Type == gravel;
	Type == paved.

%Defines how many people can travel with a certain vehicle type
valid-vehicle(car,NumberOfPassengers) :-
	NumberOfPassengers > 0,
	NumberOfPassengers =< 4.

valid-vehicle(bicycle, NumberOfPassengers) :-
	NumberOfPassengers == 1.

valid-vehicle(bus, NumberOfPassengers) :- 
	NumberOfPassengers > 0.

valid-vehicle(taxi, NumberOfPassengers) :-
	valid-vehicle(car, NumberOfPassengers).

%Checks if two roads are connected
connected(A, B, Type, Distance, Time) :-
	road(A, B, Type, Distance, Time).

connected(A, B, Type, Distance, Time) :-
	road(B, A, Type, Distance, Time).

%Finds a route between town A and town B 
%Name = name of traveler
%NoP = number of passengers traveling
route(A, B, Name, NoP, Vehicle, Path, Distance, Time) :-
	traveler(Name, Vehicle),
	valid-vehicle(Vehicle, NoP),
	travel(A, B, Vehicle, 0, 0, [A], FoundPath, Distance, Time),
	reverse(Path, FoundPath).

%Helper function for route that traverses the graph adding towns to the path by calling itself recursevily.
%When B is reached it returns the found Path
travel(A,B, Vehicle, DistanceTraveled, TimePassed, Visited, [B|Visited], Distance1, Time1) :-
	connected(A, B, Type, Distance, Time),
	drivable-terrain(Vehicle, Type),
	Distance1 is DistanceTraveled + Distance,
	Time1 is TimePassed + Time.

travel(A, B, Vehicle, DistanceTraveled, TimePassed, Visited, Path, Distance1, Time1) :-
	connected(A, C, Type, Distance, Time),
	drivable-terrain(Vehicle, Type),
	C \== B,
	\+member(C,Visited),
	DistanceTraveled1 is DistanceTraveled + Distance,
	TimePassed1 is TimePassed + Time,
	travel(C, B, Vehicle, DistanceTraveled1, TimePassed1, [C|Visited], Path, Distance1, Time1).

%Finds a route from town A to town B that only uses a certain roadtype RoadType
routeWithCertainRoadType(A, B, RoadType, Path, Distance, Time) :- 
	travelWithRoadType(A, B, RoadType, 0, 0, [A], FoundPath, Distance, Time),
	reverse(Path, FoundPath).

%Helper function for routeWithCertainRoadType by traversing the graph adding towns to the path.
%This is done bycalling itself recursevily.
%When B is reached it stops execution.
travelWithRoadType(A, B, Type, DistanceTraveled, TimePassed, Visited, [B|Visited], Distance1, Time1) :-
	connected(A, B, Type, Distance, Time),
	Distance1 is DistanceTraveled + Distance,
	Time1 is TimePassed + Time.

travelWithRoadType(A, B, Type, DistanceTraveled, TimePassed, Visited, Path, Distance1, Time1) :-
	connected(A, C, Type, Distance, Time),
	C \== B,
	\+member(C, Visited),
	DistanceTraveled1 is DistanceTraveled + Distance,
	TimePassed1 is TimePassed + Time,
	travelWithRoadType(C, B, Type, DistanceTraveled1, TimePassed1, [C|Visited], Path, Distance1, Time1).

%Finds a route that a list of travelers can traveler.
%This is done by finding a route for the first traveler and the checking if all the other 
%travelers can use it.
routeForListOfTravelers([[Name,NoP]|Rest], A, B, Path) :-
	route(A, B, Name, NoP, Path, _, _),
	allTravelersAbleToTravelRoute(Rest, A, B, Path).

%Helper function for routeForListOfTravelers that checks if a list of travelers can use a path Path.
%This is done by calling itself recursively until it reaches the end of the list.
allTravelersAbleToTravelRoute([[Name,NoP]|Rest], A, B, Path) :-
	route(A, B, Name, NoP, Path, _, _),
	allTravelersAbleToTravelRoute(Rest, A, B, Path).

allTravelersAbleToTravelRoute([], _, _, _).

%Finds a route that travels through a list of towns.
%This is done by finding a route with the route funciton and checking if the list
%of towns is a subset of the found route.
routeTravelingThroughTowns(ListOfTowns, A, B, Name, NoP, FoundRoute) :-
	route(A, B, Name, NoP, FoundRoute, _, _),
	subset(ListOfTowns, FoundRoute).

%Finds the shortest path between A and B by finding all paths between A and B and then using minOfList to find the path
%with the smallest distance
shortest(A, B, Name, NoP, Path, Distance) :-
	findall([P,D], route(A, B, Name, NoP, P, D, _), Set),
	Set = [_|_],
	minOfList(Set, [Path, Distance]).
%Find the route between A and B that is the fastest. This is done just like with shortest, only it is done for TIme instead of distance-
fastest(A,B,Name,NoP,Path, Time) :-
	findall([P,T], route(A, B, Name, NoP, P, _, T), Set),
	Set = [_|_],
	minOfList(Set, [Path, Time]).

%Finds the smallest value in a list of touples
minOfList([H|T], [Path, Value]) :-
	minhelper(T, H, [Path, Value]).
	
%Helper function for minOfList that calls itself recursively untill it reaches end of list and return the path with the smallest value.
minhelper([], Min, Min).

minhelper([[Path, Value]|R], [MinP, MinV], Min) :-
	Value < MinV -> 
	minhelper(R, [Path, Value], Min);
	minhelper(R, [MinP, MinV], Min).
