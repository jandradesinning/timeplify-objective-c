// returns all routes' stations
Parse.Cloud.define("getStatus", function(request, response) {
    var bOK = true;
	var routes = null;
	var route = null;
	var station = null;
	
    try
    {
		routes = request.params.routes;
        if(bOK && null == routes) {
            response.error("Parameter 'routes' is missing");
            bOK = false;
        }
		
		for (var i = 0; i < routes.length; i++) { 
			route = routes[i];
			for (var j = 0; j < route.stations.length; i++) { 
				station = route.stations[i];
			}
		}

        if(bOK && null == request.params.lat) {
            response.error("Parameter 'lat' is missing");
            bOK = false;
        }

        if(bOK && null == request.params.lon) {
            response.error("Parameter 'lon' is missing");
            bOK = false;
        }

        if(bOK) {
            var myResponse = 
				{
				  "feedTime": "05122014140530",
				  "station": {
					"id": "102",
					"scheduledData": [
					  {
						"time": "00:30:30",
						"route": "6"
					  },
					  {
						"time": "02:30:30",
						"route": "5"
					  },
					  {
						"time": "04:30:30",
						"route": "6"
					  },
					  {
						"time": "06:30:30",
						"route": "2"
					  }
					],
					"next": [
					  {
						"route": "6",
						"time": "6",
						"unit": "Min",
						"tripAssingment": "live",
						"serviceStatus": "goodService"
					  },
					  {
						"route": "5",
						"time": "16",
						"unit": "Min"
					  },
					  {
						"route": "6",
						"time": "20",
						"unit": "Min"
					  },
					  {
						"route": "4",
						"time": "30",
						"unit": "Min"
					  },
					  {
						"route": "6",
						"time": "32",
						"unit": "Min"
					  }
					]
				  }
				};

  "feedTime": "05122014140530",
  "routes": [
	{
	  "id": "1",
	  "stations": [
		{
		  "id": "102",
		  "tripAssingment" : "live",
		  "north": {
			"next": [
			  {
				"time": "6",
				"unit": "Min"
			  },
			  {
				"time": "16",
				"unit": "Min"
			  },
			  {
				"time": "20",
				"unit": "Min"
			  },
			  {
				"time": "30",
				"unit": "Min"
			  },
			  {
				"time": "32",
				"unit": "Min"
			  }
			],
			"serviceStatus": "goodService"
		  },
		  "south": {
			"next": [
			  {
				"time": "6",
				"unit": "Min"
			  },
			  {
				"time": "16",
				"unit": "Min"
			  },
			  {
				"time": "20",
				"unit": "Min"
			  },
			  {
				"time": "30",
				"unit": "Min"
			  },
			  {
				"time": "32",
				"unit": "Min"
			  }
			],
			"serviceStatus": "goodService"
		  }
		},
		{
		  "id": "103",
		  "tripAssingment" : "scheduled",
		  "north": {
			"next": [
			  {
				"time": "6",
				"unit": "Min"
			  },
			  {
				"time": "16",
				"unit": "Min"
			  },
			  {
				"time": "20",
				"unit": "Min"
			  },
			  {
				"time": "30",
				"unit": "Min"
			  },
			  {
				"time": "32",
				"unit": "Min"
			  }
			],
			"serviceStatus": "goodService"
		  },
		  "south": {
			"next": [
			  {
				"time": "6",
				"unit": "Min"
			  },
			  {
				"time": "16",
				"unit": "Min"
			  },
			  {
				"time": "20",
				"unit": "Min"
			  },
			  {
				"time": "30",
				"unit": "Min"
			  },
			  {
				"time": "32",
				"unit": "Min"
			  }
			],
			"serviceStatus": "goodService"
		  }
		}
	  ]
	},
	{
	  "id": "2",
	  "stations": [
		{
		  "id": "104",
		  "tripAssingment" : "live",
		  "north": {
			"next": [
			  {
				"time": "6",
				"unit": "Min"
			  },
			  {
				"time": "16",
				"unit": "Min"
			  },
			  {
				"time": "20",
				"unit": "Min"
			  },
			  {
				"time": "30",
				"unit": "Min"
			  },
			  {
				"time": "32",
				"unit": "Min"
			  }
			],
			"serviceStatus": "goodService"
		  },
		  "south": {
			"next": [
			  {
				"time": "6",
				"unit": "Min"
			  },
			  {
				"time": "16",
				"unit": "Min"
			  },
			  {
				"time": "20",
				"unit": "Min"
			  },
			  {
				"time": "30",
				"unit": "Min"
			  },
			  {
				"time": "32",
				"unit": "Min"
			  }
			],
			"serviceStatus": "goodService"
		  }
		},
		{
		  "id": "105",
		  "tripAssingment" : "live",						  
		  "north": {
			"next": [
			  {
				"time": "6",
				"unit": "Min"
			  },
			  {
				"time": "16",
				"unit": "Min"
			  },
			  {
				"time": "20",
				"unit": "Min"
			  },
			  {
				"time": "30",
				"unit": "Min"
			  },
			  {
				"time": "32",
				"unit": "Min"
			  }
			],
			"serviceStatus": "goodService"
		  },
		  "south": {
			"next": [
			  {
				"time": "6",
				"unit": "Min"
			  },
			  {
				"time": "16",
				"unit": "Min"
			  },
			  {
				"time": "20",
				"unit": "Min"
			  },
			  {
				"time": "30",
				"unit": "Min"
			  },
			  {
				"time": "32",
				"unit": "Min"
			  }
			],
			"serviceStatus": "goodService"
		  }
		}
	  ]
	}
  ]
}*/			
            response.success(myResponse);
        }
    } catch (e) {
        console.log(e.message);
        response.error(e.message);
    }
});


