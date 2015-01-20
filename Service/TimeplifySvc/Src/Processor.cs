#define SKIP_PARSE_LIMIT_BURST_ISSUE

using System;
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
using System.Globalization;

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

        private const string PT_S_RSB           = "RouteStationBounds";
        private const string PT_S_S             = "Station";
        private const string PT_S_SD            = "ScheduledData";
        private const string PT_S_R             = "Route";
        private const string PT_RT_RTD          = "RealTimeData";

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

        private string _staticCounter = "";
        private string _realTimeCounter = "";

        private ParseObject _poSTSettings = null;
        private ParseObject _poRTSettings = null;
        private ParseObject _poSTSSettings = null;

        private uint _rtMaxCounter = 0;
        private uint _rtCounter = 0;
            
        #endregion //Private Members

        #region Private Properties

        #endregion //Private Properties

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
                //ParseClient.Initialize("zvTZXlTzpGnrccEwEXiokp2UJ7ZusYftc4Wt9B0i", "Bv8UkHYe1WhIiu86rK6boshd0LIXK54k1hC1HP05");
                ParseClient.Initialize("RbAVcTWNVSPFsEXu1xhfmehMhkeBlZqdeyEcXseS", "IHMBICp0kZiMCpVB57PY4x7tpvTSt87AjYvhPccr");
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
                // live data is not available for a given set of stations by only using scheduled data when the previously retrieved live data is older than 5 minutes.
                _rtMaxCounter = ((uint)(5 * 60) / Worker.Instance.Configuration.GTFSRealTimeFeedInterval);

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
                File.Delete(file);
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

        private async void ProcessRTFeed(FeedMessage fm)
        {
            // Locals
            List<ParseObject> listPO = null;

            try
            {
                listPO = new List<ParseObject>();

                foreach(FeedEntity fe in fm.entity)
                {
                    TripUpdate tu = fe.trip_update;
                    if(null != tu)
                    {
                        foreach(TripUpdate.StopTimeUpdate stu in tu.stop_time_update)
                        {
                        #if (SKIP_PARSE_LIMIT_BURST_ISSUE)
                            if ("6" == tu.trip.route_id)//TO AVOID BURST LIMIT ISSUE FOR TESTING
                        #endif
                            {
                                ParseObject poRealTimeData = new ParseObject("RealTimeData");
                                // Last character denoting direction not needed, as we store parent stationid
                                poRealTimeData["stationId"] = stu.stop_id.Remove(stu.stop_id.Length - 1, 1);
                                poRealTimeData["routeId"] = tu.trip.route_id;
                                poRealTimeData["direction"] = (NyctTripDescriptor.Direction.NORTH == tu.trip.nyct_trip_descriptor.direction) ? "N" : "S";
                                poRealTimeData["assigned"] = tu.trip.nyct_trip_descriptor.is_assigned;
                                if (null != stu.departure && 0 != stu.departure.time)
                                {
                                    poRealTimeData["arrivalTime"] = (ulong)stu.departure.time;
                                    poRealTimeData["uid"] = _realTimeCounter;
                                    listPO.Add(poRealTimeData);
                                }
                                else if (null != stu.arrival && 0 != stu.arrival.time)
                                {
                                    poRealTimeData["arrivalTime"] = (ulong)stu.arrival.time;
                                    poRealTimeData["uid"] = _realTimeCounter;
                                    listPO.Add(poRealTimeData);
                                }
                            }
                        }
                    }
                }

                GetSettings("realTime", new string[] { _realTimeCounter, DateTimeFromUnixTimestampSeconds(fm.header.timestamp).ToString(FND_FMT) }, SetRTSettings);
                SaveSettings(_poRTSettings, ref listPO);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Going to save {0} real time objects to parse.", listPO.Count);

                await ParseObject.SaveAllAsync(listPO);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Saved {0} real time objects to parse.", listPO.Count);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to process real time feed. [Error] {0}.", e.Message);
            }
        }

        private async void GetSettings(string settingsKey, string[] settingsValues, SetSettingsCallback ssCallback)
        {
            ParseObject poSettings = null;

            try
            {
                const string TBL_SETTINGS        = "Settings";
                const string COL_SETTINGS_VALUES = "settingsValues";
                const string COL_SETTINGS_KEY    = "settingsKey";

                var query = ParseObject.GetQuery(TBL_SETTINGS);
                poSettings = await query.WhereEqualTo(COL_SETTINGS_KEY, settingsKey).FirstOrDefaultAsync();

                if (null != poSettings)
                {
                    try
                    {
                        await poSettings.DeleteAsync();
                    }
                    catch
                    { 
                    }
                }

                poSettings = new ParseObject(TBL_SETTINGS);
                poSettings[COL_SETTINGS_KEY] = settingsKey;

                foreach (var settingsValue in settingsValues)
                {
                    poSettings.AddToList(COL_SETTINGS_VALUES, settingsValue);
                }

                ssCallback(poSettings);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to get settings for {1}. [Error] {0}.", e.Message, settingsKey);
            }
        }

        private void SaveSettings(ParseObject poSettings, ref List<ParseObject> listPO)
        {
            try
            {
                listPO.Add(poSettings);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to save settings. [Error] {0}.", e.Message);
            }
        }

        private delegate void SetSettingsCallback(ParseObject poSettings);

        private void SetSTSettings(ParseObject poSettings)
        {
            try
            {
                _poRTSettings = poSettings;
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to set static feed settings. [Error] {0}.", e.Message);
            }
        }

        private void SetSTSSettings(ParseObject poSettings)
        {
            try
            {
                _poSTSSettings = poSettings;
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to set status feed settings. [Error] {0}.", e.Message);
            }
        }

        private void SetRTSettings(ParseObject poSettings)
        {
            try
            {
                _poRTSettings = poSettings;
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to set real time feed settings. [Error] {0}.", e.Message);
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

        private async void ProcessStatusFeed(string statusFile)
        {
            try
            {
                XmlDocument xmlDoc = new XmlDocument();
                xmlDoc.Load(statusFile);

                string feedTime = xmlDoc.SelectSingleNode("//timestamp").InnerText;
                DateTime dtfeed = DateTime.ParseExact(feedTime, "M/d/yyyy h:m:s tt", CultureInfo.InvariantCulture);
                string statusFeedTime = dtfeed.ToString("ddMMyyyyHHmmss");

                List<ParseObject> listPO = new List<ParseObject>();

                XmlNodeList xmlNodes = xmlDoc.SelectNodes("//subway/line");

                foreach (XmlNode xmlNode in xmlNodes)
                {
                    string name = xmlNode["name"].InnerText;
                    string status = xmlNode["status"].InnerText;
                    AddInterestedRouteStatus(name, status, statusFeedTime, ref listPO);
                }

                GetSettings("statusTime", new string[] { statusFeedTime }, SetSTSSettings);
                SaveSettings(_poSTSSettings, ref listPO);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Going to save {0} service status objects to parse.", listPO.Count);

                await ParseObject.SaveAllAsync<ParseObject>(listPO);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Saved {0} service status objects to parse.", listPO.Count);
                listPO.Clear();
                
                File.Delete(statusFile);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to process status feed. [Error] {0}.", e.Message);
            }
        }

        private void AddInterestedRouteStatus(string routeId, string status, string statusFeedTime, ref List<ParseObject> listPO)
        {
            string[] arrInterestedRoutes = null;

            try
            {
                if (routeId != "SIR")
                {
                #if (SKIP_PARSE_LIMIT_BURST_ISSUE)
                    arrInterestedRoutes = new string[] { "6" }; //TO AVOID BURST LIMIT ISSUE FOR TESTING
                #else
                    arrInterestedRoutes = new string[] { "1", "2", "3", "4", "5", "6", "L", "S" };
                #endif
                    foreach (string route in arrInterestedRoutes)
                    {
                        if (routeId.Contains(route))
                        {
                            routeId = route;
                            AddRouteStatus(routeId, status, statusFeedTime, ref listPO);
                            //break;
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to add interested Route Status. [Error] {0}.", e.Message);
            }
        }

        private void AddRouteStatus(string routeId, string status, string statusFeedTime, ref List<ParseObject> listPO)
        {
            try
            {
                switch (status)
                {
                    case "GOOD SERVICE":
                        status = "goodService";
                        break;
                    case "DELAYS":
                        status = "delays";
                        break;
                    case "SUSPENDED":
                        status = "suspended";
                        break;
                    case "PLANNED WORK":
                        status = "plannedWork";
                        break;
                    case "SERVICE CHANGE":
                        status = "serviceChange";
                        break;
                }

                ParseObject poServiceStatus = new ParseObject("ServiceStatus");
                poServiceStatus["routeId"] = routeId;
                poServiceStatus["status"] = status;
                poServiceStatus["uid"] = statusFeedTime;
                listPO.Add(poServiceStatus);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to add Route Status. [Error] {0}.", e.Message);
            }
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

                #region Route 2

                boundsMap = new Hashtable();
                boundsMap.Add("201", new Bounds("", "Manhattan"));
                boundsMap.Add("204", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("205", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("206", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("207", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("208", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("209", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("210", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("211", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("212", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("213", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("214", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("215", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("216", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("217", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("218", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("219", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("220", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("221", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("222", new Bounds("Wakefield-241 St", "Manhattan"));
                boundsMap.Add("224", new Bounds("The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("225", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("226", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("227", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("120", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("121", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("122", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("123", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("124", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("125", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("126", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("127", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("128", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("129", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("130", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("131", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("132", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("133", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("134", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("135", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("136", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("137", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("228", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("229", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("230", new Bounds("Uptown & The Bronx", "Brooklyn"));
                boundsMap.Add("231", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("232", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("233", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("234", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("235", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("236", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("237", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("238", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("239", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("241", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("242", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("243", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("244", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("245", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("246", new Bounds("Manhattan", "Flatbush Av - Bklyn College"));
                boundsMap.Add("247", new Bounds("Manhattan", ""));
                _routeMap.Add("2", boundsMap);

                #endregion Route 2

                #region Route 3

                boundsMap = new Hashtable();
                boundsMap.Add("301", new Bounds("", "Downtown & Brooklyn"));
                boundsMap.Add("302", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("224", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("225", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("226", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("227", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("120", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("123", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("127", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("128", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("132", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("137", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("228", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("229", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("230", new Bounds("Uptown", "Brooklyn"));
                boundsMap.Add("231", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("232", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("233", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("234", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("235", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("236", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("237", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("238", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("239", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("248", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("249", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("250", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("251", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("252", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("253", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("254", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("255", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("256", new Bounds("Manhattan", "New Lots Ave"));
                boundsMap.Add("257", new Bounds("Manhattan", ""));
                _routeMap.Add("3", boundsMap);

                #endregion Route 3

                #region Route 4

                boundsMap = new Hashtable();
                boundsMap.Add("401", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("402", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("405", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("406", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("407", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("408", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("409", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("410", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("411", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("412", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("413", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("414", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("415", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("416", new Bounds("Woodlawn", "Manhattan"));
                boundsMap.Add("621", new Bounds("The Bronx", "Manhattan"));
                boundsMap.Add("622", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("623", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("624", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("625", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("626", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("627", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("628", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("629", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("630", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("631", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("632", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("633", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("634", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("635", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("636", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("637", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("638", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("639", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("640", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("418", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("419", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("420", new Bounds("Uptown & The Bronx", "Brooklyn"));
                boundsMap.Add("423", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("234", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("235", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("236", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("237", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("238", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("239", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("248", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("249", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("250", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("251", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("252", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("253", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("254", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("255", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("256", new Bounds("Manhattan", "New Lots Av"));
                boundsMap.Add("257", new Bounds("Manhattan", ""));
                _routeMap.Add("4", boundsMap);

                #endregion Route 4

                #region Route 5

                boundsMap = new Hashtable();
                boundsMap.Add("501", new Bounds("", "Manhattan"));
                boundsMap.Add("502", new Bounds("Eastchester", "Manhattan"));
                boundsMap.Add("503", new Bounds("Eastchester", "Manhattan"));
                boundsMap.Add("504", new Bounds("Eastchester", "Manhattan"));
                boundsMap.Add("505", new Bounds("Eastchester", "Manhattan"));
                boundsMap.Add("204", new Bounds("Nereid Av", "Manhattan"));
                boundsMap.Add("205", new Bounds("Nereid Av", "Manhattan"));
                boundsMap.Add("206", new Bounds("Nereid Av", "Manhattan"));
                boundsMap.Add("207", new Bounds("Nereid Av", "Manhattan"));
                boundsMap.Add("208", new Bounds("Nereid Av", "Manhattan"));
                boundsMap.Add("209", new Bounds("Nereid Av", "Manhattan"));
                boundsMap.Add("210", new Bounds("Nereid Av", "Manhattan"));
                boundsMap.Add("211", new Bounds("Nereid Av", "Manhattan"));
                boundsMap.Add("212", new Bounds("Nereid Av", "Manhattan"));
                boundsMap.Add("213", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("214", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("215", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("216", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("217", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("218", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("219", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("220", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("221", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("222", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("416", new Bounds("Eastchester Or Nereid Av", "Manhattan"));
                boundsMap.Add("621", new Bounds("The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("626", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("629", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("631", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("635", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("640", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("418", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("419", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("420", new Bounds("Uptown & The Bronx", "Brooklyn"));
                boundsMap.Add("423", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("234", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("235", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("239", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("241", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("242", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("243", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("244", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("245", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("246", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                boundsMap.Add("247", new Bounds("Manhattan", "Flatbush Av - Brooklyn College"));
                _routeMap.Add("5", boundsMap);

                #endregion Route 5

                #region Route 5X

                boundsMap = new Hashtable();
                _routeMap.Add("5X", boundsMap);

                #endregion Route 5X

                #region Route 6

                boundsMap = new Hashtable();
                boundsMap.Add("601", new Bounds("", "Manhattan"));
                boundsMap.Add("602", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("603", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("604", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("606", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("607", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("608", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("609", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("610", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("611", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("612", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("613", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("614", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("615", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("616", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("617", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("618", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("619", new Bounds("Pelham Bay Park", "Manhattan"));
                boundsMap.Add("621", new Bounds("The Bronx", "Downtown"));
                boundsMap.Add("622", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("623", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("624", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("625", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("626", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("627", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("628", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("629", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("630", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("631", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("632", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("633", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("634", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("635", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("636", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("637", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("638", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("639", new Bounds("Uptown & The Bronx", "Downtown"));
                boundsMap.Add("640", new Bounds("Uptown & The Bronx", ""));
                _routeMap.Add("6", boundsMap);

                #endregion Route 6

                #region Route 6X

                boundsMap = new Hashtable();
                _routeMap.Add("6X", boundsMap);

                #endregion Route 6X

                #region Route 7

                boundsMap = new Hashtable();
                boundsMap.Add("701", new Bounds("", "Manhattan"));
                boundsMap.Add("702", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("705", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("706", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("707", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("708", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("709", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("710", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("711", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("712", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("713", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("714", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("715", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("716", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("718", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("719", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("720", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("721", new Bounds("Flushing", "Manhattan"));
                boundsMap.Add("723", new Bounds("Queens", "Times Sq - 42 St"));
                boundsMap.Add("724", new Bounds("Queens", "Times Sq - 42 St"));
                boundsMap.Add("725", new Bounds("Queens", ""));
                _routeMap.Add("7", boundsMap);

                #endregion Route 7

                #region Route 7X

                boundsMap = new Hashtable();
                _routeMap.Add("7X", boundsMap);

                #endregion Route 7X

                #region Route A

                boundsMap = new Hashtable();
                boundsMap.Add("A02", new Bounds("", "Downtown & Brooklyn"));
                boundsMap.Add("A03", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A05", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A06", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A07", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A09", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A10", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A11", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A12", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A14", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A15", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A16", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A17", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A18", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A19", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A20", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A21", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A22", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A24", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A25", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A27", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A28", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A30", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A31", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A32", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A33", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A34", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A36", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A38", new Bounds("Uptown", "Brooklyn"));
                boundsMap.Add("A40", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A41", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A42", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A43", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A44", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A45", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A46", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A47", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A48", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A49", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A50", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A51", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A52", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A53", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A54", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A55", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A57", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A59", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A60", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A61", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A62", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A63", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A64", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("A65", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H01", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H02", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H03", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H04", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H06", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H07", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H08", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H09", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H10", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H11", new Bounds("Manhattan", "Far Rockaway"));
                boundsMap.Add("H12", new Bounds("Manhattan", "Rockaway Park"));
                boundsMap.Add("H13", new Bounds("Manhattan", "Rockaway Park"));
                boundsMap.Add("H14", new Bounds("Manhattan", "Rockaway Park"));
                boundsMap.Add("H15", new Bounds("Manhattan", ""));
                _routeMap.Add("A", boundsMap);

                #endregion Route A

                #region Route B

                boundsMap = new Hashtable();
                boundsMap.Add("D03", new Bounds("Bedford Park Blvd", ""));
                boundsMap.Add("D04", new Bounds("Bedford Park Blvd", ""));
                boundsMap.Add("D05", new Bounds("Bedford Park Blvd", ""));
                boundsMap.Add("D06", new Bounds("Bedford Park Blvd", ""));
                boundsMap.Add("D07", new Bounds("Bedford Park Blvd", ""));
                boundsMap.Add("D08", new Bounds("Bedford Park Blvd", ""));
                boundsMap.Add("D09", new Bounds("Bedford Park Blvd", ""));
                boundsMap.Add("D10", new Bounds("Bedford Park Blvd", ""));
                boundsMap.Add("D11", new Bounds("Bedford Park Blvd", ""));
                boundsMap.Add("D12", new Bounds("The Bronx", ""));
                boundsMap.Add("D13", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A14", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A15", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A16", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A17", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A18", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A19", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A20", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A21", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A22", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("A24", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("D14", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("D15", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("D16", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("D17", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("D20", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("D21", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("D22", new Bounds("Uptown & The Bronx", ""));
                boundsMap.Add("R30", new Bounds("Manhattan", ""));
                boundsMap.Add("D24", new Bounds("Manhattan", ""));
                boundsMap.Add("D25", new Bounds("Manhattan", ""));
                boundsMap.Add("D26", new Bounds("Manhattan", ""));
                boundsMap.Add("D28", new Bounds("Manhattan", ""));
                boundsMap.Add("D31", new Bounds("Manhattan", ""));
                boundsMap.Add("D35", new Bounds("Manhattan", ""));
                boundsMap.Add("D39", new Bounds("Manhattan", ""));
                boundsMap.Add("D40", new Bounds("Manhattan", ""));
                _routeMap.Add("B", boundsMap);

                #endregion Route B

                #region Route C

                boundsMap = new Hashtable();
                boundsMap.Add("A09", new Bounds("", "Downtown & Brooklyn"));
                boundsMap.Add("A10", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A11", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A12", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A14", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A15", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A16", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A17", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A18", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A19", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A20", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A21", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A22", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A24", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A25", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A27", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A28", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A30", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A31", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A32", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A33", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A34", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A36", new Bounds("Uptown", "Downtown & Brooklyn"));
                boundsMap.Add("A38", new Bounds("Uptown", "Brooklyn"));
                boundsMap.Add("A40", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A41", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A42", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A43", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A44", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A45", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A46", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A47", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A48", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A49", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A50", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A51", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A52", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A53", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A54", new Bounds("Manhattan", "Euclid Av"));
                boundsMap.Add("A55", new Bounds("Manhattan", ""));
                _routeMap.Add("C", boundsMap);

                #endregion Route C

                #region Route D

                boundsMap = new Hashtable();
                boundsMap.Add("D01", new Bounds("", "Manhattan"));
                boundsMap.Add("D03", new Bounds("Norwood", "Manhattan"));
                boundsMap.Add("D04", new Bounds("Norwood", "Manhattan"));
                boundsMap.Add("D05", new Bounds("Norwood", "Manhattan"));
                boundsMap.Add("D06", new Bounds("Norwood", "Manhattan"));
                boundsMap.Add("D07", new Bounds("Norwood", "Manhattan"));
                boundsMap.Add("D08", new Bounds("Norwood", "Manhattan"));
                boundsMap.Add("D09", new Bounds("Norwood", "Manhattan"));
                boundsMap.Add("D10", new Bounds("Norwood", "Manhattan"));
                boundsMap.Add("D11", new Bounds("Norwood", "Manhattan"));
                boundsMap.Add("D12", new Bounds("The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D13", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A15", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A24", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D14", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D15", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D16", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D17", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D20", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D21", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D22", new Bounds("Uptown & The Bronx", "Brooklyn"));
                boundsMap.Add("R30", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("R31", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("R32", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("R33", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("R34", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("R35", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("R36", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B12", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B13", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B14", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B15", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B16", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B17", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B18", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B19", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B20", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B21", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B22", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("B23", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D43", new Bounds("Manhattan", ""));
                _routeMap.Add("D", boundsMap);

                #endregion Route D

                #region Route E

                boundsMap = new Hashtable();
                boundsMap.Add("G05", new Bounds("", "Manhattan"));
                boundsMap.Add("G06", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G07", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("F05", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("F06", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("F07", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G08", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G09", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G10", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G11", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G12", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G13", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G14", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G15", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G16", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G18", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G19", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G20", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("G21", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("F09", new Bounds("Jamaica Center", "Manhattan"));
                boundsMap.Add("F11", new Bounds("Queens", "Downtown - WTC"));
                boundsMap.Add("F12", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("D14", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("A25", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("A27", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("A28", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("A30", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("A31", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("A32", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("A33", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("A34", new Bounds("Uptown & Queens", "Downtown - WTC"));
                boundsMap.Add("E01", new Bounds("Uptown & Queens", ""));
                _routeMap.Add("E", boundsMap);

                #endregion Route E

                #region Route F

                boundsMap = new Hashtable();
                boundsMap.Add("F01", new Bounds("", "Manhattan"));
                boundsMap.Add("F02", new Bounds("Jamaica - 179 St", "Manhattan"));
                boundsMap.Add("F03", new Bounds("Jamaica - 179 St", "Manhattan"));
                boundsMap.Add("F04", new Bounds("Jamaica - 179 St", "Manhattan"));
                boundsMap.Add("F05", new Bounds("Jamaica - 179 St", "Manhattan"));
                boundsMap.Add("F06", new Bounds("Jamaica - 179 St", "Manhattan"));
                boundsMap.Add("F07", new Bounds("Jamaica - 179 St", "Manhattan"));
                boundsMap.Add("G08", new Bounds("Jamaica - 179 St", "Manhattan"));
                boundsMap.Add("G14", new Bounds("Jamaica - 179 St", "Manhattan"));
                boundsMap.Add("B04", new Bounds("Jamaica - 179 St", "Manhattan"));
                boundsMap.Add("B06", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("B08", new Bounds("Queens", "Downtown & Brooklyn"));
                boundsMap.Add("B10", new Bounds("Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D15", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D16", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D17", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D18", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D19", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D20", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D21", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("F14", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("F15", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("F16", new Bounds("Uptown & Queens", "Brooklyn"));
                boundsMap.Add("F18", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("A41", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F20", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F21", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F22", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F23", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F24", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F25", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F26", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F27", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F29", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F30", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F31", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F32", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F33", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F34", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F35", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F36", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F38", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("F39", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D42", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D43", new Bounds("Manhattan", "Coney Island"));
                _routeMap.Add("F", boundsMap);

                #endregion Route F

                #region Route FS

                boundsMap = new Hashtable();
                boundsMap.Add("D26", new Bounds("", "Botanic Garden"));
                boundsMap.Add("S01", new Bounds("Prospect Park", "Botanic Garden"));
                boundsMap.Add("S03", new Bounds("Prospect Park", "Botanic Garden"));
                boundsMap.Add("S04", new Bounds("Prospect Park", ""));
                _routeMap.Add("FS", boundsMap);

                #endregion Route FS

                #region Route G

                boundsMap = new Hashtable();
                boundsMap.Add("G22", new Bounds("", "Brooklyn"));
                boundsMap.Add("G24", new Bounds("Court Sq", "Brooklyn"));
                boundsMap.Add("G26", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("G28", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("G29", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("G30", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("G31", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("G32", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("G33", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("G34", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("G35", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("G36", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("A42", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("F20", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("F21", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("F22", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("F23", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("F24", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("F25", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("F26", new Bounds("Queens", "Brooklyn"));
                boundsMap.Add("F27", new Bounds("Queens", ""));
                _routeMap.Add("G", boundsMap);

                #endregion Route G

                #region Route GS

                boundsMap = new Hashtable();
                boundsMap.Add("901", new Bounds("", "Times Sq"));
                boundsMap.Add("902", new Bounds("Grand Central", ""));
                _routeMap.Add("GS", boundsMap);

                #endregion Route GS

                #region Route H

                boundsMap = new Hashtable();
                boundsMap.Add("H04", new Bounds("", "Rockaway Park"));
                boundsMap.Add("H12", new Bounds("Broad Channel", "Rockaway Park"));
                boundsMap.Add("H13", new Bounds("Broad Channel", "Rockaway Park"));
                boundsMap.Add("H14", new Bounds("Broad Channel", "Rockaway Park"));
                boundsMap.Add("H15", new Bounds("Broad Channel", ""));
                _routeMap.Add("H", boundsMap);

                #endregion Route H

                #region Route J

                boundsMap = new Hashtable();
                boundsMap.Add("G05", new Bounds("", "Brooklyn & Manhattan"));
                boundsMap.Add("G06", new Bounds("Jamaica Center", "Brooklyn & Manhattan"));
                boundsMap.Add("J12", new Bounds("Jamaica Center", "Brooklyn & Manhattan"));
                boundsMap.Add("J13", new Bounds("Jamaica Center", "Brooklyn & Manhattan"));
                boundsMap.Add("J14", new Bounds("Jamaica Center", "Brooklyn & Manhattan"));
                boundsMap.Add("J15", new Bounds("Jamaica Center", "Brooklyn & Manhattan"));
                boundsMap.Add("J16", new Bounds("Jamaica Center", "Brooklyn & Manhattan"));
                boundsMap.Add("J17", new Bounds("Jamaica Center", "Brooklyn & Manhattan"));
                boundsMap.Add("J19", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J20", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J21", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J22", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J23", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J24", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J27", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J28", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J29", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J30", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J31", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("M11", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("M12", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("M13", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("M14", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("M16", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("M18", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M19", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M20", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M21", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M22", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M23", new Bounds("Brooklyn", ""));
                _routeMap.Add("J", boundsMap);

                #endregion Route J

                #region Route L

                boundsMap = new Hashtable();
                boundsMap.Add("L01", new Bounds("", "Brooklyn"));
                boundsMap.Add("L02", new Bounds("8th Av", "Brooklyn"));
                boundsMap.Add("L03", new Bounds("8th Av", "Brooklyn"));
                boundsMap.Add("L05", new Bounds("8th Av", "Brooklyn"));
                boundsMap.Add("L06", new Bounds("8th Av", "Brooklyn"));
                boundsMap.Add("L08", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L10", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L11", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L12", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L13", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L14", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L15", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L16", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L17", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L19", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L20", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L21", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L22", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L24", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L25", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L26", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L27", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L28", new Bounds("Manhattan", "Canarsie-Rockaway Pkwy"));
                boundsMap.Add("L29", new Bounds("Manhattan", ""));
                _routeMap.Add("L", boundsMap);

                #endregion Route L

                #region Route M

                boundsMap = new Hashtable();
                boundsMap.Add("G08", new Bounds("", "Manhattan"));
                boundsMap.Add("G09", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G10", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G11", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G12", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G13", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G14", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G15", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G16", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G18", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G19", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G20", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("G21", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("F09", new Bounds("Forest Hills", "Manhattan"));
                boundsMap.Add("F11", new Bounds("Queens", "Downtown & Brooklyn"));
                boundsMap.Add("F12", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D15", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D16", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D17", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D18", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D19", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D20", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("D21", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("M18", new Bounds("Uptown & Queens", "Brooklyn"));
                boundsMap.Add("M16", new Bounds("Manhattan", "Queens"));
                boundsMap.Add("M14", new Bounds("Manhattan", "Queens"));
                boundsMap.Add("M12", new Bounds("Manhattan", "Queens"));
                boundsMap.Add("M11", new Bounds("Manhattan", "Queens"));
                boundsMap.Add("M10", new Bounds("Manhattan", "Queens"));
                boundsMap.Add("M09", new Bounds("Manhattan", "Queens"));
                boundsMap.Add("M08", new Bounds("Manhattan", "Queens"));
                boundsMap.Add("M06", new Bounds("Brooklyn", "Middle Village - Metropolitan Av"));
                boundsMap.Add("M05", new Bounds("Brooklyn", "Middle Village - Metropolitan Av"));
                boundsMap.Add("M04", new Bounds("Brooklyn", "Middle Village - Metropolitan Av"));
                boundsMap.Add("M01", new Bounds("Brooklyn", ""));
                _routeMap.Add("M", boundsMap);

                #endregion Route M

                #region Route N

                boundsMap = new Hashtable();
                boundsMap.Add("R01", new Bounds("", "Manhattan"));
                boundsMap.Add("R03", new Bounds("Astoria - Ditmars Blvd", "Manhattan"));
                boundsMap.Add("R04", new Bounds("Astoria - Ditmars Blvd", "Manhattan"));
                boundsMap.Add("R05", new Bounds("Astoria - Ditmars Blvd", "Manhattan"));
                boundsMap.Add("R06", new Bounds("Astoria - Ditmars Blvd", "Manhattan"));
                boundsMap.Add("R08", new Bounds("Astoria - Ditmars Blvd", "Manhattan"));
                boundsMap.Add("R09", new Bounds("Astoria - Ditmars Blvd", "Manhattan"));
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
                boundsMap.Add("R28", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R29", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R30", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R31", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R32", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R33", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R34", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R35", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R36", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R39", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R40", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("R41", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("N02", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("N03", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("N04", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("N05", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("N06", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("N07", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("N08", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("N09", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("N10", new Bounds("Manhattan", "Coney Island "));
                boundsMap.Add("D43", new Bounds("Manhattan", ""));
                _routeMap.Add("N", boundsMap);

                #endregion Route N

                #region Route Q

                boundsMap = new Hashtable();
                boundsMap.Add("R01", new Bounds("", "Manhattan"));
                boundsMap.Add("R03", new Bounds("Astoria", "Manhattan"));
                boundsMap.Add("R04", new Bounds("Astoria", "Manhattan"));
                boundsMap.Add("R05", new Bounds("Astoria", "Manhattan"));
                boundsMap.Add("R06", new Bounds("Astoria", "Manhattan"));
                boundsMap.Add("R08", new Bounds("Astoria", "Manhattan"));
                boundsMap.Add("R09", new Bounds("Astoria", "Manhattan"));
                boundsMap.Add("R11", new Bounds("Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R13", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R14", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R15", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R16", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R17", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R20", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R21", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R22", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("Q01", new Bounds("Uptown & Queens", "Downtown & Brooklyn"));
                boundsMap.Add("R30", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D24", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D25", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D26", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D27", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D28", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D29", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D30", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D31", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D32", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D33", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D34", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D35", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D37", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D38", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D39", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D40", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D41", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D42", new Bounds("Manhattan", "Coney Island"));
                boundsMap.Add("D43", new Bounds("Manhattan", ""));
                _routeMap.Add("Q", boundsMap);

                #endregion Route Q


                #region Route R
                boundsMap = new Hashtable();
                boundsMap.Add("G08", new Bounds("", "Manhattan"));
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

                #region Route S

                boundsMap = new Hashtable();
                _routeMap.Add("S", boundsMap);

                #endregion Route S

                #region Route SI

                boundsMap = new Hashtable();
                _routeMap.Add("SI", boundsMap);

                #endregion Route SI

                #region Route Z

                boundsMap = new Hashtable();
                boundsMap.Add("G05", new Bounds("", "Queens"));
                boundsMap.Add("G06", new Bounds("Jamaica Ctr", "Queens"));
                boundsMap.Add("J12", new Bounds("Jamaica Ctr", "Queens"));
                boundsMap.Add("J14", new Bounds("Jamaica Ctr", "Queens"));
                boundsMap.Add("J15", new Bounds("Jamaica Ctr", "Queens"));
                boundsMap.Add("J17", new Bounds("Jamaica Ctr", "Queens"));
                boundsMap.Add("J20", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J21", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J23", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J24", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J27", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J28", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("J30", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("M11", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("M16", new Bounds("Queens", "Manhattan"));
                boundsMap.Add("M18", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M19", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M20", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M21", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M22", new Bounds("Brooklyn", "Broad St"));
                boundsMap.Add("M23", new Bounds("Brooklyn", ""));
                _routeMap.Add("Z", boundsMap);

                #endregion Route Z
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

                _staticCounter = GetCurrentTimeString();

                List<ParseObject> listStaticPO = new List<ParseObject>();

            #if (SKIP_PARSE_LIMIT_BURST_ISSUE)
                List<string> interestedRoutes = new List<string>();
                interestedRoutes.Add("R");
                interestedRoutes.Add("6");
            #endif
                int i = 0;

                var parentStops = stops.Where(stop => ((0 == stop.ParentStation.Length) || (null == stop.ParentStation))).ToList();

                foreach (var stop in parentStops)
                {
                    i++;
                    AddStation(stop, i, ref listStaticPO);
                }

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Going to save {0} static station objects to parse.", listStaticPO.Count);

                await ParseObject.SaveAllAsync<ParseObject>(listStaticPO);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Saved {0} static station objects to parse.", listStaticPO.Count);
                listStaticPO.Clear();

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "************SAVED ALL STATIONS****************");

                i = 0;

                foreach (var route in routes)
                {
                    i++;
                #if (SKIP_PARSE_LIMIT_BURST_ISSUE)
                    if (0 == interestedRoutes.Count)
                    {
                        break;
                    }
                    if ("R" == route.Id || "6" == route.Id)//TO AVOID BURST LIMIT ISSUE FOR TESTING
                #endif
                    {                        
                        var routeStops = (from stop in stops
                                          join stopTime in stopTimes on stop.Id equals stopTime.StopId
                                          join trip in trips on stopTime.TripId equals trip.Id
                                          where trip.Direction == GTFS.Entities.Enumerations.DirectionType.OneDirection//North to south
                                          join myroute in routes on trip.RouteId equals myroute.Id
                                          where myroute.Id == route.Id
                                          select stop).Distinct().ToList();

                        if (0 < routeStops.Count)
                        {
                            ParseObject poRoute = AddRoute(route, routeStops, i);

                            Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "*********RouteStationMap***************");

                            int j = 0;

                            foreach (var routeStop in routeStops)
                            {
                                j++;
                                AddRouteStationBounds(route.Id, routeStop.ParentStation, routeStop.Name, j, ref poRoute, ref listStaticPO);
                            }
                            listStaticPO.Add(poRoute);
                        }
                        else
                        {
                            Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, i + ".\trouteId\t" + route.Id + "\tZERO STOPS");
                        }
                        interestedRoutes.Remove(route.Id);
                    }
                }
                
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Going to save {0} static routestationbounds objects to parse.", listStaticPO.Count);

                await ParseObject.SaveAllAsync<ParseObject>(listStaticPO);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Saved {0} static routestationbounds objects to parse.", listStaticPO.Count);
                listStaticPO.Clear();

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "************SAVED ALL ROUTES****************");

                // this is what we need
                foreach (var parentStop in parentStops)
                {
                    ProcessStationTimes(stopTimes, parentStop.Id, "S", trips, ref listStaticPO);
                    ProcessStationTimes(stopTimes, parentStop.Id, "N", trips, ref listStaticPO);

                    Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Going to save {0} static scheduleddata objects to parse.", listStaticPO.Count);

                    await ParseObject.SaveAllAsync<ParseObject>(listStaticPO);

                    Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Saved {0} static scheduleddata objects to parse.", listStaticPO.Count);
                    listStaticPO.Clear();
                }

                GetSettings("staticTime", new string[] { _staticCounter }, SetSTSettings);
                SaveSettings(_poSTSettings, ref listStaticPO);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Going to save {0} static settings objects to parse.", listStaticPO.Count);

                await ParseObject.SaveAllAsync<ParseObject>(listStaticPO);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Saved {0} static settings objects to parse.", listStaticPO.Count);
                listStaticPO.Clear();

                Directory.Delete(dataFolder, true);

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "************SAVED ALL STOP TIMES****************");

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "ProcessStaticFeed END: " + GetCurrentTimeString());
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to process static feed. [Error] {0}.", e.Message);
            }
        }

        private void AddRouteStationBounds(string routeId, string stationId, string stopName, int iIndex, ref ParseObject poRoute, ref List<ParseObject> listStaticPO)
        {
            try
            {
                poRoute.AddToList("stations", stationId);
                ParseObject poRouteStationBounds = new ParseObject("RouteStationBounds");
                poRouteStationBounds["routeId"] = routeId;
                poRouteStationBounds["stationId"] = stationId;
                poRouteStationBounds["northBound"] = GetDisplayName(routeId, stationId, true);
                poRouteStationBounds["southBound"] = GetDisplayName(routeId, stationId, false);
                poRouteStationBounds["uid"] = _staticCounter;
                listStaticPO.Add(poRouteStationBounds);
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, iIndex + ".\trouteId\t" + routeId + "\tstationId\t" + stationId + "\tstationName\t" + stopName);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to add a Stations. [Error] {0}.", e.Message);
            }
        }

        private void AddStation(Stop stop, int iIndex, ref List<ParseObject> listStaticPO)
        {
            try
            {
                ParseObject poStation = new ParseObject("Station");
                poStation["stationId"] = stop.Id;
                poStation["name"] = stop.Name;
                poStation["latitude"] = stop.Latitude;
                poStation["longitude"] = stop.Longitude;
                poStation["uid"] = _staticCounter;
                listStaticPO.Add(poStation);
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, iIndex + ".\tstationId\t" + stop.Id + "\tname\t" + stop.Name);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to add a Stations. [Error] {0}.", e.Message);
            }
        }

        private ParseObject AddRoute(Route route, List<Stop> routeStops, int iIndex)
        {
            ParseObject poRoute = null;

            try
            {
                poRoute = new ParseObject("Route");
                poRoute["routeId"] = route.Id;
                poRoute["shortName"] = route.ShortName;
                poRoute["backgroundColor"] = route.Color;
                poRoute["textColor"] = route.TextColor;
                poRoute["northStationId"] = routeStops[0].ParentStation;
                poRoute["southStationId"] = routeStops[routeStops.Count - 1].ParentStation;
                poRoute["uid"] = _staticCounter;

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, iIndex + ".\trouteId\t" + route.Id + "\tnorthStationId\t" + routeStops[0].ParentStation
                    + "\tsouthStationId\t" + routeStops[routeStops.Count - 1].ParentStation);
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to add a Route. [Error] {0}.", e.Message);
            }

            return poRoute;
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

        private void AddScheduleData(string stopId, string routeId, TimeOfDay departureTime, string direction, int iIndex, ref List<ParseObject> listStaticPO)
        {
            try
            {
                ParseObject poSData = new ParseObject("ScheduledData");

                poSData["stationId"] = stopId;
                poSData["routeId"] = routeId;
                poSData["arrivalTime"] = departureTime.Hours + ":" + departureTime.Minutes + ":" + departureTime.Seconds;
                poSData["direction"] = direction;
                poSData["uid"] = _staticCounter;
                listStaticPO.Add(poSData);
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, iIndex + ".\trouteId\t" + routeId + "\tstationId\t" + stopId
                    + "\tdepartureTime\t" + poSData["arrivalTime"] + "\tdirection\t" + direction
                    );
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to add a Stations. [Error] {0}.", e.Message);
            }
        }

        private void ProcessStationTimes(List<StopTime> stopTimes, String stopId, string direction, List<Trip> trips, ref List<ParseObject> listStaticPO)
        {
            try
            {
                string routeChildStop = stopId + direction;
                var stationTimes = stopTimes.Where(stopTime => (stopTime.StopId == routeChildStop)).
                    OrderBy(stopTime => stopTime.DepartureTime.Hours).
                    ThenBy(stopTime => stopTime.DepartureTime.Minutes).
                    ThenBy(stopTime => stopTime.DepartureTime.Seconds).
                    ToList();

                var stationTimesD = DistinctBy(stationTimes, stopTime => stopTime.DepartureTime).ToList();

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Total station departure times count" + stationTimesD.Count);

                int i = 0;
                foreach (var stationTime in stationTimesD)
                {
                    var curTrip = trips.Where(trip => trip.Id == stationTime.TripId).FirstOrDefault();

                    i++;
                    
                #if (SKIP_PARSE_LIMIT_BURST_ISSUE)
                    if ("R" == curTrip.RouteId || "6" == curTrip.RouteId)//TO AVOID BURST LIMIT ISSUE FOR TESTING
                #endif
                    {
                        AddScheduleData(stopId, curTrip.RouteId, stationTime.DepartureTime, direction, i, ref listStaticPO);
                    }
                }
            }
            catch (Exception e)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to process station departure times. [Error] {0}.", e.Message);
            }
        }

        #endregion //Private Methods
            
        #region Public Methods
            
        
            
        #endregion //Public Methods
            
        #region Callbacks
            
        private void GTFSRTFTimerProc(object state)
        {
            // Locals
            string url = null;
            string folder = null;

            // For better memory performance.
            GC.Collect();
                
            if(!_disposed && !_bStopping)
            {
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Invoked GTFSTimerProc callback.", "");

                if (0 == _rtCounter)
                {
                    // live data is not available for a given set of stations by only using scheduled data when the previously retrieved live data is older than 5 minutes.
                    _realTimeCounter = GetCurrentTimeString();
                }

                _rtCounter++;
                
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

                if (_rtMaxCounter <= _rtCounter)
                {
                    _rtCounter = 0;
                }
            }

            // For better memory performance.
            GC.Collect();
        }

        private void GTFSSFTimerProc(object state)
        {
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
