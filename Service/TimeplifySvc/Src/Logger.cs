using System;
using System.IO;
using System.Threading;


/// <summary>
/// FileName : Logger.cs
/// The file contains Logger class which is used to log application events
/// and exceptions into a file.
/// </summary>
namespace Timeplify
{
    #region Log level
    /// <summary>
    /// Specifies the log level, NoLogging prevents all logging, Debug enables all levels of logging
    /// </summary>
    public enum LogPriorityLevel
    {
        NoLogging = 0,
        FatalError = 1,
        NonFatalError = 2,
        Warning = 3,
        Informational = 4,
        Functional = 5,
        Debug = 6
    }
    #endregion

    #region Delegate

    public delegate void LoggerDelegate(string logMessage);

    #endregion Delegate

    #region Class Logger

    public class Logger
    {
        #region Constants
        public const int DefaultMaxLogSize = 1024000;
        const string DefaultLogFileName = "AppLogFile";
        const string DefaultLogFilePath = "C:\\";
        #endregion

        #region Privates
        // File Info Variable for File Manipulation
        private FileInfo m_FileInfo;
        // File Stream
        private FileStream m_FileStream;
        // Stream Writer to write to a file
        private StreamWriter m_StreamWriter;
        // The file name
        private string m_LogFileName;
        // The file path
        private string m_LoggerFilePath;
        // The Maximum Size of the File before backup
        private int m_MaxSize;
        // Logging Enabled or not
        private bool m_Enabled;
        // The Loglevel of this Logger 
        private LogPriorityLevel m_LogLevel;
        #endregion

        public LoggerDelegate OnLogMessage;

        #region Constructor
        /// <summary>
        /// FUNCTION     - Logger()
        /// PURPOSE      - Initialize private variables 
        /// PARAMTERS    - 
        /// RETURN VALUE - 
        /// MODIFIED	 - 26/10/2012
        /// </summary> 
        public Logger(string logfilepath, string filename, int logsize)
        {
            // Set Everything to Default values.
            m_MaxSize = logsize;
            m_Enabled = false;
            m_LogFileName = filename;//DefaultLogFileName;
            m_LoggerFilePath = logfilepath;//DefaultLogFilePath;
            m_LogLevel = LogPriorityLevel.Functional;
            OnLogMessage = null;

            // modified to implement three instance
            this.SetLogFilePath(m_LoggerFilePath);
            this.StartLog(m_LogFileName, m_MaxSize, m_LogLevel);
        }
        #endregion

        #region Log functions
        /// <summary>
        /// FUNCTION     - SetLogFilePath
        /// PURPOSE      - Sets the Log File Path to Incomming value.
        /// PARAMTERS    - string logFilePath
        /// RETURN VALUE - 
        /// MODIFIED	 - 14/05/2007 
        /// </summary> 
        virtual public void SetLogFilePath(string logFilePath)
        {
            if (logFilePath != string.Empty)
            {
                m_LoggerFilePath = logFilePath;
            }
        }
        /// <summary>
        /// FUNCTION     - StartLog
        /// PURPOSE      - Starts Logging  
        /// PARAMTERS    - file name, file size limit and log level  
        /// RETURN VALUE - 
        /// MODIFIED	 - 26/10/2012
        /// </summary> 
        virtual public void StartLog(string fileName, int fileSize, LogPriorityLevel priorityLevel)
        {
            m_LogLevel = priorityLevel;
            m_MaxSize = fileSize * 1000;
            if (fileName != string.Empty)
            {
                m_LogFileName = fileName;
            }

            m_Enabled = true;

            LogMessage(LogPriorityLevel.FatalError, "-----------------------------------------------------------------------------------------------");
            LogMessage(LogPriorityLevel.FatalError, "Started Logging with LogLevel: {0} Max FileSize: {1} KBs({2} bytes)",
                        priorityLevel, fileSize, m_MaxSize);
        }

        public void StopLog()
        {
            LogMessage(LogPriorityLevel.FatalError, "Stopped Logging");
            LogMessage(LogPriorityLevel.FatalError, "------------------------------------------------------------------------------------------------");

            //Set Log Enabled flag to false. logging disabled
            m_Enabled = false;
        }


        /// <summary>
        /// FUNCTION     - LogMessage
        /// PURPOSE      - Log passed in string into file.  
        /// PARAMTERS    - 
        /// RETURN VALUE - 
        /// MODIFIED	 - 14/05/2007
        /// </summary> 
        public void LogMessage(LogPriorityLevel priorityLevel, string format, params object[] varList)
        {
            if (m_Enabled == false)
            {
                return;
            }

            // Check LogLevel
            if (priorityLevel == LogPriorityLevel.NoLogging || priorityLevel > m_LogLevel)
            {
                return;
            }

            //try for Format Exceptions
            string buffer = string.Empty;
            try
            {
                buffer = string.Format(format, varList);
            }
            catch
            {
            }

            // Lock this Logger object for Thread Synchronization
            lock (this)
            {
                bool result;
                result = LogInternal(buffer);
            }
        }

