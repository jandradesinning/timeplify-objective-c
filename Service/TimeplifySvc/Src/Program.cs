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
                #if (!DEBUG)
                    ServicesToRun = new ServiceBase[] 
			        { 
				        new TimeplifySvc() 
			        };
                    ServiceBase.Run(ServicesToRun);
                #else
                    // Debug code: this allows the process to run as a non-service.
                    // It will kick off the service start point, but never kill it.
                    // Shut down the debugger to exit
                    TimeplifySvc service = new TimeplifySvc();
                    // Put a breakpoint on the following line to always catch
                    // your service when it has finished its work
                    System.Threading.Thread.Sleep(System.Threading.Timeout.Infinite);
                #endif 
            }
        }
    }
}
