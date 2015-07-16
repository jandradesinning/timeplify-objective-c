using System;
using System.IO;
using System.Reflection;

namespace Timeplify
{
    /// <summary>
    /// [Firmusoft] The main initiator.
    /// </summary>
    class Worker : CDisposableObj
    {
        #region Private Static Members

        /// <summary>
        /// For Accessing the properties.
        /// </summary>
        private static Worker _instance;

        #endregion //Private Static Members

        #region Private Members

        private Config _config = null;
        private Logger _appLogger = null;
        private Processor _processor = null;
        private Type _parentType = null;

        #endregion //Private Members

        #region Constructor

        public Worker(Type classType)
        {
            _parentType = classType;
        }

        #endregion //Constructor

        #region Destructor

        ~Worker()
        {
        }

        #endregion //Destructor

        #region Properties

        /// <summary>
        /// For Accessing the properties.
        /// </summary>
        public static Worker Instance
        {
            get
            {
                return _instance;
            }
        }

        public Config Configuration
        {
            get
            {
                return _config;
            }
        }

        public Logger Logger
        {
            get
            {
                return _appLogger;
            }
            set
            {
                _appLogger = value;
            }
        }

        public string ApplicationPath
        {
            get
            {
                return Path.GetDirectoryName(Assembly.GetAssembly(_parentType).CodeBase).Replace("file:\\", "");
            }
        }

        public string ApplicationName
        {
            get
            {
                return System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;
            }
        }

        #endregion //Properties

        #region Methods

        #endregion Methods

        #region CDisposableObj Members

        /// <summary>
        /// Initialize the resources.
        /// </summary>
        /// <returns>true if success.</returns>
        protected override bool Initialize()
        {
            // Locals
            bool bRet = false;

            try
            {
                _instance = this;

                //System.Diagnostics.Debug.Assert(false);

                _config = new Config();

                bRet = null != _config;

                if (bRet)
                {
                    _processor = new Processor();
                }

                if (null != _appLogger)
                {
                    _appLogger.LogMessage(LogPriorityLevel.Informational, "Successfully started Timeplify Service.");
                }
            }
            catch (Exception ex)
            {
                if (null != _appLogger)
                {
                    _appLogger.LogMessage(LogPriorityLevel.FatalError, "Failed to start Timeplify Service {0}", ex.Message);

                }
            }

            return bRet;
        }

        /// <summary>
        /// UnInitialize the resources.
        /// </summary>
        /// <returns>true if success.</returns>            
        protected override bool UnInitialize()
        {
            try
            {
                _processor.Dispose();
                _config.Dispose();

                if (null != _appLogger)
                {
                    _appLogger.LogMessage(LogPriorityLevel.Informational, "Successfully stopped CSSE Service.");
                }

                _appLogger.StopLog();

                _config = null;
                _appLogger = null;
                _processor = null;
            }
            catch (Exception ex)
            {
                if (null != _appLogger)
                {
                    _appLogger.LogMessage(LogPriorityLevel.Informational, "Failed to stop CSSE Service. [Error] {0}.", ex.Message);
                }
            }

            return base.UnInitialize();
        }

        #endregion //CDisposableObj Members
    }
}
