using System;
using System.Collections;
using System.IO;
using System.Xml;
using System.Reflection;

namespace Timeplify
{
    /// <summary>
    /// [Firmusoft] Rsponsible for maintaining the configuration system needed for all CSS Export operations.             
    /// </summary>
    public class Config : CDisposableObj
    {
        #region Constants

        private const ushort DEF_RTF_REFRESH = 30;
        private const ushort DEF_SF_REFRESH = 120;
        private const ushort DEF_SS_REFRESH = 60;
        private const ushort DEF_LOG_SIZE = 6000;
        private const string DEF_RTF_URL = "http://datamine.mta.info/mta_esi.php?key=";
        private const string DEF_SF_URL = "http://web.mta.info/developers/data/nyct/subway/google_transit.zip";
        private const string DEF_SS_URL = "http://web.mta.info/status/serviceStatus.txt";
        private const LogPriorityLevel DEF_LOG_LEVEL = LogPriorityLevel.Informational;
        private static string DEF_RTF_DATA = Worker.Instance.ApplicationPath + @"\MTA\NYC-Transit\Subway\Data\Live\";
        private static string DEF_SF_DATA = Worker.Instance.ApplicationPath + @"\MTA\NYC-Transit\Subway\Data\Scheduled\";
        private static string DEF_LOG_PATH = Worker.Instance.ApplicationPath + @"\Logs";
        private static string DEF_LOG_NAME = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;

        private const string ATTR_FOLDER = "folder";
        private const string ATTR_SIZE = "size";
        private const string ATTR_LEVEL = "level";
        private const string ATTR_REFRESH = "refresh";
        private const string ATTR_URL = "url";
        private const string ATTR_DATA = "data";
        private const string ATTR_ADDR = "address";
        private const string ATTR_PORT = "port";
        
        private const string NODE_CONF = "configuration";
        private const string NODE_LOG = "log";
        
        private const string NODE_GTFS  = "gtfs";
        private const string NODE_SBWY  = "subway";
        private const string NODE_RTF   = "realTimeFeed";
        private const string NODE_SF    = "staticFeed";
        private const string NODE_STSF  = "statusFeed";

        private const string NODE_PROXY = "proxy";

        private const string XPATH_ROOT = "//";
        private const string XPATH_SEP = "/";

        #endregion Constants

        #region Private Members

        /// <summary>
        /// Log file size.
        /// </summary>
        private int _logSize = DEF_LOG_SIZE;

        /// <summary>
        /// Full path to the folder where to save the log.
        /// </summary>
        private string _logFolder = DEF_LOG_PATH;

        /// <summary>
        /// Log level.
        /// </summary>
        private LogPriorityLevel _logLevel = DEF_LOG_LEVEL;

        /// <summary>
        /// Application log File name
        /// </summary>
        private string _appLogFileName = DEF_LOG_NAME;

        /// <summary>
        /// Interval in seconds to retrieve GTFS real time feed
        /// </summary>
        private ushort _gtfsRTFInterval = DEF_RTF_REFRESH;

        /// <summary>
        /// GTFS real time feed url
        /// </summary>
        private string _gtfsRTFUrl = DEF_RTF_URL;

        /// <summary>
        /// GTFS real time feed data folder
        /// </summary>
        private string _gtfsRTFData = DEF_RTF_DATA;

        /// <summary>
        /// Interval in days to retrieve Static feed
        /// </summary>
        private ushort _gtfsSFInterval = DEF_SF_REFRESH;

        /// <summary>
        /// GTFS static feed url
        /// </summary>
        private string _gtfsSFUrl = DEF_SF_URL;

        /// <summary>
        /// GTFS static feed data folder
        /// </summary>
        private string _gtfsSFData = DEF_SF_DATA;

        /// <summary>
        /// MTA subway service status url
        /// </summary>
        private string _serviceStatusUrl = DEF_SS_URL;

        /// <summary>
        /// Interval in seconds to retrieve MTA subway service status feed
        /// </summary>
        private ushort _serviceStatusInterval = DEF_SS_REFRESH;

        /// <summary>
        /// Proxy ip address
        /// </summary>
        private string _proxyAddress = null;

