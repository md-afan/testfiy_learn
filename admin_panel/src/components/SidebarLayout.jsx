import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  FiHome,
  FiUsers,
  FiFileText,
  FiCreditCard,
  FiDollarSign,
  FiBell,
  FiLogOut,
  FiMenu,
  FiX,
  FiUser,
  FiSettings,
  FiMoon,
  FiSun,
  FiChevronDown,
} from "react-icons/fi";
import { Link, useLocation, useNavigate, Outlet } from "react-router-dom";
import { auth } from "../services/firebase";
import { useTheme } from "../context/ThemeContext";
import NotificationPopup from "./NotificationPopup";

const SidebarLayout = ({ user }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [notificationOpen, setNotificationOpen] = useState(false);
  const [profileMenuOpen, setProfileMenuOpen] = useState(false);
  const { darkMode, toggleTheme } = useTheme();
  const location = useLocation();
  const navigate = useNavigate();

  const navItems = [
    { path: "/", label: "Dashboard", icon: <FiHome /> },
    { path: "/teacher-requests", label: "Teacher Requests", icon: <FiUsers /> },
    { path: "/tests", label: "Tests", icon: <FiFileText /> },
    { path: "/transactions", label: "Transactions", icon: <FiCreditCard /> },
    { path: "/withdrawals", label: "Withdrawals", icon: <FiDollarSign /> },
    { path: "/notifications", label: "Notifications", icon: <FiBell /> },
    { path: "/profile", label: "Profile", icon: <FiUser /> },
  ];

  const isActive = (path) => location.pathname === path;

  const handleLogout = async () => {
    try {
      await auth.signOut();
      navigate("/login");
    } catch (error) {
      console.error("Logout error:", error);
    }
  };

  // Mock notifications
  const notifications = [
    {
      id: 1,
      title: "New Teacher Request",
      message: "John Smith requested teacher access",
      time: "10 mins ago",
      read: false,
    },
    {
      id: 2,
      title: "Test Created",
      message: "Mathematics Final Exam created by Dr. Sharma",
      time: "45 mins ago",
      read: true,
    },
    {
      id: 3,
      title: "Withdrawal Approved",
      message: "Your ₹2500 withdrawal has been processed",
      time: "2 hours ago",
      read: true,
    },
    {
      id: 4,
      title: "System Update",
      message: "New admin features available in version 2.1",
      time: "1 day ago",
      read: true,
    },
  ];

  const unreadCount = notifications.filter((n) => !n.read).length;

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-900 w-screen">
      {/* Mobile sidebar */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-40 md:hidden">
          <div
            className="fixed inset-0 bg-gray-600 bg-opacity-75"
            onClick={() => setSidebarOpen(false)}
          ></div>
          <motion.div
            initial={{ x: "-100%" }}
            animate={{ x: 0 }}
            exit={{ x: "-100%" }}
            className="relative flex-1 flex flex-col max-w-xs w-full bg-white dark:bg-gray-800"
          >
            <div className="flex items-center justify-between h-16 px-4 border-b dark:border-gray-700">
              <div className="text-xl font-bold text-indigo-600 dark:text-indigo-400">
                Admin Panel
              </div>
              <button
                onClick={() => setSidebarOpen(false)}
                className="p-2 rounded-md text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
              >
                <FiX className="h-6 w-6" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto py-4">
              <nav>
                {navItems.map((item) => (
                  <Link
                    key={item.path}
                    to={item.path}
                    className={`flex items-center px-4 py-3 text-sm font-medium ${
                      isActive(item.path)
                        ? "bg-indigo-50 text-indigo-700 dark:bg-indigo-900/20 dark:text-indigo-300 border-l-4 border-indigo-600 dark:border-indigo-500"
                        : "text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700/50"
                    }`}
                    onClick={() => setSidebarOpen(false)}
                  >
                    <span className="mr-3 text-lg">{item.icon}</span>
                    {item.label}
                  </Link>
                ))}
              </nav>
            </div>
            <div className="p-4 border-t dark:border-gray-700">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center">
                  <div className="bg-indigo-100 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200 rounded-full w-10 h-10 flex items-center justify-center font-bold">
                    {user?.email?.charAt(0).toUpperCase() || "A"}
                  </div>
                  <div className="ml-3">
                    <p className="text-sm font-medium text-gray-800 dark:text-gray-200">
                      {user?.email || "Admin User"}
                    </p>
                    <p className="text-xs text-black dark:text-gray-400">
                      Administrator
                    </p>
                  </div>
                </div>
                <button
                  onClick={toggleTheme}
                  className="p-2 rounded-lg bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 transition"
                >
                  {darkMode ? (
                    <FiSun className="h-5 w-5" />
                  ) : (
                    <FiMoon className="h-5 w-5" />
                  )}
                </button>
              </div>
              <button
                onClick={handleLogout}
                className="w-full flex items-center justify-center text-gray-600 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-500"
              >
                <FiLogOut className="mr-2" /> Logout
              </button>
            </div>
          </motion.div>
        </div>
      )}

      {/* Desktop sidebar */}
      <div className="hidden md:flex md:flex-shrink-0">
        <div className="flex flex-col w-64 bg-white dark:bg-gray-800 border-r dark:border-gray-700">
          <div className="h-16 flex items-center px-4 border-b dark:border-gray-700">
            <div className="text-xl font-bold text-indigo-600 dark:text-indigo-400">
              Admin Panel 
            </div>
          </div>
          <div className="flex-1 overflow-y-auto py-4">
            <nav>
              {navItems.map((item) => (
                <Link
                  key={item.path}
                  to={item.path}
                  className={`flex items-center px-4 py-3 text-sm font-medium ${
                    isActive(item.path)
                      ? "bg-indigo-50 text-indigo-700 dark:bg-indigo-900/20 dark:text-indigo-300 border-l-4 border-indigo-600 dark:border-indigo-500"
                      : "text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-700/50"
                  }`}
                >
                  <span className="mr-3 text-lg">{item.icon}</span>
                  {item.label}
                </Link>
              ))}
            </nav>
          </div>
          <div className="p-4 border-t dark:border-gray-700">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center">
                <div className="bg-indigo-100 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200 rounded-full w-10 h-10 flex items-center justify-center font-bold">
                  {user?.email?.charAt(0).toUpperCase() || "A"}
                </div>
                <div className="ml-3">
                  <p className="text-sm font-medium text-gray-800 dark:text-gray-200">
                    {user?.email || "Admin User"}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">
                    Administrator
                  </p>
                </div>
              </div>
              <button
                onClick={toggleTheme}
                className="p-2 rounded-lg bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600 transition"
              >
                {darkMode ? (
                  <FiSun className="h-5 w-5" />
                ) : (
                  <FiMoon className="h-5 w-5" />
                )}
              </button>
            </div>
            <button
              onClick={handleLogout}
              className="w-full flex items-center justify-center text-gray-600 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-500"
            >
              <FiLogOut className="mr-2" /> Logout
            </button>
          </div>
        </div>
      </div>

      <div className="flex-1 flex flex-col overflow-hidden ">
        {/* Top bar */}
        <header className="bg-white dark:bg-gray-800 shadow-sm z-10">
          <div className="flex items-center justify-between h-16 px-4">
            <button
              type="button"
              className="md:hidden text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
              onClick={() => setSidebarOpen(true)}
            >
              <FiMenu className="h-6 w-6" />
            </button>
            <div className="flex-1"></div>
            <div className="ml-4 flex items-center gap-4">
              <div className="relative">
                <button
                  onClick={() => setNotificationOpen(!notificationOpen)}
                  className="p-2 rounded-full text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 relative"
                >
                  <FiBell className="h-5 w-5" />
                  {unreadCount > 0 && (
                    <span className="absolute top-0 right-0 w-5 h-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">
                      {unreadCount}
                    </span>
                  )}
                </button>

                <AnimatePresence>
                  {notificationOpen && (
                    <NotificationPopup
                      notifications={notifications}
                      onClose={() => setNotificationOpen(false)}
                    />
                  )}
                </AnimatePresence>
              </div>

              <div className="relative">
                <button
                  onClick={() => setProfileMenuOpen(!profileMenuOpen)}
                  className="flex items-center gap-2 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-full p-1 pl-3 transition"
                >
                  <div className="text-left hidden md:block">
                    <p className="text-sm font-medium text-gray-800 dark:text-gray-200 truncate max-w-[120px]">
                      {user?.displayName || user?.email || "Admin User"}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">
                      Administrator
                    </p>
                  </div>
                  <div className="bg-indigo-100 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200 rounded-full w-8 h-8 flex items-center justify-center font-bold">
                    {user?.email?.charAt(0).toUpperCase() || "A"}
                  </div>
                  <FiChevronDown className="mr-2 text-gray-500 dark:text-gray-400" />
                </button>

                <AnimatePresence>
                  {profileMenuOpen && (
                    <motion.div
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: 10 }}
                      className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg py-1 z-50"
                    >
                      <Link
                        to="/profile"
                        className="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                        onClick={() => setProfileMenuOpen(false)}
                      >
                        <FiUser className="mr-2" /> Profile
                      </Link>
                      <Link
                        to="/settings"
                        className="flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                        onClick={() => setProfileMenuOpen(false)}
                      >
                        <FiSettings className="mr-2" /> Settings
                      </Link>
                      <button
                        onClick={handleLogout}
                        className="w-full text-left flex items-center px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                      >
                        <FiLogOut className="mr-2" /> Logout
                      </button>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            </div>
          </div>
        </header>

        {/* Main content */}
        <main className="flex-1 overflow-y-auto p-4 bg-gray-50 dark:bg-gray-900 ">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default SidebarLayout;
