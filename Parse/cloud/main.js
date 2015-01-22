function getServiceStatus(trainData, uid) {
    var promises = [];
    var serviceStatus = null;
    var ServiceStatus = Parse.Object.extend("ServiceStatus");
    var querySStatus = new Parse.Query(ServiceStatus);
            
    querySStatus.equalTo("routeId", trainData.routeId);
    querySStatus.equalTo("uid", uid);
       
    promises.push(querySStatus.first());
       
    return Parse.Promise.when(promises).then(function(ssObj) {
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
            var retSS = "";
            if(ssObj){
                trainData.serviceStatus = ssObj.get("status");
            } else {
                console.log("Service status NOT FOUND for " + trainData.routeId);
            }
            return trainData;
        });
        return promise;
    });
}
    
function getScheduledData(routeId, stationId, direction, uid, ssUID, skip) {
    var promises = [];
    var scheduledData = [];
    var ScheduledData = Parse.Object.extend("ScheduledData");
    var querySData = new Parse.Query(ScheduledData);
            
    querySData.equalTo("stationId", stationId);
    querySData.equalTo("direction", direction);
    querySData.equalTo("uid", uid); 
    querySData.skip(skip);
    querySData.limit(1000);
            
    promises.push(querySData.find());
        
    return Parse.Promise.when(promises).then(function(sdObjs) {
        var promise = Parse.Promise.as();
        var curTime = (new Date()).getTime();
        promise = promise.then(function() {
            var sMap = {};
            for (var i = 0; i < sdObjs.length; i++) {
       
                var sdObj = sdObjs[i];
                var arrTime = sdObj.get("arrivalTime");
                var diff =  (getUTCToday() + convertToMilliSeconds(arrTime)) - curTime;
                var diffStr = getTimeString(diff);
                       
                if((null != diffStr) && 0 < diff) {              
                    var sData = {
                        "routeId": sdObj.get("routeId"),
                        "arrivalTime": diffStr,
                        "serviceStatus": ""
                    }
                    var sKey = sData.routeId + diffStr;
                    // to avoid duplicates
                    var found = sKey in sMap;
                    if(!found) {                    
                        scheduledData.push(sData);
                        sMap[sKey] = {
                            "diff": diff,
                            "sData": sData,
                            "index": (scheduledData.length - 1)
                        };
                    } else {
                        if(sMap[sKey].diff > diff) {
                            // update if we found latest data
                            sMap[sKey].rtData = sData;
                            sMap[sKey].diff = diff;
                            scheduledData[sMap[sKey].index] = sData;
                        }
                    }
                }
            }
            return scheduledData;
        });
        return promise;
    }).then(function(scheduledData){
        return setServiceStatus(scheduledData, ssUID);
    }).then(function(scheduledData){        
        return scheduledData;
    });
}
    
function getScheduledDataEx(routeId, stationId, direction, uid, ssUID) {
    var promises = [];
    var scheduledData = [];
    var ScheduledData = Parse.Object.extend("ScheduledData");
    var querySData = new Parse.Query(ScheduledData);
        
    var limit = 1000;
            
    querySData.equalTo("stationId", stationId);
    querySData.equalTo("direction", direction);
    querySData.equalTo("uid", uid);
    querySData.limit(limit);
            
    promises.push(querySData.count());
        
    return Parse.Promise.when(promises).then(function(objCount) {
        var loop = objCount/limit;
        var promise = Parse.Promise.as();
        for (var i = 0; i < loop; i++) {
            promise = promise.then(function() {             
                var promisesX = [];
                promisesX.push(getScheduledData(routeId, stationId, direction, uid, ssUID, i*limit));
                return Parse.Promise.when(promisesX).then(function(sdObjs) {
                    var promiseX = Parse.Promise.as();
                    promiseX = promiseX.then(function() {                       
                        for (var i = 0; i < sdObjs.length; i++) {
                            scheduledData.push(sdObjs[i]);
                        }
                        return scheduledData;
                    });                 
                    return promiseX;
                })  
            }); 
        }
        return promise;
    }).then(function(){
        scheduledData.sort(compareDateTime);
        return scheduledData;
    });
}
    