        /// <summary>
        /// Proxy port
        /// </summary>
        private ushort _proxyPort = 0;

        #endregion //Private Members

        #region Constructor

        public Config()
        {
        }

        #endregion //Constructor

        #region Destructor

        ~Config()
        {
        }

        #endregion //Destructor

        #region Properties

        /// <summary>
        /// Full path to the folder where to save the log.
        /// </summary>
        public string LogFolder
        {
            get
            {
                return _logFolder;
            }
        }

        /// <summary>
        /// Log file size.
        /// </summary>
        public int LogSize
        {
            get
            {
                return _logSize;
            }
        }

        /// <summary>
        /// Log level.
        /// </summary>
        public LogPriorityLevel LogLevel
        {
            get
            {
                return _logLevel;
            }
        }

        /// <summary>
        /// Application log file name
        /// </summary>
        public string LogFileName
        {
            get
            {
                return _appLogFileName;
            }
        }

        /// <summary>
        /// Interval in seconds to retrieve GTFS real time feed
        /// </summary>
        public ushort GTFSRealTimeFeedInterval
        {
            get
            {
                return _gtfsRTFInterval;
            }
        }

        /// <summary>
        /// GTFS real time feed url
        /// </summary>
        public string GTFSRealTimeFeedURL
        {
            get
            {
                return _gtfsRTFUrl + "d3e0e8b948b118597b708bea5e5e786b";
            }
        }

        /// <summary>
        /// GTFS real time feed data folder
        /// </summary>
        public string GTFSRealTimeDataFolder
        {
            get
            {
                return _gtfsRTFData;
            }
        }

        /// <summary>
        /// Interval in seconds to retrieve GTFS static feed
        /// </summary>
        public uint GTFSStaticFeedInterval
        {
            get
            {
                // convert to seconds
                return Convert.ToUInt32(_gtfsSFInterval * 24 * 60 * 60);
            }
        }

        /// <summary>
        /// GTFS static feed url
        /// </summary>
        public string GTFSStaticFeedURL
        {
            get
            {
                // append key
                return _gtfsSFUrl;
            }
        }

        /// <summary>
        /// GTFS static feed data folder
        /// </summary>
        public string GTFSStaticDataFolder
        {
            get
            {
                return _gtfsSFData;
            }
        }

        /// <summary>
        /// Interval in seconds to retrieve MTA subway service status feed
        /// </summary>
        public ushort ServiceStatusInterval
        {
            get
            {
                return _serviceStatusInterval;
            }
        }

        /// <summary>
        /// MTA subway service status url
        /// </summary>
        public string ServiceStatusFeedURL
        {
            get
            {
                // append key
                return _serviceStatusUrl;
            }
        }

        /// <summary>
        /// Proxy ip address
        /// </summary>
        public string ProxyAddress
        {
            get
            {
                return _proxyAddress;
            }
        }

        /// <summary>
        /// Proxy port
        /// </summary>
        public ushort ProxyPort
        {
            get
            {
                return _proxyPort;
            }
        }

        #endregion //Properties        

        #region Public Methods        

