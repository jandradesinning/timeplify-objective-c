﻿using System;
using System.Xml;
using System.IO;
using System.IO.Compression;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using System.Net;
using System.Xml.Serialization;
using System.Text;
using System.Linq;
using ProtoBuf;
using transit_realtime;
using GTFS;
using GTFS.IO;
using GTFS.Entities;
using Parse;
using nyct_subway;

namespace Timeplify
{
    /// <summary>
    /// Responsible for gathering data from service provider (Siemens) based on 
    /// the configuration. The implementation of this module would adapt to the requirements 
    /// based on the type of service provider. Data obtained from service provider is transformed
    /// into a structure understandable by PRIS Parking Data Manager. The transformed data is 
    /// then passed to OnShoreClient to be sent to Parking Data Manager service.
    /// </summary>
    public class Processor : CDisposableObj
    {
        #region Enumerations
            
        #endregion //Enumerations
            
        #region Constants
            
        private const string XPATH_ROOT      = "//";
        private const string XPATH_SEP       = "/";

        private const string PATH_SEP        = "\\";
            
        /// <summary>
        /// File name date format.
        /// </summary>
        private const string FND_FMT         = "ddMMyyyyHHmmss";
            
            
        private const int    HALF_MILLI_SECS = 30*1000;
            
        #endregion //Constants
            
        #region Static Members
            
        #endregion //Static Members
            
        #region Private Members
            
        /// <summary>
        /// Timer to fetch gtfs real time feed.
        /// </summary>
        private Timer               _gtfsRTFTimer       = null;

        /// <summary>
        /// Timer to fetch gtfs static feed.
        /// </summary>
        private Timer _gtfsSFTimer = null;

        /// <summary>
        /// Timer to fetch service status feed.
        /// </summary>
        private Timer _serviceStatusTimer = null;

        /// <summary>
        /// Timer to cleanup live data.
        /// </summary>
        private Timer _cleanupLiveDataTimer = null;
            
        /// <summary>
        /// Used for locking ...similar to critical section.
        /// </summary>
        private static Object       _lockThis           = new Object();
            
        /// <summary>
        /// Used for identify service stop signal.
        /// </summary>
        private static bool         _bStopping          = false;

        /// <summary>
        /// Hardcoded values of north & south bound for each route
        /// </summary>
        private Hashtable _routeMap = null;

        private List<ParseObject> _listStaticPO = null;

        private List<ParseObject> _listRealTimePO = null;
            
        #endregion //Private Members
            
        #region Constructor
            
        public Processor()
        {   
        }
            
        #endregion //Constructor            
            
        #region Destructor

        ~Processor()
        {
        }
            
        #endregion //Destructor
                        
        #region CDisposableObj Members
            
        /// <summary>
        /// Initialize acknowledgement map.
        /// Starts timer to fetch the xml.
        /// </summary>
        /// <returns>true if success.</returns>
        protected override bool Initialize()
        {
            // Locals
            bool bRet = false;
                
            try
            {
                ParseClient.Initialize("zvTZXlTzpGnrccEwEXiokp2UJ7ZusYftc4Wt9B0i", "Bv8UkHYe1WhIiu86rK6boshd0LIXK54k1hC1HP05");
                bRet = StartTimers();
            }
            catch(Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to initialize CPCSClient. [Error] {0}.", e.Message);
            }
                
            return bRet;
        }
            
        /// <summary>            
        /// Clear acknowledgement map.
        /// Stops timer.
        /// </summary>
        /// <returns>true if success.</returns>
        protected override bool UnInitialize()
        {
            // Locals
            bool bRet = false;
                
            try
            {
                _bStopping  = true;
                bRet        = StopTimers();
                    
                _lockThis      = null;
            }
            catch(Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.NonFatalError, "Failed to Uninitialize Processor. [Error] {0}.", e.Message);
            }
                
            return base.UnInitialize();
        }
            
