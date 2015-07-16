//#define SKIP_PARSE_LIMIT_BURST_ISSUE

using System;
using System.Xml;
using System.IO;
using System.IO.Compression;
using System.Collections;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using System.Net;
using System.Xml.Serialization;
using System.Xml.Linq;
using System.Text;
using System.Linq;
using System.Globalization;
using System.Runtime.Serialization;
using System.Collections.ObjectModel;
using GTFS;
using GTFS.IO;
using GTFS.Entities;
using GTFS.Entities.Enumerations;
using ProtoBuf;
using transit_realtime;
using nyct_subway;
using System.Configuration;

namespace Timeplify
{
    /// <summary>
    /// Process MTA.info NYC Subway data and push data into parse cloud.
    /// </summary>
    public class Processor : CDisposableObj
    {
        #region Internal Classes

        #region RealTimeData

        protected internal class RealTimeData : Dictionary<string, RTStationData>
        {
        }

        #endregion RealTimeData

        #region ScheduledData

        protected internal class ScheduledData : Dictionary<string, ScheduledStationData>
        {
        }

        #endregion ScheduledData

        #region ServiceStatusData

        protected internal class ServiceStatusData : Dictionary<string, string>
        {
        }

        #endregion ServiceStatusData

        #region RouteStationBoundsData

        protected internal class RouteStationBoundDataList : List<RouteStationBoundData>
        {   
        }

        #endregion RouteStationBoundsData

        #region RouteStationBoundData

        [DataContract]
        protected internal class RouteStationBoundData
        {
            [DataMember(Name = "i")]
            public string StationId;

            [DataMember(Name = "n")]
            public string NorthBound;

            [DataMember(Name = "s")]
            public string SouthBound;
        }

        #endregion RouteStationBoundData

        #region StationData

        [DataContract]
        protected internal class RTStationData
        {
            public RTStationData()
            {
                South = new List<RTStopData>();
                North = new List<RTStopData>();
            }

            [DataMember(Name = "S")]
            public List<RTStopData> South;

            [DataMember(Name = "N")]
            public List<RTStopData> North;
        }

        [DataContract]
        protected internal class ScheduledStationData
        {
            public ScheduledStationData()
            {
                South = new List<ScheduledStopData>();
                North = new List<ScheduledStopData>();
            }

            [DataMember(Name = "S")]
            public List<ScheduledStopData> South;

            [DataMember(Name = "N")]
            public List<ScheduledStopData> North;
        }

        #endregion StationData

        #region StopData

        [DataContract]
        protected internal class RTStopData : StopData
        {
            [DataMember(Name = "s")]
            public string ServiceId;

            [DataMember(Name = "t")]
            public ulong ArrivalTime;
        }

        [DataContract]
        protected internal class ScheduledStopData : StopData
        {
            [DataMember(Name = "s")]
            public string ServiceId;

            [DataMember(Name = "t")]
            public string ArrivalTime;
        }

        [DataContract]
        protected internal class StopData
        {
            [DataMember(Name = "r")]
            public string RouteId;
        }

        #endregion StopData

        #region Serialize


        #endregion Serialize

        #endregion //Internal Classes

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
        /// Hardcoded values of north & south bound for each route
        /// </summary>
        private Hashtable _routeMap = null;

        private Dictionary<string, string> _arrInterestedRoutes = null;

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
                DownloadStaticFeed();
            }
            catch(Exception e)
            {
                Console.WriteLine("[INFO] Failed to initialize Static Feed Processor. [Error] {0}.", e.Message);
            }
                