function deleteObjects(objs) {
    var delCount = 0;
	
	steps += "deleteObjects - " + objs.length + "\r\n";

    try
	{
		Parse.Object.destroyAll(objs, {
			success: function() {
				delCount = objs.length;
			},
			error: function(error) {
			}
		});
    } catch (e) {
        console.log(e.message);
    }
    return delCount;
}

function getObjects(className, skipCount, objCount, uid) {
	steps += "getObjects - " + className + ", " + skipCount + ", " + objCount + ", " + uid + "\r\n";
    var Table = Parse.Object.extend(className);
	var query = new Parse.Query(Table);
	
	// find all rows that doesn't match 
	query.notEqualTo("uid", uid);
	query.skip(skipCount);
	query.limit(1000);
	
	queryObjects(query, className, skipCount, objCount, uid);
}

function countObjects(className, uid) {
	var count = 0;
	var promises = [];  // Set up a list that will hold the promises being waited on.
	try
	{
		steps += "countObjects - " + className + ", " + uid + "\r\n";
		var Table = Parse.Object.extend(className);
		var query = new Parse.Query(Table);	
		// find all rows that doesn't match this uid
		query.notEqualTo("uid", uid);
		promises.push(query.count());
		
		return Parse.Promise.when(promises).then(function(rowCount) {
			var promise = Parse.Promise.as();
			// For each item, extend the promise with a function to delete it.
			promise = promise.then(function() {
			  // Return a promise that will be resolved when the delete is finished.
			  steps += "countObjects - " + rowCount + "\r\n";
			  return rowCount;
			});
			return promise;
		}, function(error) {
			return Parse.Promise.error(error);
		});
	} catch (e) {
        console.log(e.message);
    }
}

function queryObjects(query, className, skipCount, objCount, uid) {
    try
	{
	    steps += "queryObjects - " + className + ", " + skipCount + ", " + objCount + ", " + uid + "\r\n";
		query.find({
		  success: function(objs) {
			var delCnt = deleteObjects(objs);
			skipCount += delCnt;
			objCount -= delCnt;
			if(0 < objCount) {
				getObjects(className, skipCount, objCount, uid);
			}
		  },
		  error: function(error) {
		  }
		});
	} catch (e) {
        console.log(e.message);
    }
    return skipCount;
}