        #endregion //CDisposableObj Members
            
        #region Private Methods
            
        /// <summary>
        /// Starts the process & acknowledgement timers.
        /// </summary>
        /// <returns></returns>
        private bool StartTimers()
        {
            // Locals
            bool bRet = false;
                
            try
            {
                StartTimer(ref _gtfsRTFTimer, Worker.Instance.Configuration.GTFSRealTimeFeedInterval, GTFSRTFTimerProc, "GTFS Real Time");
                StartTimer(ref _gtfsSFTimer, Worker.Instance.Configuration.GTFSStaticFeedInterval, GTFSSFTimerProc, "GTFS Static");
                StartTimer(ref _serviceStatusTimer, Worker.Instance.Configuration.ServiceStatusInterval, ServiceStatusTimerProc, "ServiceStatus");
                StartTimer(ref _cleanupLiveDataTimer, 1*60, CleanUpTimerProc, "Cleanup Live Data");
                    
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Successfully started timer","");
            }
            catch(Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to start timer. [Error] {0}.", e.Message);
            }
                
            return bRet; 
        }

        private bool StartTimer(ref Timer timer, uint uInterval, TimerCallback procCallbk, string description)
        {
            // Locals
            bool bRet = false;

            try
            {
                if (null == timer)
                {
                    timer = new Timer(new TimerCallback(procCallbk));
                    timer.Change(HALF_MILLI_SECS, uInterval * 1000);
                }

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Successfully started " + description + " timer", "");
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to start timer. [Error] {0}.", e.Message);
            }

            return bRet;
        }

        private bool StopTimer(ref Timer timer, string description)
        {
            // Locals
            bool bRet = false;

            try
            {
                if (null != timer)
                {
                    Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Stopping " + description + "Timer");
                    timer.Change(Timeout.Infinite, Timeout.Infinite);
                    timer.Dispose();
                    timer = null;
                    Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Stopped " + description + "Timer");
                }
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to stop timer. [Error] {0}.", e.Message);
            }

            return bRet;
        }
            
        /// <summary>
        /// Stops the process & acknowledgement timers.
        /// </summary>
        /// <returns></returns>
        private bool StopTimers()
        {
            // Locals
            bool bRet = false;
                
            try
            {
                StopTimer(ref _gtfsRTFTimer, "GTFS Real Time");
                StopTimer(ref _gtfsSFTimer, "GTFS Static");
                StopTimer(ref _serviceStatusTimer, "ServiceStatus");
                StopTimer(ref _cleanupLiveDataTimer, "Cleanup Live Data");

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Successfully stoppped timers", "");
            }
            catch(Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to stop timer. [Error] {0}.", e.Message);
            }
                
            return bRet; 
        }

        private string GetCurrentTimeString()
        {
            return DateTime.Now.ToString(FND_FMT);
        }

        private void DownloadRTFeed(string url, string folder)
        {
            // Locals
            FeedMessage fm = null;
            string file = null;

            try
            {
                file = folder + GetCurrentTimeString();
                fm = DownloadRTFile(url, file);
                SaveRTFeed(file, fm);
                ProcessRTFeed(fm);                
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to download feed. [Error] {0}.", e.Message);
            }
        }

        private FeedMessage DownloadRTFile(string url, string toLocalPath)
        {
            // Locals
            FeedMessage fm = null;
            byte[] buffer = null;
            WebRequest wr = null;
            WebResponse response = null;
            Stream responseStream = null;
            MemoryStream memoryStream = null;
            int count = 0;

            try
            {
                buffer = new byte[4097];
                wr = WebRequest.Create(url);
                wr.Proxy = GetProxy();

                response = wr.GetResponse();
                responseStream = response.GetResponseStream();
                memoryStream = new MemoryStream();

                do
                {
                    count = responseStream.Read(buffer, 0, buffer.Length);
                    memoryStream.Write(buffer, 0, count);

                    if (count == 0)
                    {
                        break;
                    }
                }
                while (true);

                memoryStream.Seek(0, SeekOrigin.Begin);
                fm = (FeedMessage)Serializer.Deserialize<FeedMessage>(memoryStream);
                
                memoryStream.Close();
                responseStream.Close();
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to download feed. [Error] {0}.", e.Message);
            }

            return fm;
        }