function getRealTimeDataEx(routeId, stationId, direction, uid, ssUID) {
    var promises = [];
    var realTimeData = [];
    var RealTimeData = Parse.Object.extend("RealTimeData");
    var queryRTData = new Parse.Query(RealTimeData);
    var limit = 1000;
            
    queryRTData.equalTo("stationId", stationId);
    queryRTData.equalTo("direction", direction);
    queryRTData.equalTo("uid", uid);
    queryRTData.limit(limit);
            
    promises.push(queryRTData.count());
            
    return Parse.Promise.when(promises).then(function(objCount) {
        var loop = objCount/limit;
        var promise = Parse.Promise.as();
        for (var i = 0; i < loop; i++) {
            promise = promise.then(function() {             
                var promisesX = [];
                promisesX.push(getRealTimeData(routeId, stationId, direction, uid, ssUID, i*limit));
                return Parse.Promise.when(promisesX).then(function(rtdObjs) {
                    var promiseX = Parse.Promise.as();
                    promiseX = promiseX.then(function() {                       
                        for (var i = 0; i < rtdObjs.length; i++) {
                            realTimeData.push(rtdObjs[i]);
                        }
                        return realTimeData;
                    });                 
                    return promiseX;
                })  
            }); 
        }
        return promise;
    }).then(function(){
        realTimeData.sort(compareDateTime);
        return realTimeData;
    });
}
    
function compareDateTime(a, b) {
    var retVal = 0;
    var str = a.arrivalTime.split(":");
    var aHours = Math.floor(str[0]);
    var aMinutes = Math.floor(str[1]);
    var aSeconds = Math.floor(str[2]);
        
    str = b.arrivalTime.split(":");
    var bHours = Math.floor(str[0]);
    var bMinutes = Math.floor(str[1]);
    var bSeconds = Math.floor(str[2]);
        
    if(aHours == bHours) {
        if(aMinutes == bMinutes) {
            if(aSeconds == bSeconds) {
                retVal = 0;
            } else {
                retVal = aSeconds - bSeconds;
            }
        } else {
            retVal = aMinutes - bMinutes;
        }
    } else {
        retVal = aHours - bHours;
    }
        
    return retVal;
}
    
function getRealTimeData(routeId, stationId, direction, uid, ssUID, skip) {
    var promises = [];
    var realTimeData = [];
    var RealTimeData = Parse.Object.extend("RealTimeData");
    var queryRTData = new Parse.Query(RealTimeData);
            
    queryRTData.equalTo("stationId", stationId);
    queryRTData.equalTo("direction", direction);
    queryRTData.equalTo("uid", uid);
    queryRTData.skip(skip);
    queryRTData.limit(1000);    
            
    promises.push(queryRTData.find());
        
    return Parse.Promise.when(promises).then(function(rtdObjs) {
        var promise = Parse.Promise.as();
        var curTime = (new Date()).getTime();     
        promise = promise.then(function() {
            var rtMap = {};
            for (var i = 0; i < rtdObjs.length; i++) {
                var rtdObj = rtdObjs[i];
                var arrTime = rtdObj.get("arrivalTime") * 1000;
                var diff = arrTime - curTime;
                var diffStr = getTimeString(diff);
       
                if((null != diffStr) && (0 < diff)) {
                    var rtData = {
                        "routeId": rtdObj.get("routeId"),
                        "arrivalTime": diffStr,
                        "tripAssignment": rtdObj.get("assigned"),
                        "serviceStatus": ""
                    }
                    var rtKey = rtData.routeId + diffStr + rtData.tripAssignment;
                    // to avoid duplicates
                    var found = rtKey in rtMap;
                    if(!found) {                    
                        realTimeData.push(rtData);
                        rtMap[rtKey] = {
                            "diff": diff,
                            "rtData": rtData,
                            "index": (realTimeData.length - 1)
                        };
                    } else {
                        if(rtMap[rtKey].diff > diff) {
                            // update if we found latest data
                            rtMap[rtKey].rtData = rtData;
                            rtMap[rtKey].diff = diff;
                            realTimeData[rtMap[rtKey].index] = rtData;
                        }
                    }
                } else {
                    console.log("TIME PASSED " + arrTime + " " + diffStr + " " + diff);
                }
            }
            return realTimeData;
        });
        return promise;
    }).then(function(realTimeData){
        return setServiceStatus(realTimeData, ssUID);
    }).then(function(realTimeData){
        return realTimeData;
    });
}
       