            return bRet;
        }
            
        #endregion //CDisposableObj Members
            
        #region Private Methods
            

        private string GetCurrentTimeString()
        {
            return DateTime.Now.ToString(FND_FMT);
        }

        private static readonly DateTime UnixEpoch = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public static DateTime DateTimeFromUnixTimestampSeconds(ulong seconds)
        {
            return UnixEpoch.AddSeconds(seconds);
        }

        private WebProxy GetProxy()
        {
            WebProxy webProxy = null;
            /// Proxy ip address       
            string proxyAddress = null;            
            /// Proxy port
            string port = null;
            ushort proxyPort = 0;

            proxyAddress = ConfigurationManager.AppSettings["proxyAddress"];
            port = ConfigurationManager.AppSettings["proxyPort"];

            if (port != null && 0 < port.Length)
            {
                proxyPort = Convert.ToUInt16(port);
            }

            if ((null != proxyAddress) &&
                (0 < proxyAddress.Length) &&
                (0 < proxyPort))
            {
                webProxy = new WebProxy(proxyAddress, proxyPort);
                webProxy.BypassProxyOnLocal = false;
            }
            return webProxy;
        }       

        // Download and process Static Feed
        private void DownloadStaticFeed()
        {
            // Locals
            string curDT = null;
            string dataFolder = null;
            string remoteUri = null;
            string localFile = null;

            try
            {
                dataFolder = Directory.GetCurrentDirectory() + @"\Input\";

                if (!Directory.Exists(dataFolder))
                {
                    Directory.CreateDirectory(dataFolder);
                }

                curDT = GetCurrentTimeString();
                localFile = dataFolder + curDT + ".gtfs";
                dataFolder = dataFolder + "gtfs_" + curDT;
                remoteUri = ConfigurationManager.AppSettings["staticFeedUrl"];

                // Create a new WebClient instance.
                WebClient webClient = new WebClient();
                webClient.Proxy = GetProxy();
                Console.WriteLine("[INFO] Downloading File \"{0}\" to \"{1}\" .......\n\n", remoteUri, localFile);
                // Download the Web resource and save it into the current filesystem folder.
                webClient.DownloadFile(remoteUri, localFile);
                Console.WriteLine("[INFO] Successfully Downloaded File \"{0}\" to \"{1}\"", remoteUri, localFile);

                ZipFile.ExtractToDirectory(localFile, dataFolder);
                ProcessStaticFeed(dataFolder, curDT);
            }
            catch (Exception e)
            {
                Console.WriteLine("[INFO] Failed to download static feed. [Error] {0}.", e.Message);
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

        // As per the spread sheet sent by Tim, north bound and south bound for each stations are added here
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
                boundsMap.Add("101", new Bounds("", "Downtown"));
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
                boundsMap.Add("401", new Bounds("", "Manhattan"));
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
                boundsMap.Add("247", new Bounds("Manhattan", ""));
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
                boundsMap.Add("D03", new Bounds("", "Manhattan"));
                boundsMap.Add("D04", new Bounds("Bedford Park Blvd", "Manhattan"));
                boundsMap.Add("D05", new Bounds("Bedford Park Blvd", "Manhattan"));
                boundsMap.Add("D06", new Bounds("Bedford Park Blvd", "Manhattan"));
                boundsMap.Add("D07", new Bounds("Bedford Park Blvd", "Manhattan"));
                boundsMap.Add("D08", new Bounds("Bedford Park Blvd", "Manhattan"));
                boundsMap.Add("D09", new Bounds("Bedford Park Blvd", "Manhattan"));
                boundsMap.Add("D10", new Bounds("Bedford Park Blvd", "Manhattan"));
                boundsMap.Add("D11", new Bounds("Bedford Park Blvd", "Manhattan"));
                boundsMap.Add("D12", new Bounds("The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D13", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A14", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A15", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A16", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A17", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A18", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A19", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A20", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A21", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A22", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("A24", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D14", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D15", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D16", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D17", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D20", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D21", new Bounds("Uptown & The Bronx", "Downtown & Brooklyn"));
                boundsMap.Add("D22", new Bounds("Uptown & The Bronx", "Brooklyn"));
                boundsMap.Add("R30", new Bounds("Manhattan", "Brighton Beach"));
                boundsMap.Add("D24", new Bounds("Manhattan", "Brighton Beach"));
                boundsMap.Add("D25", new Bounds("Manhattan", "Brighton Beach"));
                boundsMap.Add("D26", new Bounds("Manhattan", "Brighton Beach"));
                boundsMap.Add("D28", new Bounds("Manhattan", "Brighton Beach"));
                boundsMap.Add("D31", new Bounds("Manhattan", "Brighton Beach"));
                boundsMap.Add("D35", new Bounds("Manhattan", "Brighton Beach"));
                boundsMap.Add("D39", new Bounds("Manhattan", "Brighton Beach"));
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
                boundsMap.Add("D43", new Bounds("Manhattan", ""));
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

        private bool IsInterestedRoute(string route)
        {
            return "SIR" != route;
        }

        private bool IsNotExpressTrains(string route)
        {
            return 'X' != route[route.Length - 1];
        }

        // Process Static Feed
        private void ProcessStaticFeed(string dataFolder, string curDT)
        {
            try
            {
                // Feed Logic
                // 1 Get all trip_id for a given route_id from trips.txt
                // 2 Get all stop_id for a given trip_id from stop_times.txt
                // 3 Do #2 for each trip_id resulted in #1.
                // 4 Get unique stop_id from stops.txt based on the above list.
                Console.WriteLine("[INFO] ProcessStaticFeed BEGIN: " + GetCurrentTimeString());
                int capacity = 51231360;
                // create the reader.
                var reader = new GTFSReader<GTFSFeed>();
                string outputFolder = Directory.GetCurrentDirectory() + @"\Output\" + curDT;
                // execute the reader.
                var feed = reader.Read(new GTFSDirectorySource(new DirectoryInfo(dataFolder)));

                // get all routes
                var routes = new List<Route>(feed.GetRoutes());
                var trips = new List<Trip>(feed.GetTrips());
                var stopTimes = new List<StopTime>(feed.GetStopTimes());
                var stops = new List<Stop>(feed.GetStops());

                int i = 0;

                _arrInterestedRoutes = new Dictionary<string, string>();

            #if (SKIP_PARSE_LIMIT_BURST_ISSUE)
                List<string> interestedRoutes = new List<string>();
                interestedRoutes.Add("R");
                interestedRoutes.Add("6");
            #endif                

                var parentStops = stops.Where(stop => ((0 == stop.ParentStation.Length) || (null == stop.ParentStation))).ToList();

                StringBuilder sbCSV = new StringBuilder(capacity);
                sbCSV.AppendLine(string.Format("{0},{1},{2},{3}", "Id", "Name", "Latitude", "Longitude"));

                foreach (var stop in parentStops)
                {
                    i++;
                    AddStation(stop, i, ref sbCSV);
                }

                if (!Directory.Exists(outputFolder))
                {
                    Directory.CreateDirectory(outputFolder);
                }

                System.IO.StreamWriter file = new System.IO.StreamWriter(outputFolder + @"\Station.csv");
                file.Write(sbCSV.ToString());
                file.Close();
                file.Dispose();
                file = null;

                Console.WriteLine("[INFO] ************SAVED ALL STATIONS****************");

                i = 0;

                sbCSV = new StringBuilder(capacity);
                sbCSV.AppendLine(string.Format("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\"", "Id", "Name", "Image", "NorthStationId", "SouthStationId"));

                StringBuilder sbTrainStop = new StringBuilder(capacity);
                sbTrainStop.AppendLine(string.Format("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\"", "RouteId", "StationId", "North", "South", "DirOrder"));

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
                            if (IsInterestedRoute(route.ShortName) && IsNotExpressTrains(route.Id))
                            {
                                AddRoute(route, routeStops, i, ref sbCSV);

                                Console.WriteLine("[INFO] *********RouteStationMap***************");

                                int j = 0;
                                RouteStationBoundDataList rsbdList = new RouteStationBoundDataList();

                                foreach (var routeStop in routeStops)
                                {
                                    j++;
                                    AddRouteStationBounds(route.Id, routeStop.ParentStation, routeStop.Name, j, ref rsbdList, ref sbTrainStop);
                                }
                            }
                        }
                        else
                        {
                            Console.WriteLine("[INFO] " + i + ".\trouteId\t" + route.Id + "\tZERO STOPS");
                        }
                        #if (SKIP_PARSE_LIMIT_BURST_ISSUE)
                            interestedRoutes.Remove(route.Id);
                        #endif
                    }
                }

                file = new System.IO.StreamWriter(outputFolder + @"\TrainStop.csv");
                file.Write(sbTrainStop.ToString());
                file.Close();
                file.Dispose();
                file = null;

                file = new System.IO.StreamWriter(outputFolder + @"\Train.csv");
                file.Write(sbCSV.ToString());
                file.Close();
                file.Dispose();
                file = null;

                Console.WriteLine("[INFO] ************SAVED ALL ROUTES****************");

                sbCSV = new StringBuilder(capacity);
                sbCSV.AppendLine(string.Format("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\"", "StationID", "Direction", "ServiceID", "RouteId", "ArrivalTime"));                

                int iLen = parentStops.Count;
                i = 0;

                // this is what we need
                foreach (var parentStop in parentStops)
                {                    
                    ScheduledStationData stationData = new ScheduledStationData();
                    ProcessStationTimes(stopTimes, parentStop.Id, "S", trips, ref stationData.South, ref sbCSV, ref i);
                    ProcessStationTimes(stopTimes, parentStop.Id, "N", trips, ref stationData.North, ref sbCSV, ref i);
                }
                file = new System.IO.StreamWriter(outputFolder + @"\ScheduledData.csv");
                file.Write(sbCSV.ToString());
                file.Close();
                file.Dispose();
                file = null;

                Directory.Delete(dataFolder, true);

                Console.WriteLine("[INFO] ************SAVED ALL STOP TIMES****************");
                Console.WriteLine("[INFO] ProcessStaticFeed END: " + GetCurrentTimeString());
            }
            catch (Exception e)
            {
                Console.WriteLine("[INFO] Failed to process static feed. [Error] {0}.", e.Message);
            }
        }

        private void AddRouteStationBounds(string routeId, string stationId, string stopName, int iIndex, ref RouteStationBoundDataList rsbdList, ref StringBuilder csv)
        {
            try
            {
                RouteStationBoundData rsbData = new RouteStationBoundData();
                rsbData.StationId = stationId;
                rsbData.NorthBound = GetDisplayName(routeId, stationId, true);
                rsbData.SouthBound = GetDisplayName(routeId, stationId, false);
                rsbdList.Add(rsbData);

                csv.AppendLine(string.Format("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\"", routeId, stationId, GetDisplayName(routeId, stationId, true), GetDisplayName(routeId, stationId, false), iIndex));

                Console.WriteLine("[INFO] " + iIndex + ".\trouteId\t" + routeId + "\tstationId\t" + stationId + "\tstationName\t" + stopName);
            }
            catch (Exception e)
            {
                Console.WriteLine("[INFO] Failed to add a Stations. [Error] {0}.", e.Message);
            }
        }

        private void AddRoute(Route route, List<Stop> routeStops, int iIndex, ref StringBuilder sb)
        {
            string routeId = null;
            string routeSN = null;

            try
            {
                routeId = GetRouteId(route.Id);

                routeSN = GetRouteId(route.ShortName);

                if (null == (from interestedRoute in _arrInterestedRoutes.Keys
                             where interestedRoute == routeId
                             select interestedRoute).FirstOrDefault())
                {
                    _arrInterestedRoutes.Add(routeId, routeSN);
                }

                sb.AppendLine(string.Format("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\"", routeId, route.ShortName, route.ShortName, routeStops[0].ParentStation, routeStops[routeStops.Count - 1].ParentStation));

                Console.WriteLine("[INFO] " + iIndex + ".\trouteId\t" + route.Id + "\tnorthStationId\t" + routeStops[0].ParentStation
                    + "\tsouthStationId\t" + routeStops[routeStops.Count - 1].ParentStation);
            }
            catch (Exception e)
            {
               Console.WriteLine("[INFO] Failed to add a Route. [Error] {0}.", e.Message);
            }
        }

        private void AddStation(Stop stop, int iIndex, ref StringBuilder sb)
        {
            try
            {
                sb.AppendLine(string.Format("\"{0}\",\"{1}\",\"{2}\",\"{3}\"", stop.Id, stop.Name, stop.Latitude, stop.Longitude));
                Console.WriteLine("[INFO] " + iIndex + ".\tstationId\t" + stop.Id + "\tname\t" + stop.Name);
            }
            catch (Exception e)
            {
                Console.WriteLine("[INFO] Failed to add a Stations. [Error] {0}.", e.Message);
            }
        }

        private string GetRouteId(string routeId)
        {
            string rId = routeId;

            if (2 == routeId.Length && 'X' == routeId[1])
            {
                rId = routeId.Remove(1);
            }

            return rId;
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

        private void AddScheduleData(string stopId, string serviceId, string routeId, TimeOfDay departureTime, string direction, int iIndex, ref List<ScheduledStopData> stopDataList, ref StringBuilder sb, ref int i)
        {
            try
            {
                ScheduledStopData stopData = new ScheduledStopData();
                stopData.RouteId = GetRouteId(routeId);
                stopData.ServiceId = serviceId;
                stopData.ArrivalTime = departureTime.Hours + ":" + departureTime.Minutes + ":" + departureTime.Seconds;
                stopDataList.Add(stopData);

                sb.AppendLine(string.Format("\"{0}\",\"{1}\",\"{2}\",\"{3}\",\"{4}\"", stopId, direction, serviceId, stopData.RouteId, stopData.ArrivalTime));
                i++;

                Console.WriteLine("[INFO] " + iIndex + ".\trouteId\t" + routeId + "\tstationId\t" + stopId
                    + "\tserviceId\t" + serviceId + "\tdepartureTime\t" + stopData.ArrivalTime + "\tdirection\t" + direction
                    );
            }
            catch (Exception e)
            {
               Console.WriteLine("[INFO] Failed to add a Stations. [Error] {0}.", e.Message);
            }
        }

        private void ProcessStationTimes(List<StopTime> stopTimes, String stopId, string direction, List<Trip> trips, ref List<ScheduledStopData> stopDataList, ref StringBuilder sb, ref int j)
        {
            try
            {
                string routeChildStop = stopId + direction;
                var stationTimes = stopTimes.Where(stopTime => (stopTime.StopId == routeChildStop)).
                    OrderBy(stopTime => stopTime.ArrivalTime.Hours).
                    ThenBy(stopTime => stopTime.ArrivalTime.Minutes).
                    ThenBy(stopTime => stopTime.ArrivalTime.Seconds).
                    ToList();

                //var stationTimesA = DistinctBy(stationTimes, stopTime => stopTime.ArrivalTime).ToList();

                Console.WriteLine("[INFO] Total station departure times count" + stationTimes.Count);

                int i = 0;
                foreach (var stationTime in stationTimes)
                {
                    var curTrip = trips.Where(trip => trip.Id == stationTime.TripId).FirstOrDefault();

                    i++;
                    
                #if (SKIP_PARSE_LIMIT_BURST_ISSUE)
                    if ("R" == curTrip.RouteId || "6" == curTrip.RouteId)//TO AVOID BURST LIMIT ISSUE FOR TESTING
                #endif
                    {
                        AddScheduleData(stopId, curTrip.ServiceId, curTrip.RouteId, stationTime.ArrivalTime, direction, i, ref stopDataList, ref sb, ref j);
                    }
                }
            }
            catch (Exception e)
            {
               Console.WriteLine("[INFO] Failed to process station departure times. [Error] {0}.", e.Message);
            }
        }

        #endregion //Private Methods
            
        #region Public Methods
            
        
            
        #endregion //Public Methods
            
        #region Callbacks
        #endregion //Callbacks
    }
}