var steps = "";

Parse.Cloud.define("deleteAllRows", function(request, response) {
	/*
	{
	  "tables": ["tableName1", "tableName2"],
	  "uid": "unique id"
	}
	*/	
	try
    {
		var myResponse = "";		
		var uid = request.params.uid;
		var promises = [];
		
		steps = "";
		
		for (var i = 0; i < request.params.tables.length; i++) {
			var className = request.params.tables[i];
			//var count = countObjects(className, uid);
			promises.push(countObjects(className, uid));
			//getObjects(className, 0, count, uid);
		}
		Parse.Promise.when(promises).then(function() {
			// Calls to this function return "success/error not called" error
			response.success("Deleted all rows " + steps);
		}, function(error) {
			// Never called
			response.error();
		});
	} catch (e) {
		console.log(e.message);
		response.error(e.message);
    }
});

function addStationBoundsList(routeId, stationId, station) {
	var promises = [];
	var RouteStationBounds = Parse.Object.extend("RouteStationBounds");
	var queryRouteStationBounds = new Parse.Query(RouteStationBounds);
	
	queryRouteStationBounds.equalTo("routeId", route.id);
	queryRouteStationBounds.equalTo("stationId", station.stationId);	
					
	promises.push(queryRouteStationBounds.first());
	
	return Parse.Promise.when(promises).then(function(routeStationBoundsObj) {
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			var bounds = null;
			if(null != routeStationBoundsObj) {
				bounds =
				{
					"north": routeStationBoundsObj.get("northBound"),
					"south": routeStationBoundsObj.get("southBound")
				};
				station.northBound = bounds.north;
				station.southBound = bounds.south;
			}
			return bounds;
		});
		return promise;
	}, function(error) {
		return Parse.Promise.error(error);
	});
}

function addRouteList() {
	var Route = Parse.Object.extend("Route");
	var queryRoute = new Parse.Query(Route);
	var routes = [];
	var promises = [];
	
	queryRoute.limit(1000);
	promises.push(queryRoute.find());

	return Parse.Promise.when(promises).then(function(routeObjs) {
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			for (var i = 0; i < routeObjs.length; i++) {			
				var routeObj = routeObjs[i];				
				var route = 
				{
				  "id": routeObj.get("routeId"),
				  "name": routeObj.get("shortName"),
				  "northStationId": routeObj.get("northStationId"),
				  "southStationId": routeObj.get("southStationId")
				};
				route.stations = [];
				var routeStations = routeObj.get("stations");
				for (var j = 0; j < routeStations.length; j++) { 
					var stationId = routeStations[j];
					var promisesX = [];
					var station = {
						"stationId": stationId,
						"northBound": "NorthBound",
						"southBound": "SouthBound"
					};
					route.stations.push(station);
				}
				routes.push(route);
			}
			return routes;
		});
		return promise;
	}, function(error) {
		return Parse.Promise.error(error);
	});
}

function addStationList() {	
	var Station = Parse.Object.extend("Station");
	var queryStation = new Parse.Query(Station);
	var stations = [];
	var promises = [];
	
	queryStation.limit(1000);
	promises.push(queryStation.find());

	return Parse.Promise.when(promises).then(function(stationObjs) {
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			for (var i = 0; i < stationObjs.length; i++) { 
				var stationObj = stationObjs[i];
				var station = 
				{
				  "id": stationObj.get("stationId"),
				  "name": stationObj.get("name"),
				  "lat": stationObj.get("latitude"),
				  "lon": stationObj.get("longitude")
				};
				stations.push(station);
			}
			return stations;
		});
		return promise;
	}, function(error) {
		return Parse.Promise.error(error);
	});
}