        /// <summary>
        /// FUNCTION     - OpenLogFile
        /// PURPOSE      - Open a LogFile with Correct Name Format based on Incomming Name.
        ///                Get Path of Log. Format Name of Log File. Open File.   
        /// PARAMTERS    - Log file name
        /// RETURN VALUE - true/false
        /// MODIFIED	 - 14/05/2007
        /// </summary> 
        private bool OpenLogFile(ref string fileName)
        {
            // Check if path is provided                
            if (m_LoggerFilePath == string.Empty)
            {
                // If no path, Set current directory as path
                m_LoggerFilePath = Directory.GetCurrentDirectory();

                if (m_LoggerFilePath == string.Empty)
                {
                    return false;
                }
            }
            string tempPath;
            tempPath = m_LoggerFilePath;

            // Create File in Path Specified
            try
            {
                CreatePath(tempPath);

                // The new file name
                string newFile = m_LoggerFilePath + "\\" + fileName/* + "-" + DateTime.Now.ToString("ddMMyyyyHHmmss")*/ + ".txt";
                m_FileInfo = new FileInfo(newFile);
                m_FileStream = new FileStream(newFile,
                                            FileMode.OpenOrCreate | FileMode.Append,
                                            FileAccess.Write, FileShare.ReadWrite);

                m_StreamWriter = new StreamWriter(m_FileStream);
            }
            catch
            {
                return false;
            }
            return true;
        }

        /// <summary>
        /// FUNCTION     - CreatePath 
        /// PURPOSE      - Create specified directory tree if 
        ///                incomming directory tree does not exist
        /// PARAMTERS    - log file path
        /// RETURN VALUE - 
        /// MODIFIED	 - 14/05/2007
        /// </summary> 
        private void CreatePath(string logFilePath)
        {
            if (Directory.Exists(logFilePath))
            {
                return;
            }
            else
            {
                Directory.CreateDirectory(logFilePath);
            }
        }

        /// <summary>
        /// FUNCTION     - LogInternal 
        /// PURPOSE      - Open the log file. Create backup if needed. Write iIncomming
        ///                data to log file
        /// PARAMTERS    - log text
        /// RETURN VALUE - true/false
        /// MODIFIED	 - 14/05/2007
        /// </summary> 
        private bool LogInternal(string buffer)
        {
            string fileName = m_LogFileName;

            // Open Log File
            if (!OpenLogFile(ref fileName))
            {
                return false;
            }

            string backupName = string.Format("{0}.bak", fileName);
            fileName = string.Format("{0}.txt", fileName);
            // Get the file size
            long fileSize = m_FileInfo.Length;

            // Check the size limit 
            if (fileSize > m_MaxSize)
            {
                // Close the current Log file
                m_FileStream.Close();
                // Delete current backup file
                RemoveLogFile(backupName);

                // Rename current file as backup File
                if (RenameLogFile(fileName, backupName) == 0)
                {
                    // Failed to rename, so remove all.
                    RemoveLogFile(fileName);
                    RemoveLogFile(backupName);
                }

                fileName = m_LogFileName;

                if (!OpenLogFile(ref fileName))
                {
                    return false;
                }
            }
            // Get the current time, current Thread ID and write to Log file
            try
            {
                DateTime now = DateTime.Now;
                string currentTime = string.Format("{0:yy}{0:MM}{0:dd} {0:HH}:{0:mm}:{0:ss}.{1:000}",
                                                now, now.Millisecond);

                WriteDateToFile(string.Format("{0} {1}\r\n", currentTime, buffer));

                m_StreamWriter.Close();
            }
            catch
            {
                return false;
            }

            return true;
        }

        private bool WriteDateToFile(string data)
        {
            m_StreamWriter.Write(data);
            if (OnLogMessage != null)
                OnLogMessage(data);
            return true;
        }

        /// <summary>
        /// FUNCTION     - RemoveLogFile 
        /// PURPOSE      - Remove the specified file. Get directory. Get formatted 
        ///                file name. Remove it.
        /// PARAMTERS    - File name
        /// RETURN VALUE - true/false (0/1)
        /// MODIFIED	 - 14/05/2007
        /// </summary> 
        private int RemoveLogFile(string fileName)
        {
            string filePath;
            // Get Directory
            if (m_LoggerFilePath.Length == 0)
            {
                filePath = Directory.GetCurrentDirectory();
                if (filePath.Length == 0)
                {
                    return 0;
                }
            }
            else
            {
                filePath = m_LoggerFilePath;
            }
            // Try to Delete File
            try
            {
                File.Delete(string.Format("{0}\\{1}", filePath, fileName));
            }
            catch
            { return 0; }

            return 1;
        }

        /// <summary>
        /// FUNCTION     - RenameLogFile 
        /// PURPOSE      - Rename the specified file.
        ///                Get Directory. Get New & Old Formatted File Names. Rename it.
        /// PARAMTERS    - File name and back up file name
        /// RETURN VALUE - true/false (0/1)
        /// MODIFIED	 - 14/05/2007
        /// </summary> 
        private int RenameLogFile(string fileName, string backupFileName)
        {
            string actualFile;
            string newFile;
            string filePath;

            // Get Dirctory
            if (m_LoggerFilePath.Length == 0)
            {
                filePath = Directory.GetCurrentDirectory();
                if (filePath.Length == 0)
                {
                    return 0;
                }
            }
            else
            {
                filePath = m_LoggerFilePath;
            }
            // Get new and Old Names of File
            actualFile = string.Format("{0}\\{1}", filePath, fileName);
            newFile = string.Format("{0}\\{1}", filePath, backupFileName);
            try
            {
                File.Move(actualFile, newFile);
            }
            catch
            {
            }
            return 1;
        }
        #endregion
    }

    #endregion Class Logger
}