        /// <summary>
        /// Loads the configuration from the application directory.
        /// </summary>
        /// <returns>true if success.</returns>
        private bool Load()
        {
            // Locals
            bool bRet = false;
            XmlDocument xmlDoc = null;
            string strFile = null;
            XmlNode xmlNode = null;

            try
            {
                strFile = System.Reflection.Assembly.GetExecutingAssembly().Location.Replace(".exe", ".config");

                xmlDoc = new XmlDocument();
                xmlDoc.Load(strFile);

                xmlNode = xmlDoc.SelectSingleNode(XPATH_ROOT + NODE_CONF + XPATH_SEP + NODE_LOG);
                if (null != xmlNode)
                {
                    if (IsAttrEmpty(xmlNode, ATTR_FOLDER))
                    {
                        _logFolder = DEF_LOG_PATH;
                    }
                    else
                    {
                        _logFolder = xmlNode.Attributes[ATTR_FOLDER].InnerText;
                        strFile = _logFolder;
                    }

                    bool bLogDirErr = false;

                    if (0 == _logFolder.Length || !Directory.Exists(_logFolder))
                    {
                        bLogDirErr = true;
                    }

                    if (IsAttrEmpty(xmlNode, ATTR_SIZE))
                    {
                        _logSize = DEF_LOG_SIZE;
                    }
                    else
                    {
                        _logSize = Convert.ToInt32(xmlNode.Attributes[ATTR_SIZE].InnerText);
                    }

                    if (IsAttrEmpty(xmlNode, ATTR_SIZE))
                    {
                        _logLevel = DEF_LOG_LEVEL;
                    }
                    else
                    {
                        _logLevel = (LogPriorityLevel)Enum.Parse(typeof(LogPriorityLevel), xmlNode.Attributes[ATTR_LEVEL].InnerText);
                    }

                    if (bLogDirErr)
                    {
                        InitLogger();
                        Worker.Instance.Logger.LogMessage(LogPriorityLevel.NonFatalError, "Failed to load log folder {0} so now using application folder {1}.", strFile, _logFolder);
                    }
                }

                xmlNode = xmlDoc.SelectSingleNode(XPATH_ROOT + NODE_CONF + XPATH_SEP + NODE_PROXY);
                if (null != xmlNode)
                {
                    if (!IsAttrEmpty(xmlNode, ATTR_ADDR))
                    {
                        _proxyAddress = xmlNode.Attributes[ATTR_ADDR].InnerText;
                    }

                    if (!IsAttrEmpty(xmlNode, ATTR_PORT))
                    {
                        _proxyPort = Convert.ToUInt16(xmlNode.Attributes[ATTR_PORT].InnerText);
                    }
                }

                xmlNode = xmlDoc.SelectSingleNode(XPATH_ROOT + NODE_CONF + XPATH_SEP + NODE_GTFS + XPATH_SEP + NODE_SBWY + XPATH_SEP + NODE_STSF);
                if (null != xmlNode)
                {
                    if (IsAttrEmpty(xmlNode, ATTR_REFRESH))
                    {
                        _serviceStatusInterval = DEF_SS_REFRESH;
                    }
                    else
                    {
                        _serviceStatusInterval = Convert.ToUInt16(xmlNode.Attributes[ATTR_REFRESH].InnerText);
                    }

                    if (IsAttrEmpty(xmlNode, ATTR_URL))
                    {
                        _serviceStatusUrl = DEF_SS_URL;
                    }
                    else
                    {
                        _serviceStatusUrl = xmlNode.Attributes[ATTR_URL].InnerText;
                    }
                }
                else
                {
                    _serviceStatusInterval = DEF_SS_REFRESH;
                    _serviceStatusUrl = DEF_SS_URL;
                }

                xmlNode = xmlDoc.SelectSingleNode(XPATH_ROOT + NODE_CONF + XPATH_SEP + NODE_GTFS + XPATH_SEP + NODE_SBWY + XPATH_SEP + NODE_RTF);
                if (null != xmlNode)
                {
                    if (IsAttrEmpty(xmlNode, ATTR_REFRESH))
                    {
                        _gtfsRTFInterval = DEF_RTF_REFRESH;
                    }
                    else
                    {
                        _gtfsRTFInterval = Convert.ToUInt16(xmlNode.Attributes[ATTR_REFRESH].InnerText);
                    }

                    if (IsAttrEmpty(xmlNode, ATTR_URL))
                    {
                        _gtfsRTFUrl = DEF_RTF_URL;
                    }
                    else
                    {
                        _gtfsRTFUrl = xmlNode.Attributes[ATTR_URL].InnerText;
                    }

                    if (IsAttrEmpty(xmlNode, ATTR_DATA))
                    {
                        _gtfsRTFData = DEF_RTF_DATA;
                    }
                    else
                    {
                        _gtfsRTFData = xmlNode.Attributes[ATTR_DATA].InnerText;
                    }
                }
                else
                {
                    _gtfsRTFInterval = DEF_RTF_REFRESH;
                    _gtfsRTFUrl = DEF_RTF_URL;
                    _gtfsRTFData = DEF_RTF_DATA; 
                }

                xmlNode = xmlDoc.SelectSingleNode(XPATH_ROOT + NODE_CONF + XPATH_SEP + NODE_GTFS + XPATH_SEP + NODE_SBWY + XPATH_SEP + NODE_SF);
                if (null != xmlNode)
                {
                    if (IsAttrEmpty(xmlNode, ATTR_REFRESH))
                    {
                        _gtfsSFInterval = DEF_SF_REFRESH;
                    }
                    else
                    {
                        _gtfsSFInterval = Convert.ToUInt16(xmlNode.Attributes[ATTR_REFRESH].InnerText);
                    }

                    if (IsAttrEmpty(xmlNode, ATTR_URL))
                    {
                        _gtfsSFUrl = DEF_SF_URL;
                    }
                    else
                    {
                        _gtfsSFUrl = xmlNode.Attributes[ATTR_URL].InnerText;
                    }

                    if (IsAttrEmpty(xmlNode, ATTR_DATA))
                    {
                        _gtfsSFData = DEF_SF_DATA;
                    }
                    else
                    {
                        _gtfsSFData = xmlNode.Attributes[ATTR_DATA].InnerText;
                    }
                }
                else
                {
                    _gtfsSFInterval = DEF_SF_REFRESH;
                    _gtfsSFUrl = DEF_SF_URL;
                    _gtfsSFData = DEF_SF_DATA;
                }

                InitLogger();

                bRet = true;

                if (!bRet)
                {
                    bRet = SetDefaultValues();
                }
            }
            catch (Exception ex)
            {
                InitLogger();
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to load configuration. [Error] {0}.", ex.Message);

                if (!bRet)
                {
                    bRet = SetDefaultValues();
                }
            }

            return bRet;
        }

