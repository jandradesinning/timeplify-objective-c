using System.ServiceProcess;
using System.Diagnostics;

namespace Timeplify
{
    public partial class TimeplifySvc : ServiceBase
    {
        #region Private Static Members

        /// <summary>
        /// For Accessing the properties.
        /// </summary>
        private static TimeplifySvc _instance;

        #endregion //Private Static Members

        #region Private Members

        private Worker _csseWorker = null;
        private bool _forceStop = false;

        #endregion //Private Members

        #region Constructor

        public TimeplifySvc()
        {
            this.CanShutdown = true;
            this.CanStop = true;

            InitializeComponent();
            Initialize();
        }

        #endregion //Constructor

        #region Destructor

        ~TimeplifySvc()
        {
            UnInitialize();
        }

        #endregion //Destructor

        #region Overrides

        /// <summary>
        /// Invokes initialization.
        /// </summary>
        /// <param name="args"></param>
        protected override void OnStart(string[] args)
        {
            Worker.Instance.Logger.LogMessage(LogPriorityLevel.Informational, "Starting Service ......");

            Initialize();
        }

        private void Initialize()
        {
            _instance = this;

            if (null == _csseWorker)
            {
                _csseWorker = new Worker();
            }
        }

        /// <summary>
        /// Invokes uninitialization.
        /// </summary>
        protected override void OnStop()
        {
            Worker.Instance.Logger.LogMessage(LogPriorityLevel.NonFatalError, "Stopping Service ..... ");
            UnInitialize();

            if (_forceStop)
            {
                OnShutdown();
                // Service doesn't seems to stop automatically, so purposefully killing app after uninitializing.
                // What is the correct solution here OR what is the issue in exiting normally when request is received?
                KillService();
            }
        }

        protected override void OnShutdown()
        {
            base.OnShutdown();
        }

        private void UnInitialize()
        {
            if (null != _csseWorker)
            {
                _csseWorker.Dispose();
                _csseWorker = null;
            }
        }

        #endregion //Overrides

        #region Properties

        /// <summary>
        /// For Accessing the properties.
        /// </summary>
        public static TimeplifySvc Instance
        {
            get
            {
                return _instance;
            }
        }

        #endregion //Properties

        #region Methods

        public void ForceStop()
        {
            try
            {
                _forceStop = true;
                this.Stop();
            }
            catch
            {
            }
        }

        private void KillService()
        {
            Process serviceProcess = null;

            try
            {
                serviceProcess = Process.GetCurrentProcess();

                if (null != serviceProcess)
                {
                    serviceProcess.Kill();
                }
            }
            catch
            {
            }
        }

        #endregion Methods
    }
}