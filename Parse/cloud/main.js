function getServiceStatus(routeId, uid) {
	var promises = [];
	var serviceStatus = null;
	var ServiceStatus = Parse.Object.extend("ServiceStatus");
	var querySStatus = new Parse.Query(ServiceStatus);
	
	querySStatus.equalTo("routeId", routeId);
	querySStatus.equalTo("uid", uid);
	
	promises.push(querySStatus.first());

	return Parse.Promise.when(promises).then(function(ssObj) {
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			var retSS = "";
			if(ssObj){
				retSS = ssObj.get("status");
			}
			return retSS;
		});
		return promise;
	});
}

function getScheduledData(routeId, stationId, direction, uid) {
	var promises = [];
	var scheduledData = [];
	var ScheduledData = Parse.Object.extend("ScheduledData");
	var querySData = new Parse.Query(ScheduledData);
	
	querySData.equalTo("routeId", routeId);
	querySData.equalTo("stationId", stationId);
	querySData.equalTo("direction", direction);
	querySData.equalTo("uid", uid);	
	querySData.limit(1000);	
	
	promises.push(querySData.find());

	return Parse.Promise.when(promises).then(function(sdObjs) {
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			for (var i = 0; i < sdObjs.length; i++) {
				var sdObj = sdObjs[i];
				var sData = {
					"arrivalTime": sdObj.get("arrivalTime")
				}

				scheduledData.push(sData);
			}
			return scheduledData;
		});
		return promise;
	});
}

function getRealTimeData(routeId, stationId, direction, uid, ssUID) {
	var promises = [];
	var realTimeData = [];
	var RealTimeData = Parse.Object.extend("RealTimeData");
	var queryRTData = new Parse.Query(RealTimeData);
	
	queryRTData.equalTo("routeId", routeId);
	queryRTData.equalTo("stationId", stationId);
	queryRTData.equalTo("direction", direction);
	queryRTData.equalTo("uid", uid);
	queryRTData.limit(1000);	
	
	promises.push(queryRTData.find());

	return Parse.Promise.when(promises).then(function(rtdObjs) {
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			for (var i = 0; i < rtdObjs.length; i++) {
				var rtdObj = rtdObjs[i];
				var rtData = {
					"arrivalTime": rtdObj.get("arrivalTime"),
					"tripAssignment": rtdObj.get("assigned")
				}
				realTimeData.push(rtData);
			}
			return realTimeData;
		});
		return promise;
	}).then(function(realTimeData){
		var promisesX = [];
		promisesX.push(getServiceStatus(routeId, ssUID));		
		return Parse.Promise.when(promisesX).then(function(serviceStatus) {
			var promise = Parse.Promise.as();
			promise = promise.then(function() {
				if(null != realTimeData && null != realTimeData[0]) {
					// Find out the service status for the first station only.
					realTimeData[0].serviceStatus = serviceStatus;
				}
				return realTimeData;
			});
			return promise;
		});
	});
}

function getSettings() {
	var promises = [];	
	var Settings = Parse.Object.extend("Settings");
	var querySettings = new Parse.Query(Settings);
	
	promises.push(querySettings.find());

	return Parse.Promise.when(promises).then(function(settingsObjs) {
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			var settings = {};
			
			for (var i = 0; i < settingsObjs.length; i++) {
				var settingsObj = settingsObjs[i];
				
				var settingsValues = eval(JSON.stringify(settingsObj.get("settingsValues")));
				var settingsKey = settingsObj.get("settingsKey");
				if("realTime" == settingsKey) {
					settings.realTimeFeedTime = settingsValues[0];
					settings.gtfsFeedTime = settingsValues[1];
				} else if ("staticTime" == settingsKey) {
					settings.staticFeedTime = settingsValues[0];
				} else if ("statusTime" == settingsKey) {
					settings.serviceStatusFeedTime = settingsValues[0];
				}
			}
			return settings;
		});
		return promise;
	});
}

function getStatus(settings, realTimeData, scheduledData, fetchScheduledData) {
	var status = {};

	status = {
		"realTime": {
			"data": realTimeData,
			"feedTime": settings.gtfsFeedTime
		}
	};

	if(fetchScheduledData && scheduledData) {
		status.scheduled = {
			"data": scheduledData,
			"feedTime": settings.staticFeedTime
		}
	}
	return status;
}

