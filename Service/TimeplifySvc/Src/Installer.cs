using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration.Install;
using System.Linq;


namespace Timeplify
{
    [RunInstaller(true)]
    public partial class TimeplifySvcInstaller : Installer
    {
        #region Constructor

        public TimeplifySvcInstaller()
        {
            InitializeComponent();
        }

        #endregion //Constructor

        #region Public Methods

        /// <summary>
        /// Installs the service.
        /// </summary>
        /// <returns>true if success.</returns>            
        public bool Register()
        {
            // Locals
            bool bRet = false;

            try
            {
                SetIntallContext();
                _siTimeplifySvc.Install(new System.Collections.Specialized.ListDictionary());
                bRet = true;
            }
            catch (Exception ex)
            {
                System.Console.WriteLine("TimeplifySvcInstaller: Register " + ex.Message);
            }

            return bRet;
        }

        /// <summary>
        /// Uninstalls the service.
        /// </summary>
        /// <returns></returns>
        public bool UnRegister()
        {
            // Locals
            bool bRet = false;

            try
            {
                SetIntallContext();
                _siTimeplifySvc.Uninstall(null);

                bRet = true;
            }
            catch (Exception ex)
            {
                System.Console.WriteLine("TimeplifySvcInstaller: UnRegister " + ex.Message);
            }

            return bRet;
        }

        #endregion //Public Methods

        #region Private Methods

        private bool SetIntallContext()
        {
            // Locals
            bool bRet = false;
            String strPath = null;
            String[] cmdline = null;
            InstallContext iCntext = null;

            try
            {
                strPath = String.Format("/assemblypath={0}", System.Reflection.Assembly.GetExecutingAssembly().Location);
                cmdline = new String[1];
                cmdline[0] = strPath;
                iCntext = new InstallContext(null, cmdline);

                _siTimeplifySvc.Context = iCntext;

                bRet = true;
            }
            catch (Exception ex)
            {
                System.Console.WriteLine("TimeplifySvcInstaller: SetIntallContext " + ex.Message);
            }

            return bRet;
        }

        #endregion //Private Methods
    }

}