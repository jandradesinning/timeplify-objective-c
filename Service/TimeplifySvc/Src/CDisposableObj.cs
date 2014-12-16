using System;

namespace Timeplify
{
    #region Class - CDisposableObj

    /// <summary>
    /// [Firmusoft] Disposable object.
    /// </summary>
    public class CDisposableObj : IDisposable
    {
        #region Private Members

        /// <summary>
        /// Track whether Dispose has been called.
        /// </summary> 
        protected bool _disposed = false;

        #endregion //Private Members

        #region Constructor

        public CDisposableObj()
        {
            Initialize();
        }

        #endregion //Constructor

        #region Destructor

        ~CDisposableObj()
        {
            UnInitialize();
        }

        #endregion //Destructor

        #region Virtual Methods

        protected virtual bool Initialize()
        {
            return true;
        }

        protected virtual bool UnInitialize()
        {
            return true;
        }

        #endregion //Virtual Methods

        #region Private Methods

        private void Dispose(bool disposing)
        {
            // Check to see if Dispose has already been called.
            if (!_disposed)
            {
                // If disposing equals true, dispose all managed
                // and unmanaged resources.
                if (disposing)
                {
                    UnInitialize();
                }

                // Note disposing has been done.
                _disposed = true;
            }
        }

        #endregion //Private Methods

        #region IDisposable Members

        public void Dispose()
        {
            Dispose(true);
            // This object will be cleaned up by the Dispose method.
            // Therefore, you should call GC.SupressFinalize to
            // take this object off the finalization queue
            // and prevent finalization code for this object
            // from executing a second time.
            GC.SuppressFinalize(this);
        }

        #endregion //IDisposable Members
    }

    #endregion //Class - CDisposableObj
}