// returns all routes' stations
Parse.Cloud.define("getStatus", function(request, response) {
    var bOK = true;
	var routeId = null;
	var stationId = null;
	var direction = null;
	
	/*	
	{
	  "appVersion": "10020",
	  "route": "1",
	  "station": "101",
	  "direction": "N",
	  "fetchScheduledData": "true",
	}
	*/

    try
    {
		routeId = request.params.route;
		if(bOK && null == routeId) {
            response.error("Parameter 'route' is missing");
            bOK = false;
        }

		stationId = request.params.station;
        if(bOK && null == stationId) {
            response.error("Parameter 'station' is missing");
            bOK = false;
        }
		
		direction = request.params.direction;
		if(bOK && null == direction) {
            response.error("Parameter 'direction' is missing");
            bOK = false;
        }

        if(bOK) {
			var status = {};
			var returns = [];
			
			getSettings().then(function(settings){
				returns.push(settings);
				return getRealTimeData(routeId, stationId, direction, settings.realTimeFeedTime, settings.serviceStatusFeedTime);
			}).then(function(realTimeData){
				returns.push(realTimeData);
				return request.params.fetchScheduledData ? getScheduledData(routeId, stationId, direction, returns[0].staticFeedTime) : null;
			}).then(function(scheduledData){				
				return getStatus(returns[0], returns[1], scheduledData, request.params.fetchScheduledData);
			}).then(function(status){
				response.success(status);
			}, function(error) {
				response.error(error);
			});
        }
    } catch (e) {
        console.log(e.message);
        response.error(e.message);
    }
});

