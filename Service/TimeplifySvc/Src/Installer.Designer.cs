namespace Timeplify
{
    partial class TimeplifySvcInstaller
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this._spiTimeplifySvc = new System.ServiceProcess.ServiceProcessInstaller();
            this._siTimeplifySvc = new System.ServiceProcess.ServiceInstaller();

            try
            {
                // 
                // _spiTimeplifySvc
                // 
                this._spiTimeplifySvc.Account = System.ServiceProcess.ServiceAccount.LocalService;
                this._spiTimeplifySvc.Installers.AddRange(new System.Configuration.Install.Installer[] {
			    this._siTimeplifySvc});
                this._spiTimeplifySvc.Password = null;
                this._spiTimeplifySvc.Username = null;
                // 
                // _siTimeplifySvc
                // 
                this._siTimeplifySvc.DisplayName = "Timeplify Service";
                this._siTimeplifySvc.ServiceName = "timeplifysvc";
                this._siTimeplifySvc.Description = "Timeplify backend update service";

                // 
                // TimeplifySvcInstaller
                // 
                this.Installers.AddRange(new System.Configuration.Install.Installer[] {
                this._spiTimeplifySvc});
            }
            catch (System.Exception ex)
            {
                System.Console.WriteLine("TimeplifySvcInstaller: InitializeComponent " + ex.Message);
            }
        }

        #endregion

        private System.ServiceProcess.ServiceProcessInstaller _spiTimeplifySvc;
        private System.ServiceProcess.ServiceInstaller _siTimeplifySvc;
    }
}