        private void ProcessRTFeed(FeedMessage fm)
        {
            // Locals
            List<ParseObject> listPO = null;

            try
            {
                if(null == _listRealTimePO)//first time
                {
                }
                else// update
                {
                }

                listPO = new List<ParseObject>();

                foreach(FeedEntity fe in fm.entity)
                {
                    TripUpdate tu = fe.trip_update;
                    if(null != tu)
                    {
                        foreach(TripUpdate.StopTimeUpdate stu in tu.stop_time_update)
                        {
                            ParseObject poRealTimeData = new ParseObject("RealTimeData");
                            // Last character denoting direction not needed, as we store parent stationid
                            poRealTimeData["stationId"] = stu.stop_id.Remove(stu.stop_id.Length-1, 1);
                            poRealTimeData["routeId"] = tu.trip.route_id;
                            poRealTimeData["direction"] = (NyctTripDescriptor.Direction.NORTH == tu.trip.nyct_trip_descriptor.direction) ? "SOUTH" : "NORTH";
                            poRealTimeData["assigned"] = tu.trip.nyct_trip_descriptor.is_assigned;
                            listPO.Add(poRealTimeData);
                        }
                    }
                }

                ParseObject poSettings = new ParseObject("Settings");
                poSettings["settingsKey"] = "realTime";
                poSettings["settingsValue"] = DateTimeFromUnixTimestampSeconds(fm.header.timestamp).ToString(FND_FMT);
                listPO.Add(poSettings);

                if(null != _listRealTimePO)
                {
                    // TODO: Delete previous entries???
                    //??ParseObject.DeleteAllAsync(_listRealTimePO);
                    _listRealTimePO = null;
                    // For better memory performance.
                    GC.Collect();
                }

                if(null != listPO)
                {
                    ParseObject.SaveAllAsync(listPO);
                    _listRealTimePO = listPO;
                }
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to process real time feed. [Error] {0}.", e.Message);
            }
        }

        private void SaveRTFeed(string file, FeedMessage fm)
        {
            try
            {
                string xmlfeed = SerializeXml<FeedMessage>(fm);
                StreamWriter xmlfile = new StreamWriter(file + ".xml");
                xmlfile.WriteLine(xmlfeed);
                xmlfile.Close();
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to save feed. [Error] {0}.", e.Message);
            }
        }

        private static readonly DateTime UnixEpoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public static DateTime DateTimeFromUnixTimestampSeconds(ulong seconds)
        {
            return UnixEpoch.AddSeconds(seconds);
        }

        private static string SerializeXml<T>(T obj, Type[] extraTypes = null)
        {
            using (var stream = new MemoryStream())
            {
                var ns = new XmlSerializerNamespaces();
                ns.Add("", "");
                var serializer = GetXmlSerializer(typeof(T), extraTypes);
                serializer.Serialize(stream, obj, ns);
                stream.Position = 0;
                return new StreamReader(stream).ReadToEnd();
            }
        }

        private static XmlSerializer GetXmlSerializer(Type type, Type[] extraTypes)
        {
            var key = new StringBuilder();
            XmlSerializer serializer = null;

            key.Append(type.FullName);
            if (null != extraTypes)
            {
                foreach (var extraType in extraTypes)
                {
                    key.AppendFormat("~{0}", extraType.FullName);
                }
                serializer = new XmlSerializer(type, extraTypes);
            }
            else
            {
                serializer = new XmlSerializer(type);
            }

            return serializer;
        }

