import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { FiBell, FiCheck, FiX } from "react-icons/fi";

const NotificationPopup = ({ notifications, onClose }) => {
  const unreadNotifications = notifications.filter(n => !n.read);
  const readNotifications = notifications.filter(n => n.read);

  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -10 }}
      className="absolute right-0 mt-2 w-80 bg-white dark:bg-gray-800 rounded-lg shadow-xl z-50 border dark:border-gray-700"
    >
      <div className="p-4 border-b dark:border-gray-700">
        <div className="flex justify-between items-center">
          <h3 className="font-semibold text-gray-800 dark:text-gray-200 flex items-center">
            <FiBell className="mr-2" /> Notifications
          </h3>
          <button 
            onClick={onClose}
            className="text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
          >
            <FiX />
          </button>
        </div>
      </div>
      
      <div className="max-h-96 overflow-y-auto">
        {unreadNotifications.length > 0 && (
          <>
            <div className="px-4 py-2 text-xs font-medium text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-700">
              New
            </div>
            {unreadNotifications.map(notification => (
              <div 
                key={notification.id}
                className="p-4 border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition"
              >
                <div className="flex justify-between">
                  <h4 className="font-medium text-gray-800 dark:text-gray-200">
                    {notification.title}
                  </h4>
                  <span className="text-xs text-gray-500 dark:text-gray-400">
                    {notification.time}
                  </span>
                </div>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {notification.message}
                </p>
              </div>
            ))}
          </>
        )}
        
        {readNotifications.length > 0 && (
          <>
            <div className="px-4 py-2 text-xs font-medium text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-700">
              Earlier
            </div>
            {readNotifications.map(notification => (
              <div 
                key={notification.id}
                className="p-4 border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition"
              >
                <div className="flex justify-between">
                  <h4 className="font-medium text-gray-800 dark:text-gray-200">
                    {notification.title}
                  </h4>
                  <span className="text-xs text-gray-500 dark:text-gray-400">
                    {notification.time}
                  </span>
                </div>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {notification.message}
                </p>
              </div>
            ))}
          </>
        )}
        
        {notifications.length === 0 && (
          <div className="p-8 text-center">
            <FiBell className="mx-auto text-3xl text-gray-400 mb-2" />
            <p className="text-gray-500 dark:text-gray-400">No notifications</p>
          </div>
        )}
      </div>
      
      <div className="p-3 border-t dark:border-gray-700 text-center">
        <button className="text-sm text-indigo-600 dark:text-indigo-400 hover:underline">
          Mark all as read
        </button>
      </div>
    </motion.div>
  );
};

export default NotificationPopup;