        /// <summary>
        /// Not used now.
        /// </summary>
        /// <returns>false for now.</returns>
        public bool Save()
        {
            //For future use
            return false;
        }

        #endregion //Public Methods

        #region CDisposableObj Members

        protected override bool Initialize()
        {
            return Load();
        }

        protected override bool UnInitialize()
        {
            _logSize = 0;
            _logLevel = LogPriorityLevel.NoLogging;

            return base.UnInitialize();
        }

        #endregion //CDisposableObj Members

        #region Private Methods

        private void InitLogger()
        {
            if (null == Worker.Instance.Logger)
            {
                Worker.Instance.Logger = new Logger(_logFolder, _appLogFileName, _logSize);
            }
        }

        private bool IsAttrEmpty(XmlNode xmlNode, string attrName)
        {
            // Locals
            bool bIsEmpty = true;
            XmlAttribute xmlAttr = null;

            if (null != xmlNode)
            {
                xmlAttr = xmlNode.Attributes[attrName];

                if (null != xmlAttr)
                {
                    bIsEmpty = (0 == xmlAttr.InnerText.Length);
                }
            }

            return bIsEmpty;
        }

        private bool SetDefaultValues()
        {
            // Locals
            bool bRet = false;

            try
            {
                InitLogger();
                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Loading default configuration");

                _logFolder = DEF_LOG_PATH;
                _logSize = DEF_LOG_SIZE;
                _logLevel = DEF_LOG_LEVEL;
                _appLogFileName = DEF_LOG_NAME;
                _serviceStatusInterval = DEF_SS_REFRESH;
                _serviceStatusUrl = DEF_SS_URL;
                _gtfsRTFInterval = DEF_RTF_REFRESH;
                _gtfsSFInterval = DEF_SF_REFRESH;
                _gtfsRTFUrl = DEF_RTF_URL;
                _gtfsSFUrl = DEF_SF_URL;
                _gtfsRTFData = DEF_RTF_DATA;
                _gtfsSFData = DEF_SF_DATA;

                bRet = true;

                Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Successfully intialized with default values.");
            }
            catch (Exception ex)
            {
                if (null != Worker.Instance.Logger)
                {
                    Worker.Instance.Logger.LogMessage(LogPriorityLevel.FatalError, "Failed to setup default values. [Error] {0}.", ex.Message);
                }
            }

            return bRet;
        }

        #endregion //Private Methods
    }
}