        private WebProxy GetProxy()
        {
            WebProxy webProxy = null;

            if ((null != Worker.Instance.Configuration.ProxyAddress) && 
                (0 < Worker.Instance.Configuration.ProxyAddress.Length) && 
                (0 < Worker.Instance.Configuration.ProxyPort))
            {
                webProxy = new WebProxy(Worker.Instance.Configuration.ProxyAddress, Worker.Instance.Configuration.ProxyPort);
                webProxy.BypassProxyOnLocal = false;
            }
            return webProxy;
        }

        private void DownloadServiceStatusFeed()
        {
            // Locals
            string curDT = null;
            string dataFolder = null;
            string remoteUri = null;
            string localFile = null;

            try
            {
                dataFolder = Worker.Instance.Configuration.GTFSRealTimeDataFolder;

                if (!Directory.Exists(dataFolder))
                {
                    Directory.CreateDirectory(dataFolder);
                }

                curDT = GetCurrentTimeString();
                localFile = dataFolder + curDT + "_serviceStatus.xml";
                remoteUri = Worker.Instance.Configuration.ServiceStatusFeedURL;

                // Create a new WebClient instance.
                WebClient webClient = new WebClient();
                webClient.Proxy = GetProxy();
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Downloading File \"{0}\" to \"{1}\" .......\n\n", remoteUri, localFile);
                // Download the Web resource and save it into the current filesystem folder.
                webClient.DownloadFile(remoteUri, localFile);
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Successfully Downloaded File \"{0}\" to \"{1}\"", remoteUri, localFile);