Parse.Cloud.define("getStaticData", function(request, response) {
    var bOK = true;
	/*
	{
	  "appVersion": "10020",
	  "updatedTime": "05122014140830"
	}
	*/	
    try
    {
        if(bOK && null == request.params.appVersion) {
            response.error("Parameter 'appVersion' is missing");
            bOK = false;
        }

        if(bOK) {		
			var promises = [];

			promises.push(addRouteList());
			promises.push(addStationList());
			
			Parse.Promise.when(promises).then(function(routes, stations) {
				var myResponse = {
					"feedTime": "05122014140830",
					"routes": routes,
					"stations": stations
				};
				response.success(myResponse);
			}, function(error) {
				// Never called
				response.error();
			});
        }
    } catch (e) {
        console.log(e.message);
        response.error(e.message);
    }
});

Parse.Cloud.define("getSettings", function(request, response) {
    var bOK = true;
	/*
	{
	  "appVersion": "10020",
	  "updatedTime": "05122014140830"
	}
	*/
	
    try
    {
        if(bOK && null == request.params.line) {
            response.error("Parameter 'line' is missing");
            bOK = false;
        }

        /*if(bOK && null == request.params.category) {
            response.error("Parameter 'category' is missing");
            bOK = false;
        }*/

        if(bOK) {
            var myResponse = 
				{
				  "updatedTime": "05122014140830",
				  "subway": {
					"serviceStatuses": {
					  "suspended": {
						"text": "Suspended",
						"color": "#996600"
					  },
					  "delays": {
						"text": "Delays",
						"color": "#990033"
					  },
					  "goodService": {
						"text": "Good Service",
						"color": "#006600"
					  },
					  "plannedWork": {
						"text": "Planned Work",
						"color": "#996600"
					  },
					  "serviceChange": {
						"text": "Service Change",
						"color": "#996600"
					  }
					},
					"font": "Helvetica",
					"refreshInterval": {
					  "time": "30",
					  "unit": "sec"
					},
					"tripAssingment": {
					  "live": {
						"text": "Live Data",
						"color": "#00ff00"
					  },
					  "scheduled": {
						"text": "Scheduled Data",
						"color": "#0000ff"
					  }
					},
					labels: {
					  "welcomeDisclaimer": "<p align=\"center\">Congratulations, we are now ready to begin.</p><p align=\"center\">Please note that train departure data is obtained from the MTA and we can't provide any guarantees as to its accuracy. In those cases where we are using scheduled data you will see this on the screen.</p><p align=\"center\">At the moment the MTA only provides live data for the 1,2,3,4,5,6, L, and S trains.</p>",
					  "preference": "Preference",
					  "seeAllStations": "See all stations",
					  "allStations": "All Stations",
					  "chooseYourDirection": "Choose your direction",
					  "addStation": "Add Station",
					  "either": "Either",
					  "allSet": "All Set",
					  "checkTimes": "Check Times",
					  "appExplanation": "Timeplify finds the nearest stations near you. To start checking times, choose \"Allow\" so the app can find your location.",
					  "next": "Next",
					  "search": "Search",
					  "add": "Add",
					  "done": "Done",
					  "startWalking": "You must start walking now to catch the next train.",
					  "unableToFindStation": "<p align=\"center\"><b>UNABLE TO FIND STATIONS NEAR YOU</b><br/>We're unable to find stations within a radius of 3 miles. Please select your station from the available list.</p>",
					  "unableToConnect": "<p align=\"center\"><b>UNABLE TO CONNECT</b><br/>We're unable to connect to Timeplify Servers, please check your connection and try again to receive live updates.</p>",
					  "locationNotFound": "<p align=\"center\"><b>LOCATION NOT FOUND</b><br/>Go to settings and enable location services if you wish to see the nearest stations to you.</p>",
					  "trains": "Trains",
					  "favorites": "Favorites",
					  "stations": "Stations",
					  "about": "About This App",
					  "rate": "Rate This App",
					  "min": "Min",
					  "hrs": "Hrs"
					}
				  }
				};
            response.success(myResponse);
        }
    } catch (e) {
        console.log(e.message);
        response.error(e.message);
    }
});