// returns all routes, stations
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

			promises.push(getSettings());
			promises.push(addRouteList());
			promises.push(addStationList());
			
			Parse.Promise.when(promises).then(function(settings, routes, stations) {
				var myResponse = {
					"feedTime": settings.staticFeedTime,
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

function addStationBoundsList(routeId, stationId, station) {
	var promises = [];
	var RouteStationBounds = Parse.Object.extend("RouteStationBounds");
	var queryRouteStationBounds = new Parse.Query(RouteStationBounds);
	
	queryRouteStationBounds.equalTo("routeId", routeId);
	queryRouteStationBounds.equalTo("stationId", stationId);
					
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
			return station;
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
	var promisesX = [];
	
	queryRoute.limit(1000);
	promises.push(queryRoute.find());

	return Parse.Promise.when(promises).then(function(routeObjs) {
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			for (var i = 0; i < routeObjs.length; i++) {			
				var routeObj = routeObjs[i];
				var routeId = routeObj.get("routeId");
				var route = 
				{
				  "id": routeId,
				  "name": routeObj.get("shortName"),
				  "northStationId": routeObj.get("northStationId"),
				  "southStationId": routeObj.get("southStationId")
				};
				route.stations = [];
				var routeStations = routeObj.get("stations");
				for (var j = 0; j < routeStations.length; j++) { 
					var stationId = routeStations[j];
					var station = {
						"stationId": stationId,
						"northBound": "NorthBound",
						"southBound": "SouthBound"
					};
					promisesX.push(addStationBoundsList(routeId, stationId, station));
					route.stations.push(station);
				}
				routes.push(route);
			}
			return routes;
		});
		return promise;
	}).then(function(routes){
		return Parse.Promise.when(promisesX).then(function(stations) {
			var promise = Parse.Promise.as();
			promise = promise.then(function() {
				return routes;
			});
			return promise;
		});
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
					  "hrs": "Hrs",
					  "liveData": "Live Data",
					  "scheduledData": "Scheduled Data"
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


Parse.Cloud.job("deleteAllObsoleteRealTimeRows", function(request, response) {
	/*
	{
	  "tables": ["tableName1", "tableName2"],
	  "uid": "unique id"
	}
	*/	
	try
    {
		var uid = request.params.uid;
		var promises = [];
		var count = 0;
		var settings = {};
		var returns = [];
		
		steps = "";
		
		Parse.Cloud.useMasterKey();
		
		promises.push(getSettings().then(function(settings){
			console.log("GOT SETTINGS\r\n");
			steps += "GOT SETTINGS\r\n";
			returns.push(settings.serviceStatusFeedTime);
			
			return deleteAllRowsY("RealTimeData", settings.realTimeFeedTime);
		}).then(function(){
			return deleteAllRowsY("ServiceStatus", returns[0]);
		}));
		
		return Parse.Promise.when(promises).then(function(rowCount) {
			var promise = Parse.Promise.as();
			// For each item, extend the promise with a function to delete it.
			promise = promise.then(function() {
			  // Return a promise that will be resolved when the delete is finished.
			  console.log("finally deleted all static rows\r\n");
			  steps += "finally deleted all static rows\r\n";
			  response.success(steps);
			});
			return promise;
		}, function(error) {
			response.error(steps);
		});
	} catch (e) {
		console.log(e.message);
		response.error(steps);
    }
});

Parse.Cloud.job("deleteAllObsoleteStaticRows", function(request, response) {
	/*
	{
	  "tables": ["tableName1", "tableName2"],
	  "uid": "unique id"
	}
	*/	
	try
    {
		var uid = request.params.uid;
		var promises = [];
		var count = 0;
		var settings = {};
		var returns = [];
		
		steps = "";
		
		Parse.Cloud.useMasterKey();
		
		promises.push(getSettings().then(function(settings){
			console.log("GOT SETTINGS\r\n");
			steps += "GOT SETTINGS\r\n";
			returns.push(settings.staticFeedTime);
			
			return deleteAllRowsY("Route", settings.staticFeedTime);
		}).then(function(){
			return deleteAllRowsY("RouteStationBounds", returns[0]);
		}).then(function(){
			return deleteAllRowsY("StationX", returns[0]);
		}).then(function(){
			return deleteAllRowsY("ScheduledData", returns[0]);
		}));
		
		return Parse.Promise.when(promises).then(function(rowCount) {
			var promise = Parse.Promise.as();
			// For each item, extend the promise with a function to delete it.
			promise = promise.then(function() {
			  // Return a promise that will be resolved when the delete is finished.
			  console.log("finally deleted all static rows\r\n");
			  steps += "finally deleted all static rows\r\n";
			  response.success(steps);
			});
			return promise;
		}, function(error) {
			response.error(steps);
		});
	} catch (e) {
		console.log(e.message);
		response.error(steps);
    }
});

function deleteAllRowsYY(className, uid, limit) {
	console.log("deleteAllRowsYY - " + className + ", " + uid + "\r\n");
	steps += "deleteAllRowsYY - " + className + ", " + uid + "\r\n";
	var promises = [];
	var Table = Parse.Object.extend(className);
	var query = new Parse.Query(Table);
	
	// find all rows that doesn't match 
	query.notEqualTo("uid", uid);
	query.limit(limit);
	promises.push(query.find());
	
	return Parse.Promise.when(promises).then(function(objs) {
		steps += "GOT OBJS " + objs.length + " for " + className + ", " + uid + "\r\n";
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			for (var i = 0; i < objs.length; i++) {
				objs[i].destroy();
			}
			console.log(" DONE DELETING " + objs.length + " for " + className + ", " + uid + "\r\n");
			steps += " DONE DELETING " + objs.length + " for " + className + ", " + uid + "\r\n";
			return objs.length;
		});
		return promise;
	});
}

function deleteAllRowsY(className, uid) {
	console.log("deleteAllRowsY - " + className + ", " + uid + "\r\n");
	var promises = [];
	var Table = Parse.Object.extend(className);
	var query = new Parse.Query(Table);
	var limit = 1000;
	
	// find all rows that doesn't match 
	query.notEqualTo("uid", uid);
	query.limit(limit);
	
	promises.push(query.count());
	
	return Parse.Promise.when(promises).then(function(objCount) {
		steps += "GOT COUNT " + objCount + " for " + className + ", " + uid + "\r\n";
		var promise = Parse.Promise.as();
		promise = promise.then(function() {
			var loop = objCount/limit;
			console.log("FOUND " + objCount + " for " + className + ", " + uid + "\r\n");
			steps += "FOUND " + objCount + " for " + className + ", " + uid + "\r\n";
			for (var i = 0; i < loop; i++) {
				var promisesX = [];
				promisesX.push(deleteAllRowsYY(className, uid, limit));
				return Parse.Promise.when(promisesX).then(function(delCount) {
					var promiseX = Parse.Promise.as();
					promiseX = promiseX.then(function() {
						console.log("LOOP " + i + ":" + " DELETED " + delCount + " for " + className + ", " + uid + "\r\n");
						steps += "LOOP " + i + ":" + " DELETED " + delCount + " for " + className + ", " + uid + "\r\n";
						return delCount;
					});
					return promiseX;
				});
			}
			console.log("DOME deleteAllRowsY - " + className + ", " + uid + "\r\n");
			steps += "DOME deleteAllRowsY - " + className + ", " + uid + "\r\n";

			return objCount;
		});
		return promise;
	});
}