function getTimeString(milliSeconds) {
    var x = milliSeconds / 1000;
    var seconds = x % 60;
    x /= 60;
    var minutes = x % 60;
    x /= 60;
    var hours = x % 24;
    x /= 24;
    var days = x;
           
    return Math.floor(hours) + ":" + Math.floor(minutes) + ":" + Math.floor(seconds)
}
       
function convertToMilliSeconds(timeString) {
    var str = timeString.split(":");
    var milliSeconds = 0;
    var hours = str[0];
    var minutes = str[1];
    var seconds = str[2];
    milliSeconds = ((hours * 60 * 60) + (minutes * 60) + seconds) * 1000;
    return milliSeconds;
}
       
 function getUTCToday() {
    var curDate = new Date();
    var year = curDate.getUTCFullYear();
    var month = curDate.getUTCMonth();
    var day = curDate.getUTCDate();
    var utcToday = new Date(year, month, day).getTime();    
    return utcToday;
}
       
function setServiceStatus(trainData, ssUID) {
    var promises = [];
    var routeMap = {};
       
    for (var i = 0; i < trainData.length; i++) {
        var tD = trainData[i];
        var found = tD.routeId in routeMap;
        if(!found){
            promises.push(getServiceStatus(tD, ssUID).then(function(tData) {
                routeMap[tData.routeId] = tData.serviceStatus;
            }));
        } else {
            tD.serviceStatus = routeMap[tD.routeId];
        }
    }
       
    return Parse.Promise.when(promises).then(function() {
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
            return trainData;
        });
        return promise;
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
        "status": 0,//SUCCESS
        "data": {
            "realTime": {
                "data": realTimeData,
                "feedTime": settings.gtfsFeedTime
            }
        }
    };
        
    if(fetchScheduledData && scheduledData) {
        status.data.scheduled = {
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
    var fetchScheduledData = false;
            
    /*  
    {
      "appVersion": "10020",
      "station": "101",
      "direction": "N",
      "scheduledDataUpdatedTime": "05122014140830",
    }
    */
        
    try
    {
        stationId = request.params.station;
        if(bOK && null == stationId) {
            response.error(getErrorJSON("Parameter 'station' is missing"));
            bOK = false;
        }
                
        direction = request.params.direction;
        if(bOK && null == direction) {
            response.error(getErrorJSON("Parameter 'direction' is missing"));
            bOK = false;
        }
        
        if(bOK) {
            var status = {};
            var returns = [];
                    
            getSettings().then(function(settings){
                returns.push(settings);
                if ( (null == request.params.scheduledDataUpdatedTime) ||
                     (null != request.params.scheduledDataUpdatedTime && request.params.scheduledDataUpdatedTime != settings.staticFeedTime)
                ) {       
                    fetchScheduledData = true;          
                } else {
                    fetchScheduledData = false;             
                }
                return getRealTimeDataEx(routeId, stationId, direction, settings.realTimeFeedTime, settings.serviceStatusFeedTime);
            }).then(function(realTimeData){
                returns.push(realTimeData);
                return fetchScheduledData ? getScheduledDataEx(routeId, stationId, direction, returns[0].staticFeedTime, returns[0].serviceStatusFeedTime) : null;
            }).then(function(scheduledData){                
                return getStatus(returns[0], returns[1], scheduledData, fetchScheduledData);
            }).then(function(status){
                response.success(status);
            }, function(error) {
                response.error(getErrorJSON(error.message));
            });
        }
    } catch (e) {
        response.error(getErrorJSON(e.message));
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
 
function getErrorJSON(message) {
    var errObj = {
        "status" : -1, //ERROR
        "data": {
            "message": message
        }
    }
    return JSON.stringify(errObj);
}
   
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
            response.error(getErrorJSON("Parameter 'appVersion' is missing"));
            bOK = false;
        }
          
        if(bOK) {       
            var promises = [];
        
            promises.push(getSettings());
            promises.push(addRouteList());
            promises.push(addStationList());
                    
            Parse.Promise.when(promises).then(function(settings, routes, stations) {
                var myResponse = null;
              
                if ( (null == request.params.updatedTime) ||
                     (null != request.params.updatedTime && request.params.updatedTime != settings.staticFeedTime)
                ) {       
                    myResponse = {
                        "status": 0,//SUCCESS
                        "data": {
                            "feedTime": settings.staticFeedTime,
                            "routes": routes,
                            "stations": stations
                        }
                    };              
                } else {
                     
                    myResponse = {
                        "status": 2//DATAUPTODATE
                    }//"Static data is uptodate"
                }
                response.success(myResponse);
            }, function(error) {
                // Never called
                response.error();
            });
        }
    } catch (e) {
        response.error(getErrorJSON(e.message));
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
        if(bOK) {
            var myResponse = 
                {
                  "status": 0,//SUCCESS
                  "data": {
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
                    }
                };
            response.success(myResponse);
        }
    } catch (e) {
        response.error(getErrorJSON(e.message));
    }
});
       