                ProcessStatusFeed(localFile);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to download static feed. [Error] {0}.", e.Message);
            }
        }

        private void ProcessStatusFeed(string statusFile)
        { 
            //TODO
        }

        private void DownloadStaticFeed()
        {
            // Locals
            string curDT = null;
            string dataFolder = null;
            string remoteUri = null;
            string localFile = null;

            try
            {
                dataFolder = Worker.Instance.Configuration.GTFSStaticDataFolder;

                if (!Directory.Exists(dataFolder))
                {
                    Directory.CreateDirectory(dataFolder);
                }

                curDT = GetCurrentTimeString();
                localFile = dataFolder + curDT + ".gtfs";
                dataFolder = dataFolder + "gtfs_" + curDT;
                remoteUri = Worker.Instance.Configuration.GTFSStaticFeedURL;

                // Create a new WebClient instance.
                WebClient webClient = new WebClient();
                webClient.Proxy = GetProxy();
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Downloading File \"{0}\" to \"{1}\" .......\n\n", remoteUri, localFile);
                // Download the Web resource and save it into the current filesystem folder.
                webClient.DownloadFile(remoteUri, localFile);
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Successfully Downloaded File \"{0}\" to \"{1}\"", remoteUri, localFile);

                ZipFile.ExtractToDirectory(localFile, dataFolder);
                ProcessStaticFeed(dataFolder);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to download static feed. [Error] {0}.", e.Message);
            }
        }

        protected internal class Bounds
        {
            public string North;
            public string South;

            public Bounds(string north, string south)
            {
                North = north;
                South = south;
            }
        }

        private string GetDisplayName(string routeId, string stationId, bool directionNorth)
        { 
            // Locals
            string displayName = "";
            Hashtable boundsMap = null;

            if (null == _routeMap)
            {
                _routeMap = new Hashtable();

                #region Route 1

                boundsMap = new Hashtable();
                boundsMap.Add("101", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("103", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("104", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("106", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("107", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("108", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("109", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("110", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("111", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("112", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("113", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("114", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("115", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("116", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("117", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("118", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("119", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("120", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("121", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("122", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("123", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("124", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("125", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("126", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("127", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("128", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("129", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("130", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("131", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("132", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("133", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("134", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("135", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("136", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("137", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("138", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("139", new Bounds("Uptown", "Downtown"));
                boundsMap.Add("140", new Bounds("Uptown", ""));
                _routeMap.Add("1", boundsMap);

                #endregion Route 1

                _routeMap.Add("2", boundsMap);
                _routeMap.Add("3", boundsMap);
                _routeMap.Add("4", boundsMap);
                _routeMap.Add("5", boundsMap);
                _routeMap.Add("5X", boundsMap);
                _routeMap.Add("6", boundsMap);
                _routeMap.Add("6X", boundsMap);
                _routeMap.Add("7", boundsMap);
                _routeMap.Add("7X", boundsMap);
                _routeMap.Add("A", boundsMap);
                _routeMap.Add("B", boundsMap);
                _routeMap.Add("C", boundsMap);
                _routeMap.Add("D", boundsMap);
                _routeMap.Add("E", boundsMap);
                _routeMap.Add("F", boundsMap);
                _routeMap.Add("FS", boundsMap);
                _routeMap.Add("G", boundsMap);
                _routeMap.Add("GS", boundsMap);
                _routeMap.Add("H", boundsMap);
                _routeMap.Add("J", boundsMap);
                _routeMap.Add("L", boundsMap);
                _routeMap.Add("M", boundsMap);
                _routeMap.Add("N", boundsMap);
                _routeMap.Add("Q", boundsMap);

                #region Route R

				boundsMap = new Hashtable();
                boundsMap.Add("G08", new Bounds("Manhattan", ""));
                boundsMap.Add("G09", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G10", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G11", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G12", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G13", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G14", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G15", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G16", new Bounds("Forest Hills - 71 Av", "Manhattan"));                
                boundsMap.Add("G18", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G19", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G20", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("G21", new Bounds("Forest Hills - 71 Av", "Manhattan"));
                boundsMap.Add("R11", new Bounds("Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R13", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R14", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R15", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R16", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R17", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R18", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R19", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R20", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R21", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R22", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R23", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R24", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R25", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R26", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R27", new Bounds("Uptown & Queens", "Brooklyn"));
                boundsMap.Add("R28", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R29", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R30", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R31", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R32", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R33", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R34", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R35", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R36", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R39", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R40", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R41", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R42", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R43", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R44", new Bounds("Manhattan", "Bay Ridge - 95 St"));
                boundsMap.Add("R45", new Bounds("Manhattan", ""));
                _routeMap.Add("R", boundsMap);

                #endregion Route R

                _routeMap.Add("S", boundsMap);
                _routeMap.Add("SI", boundsMap);
                _routeMap.Add("Z", boundsMap);
            }

            boundsMap = _routeMap[routeId] as Hashtable;

            if (null != boundsMap)
            {
                Bounds bounds = boundsMap[stationId] as Bounds;
                displayName = directionNorth ? bounds.North : bounds.South;
            }

            return displayName;
        }

        private async void ProcessStaticFeed(string dataFolder)
        {
            try
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "ProcessStaticFeed BEGIN: " + GetCurrentTimeString());

                // create the reader.
                var reader = new GTFSReader<GTFSFeed>();

                // execute the reader.
                var feed = reader.Read(new GTFSDirectorySource(new DirectoryInfo(dataFolder)));

                // get all routes
                var routes = new List<Route>(feed.GetRoutes());
                var trips = new List<Trip>(feed.GetTrips());
                var stopTimes = new List<StopTime>(feed.GetStopTimes());
                var stops = new List<Stop>(feed.GetStops());

                if (null == _listStaticPO)//firsttime
                {
                }
                else // update
                { 
                }

                int i = 0;

                var parentStops = stops.Where(stop => ((0 == stop.ParentStation.Length) || (null == stop.ParentStation))).ToList();

                foreach (var stop in parentStops)
                {
                    i++;
                    ParseObject poStation = new ParseObject("Station");
                    poStation["stationId"] = stop.Id;
                    poStation["name"] = stop.Name;
                    poStation["latitude"] = stop.Latitude;
                    poStation["longitude"] = stop.Longitude;
                    _listStaticPO.Add(poStation);
                    Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, i + ".\tstationId\t" + stop.Id + "\tname\t" + stop.Name);
                }

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "************SAVED ALL STATIONS****************");

                i = 0;

                foreach (var route in routes)
                {
                    i++;
                    var routeStops = (from stop in stops
                                      join stopTime in stopTimes on stop.Id equals stopTime.StopId
                                      join trip in trips on stopTime.TripId equals trip.Id
                                      where trip.Direction == GTFS.Entities.Enumerations.DirectionType.OneDirection//North to south
                                      join myroute in routes on trip.RouteId equals myroute.Id
                                      where myroute.Id == route.Id
                                      select stop).Distinct().ToList();

                    if (0 < routeStops.Count)
                    {
                        ParseObject poRoute = new ParseObject("Route");
                        poRoute["routeId"] = route.Id;
                        poRoute["shortName"] = route.ShortName;
                        poRoute["backgroundColor"] = route.Color;
                        poRoute["textColor"] = route.TextColor;
                        poRoute["northStationId"] = routeStops[0].ParentStation;
                        poRoute["southStationId"] = routeStops[routeStops.Count - 1].ParentStation;
                        
                        Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, i + ".\trouteId\t" + route.Id + "\tnorthStationId\t" + routeStops[0].ParentStation
                            + "\tsouthStationId\t" + routeStops[routeStops.Count - 1].ParentStation);

                        Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "*********RouteStationMap***************");

                        int j = 0;

                        foreach (var routeStop in routeStops)
                        {
                            j++;
                            poRoute.AddToList("stations", routeStop.ParentStation);

                            ParseObject poRouteStationBounds = new ParseObject("RouteStationBounds");
                            poRouteStationBounds["routeId"] = route.Id;
                            poRouteStationBounds["stationId"] = routeStop.ParentStation;
                            poRouteStationBounds["northBound"] = GetDisplayName(route.Id, routeStop.ParentStation, true);
                            poRouteStationBounds["southBound"] = GetDisplayName(route.Id, routeStop.ParentStation, false);
                            _listStaticPO.Add(poRoute);

                            Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, j + ".\trouteId\t" + route.Id + "\tstationId\t" + routeStop.ParentStation + "\tstationName\t" + routeStop.Name);
                        }
                        _listStaticPO.Add(poRoute);
                    }
                    else
                    {
                        Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, i + ".\trouteId\t" + route.Id + "\tZERO STOPS");
                    }
                }

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "************SAVED ALL ROUTES****************");

                // this is what we need
                foreach (var parentStop in parentStops)
                {
                    ProcessStationTimes(stopTimes, parentStop.Id, "S", trips);
                    ProcessStationTimes(stopTimes, parentStop.Id, "N", trips);
                }

                ParseObject poSettings = new ParseObject("Settings");
                poSettings["settingsKey"] = "staticTime";
                poSettings["settingsValue"] = GetCurrentTimeString();
                _listStaticPO.Add(poSettings);

                await ParseObject.SaveAllAsync<ParseObject>(_listStaticPO);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "************SAVED ALL STOP TIMES****************");

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "ProcessStaticFeed END: " + GetCurrentTimeString());
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to process static feed. [Error] {0}.", e.Message);
            }
        }

        private static IEnumerable<TSource> DistinctBy<TSource, TKey>(IEnumerable<TSource> source, Func<TSource, TKey> keySelector)
        {
            HashSet<TKey> seenKeys = new HashSet<TKey>();
            foreach (TSource element in source)
            {
                if (seenKeys.Add(keySelector(element)))
                {
                    yield return element;
                }
            }
        }

        private void ProcessStationTimes(List<StopTime> stopTimes, String stopId, string direction, List<Trip> trips)
        {
            try
            {
                string routeChildStop = stopId + direction;
                var stationTimes = stopTimes.Where(stopTime => (stopTime.StopId == routeChildStop)).
                    OrderBy(stopTime => stopTime.ArrivalTime.Hours).
                    ThenBy(stopTime => stopTime.ArrivalTime.Minutes).
                    ThenBy(stopTime => stopTime.ArrivalTime.Seconds).
                    ToList();

                var stationTimesD = DistinctBy(stationTimes, stopTime => stopTime.ArrivalTime).ToList();

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Total station arrival times count" + stationTimesD.Count);

                int i = 0;
                foreach (var stationTime in stationTimesD)
                {
                    var curTrip = trips.Where(trip => trip.Id == stationTime.TripId).FirstOrDefault();

                    i++;
                    ParseObject poSData = new ParseObject("ScheduledData");

                    poSData["stationId"] = stopId;
                    poSData["routeId"] = curTrip.RouteId;
                    poSData["arrivalTime"] = stationTime.ArrivalTime.Hours + ":" + stationTime.ArrivalTime.Minutes + ":" + stationTime.ArrivalTime.Seconds;
                    poSData["direction"] = direction;
                    _listStaticPO.Add(poSData);
                    Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, i + ".\trouteId\t" + curTrip.RouteId + "\tstationId\t" + stopId
                        + "\tarrivalTime\t" + poSData["arrivalTime"] + "\tdirection\t" + direction
                        );
                }
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to process station arrival times. [Error] {0}.", e.Message);
            }
        }

        #endregion //Private Methods
            
        #region Public Methods
            
        
            
        #endregion //Public Methods
            
        #region Callbacks
            
        private void GTFSRTFTimerProc(object state)
        {
            // Locals
            bool bOK = false;
            string url = null;
            string folder = null;

            // For better memory performance.
            GC.Collect();
                
            if(!_disposed && !_bStopping)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Invoked GTFSTimerProc callback.", "");
                
                url = Worker.Instance.Configuration.GTFSRealTimeFeedURL;
                folder = Worker.Instance.Configuration.GTFSRealTimeDataFolder;

                if (!Directory.Exists(folder))
                {
                    Directory.CreateDirectory(folder);
                }

                // Real-Time Subway Locations - 1, 2, 3, 4, 5, 6, S Lines
                DownloadRTFeed(url + "&feed_id=1", folder + "gtfs_123456S_");

                // Real-Time Subway Locations - L Line
                DownloadRTFeed(url + "&feed_id=2", folder + "gtfs_L_");
            }

            // For better memory performance.
            GC.Collect();
        }

        private void GTFSSFTimerProc(object state)
        {
            // Locals
            bool bOK = false;

            // For better memory performance.
            GC.Collect();

            if (!_disposed && !_bStopping)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Invoked GTFSTimerProc callback.", "");

                DownloadStaticFeed();
            }

            // For better memory performance.
            GC.Collect();
        }

        private void ServiceStatusTimerProc(object state)
        {
            // Locals
            bool bOK = false;

            // For better memory performance.
            GC.Collect();

            if (!_disposed && !_bStopping)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Invoked ServiceStatusTimerProc callback.", "");

                DownloadServiceStatusFeed();
            }

            // For better memory performance.
            GC.Collect();
        }
         
        private void CleanUpTimerProc(object state)
        {
            // For better memory performance.
            GC.Collect();

            if (!_disposed && !_bStopping)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Invoked CleanUpTimerProc callback.", "");

                DirectoryInfo dataFolder = new DirectoryInfo(Worker.Instance.Configuration.GTFSRealTimeDataFolder);
                // Delete all files in live data folder ie real time gtfs & service status
                foreach (FileInfo file in dataFolder.GetFiles())
                {
                    try
                    {
                        // Even if one of those files fails to delete, continue with others
                        file.Delete();
                    }
                    catch
                    { 
                    }
                }
            }

            // For better memory performance.
            GC.Collect();
        }
        #endregion //Callbacks
    }
}