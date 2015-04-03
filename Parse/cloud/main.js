var moment = require('cloud/moment');
   
function getESTTime(utcOffset) {
    var estTime = moment().utcOffset(utcOffset);
    var year = estTime.format("YYYY");
    var month = estTime.format("MM");
    var date = estTime.format("DD");
    var hours = estTime.format("HH");
    var minutes = estTime.format("mm");
    var seconds = estTime.format("ss");
    var day = estTime.format("d");
    return getDateObj(year, month, date, hours, minutes, seconds, day);
}
  
function getESTNextDay(utcOffset) {
    var today = moment();
    var tomorrow = today.add('days', 1);    
    var estTime = moment(tomorrow).utcOffset(utcOffset);
    var year = estTime.format("YYYY");
    var month = estTime.format("MM");
    var date = estTime.format("DD");
    var hours = 0;
    var minutes = 0;
    var seconds = 0;
    var day = estTime.format("d");
    return getDateObj(year, month, date, hours, minutes, seconds, day);
}
  
function getDateObj(year, month, date, hours, minutes, seconds, day) {
    var curTime = new Date(year, month, date, hours, minutes, seconds).getTime();
    var todayMorning = new Date(year, month, date).getTime();
    return {
        "curTime": curTime,
        "todayMorning": todayMorning,
        "year": year,
        "month": month,
        "date": date,
        "hours": hours,
        "minutes": minutes,
        "seconds": seconds,
        "day": day
    }
}
   
function getServiceStatus(uid) {
    var promises = [];
    var serviceStatus = null;
    var ServiceStatus = Parse.Object.extend("ServiceStatus");
    var querySStatus = new Parse.Query(ServiceStatus);
                    
    querySStatus.equalTo("uid", uid);
               
    promises.push(querySStatus.first());
               
    return Parse.Promise.when(promises).then(function(ssObj) {
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
            if(ssObj){
                var ssMap = JSON.parse(ssObj.get("ssMap"));
            }
            return ssMap;
        });
        return promise;
    });
}
  