function deleteAllObjects(className, uid, objs) {
    steps += "deleteAllObjects - " + className + ", " + uid + "\r\n";
    var promises = [];
       
    promises.push(Parse.Object.destroyAll(objs));
            
    return Parse.Promise.when(promises).then(function() {
        steps += "DELETED ALL OBJS " + objs.length + " for " + className + ", " + uid + "\r\n";
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
            steps += " SUCCESS DELETING " + objs.length + " for " + className + ", " + uid + "\r\n";
            return objs.length;
        });
        return promise;
    });
}
       
function deleteAllRowsEx(className, uid, limit) {
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
            steps += " DONE DELETING " + objs.length + " for " + className + ", " + uid + "\r\n";
            return deleteAllObjects(className, uid, objs);
        });
        return promise;
    });
}
        
function deleteAllRows(className, uid) {
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
        var loop = objCount/limit;
        var promise = Parse.Promise.as();
        for (var i = 0; i < loop; i++) {         
            promise = promise.then(function() {             
                steps += "FOUND " + objCount + " for " + className + ", " + uid +  "\r\n";              
                var promisesX = [];
                promisesX.push(deleteAllRowsEx(className, uid, limit));
                return Parse.Promise.when(promisesX).then(function(delCount) {
                    var promiseX = Parse.Promise.as();
                    promiseX = promiseX.then(function() {                       
                        return delCount;
                    });                 
                    return promiseX;
                })  
            }); 
        }
        return promise;
    }).then(function(){
        steps += "DONE deleteAllRows - " + ", " + uid + "\r\n"; 
    });
}
  
Parse.Cloud.job("deleteAllObsoleteRows", function(request, response) {
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
            steps += "GOT SETTINGS\r\n";
            returns.push(settings.serviceStatusFeedTime);
            returns.push(settings.staticFeedTime);
        // delete real time rows     
            return deleteAllRows("RealTimeData", settings.realTimeFeedTime);
        }).then(function(){
            return deleteAllRows("ServiceStatus", returns[0]);
        }).then(function(){
        // delete static rows
            return deleteAllRows("Route", returns[1]);
        }).then(function(){
            return deleteAllRows("RouteStationBounds", returns[1]);
        }).then(function(){
            return deleteAllRows("Station", returns[1]);
        }).then(function(){
            return deleteAllRows("ScheduledData", returns[1]);
        }));
                
        return Parse.Promise.when(promises).then(function(rowCount) {
            var promise = Parse.Promise.as();
            // For each item, extend the promise with a function to delete it.
            promise = promise.then(function() {
              // Return a promise that will be resolved when the delete is finished.
              steps += "finally deleted all static & realTime rows\r\n";
              var retVal = {
                "status": 0,//SUCCESS
                "data": {
                    "message": steps
                }
              }
              response.success(JSON.stringify(retVal));
            });
            return promise;
        }, function(error) {
            response.error(getErrorJSON(steps));
        });
    } catch (e) {
        response.error(getErrorJSON(steps));
    }
});