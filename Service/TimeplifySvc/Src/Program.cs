using System.ServiceProcess;
using System.Windows.Forms;

namespace Timeplify
{    
    static class Program
    {
        /// <summary>
        /// [Firmusoft] The main entry point for the application.
        /// </summary>
        static void Main(string[] args)
        {
            // Locals
            ServiceBase[] ServicesToRun = null;
            TimeplifySvcInstaller projInstaller = null;

            // Handle command line arguments.
            if (null != args && 0 != args.Length)
            {
                if ("-i" == args[0])
                {
                    projInstaller = new TimeplifySvcInstaller();
                    projInstaller.Register();
                }
                else if ("-u" == args[0])
                {
                    projInstaller = new TimeplifySvcInstaller();
                    projInstaller.UnRegister();
                }
            }
            else
            {
                ServicesToRun = new ServiceBase[] 
			    { 
				    new TimeplifySvc() 
			    };
                ServiceBase.Run(ServicesToRun);
            }
        }
    }
}