function prepareScheduledData(stpData, curTime, curDay, curD, curM, curY, today, runningDaysMap, exceptionDatesMap, sMap, scheduledData) {
                   
    var arrTime = stpData.t;
    var diff =  (today + convertToMilliSeconds(arrTime)) - curTime;                 
    var diffStr = getTimeString(diff);              
    var serviceId = stpData.s;
    var runningDays = runningDaysMap[serviceId];
    var exceptionDates = exceptionDatesMap[serviceId];
    var bOK = true;
            
    if((undefined != exceptionDates) && (-1 != exceptionDates.indexOf(curY + "" + curM + "" + curD))){
        bOK = false;
    }
            
    if(bOK && (undefined != runningDays) && (-1 == runningDays.indexOf(curDay))){
        bOK = false;
    }
            
    if(bOK && ((null == diffStr) || 0 >= diff)) {              
        bOK = false;
    }
                   
    if(bOK) {   
        var sData = {
            "routeId": stpData.r,
            "arrivalTime": arrTime/*,
            "serviceStatus": ""*/
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
            
function getScheduledData(routeId, stationId, direction, uid, ssUID, skip, runningDaysMap, exceptionDatesMap, utcOffset) {
    var promises = [];
    var scheduledData = [];
    var ScheduledData = Parse.Object.extend("ScheduledData");
    var querySData = new Parse.Query(ScheduledData);
                    
    querySData.equalTo("stationId", stationId);
    //querySData.equalTo("direction", direction);
    querySData.equalTo("uid", uid); 
    querySData.skip(skip);
    querySData.limit(1000);
                    
    promises.push(querySData.first());
                
    return Parse.Promise.when(promises).then(function(sdObj) {
        var promise = Parse.Promise.as();
        var estTime = getESTTime(utcOffset);         
        var curTime = estTime.curTime;
        var curDay = parseInt(estTime.day);
        var curD = estTime.date;
        var curM = estTime.month;
        var curY = estTime.year;
        var today = estTime.todayMorning;
           
        promise = promise.then(function() {
            if(sdObj) {
                var sMap = {};          
                var stationTimeMap = JSON.parse(sdObj.get("stationTimeMap"));               
                var stopData = stationTimeMap[direction];               
                  
                for (var i = 0; i < stopData.length; i++) {                 
                    var stpData = stopData[i];                  
                    prepareScheduledData(stpData, curTime, curDay, curD, curM, curY, today, runningDaysMap, exceptionDatesMap, sMap, scheduledData);
                }
                  
                if(0 == scheduledData.length) {
                    // try with next day
                    estTime = getESTNextDay(utcOffset);
           
                    curTime = estTime.curTime;
                    curDay = parseInt(estTime.day);
                    curD = estTime.date;
                    curM = estTime.month;
                    curY = estTime.year;
                    today = estTime.todayMorning;
                      
                    for (var i = 0; i < stopData.length; i++) {
                        prepareScheduledData(stpData, curTime, curDay, curD, curM, curY, today, runningDaysMap, exceptionDatesMap, sMap, scheduledData);
                    }
                }
            }
            return scheduledData;
        });
        return promise;
    /*}).then(function(scheduledData){
        return setServiceStatus(scheduledData, ssUID);*/
    }).then(function(scheduledData){       
        scheduledData.sort(compareDateTime);    
        return scheduledData;
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
            
function getRealTimeData(routeId, stationId, direction, uid, ssUID, skip, utcOffset) {
    var promises = [];
    var realTimeData = [];
    var dataAvailForReqRoute = false;
    var RealTimeData = Parse.Object.extend("RealTimeData");
    var queryRTData = new Parse.Query(RealTimeData);
      
    queryRTData.equalTo("uid", uid);
    queryRTData.skip(skip);
    queryRTData.limit(1000);    
                    
    promises.push(queryRTData.first());
                
    return Parse.Promise.when(promises).then(function(rtdObj) {
        var promise = Parse.Promise.as();
        var curTime = (new Date()).getTime();     
        promise = promise.then(function() {
            var rtMap = {};
            if(undefined != rtdObj) {           
                var stationTimeMap = JSON.parse(rtdObj.get("stationTimeMap"));
                var dirMap = stationTimeMap[stationId];         
                if(undefined != dirMap) {
                    var stopData = dirMap[direction];                   
                    for (var i = 0; i < stopData.length; i++) {
                        var stpData = stopData[i];
                        var arrTime = stpData.t * 1000;
                        var diff = arrTime - curTime;
                        var diffStr = getTimeString(diff);
                       
                        if((null != diffStr) && (0 < diff)) {
                            if(!dataAvailForReqRoute) {
                                dataAvailForReqRoute = (stpData.r == routeId);
                            }
                            var rtData = {
                                "routeId": stpData.r,
                                "arrivalTime": diffStr,
                                "tripAssignment": true/*,
                                "serviceStatus": ""*/
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
                            //console.log("TIME PASSED " + arrTime + " " + diffStr + " " + diff);
                        }
                    }
                }
            }
            return realTimeData;            
        });
        return promise;
    /*}).then(function(realTimeData){
        return setServiceStatus(realTimeData, ssUID);*/
    }).then(function(realTimeData){
        realTimeData.sort(compareDateTime);
        return {
            "realTimeData" : realTimeData,
            "dataAvailForReqRoute" : dataAvailForReqRoute,
        };
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
    var hours = parseInt(str[0]);
    var minutes = parseInt(str[1]);
    var seconds = parseInt(str[2]);
    milliSeconds = ((hours * 60 * 60) + (minutes * 60) + seconds) * 1000;
    return milliSeconds;
}
               
function setServiceStatus(trainData, ssUID) {
    var promises = [];
    var routeMap = {};
          
    promises.push(getServiceStatus(ssUID));
               
    return Parse.Promise.when(promises).then(function(ssMap) {
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
            if(undefined != ssMap) {
                for (var i = 0; i < trainData.length; i++) {
                    var tD = trainData[i];
                    tD.serviceStatus = ssMap[tD.routeId];
                }
            }
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
                } else if ("utcOffset" == settingsKey) {
                    settings.utcOffset = settingsValues[0];
                }
            }
            return settings;
        });
        return promise;
    });
}
                
function getStatus(settings, realTimeDataEx, scheduledData, fetchScheduledData, serviceStatus) {
    var status = {};
                
    status = {
        "status": (false == realTimeDataEx.dataAvailForReqRoute) ? 1/*NO RealTimeData*/ : 0/*SUCCESS*/,
        "data": {
            "realTime": {
                "data": realTimeDataEx.realTimeData,
                "feedTime": settings.gtfsFeedTime
            },
            "serviceStatus": serviceStatus
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
        
function getExceptionDates() {
    var promises = [];  
    var ExceptionDate = Parse.Object.extend("ExceptionDate");
    var queryExceptionDate = new Parse.Query(ExceptionDate);
                    
    promises.push(queryExceptionDate.find());
                
    return Parse.Promise.when(promises).then(function(exceptionDateObjs) {
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
            var expDateMap = {};
                            
            for (var i = 0; i < exceptionDateObjs.length; i++) {
                var exceptionDateObj = exceptionDateObjs[i];
                var serviceId = exceptionDateObj.get("serviceId");
                        
                if(!expDateMap[serviceId]) {
                    expDateMap[serviceId] = [];
                }
                        
                expDateMap[serviceId].push(exceptionDateObj.get("date"));
            }
            return expDateMap;
        });
        return promise;
    });
}
        
function getRunningDays() {
    var promises = [];  
    var Calendar = Parse.Object.extend("Calendar");
    var queryCalendar = new Parse.Query(Calendar);
                    
    promises.push(queryCalendar.find());
                
    return Parse.Promise.when(promises).then(function(calendarObjs) {
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
            var runningDaysMap = {};
                            
            for (var i = 0; i < calendarObjs.length; i++) {
                var calendarObj = calendarObjs[i];
                var serviceId = calendarObj.get("serviceId");
                        
                if(!runningDaysMap[serviceId]) {
                    runningDaysMap[serviceId] = [];
                }
                        
                if(calendarObj.get("sunDay")) {
                    runningDaysMap[serviceId].push(0);
                }               
                        
                if(calendarObj.get("monDay")) {
                    runningDaysMap[serviceId].push(1);
                }
                        
                if(calendarObj.get("tuesDay")) {
                    runningDaysMap[serviceId].push(2);
                }
                        
                if(calendarObj.get("wednesDay")) {
                    runningDaysMap[serviceId].push(3);
                }
                        
                if(calendarObj.get("thursDay")) {
                    runningDaysMap[serviceId].push(4);
                }
                        
                if(calendarObj.get("friDay")) {
                    runningDaysMap[serviceId].push(5);
                }
                        
                if(calendarObj.get("saturDay")) {
                    runningDaysMap[serviceId].push(6);
                }
            }
            return runningDaysMap;
        });
        return promise;
    });
}
  
// check whether any update for scheduledData available
Parse.Cloud.define("isUpdateForScheduledDataAvailable", function(request, response) {
    var bOK = true;
    var isAvailable = false;
                    
    /*  
    {
      "appVersion": "10020",
      "scheduledDataUpdatedTime" : "ddMMyyyyHHmmss"
    }
    */
                
    try
    {
        if(bOK && null == request.params.scheduledDataUpdatedTime) {
            response.error(getErrorJSON("Parameter 'scheduledDataUpdatedTime' is missing"));
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
                    isAvailable = true;          
                }
                  
                status = {
                    "status": isAvailable ? 1 : 0
                };
                response.success(status);
            }, function(error) {
                response.error(getErrorJSON(error.message));
            });
        }
    } catch (e) {
        response.error(getErrorJSON(e.message));
    }
});
               
function prepareServiceStatus(ssUID) {
    var promises = [];
          
    promises.push(getServiceStatus(ssUID));
               
    return Parse.Promise.when(promises).then(function(ssMap) {
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
            return ssMap;
        });
        return promise;
               
    });
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
      "fetchScheduledData": false,
      "route": "1"
    }
    */
                
    try
    {
        var liveRoutes = ["1","2","3","4","5","6","L","S"];
        if(-1 == liveRoutes.indexOf(request.params.route)) {
            var status = {};
                
            status = {
                "status": 1/*NO RealTimeData*/,
                "data": {
                }
            };                    
              
            getSettings().then(function(settings){
                return prepareServiceStatus(settings.serviceStatusFeedTime);    
            }).then(function(serviceStatus){        
                status.data.serviceStatus = serviceStatus;
                response.success(status);
            }, function(error) {
                response.error(getErrorJSON(error.message));
            });
        } else {
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
                    fetchScheduledData = request.params.fetchScheduledData;
                    return getRunningDays();
                }).then(function(runningDays){
                    returns.push(runningDays);
                    return getExceptionDates();
                }).then(function(exceptionDates){
                    returns.push(exceptionDates);
                    return getRealTimeData(routeId, stationId, direction, returns[0].realTimeFeedTime, returns[0].serviceStatusFeedTime, 0, returns[0].utcOffset);
                }).then(function(realTimeData){
                    returns.push(realTimeData);
                    return fetchScheduledData ? getScheduledData(routeId, stationId, direction, returns[0].staticFeedTime, returns[0].serviceStatusFeedTime, 0, returns[1], returns[2], returns[0].utcOffset) : null;
                }).then(function(scheduledData){                
                    returns.push(scheduledData);
                    return prepareServiceStatus(returns[0].serviceStatusFeedTime);
                }).then(function(serviceStatus){
                    return getStatus(returns[0], returns[3], returns[4], fetchScheduledData, serviceStatus);                    
                }).then(function(status){
                    response.success(status);
                }, function(error) {
                    response.error(getErrorJSON(error.message));
                });
            }
        }
    } catch (e) {
        response.error(getErrorJSON(e.message));
    }
});  
                
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
                var routeStations = JSON.parse(routeObj.get("stations"));
                for (var j = 0; j < routeStations.length; j++) { 
                    var routeStation = routeStations[j];
                    var station = {
                        "stationId": routeStation.i,
                        "northBound": routeStation.n,
                        "southBound": routeStation.s
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
                            "realTimeData" : {
                                "time": "30",
                                "unit": "sec"
                            }, 
                            "scheduledData" : {
                                "time": "120",
                                "unit": "days"
                            }
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
    var promises = [];
               
    promises.push(Parse.Object.destroyAll(objs));
                    
    return Parse.Promise.when(promises).then(function() {
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
            return objs.length;
        });
        return promise;
    });
}
               
function deleteAllRowsEx(className, uid, limit) {
    var promises = [];
    var Table = Parse.Object.extend(className);
    var query = new Parse.Query(Table);
                    
    // find all rows that doesn't match 
    query.notEqualTo("uid", uid);
    query.limit(limit);
    promises.push(query.find());
                    
    return Parse.Promise.when(promises).then(function(objs) {
        var promise = Parse.Promise.as();
        promise = promise.then(function() {
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
        var loop = objCount/limit;
        var promise = Parse.Promise.as();
        for (var i = 0; i < loop; i++) {         
            promise = promise.then(function() {             
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
                        
        Parse.Cloud.useMasterKey();
                        
        promises.push(getSettings().then(function(settings){
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
            return deleteAllRows("Calendar", returns[1]);   
        }).then(function(){
            return deleteAllRows("ExceptionDate", returns[1]);
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
              var retVal = {
                "status": 0//SUCCESS
              }
              response.success(JSON.stringify(retVal));
            });
            return promise;
        }, function(error) {
            response.error(getErrorJSON(error.message));
        });
    } catch (e) {
        response.error(getErrorJSON(e.message));
    }
});